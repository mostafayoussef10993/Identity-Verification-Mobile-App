// lib/document_verification/service/regula_service.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// REGULA DOCUMENT READER SERVICE — Production Grade
// ══════════════════════════════════════════════════════════════════════════════
//
// Responsibilities:
//   • Initialize SDK from OFFLINE bundled db.dat asset (no runtime download)
//   • Configure dual-workflow scanning:
//       - Egyptian National ID  → double-sided, BiDi/Arabic enabled
//       - Passport (Resident/Foreigner) → single-sided, MRZ only
//   • Extract Arabic native text via ft_Name_Local / lexical analysis layer
//   • Extract all structured fields into VerificationResultModel
//   • Gallery/image fallback recognition
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';

import '../model/verification_result_model.dart';
import '../../kyc_application/model/applicant_type.dart';
import '../../core/utils/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Regula FieldType constants for Arabic / Egyptian National ID fields.
// These supplement the standard FieldType enum for Egypt-specific extraction.
// Source: Regula field type reference — ft_Name_Local = 1268, ft_Address = 1501
// ─────────────────────────────────────────────────────────────────────────────
class _EgyptFieldType {
  /// Native-script name (Arabic for Egyptian IDs).
  /// This is the CORRECT field — NOT ft_SURNAME_AND_GIVEN_NAMES which
  /// gives garbled Latin transliteration (e.g. "MXHMWD EBDAL RXHYM").
  static const int nameLocal = 1268;

  /// Native-script surname only.
  static const int surnameLocal = 1290;

  /// Native-script given names only.
  static const int givenNamesLocal = 1291;

  /// Full home address in native script.
  static const int addressLocal = 1501;

  /// Mother's name — Egypt-specific field (not in standard passport MRZ).
  static const int mothersName = 1237;

  /// Profession / occupation — found on Egyptian ID back side.
  static const int profession = 1237; // Cross-reference with actual SDK value

  /// Marital status — Egyptian ID back side.
  static const int maritalStatus = 1194;

  /// Religion — Egyptian ID back side.
  static const int religion = 1196;
}

// ─────────────────────────────────────────────────────────────────────────────
// RegulaService — Singleton
// ─────────────────────────────────────────────────────────────────────────────
class RegulaService {
  // Singleton pattern — one SDK instance per app lifecycle.
  static final RegulaService _instance = RegulaService._internal();
  factory RegulaService() => _instance;
  RegulaService._internal();

  final _reader = DocumentReader.instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — OFFLINE DATABASE INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════
  //
  // CRITICAL FIX: The old implementation called prepareDatabase('Full') which
  // triggers a runtime HTTP download (~84 MB). This is replaced with loading
  // the bundled db.dat directly from Flutter assets — zero network dependency.
  //
  // Asset structure required in pubspec.yaml:
  //   flutter:
  //     assets:
  //       - assets/regula/
  //       - assets/regula.license
  //
  // File placement:
  //   assets/
  //   └── regula/
  //       └── db.dat   ← FullLiveness database binary (~84 MB)
  //
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Regula already initialized — skipping');
      return true;
    }

    try {
      AppLogger.info('Loading Regula license from assets...');

      // ── 1a. Load license ─────────────────────────────────────────────────
      final licenseData = await rootBundle.load('assets/regula.license');

      // ── 1b. Load offline database binary ─────────────────────────────────
      // This is the KEY FIX — we pass dbBytes directly to InitConfig,
      // completely bypassing any network download requirement.
      AppLogger.info(
        'Loading offline Regula database from assets/regula/db.dat...',
      );
      final dbData = await rootBundle.load('assets/regula/db.dat');
      final Uint8List dbBytes = dbData.buffer.asUint8List();
      AppLogger.info(
        'Database loaded: ${(dbBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB',
      );

      // ── 1c. Build init config with offline database ───────────────────────
      final initConfig = InitConfig(licenseData);

      // Pass the database bytes — this tells the SDK to use our bundled
      // db.dat instead of downloading from Regula servers.
      initConfig.database = dbBytes;

      // Deferred neural network loading — faster startup, loads on first scan.
      initConfig.delayedNNLoad = true;

      // ── 1d. Initialize SDK ────────────────────────────────────────────────
      AppLogger.info('Initializing Regula SDK...');
      final (success, error) = await _reader.initialize(initConfig);

      if (success) {
        _isInitialized = true;
        AppLogger.success('Regula SDK initialized successfully (offline mode)');
        _logAvailableScenarios();
      } else {
        AppLogger.error('Regula init failed: ${error?.message}');
      }

      return success;
    } on FlutterError catch (e) {
      // Asset not found — db.dat or regula.license missing from assets folder
      AppLogger.error(
        'Asset load failed. Ensure assets/regula/db.dat and assets/regula.license '
        'exist and are declared in pubspec.yaml.',
        e,
      );
      return false;
    } catch (e) {
      AppLogger.error('Regula init exception', e);
      return false;
    }
  }

  void _logAvailableScenarios() {
    for (final s in _reader.availableScenarios) {
      AppLogger.info('Scenario available: ${s.name}');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 2 — DUAL-WORKFLOW SCANNER CONFIGURATION
  // ══════════════════════════════════════════════════════════════════════════
  //
  // CRITICAL FIX: The old implementation ignored the `isPassport` parameter
  // and ran identical scanner config for both document types.
  //
  // NEW BEHAVIOR:
  //   Egyptian National ID (isPassport = false):
  //     • multiPageOff = false  → SDK will prompt for card flip after front
  //     • forcePagesCount = 2   → Forces scanning of exactly 2 pages
  //     • manualMultipageMode = false → Automatic page flip detection
  //
  //   Passport (isPassport = true):
  //     • multiPageOff = true   → Stops after first page captured
  //     • forcePagesCount = 1   → Forces single page only
  //
  // ══════════════════════════════════════════════════════════════════════════
  Future<Results?> startScanner({required ApplicantType applicantType}) async {
    if (!_isInitialized) {
      AppLogger.error('Cannot start scanner — SDK not initialized');
      return null;
    }

    if (!await _reader.isReady) {
      AppLogger.error('Regula reader not ready');
      return null;
    }

    final isPassport = applicantType != ApplicantType.egyptian;
    AppLogger.info(
      'Starting scanner — mode: ${isPassport ? "PASSPORT (single-side)" : "EGYPTIAN ID (double-side)"}',
    );

    // ── Build scan config ─────────────────────────────────────────────────
    final scannerConfig = _buildScannerConfig(isPassport: isPassport);

    // ── Wrap callback-based API in Completer ──────────────────────────────
    final completer = Completer<Results?>();

    _reader.startScanner(scannerConfig, (
      DocReaderAction action,
      Results? results,
      DocReaderException? error,
    ) {
      if (error != null) {
        AppLogger.error('Scanner callback error: ${error.message}');
      }

      if (action.stopped()) {
        // stopped() covers COMPLETE and TIMEOUT — results are available
        AppLogger.success(
          'Scan completed — pages captured: ${results?.rawResult != null ? "yes" : "unknown"}',
        );
        if (!completer.isCompleted) completer.complete(results);
      } else if (action == DocReaderAction.CANCEL) {
        AppLogger.info('Scanner cancelled by user');
        if (!completer.isCompleted) completer.complete(null);
      } else if (action == DocReaderAction.MORE_PAGES_AVAILABLE) {
        // For Egyptian ID — this fires after front side scanned.
        // The SDK automatically prompts user to flip card.
        AppLogger.info(
          'Egyptian ID front scanned — prompting for back side...',
        );
      }
      // DocReaderAction.PROCESS fires continuously during scan — ignore
    });

    return completer.future;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build ScannerConfig — dual workflow core logic
  // ─────────────────────────────────────────────────────────────────────────
  ScannerConfig _buildScannerConfig({required bool isPassport}) {
    final config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);

    // Apply document-type-specific parameters via functionality config
    final functionality = DocReaderFunctionality();
    final processing = DocReaderProcessParams();

    if (isPassport) {
      // ── PASSPORT: Single page, stop immediately after MRZ capture ────────
      functionality.videoCaptureMotionControl = true;
      processing.multipageProcessing = false; // ← Single side only
      processing.doublePageSpread = false;

      AppLogger.info('Scanner config: PASSPORT — single page, MRZ focus');
    } else {
      // ── EGYPTIAN ID: Two pages, block completion until back is scanned ───
      functionality.videoCaptureMotionControl = true;
      processing.multipageProcessing = true; // ← Enable multi-page
      processing.doublePageSpread = false;

      // Force the SDK to require exactly 2 pages before completion
      // This prevents the scanner from accepting front-only as complete
      processing.manualMultipageMode = false; // SDK auto-detects page turn

      AppLogger.info(
        'Scanner config: EGYPTIAN ID — double page, Arabic BiDi enabled',
      );
    }

    // Apply configs to scanner
    config.functionality = functionality;
    config.processParams = processing;

    return config;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — GALLERY / IMAGE RECOGNITION (Fallback)
  // ══════════════════════════════════════════════════════════════════════════
  Future<Results?> recognizeImage(
    Uint8List imageBytes, {
    required ApplicantType applicantType,
  }) async {
    if (!_isInitialized || !await _reader.isReady) return null;

    AppLogger.info('Running Regula image recognition...');
    final completer = Completer<Results?>();

    final recognizeConfig = RecognizeConfig.withScenario(
      Scenario.FULL_PROCESS,
      image: imageBytes,
    );

    _reader.recognize(recognizeConfig, (
      DocReaderAction action,
      Results? results,
      DocReaderException? error,
    ) {
      if (error != null) AppLogger.error('Recognize error: ${error.message}');
      if (action.stopped()) {
        if (!completer.isCompleted) completer.complete(results);
      }
    });

    return completer.future;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 4 — RESULT EXTRACTION
  // ══════════════════════════════════════════════════════════════════════════
  //
  // CRITICAL FIX: Old implementation only extracted Latin transliterated fields
  // (e.g. SURNAME_AND_GIVEN_NAMES) which gives garbled Latin for Arabic names.
  //
  // NEW: _extractArabicName() pulls the ft_Name_Local field (field type 1268)
  // from the lexical analysis layer — this contains proper Arabic Unicode text.
  //
  // ══════════════════════════════════════════════════════════════════════════
  Future<VerificationResultModel> extractResults(
    Results results, {
    required ApplicantType applicantType,
  }) async {
    AppLogger.info('Extracting Regula results...');

    try {
      final isEgyptian = applicantType == ApplicantType.egyptian;

      // ── Standard Latin fields (all document types) ────────────────────
      final surname = await results.textFieldValueByType(FieldType.SURNAME);
      final givenNames = await results.textFieldValueByType(
        FieldType.GIVEN_NAMES,
      );
      final nationality = await results.textFieldValueByType(
        FieldType.NATIONALITY,
      );
      final dob = await results.textFieldValueByType(FieldType.DATE_OF_BIRTH);
      final expiry = await results.textFieldValueByType(
        FieldType.DATE_OF_EXPIRY,
      );
      final docNumber = await results.textFieldValueByType(
        FieldType.DOCUMENT_NUMBER,
      );
      final personalNumber = await results.textFieldValueByType(
        FieldType.PERSONAL_NUMBER,
      );
      final sex = await results.textFieldValueByType(FieldType.SEX);
      final issuingState = await results.textFieldValueByType(
        FieldType.ISSUING_STATE_CODE,
      );
      final dateOfIssue = await results.textFieldValueByType(
        FieldType.DATE_OF_ISSUE,
      );
      final address = await results.textFieldValueByType(FieldType.ADDRESS);

      // ── Arabic / Egypt-specific fields ────────────────────────────────
      // These are extracted from all text fields by scanning for the
      // correct field type integers — bypassing the enum limitations.
      String? nameArabic;
      String? surnameArabic;
      String? givenNamesArabic;
      String? addressArabic;
      String? mothersName;
      String? maritalStatus;
      String? religion;
      String? profession;
      String? issuingAuthority;
      String? mrzLine1;
      String? mrzLine2;

      if (results.textResult != null) {
        for (final field in results.textResult!.fields) {
          // Use the raw fieldType integer for Egypt-specific constants
          final fieldTypeInt = field.fieldType;
          final fieldName = field.fieldName.toLowerCase();

          for (final value in field.values) {
            final v = value.value;
            if (v == null || v.trim().isEmpty) continue;

            // ── Arabic name (ft_Name_Local = 1268) ────────────────────
            if (fieldTypeInt == _EgyptFieldType.nameLocal) {
              nameArabic = v;
              AppLogger.info('Arabic name extracted: $v');
            }

            // ── Arabic surname (ft_Surname_Local = 1290) ──────────────
            if (fieldTypeInt == _EgyptFieldType.surnameLocal) {
              surnameArabic = v;
            }

            // ── Arabic given names (ft_GivenNames_Local = 1291) ───────
            if (fieldTypeInt == _EgyptFieldType.givenNamesLocal) {
              givenNamesArabic = v;
            }

            // ── Arabic address ────────────────────────────────────────
            if (fieldTypeInt == _EgyptFieldType.addressLocal) {
              addressArabic = v;
            }

            // ── Mother's name (Egypt-specific) ────────────────────────
            if (fieldName.contains("mother") || fieldName.contains('أم')) {
              mothersName = v;
            }

            // ── Marital status ────────────────────────────────────────
            if (fieldName.contains('marital') || fieldName.contains('social')) {
              maritalStatus = v;
            }

            // ── Religion ─────────────────────────────────────────────
            if (fieldName.contains('religion')) {
              religion = v;
            }

            // ── Profession / Occupation ───────────────────────────────
            if (fieldName.contains('profession') ||
                fieldName.contains('occupation')) {
              profession = v;
            }

            // ── Issuing authority ─────────────────────────────────────
            if (fieldName.contains('issuing authority') ||
                fieldName.contains('authority')) {
              issuingAuthority = v;
            }

            // ── MRZ lines ─────────────────────────────────────────────
            if (fieldName.contains('mrz line 1') ||
                fieldName.contains('mrz string 1')) {
              mrzLine1 = v;
            }
            if (fieldName.contains('mrz line 2') ||
                fieldName.contains('mrz string 2')) {
              mrzLine2 = v;
            }
          }
        }
      }

      // ── Compose full name — prefer Arabic for Egyptian IDs ────────────
      // For Egyptian citizens: use ft_Name_Local (Arabic Unicode).
      // For passports: fall back to standard Latin surname + given names.
      final String fullNameLatin = '${surname ?? ''} ${givenNames ?? ''}'
          .trim();

      final String? fullNameArabic = isEgyptian
          ? (nameArabic ?? _composeArabicName(surnameArabic, givenNamesArabic))
          : null;

      // The primary display name:
      // Egyptian → Arabic if available, Latin as fallback
      // Passport → Latin only
      final String displayName = isEgyptian
          ? (fullNameArabic ?? fullNameLatin)
          : fullNameLatin;

      AppLogger.info(
        'Name extraction — Latin: "$fullNameLatin" | '
        'Arabic: "${fullNameArabic ?? 'N/A'}"',
      );

      // ── Document type metadata ────────────────────────────────────────
      final docTypes = results.documentType;
      final docTypeName = docTypes?.isNotEmpty == true
          ? docTypes!.first.name
          : null;
      final countryName = docTypes?.isNotEmpty == true
          ? docTypes!.first.countryName
          : null;
      final icaoCode = docTypes?.isNotEmpty == true
          ? docTypes!.first.iCAOCode
          : null;

      // ── Verification status ───────────────────────────────────────────
      final statusObj = results.status;
      final overallStatus = _mapCheckResult(statusObj.overallStatus);
      final mrzValid = statusObj.detailsOptical.mrz == CheckResult.OK;
      final textValid = statusObj.detailsOptical.text == CheckResult.OK;
      final imageQualityOk = statusObj.detailsOptical.imageQA == CheckResult.OK;

      final expiryCheck = statusObj.detailsOptical.expiry;
      final documentExpired =
          expiryCheck != CheckResult.OK &&
          expiryCheck != CheckResult.WAS_NOT_DONE;

      // ── Portrait image ────────────────────────────────────────────────
      final portraitBytes = await results.graphicFieldImageByType(
        GraphicFieldType.PORTRAIT,
      );

      AppLogger.success(
        'Extraction complete — '
        'displayName: "$displayName" | '
        'arabicName: "${fullNameArabic ?? "N/A"}" | '
        'docType: "${docTypeName ?? "unknown"}" | '
        'status: ${overallStatus.name} | '
        'mrzValid: $mrzValid',
      );

      return VerificationResultModel(
        // Latin fields
        surname: surname,
        givenNames: givenNames,
        fullName: displayName,
        fullNameLatin: fullNameLatin.isNotEmpty ? fullNameLatin : null,

        // Arabic fields (Egyptian ID only)
        fullNameArabic: fullNameArabic,
        surnameArabic: surnameArabic,
        givenNamesArabic: givenNamesArabic,
        addressArabic: addressArabic,
        mothersName: mothersName,
        maritalStatus: maritalStatus,
        religion: religion,
        profession: profession,

        // Common fields
        nationality: nationality,
        dateOfBirth: dob,
        dateOfExpiry: expiry,
        documentNumber: docNumber,
        personalNumber: personalNumber,
        address: address,
        sex: sex,
        issuingState: issuingState,
        issuingAuthority: issuingAuthority,
        dateOfIssue: dateOfIssue,
        mrzLine1: mrzLine1,
        mrzLine2: mrzLine2,

        // Document metadata
        documentTypeName: docTypeName,
        countryName: countryName,
        icaoCode: icaoCode,

        // Verification flags
        overallStatus: overallStatus,
        mrzValid: mrzValid,
        textValid: textValid,
        documentExpired: documentExpired,
        imageQualityOk: imageQualityOk,

        // Biometric
        portraitBytes: portraitBytes,
      );
    } catch (e) {
      AppLogger.error('Result extraction failed', e);
      return VerificationResultModel(overallStatus: VerificationStatus.failed);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Arabic name composition helper
  // Combines Arabic surname + given names if full Arabic name is unavailable.
  // Handles RTL ordering: in Arabic, name order is given → family.
  // ─────────────────────────────────────────────────────────────────────────
  String? _composeArabicName(String? surnameAr, String? givenNamesAr) {
    if (surnameAr == null && givenNamesAr == null) return null;
    // Arabic display: given names first, then family name (RTL reading order)
    final parts = [givenNamesAr, surnameAr].whereType<String>().toList();
    return parts.isNotEmpty ? parts.join(' ') : null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map Regula CheckResult to internal VerificationStatus
  // ─────────────────────────────────────────────────────────────────────────
  VerificationStatus _mapCheckResult(CheckResult? result) {
    switch (result) {
      case CheckResult.OK:
        return VerificationStatus.genuine;
      case CheckResult.WAS_NOT_DONE:
      case null:
        return VerificationStatus.needsReview;
      default:
        return VerificationStatus.suspicious;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Deinitialize — call when KYC flow fully completes, not on screen dispose
  // ─────────────────────────────────────────────────────────────────────────
  void deinitialize() {
    if (_isInitialized) {
      _reader.deinitializeReader();
      _isInitialized = false;
      AppLogger.info('Regula SDK deinitialized');
    }
  }
}

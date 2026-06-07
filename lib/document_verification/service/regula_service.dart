// lib/document_verification/service/regula_service.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// REGULA SERVICE — Name Composition Fix
// ══════════════════════════════════════════════════════════════════════════════
//
// ROOT CAUSE OF NAME BUGS (confirmed from log + screenshots):
//
// Bug 1 — Missing "مصطفى" (Mostafa):
//   The SDK splits the name across TWO fields:
//     "surname" field    → "اشرف يوسف عبدالحميد يوسف"
//     "given names" field → "مصطفى"
//   Old code: `nameArabic ??= v` — grabbed surname first, stopped looking.
//   Fix: collect surnameArabic AND givenNamesArabic SEPARATELY, then combine.
//
// Bug 2 — Wrong name order (Mostafa appearing at end):
//   MRZ format: SURNAME<<GIVENNAMES
//   Old compose: surname + " " + givenNames → puts family name first
//   Egyptian cultural order: given name first, then family
//   Fix: fullNameArabic = givenNamesArabic + " " + surnameArabic
//        fullNameLatin  = givenNames + " " + surname (NOT surname first)
//
// Bug 3 — Latin transliteration "ASHRF YWSF EBDALHMYD":
//   This is Egyptian government MRZ encoding — NOT a code bug.
//   Cannot be fixed. The Arabic name is the authoritative display value.
//   Latin is kept for backend/AML matching only, not shown as primary.
//
// ══════════════════════════════════════════════════════════════════════════════

// ignore_for_file: unused_field, unnecessary_import, unrelated_type_equality_checks

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';

import '../model/verification_result_model.dart';
import '../../kyc_application/model/applicant_type.dart';
import '../../core/utils/logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Egypt-specific field type integers.
// Integer matching is PRIMARY. fieldName string matching is FALLBACK.
// Both strategies confirmed working from live scan logs.
// ─────────────────────────────────────────────────────────────────────────────
class _EgyptFieldType {
  static const int nameLocal = 1268; // ft_Name_Local — full Arabic name
  static const int surnameLocal = 1290; // ft_Surname_Local
  static const int givenNamesLocal = 1291; // ft_GivenNames_Local
  static const int addressLocal = 1501; // ft_Address_Local
  static const int mothersName = 1237; // verify against SDK docs
  static const int maritalStatus = 1194;
  static const int religion = 1196;
}

// ─────────────────────────────────────────────────────────────────────────────
// Returns true if string contains Arabic Unicode (U+0600–U+06FF).
// Used to distinguish Arabic visual zone values from Latin MRZ values.
// Confirmed working from scan log:
//   "✅ Arabic name — fieldName fallback ("surname"): اشرف يوسف عبدالحميد يوسف"
// ─────────────────────────────────────────────────────────────────────────────
bool _containsArabic(String text) {
  return text.runes.any((r) => r >= 0x0600 && r <= 0x06FF);
}

// ─────────────────────────────────────────────────────────────────────────────
// RegulaService — Singleton
// ─────────────────────────────────────────────────────────────────────────────
class RegulaService {
  static final RegulaService _instance = RegulaService._internal();
  factory RegulaService() => _instance;
  RegulaService._internal();

  final _reader = DocumentReader.instance;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 1 — OFFLINE INITIALIZATION
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Regula already initialized — skipping');
      return true;
    }

    try {
      AppLogger.info('Loading Regula license...');
      final licenseData = await rootBundle.load('assets/regula.license');

      AppLogger.info('Loading offline database from assets/regula/db.dat...');
      final dbData = await rootBundle.load('assets/regula/db.dat');
      final Uint8List dbBytes = dbData.buffer.asUint8List();
      AppLogger.info(
        'Database loaded: ${(dbBytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB',
      );

      final initConfig = InitConfig(licenseData);
      initConfig.customDb = ByteData.sublistView(dbBytes);
      initConfig.delayedNNLoad = true;

      AppLogger.info('Initializing Regula SDK...');
      final (success, error) = await _reader.initialize(initConfig);

      if (success) {
        _isInitialized = true;
        AppLogger.success('Regula SDK initialized (offline mode)');
        _logAvailableScenarios();
      } else {
        AppLogger.error('Regula init failed: ${error?.message}');
      }

      return success;
    } on FlutterError catch (e) {
      AppLogger.error(
        'Asset load failed. Ensure assets/regula/db.dat and '
        'assets/regula.license exist and are declared in pubspec.yaml.',
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
  // STEP 2 — DUAL-WORKFLOW SCANNER
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
      'Starting scanner — '
      '${isPassport ? "PASSPORT (single-side)" : "EGYPTIAN ID (double-side)"}',
    );

    final scannerConfig = _buildScannerConfig(isPassport: isPassport);
    final completer = Completer<Results?>();

    _reader.startScanner(scannerConfig, (
      DocReaderAction action,
      Results? results,
      DocReaderException? error,
    ) {
      if (error != null) AppLogger.error('Scanner error: ${error.message}');

      if (action.stopped()) {
        AppLogger.success('Scan complete');
        if (!completer.isCompleted) completer.complete(results);
      } else if (action == DocReaderAction.CANCEL) {
        AppLogger.info('Scan cancelled by user');
        if (!completer.isCompleted) completer.complete(null);
      } else if (action == DocReaderAction.MORE_PAGES_AVAILABLE) {
        AppLogger.info(
          'Egyptian ID front scanned — prompting for back side...',
        );
      }
    });

    return completer.future;
  }

  ScannerConfig _buildScannerConfig({required bool isPassport}) {
    final config = ScannerConfig.withScenario(Scenario.FULL_PROCESS);
    final functionality = Functionality();
    final processing = ProcessParams();

    if (isPassport) {
      functionality.videoCaptureMotionControl = true;
      processing.multipageProcessing = false;
      processing.doublePageSpread = false;
      AppLogger.info('Config: PASSPORT — single page');
    } else {
      functionality.videoCaptureMotionControl = true;
      functionality.manualMultipageMode = false;
      processing.multipageProcessing = true;
      processing.doublePageSpread = false;
      AppLogger.info('Config: EGYPTIAN ID — double page');
    }

    _reader.functionality = functionality;
    _reader.processParams = processing;

    return config;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STEP 3 — GALLERY FALLBACK
  // ══════════════════════════════════════════════════════════════════════════
  Future<Results?> recognizeImage(
    Uint8List imageBytes, {
    required ApplicantType applicantType,
  }) async {
    if (!_isInitialized || !await _reader.isReady) return null;

    AppLogger.info('Running image recognition...');
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
  // NAME COMPOSITION FIX:
  //
  // The SDK splits the Arabic name across two separate fields:
  //   "surname" field    → "اشرف يوسف عبدالحميد يوسف"  (last/family names)
  //   "given names" field → "مصطفى"                     (first name)
  //
  // Old (broken): grabbed first Arabic "name" field → missed givenNames
  // New (fixed):  collect surnameArabic + givenNamesArabic independently
  //               then compose: givenNamesArabic + " " + surnameArabic
  //               = مصطفى اشرف يوسف عبدالحميد يوسف  ✅
  //
  // Same fix for Latin: givenNames + " " + surname (not surname first)
  //
  // ══════════════════════════════════════════════════════════════════════════
  Future<VerificationResultModel> extractResults(
    Results results, {
    required ApplicantType applicantType,
  }) async {
    AppLogger.info('Extracting results...');

    try {
      final isEgyptian = applicantType == ApplicantType.egyptian;

      // Debug dump — check console for field type integers
      if (kDebugMode && results.textResult != null) {
        _debugDumpAllFields(results.textResult!.fields);
      }

      // ── Standard Latin fields ──────────────────────────────────────────
      // NOTE: textFieldValueByType returns MRZ-preferred value for name fields
      // which is always Latin transliteration for Egyptian IDs.
      // We keep these for backend/AML use — NOT for display.
      final surnameLatin = await results.textFieldValueByType(
        FieldType.SURNAME,
      );
      final givenNamesLatin = await results.textFieldValueByType(
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

      // ── FIX: Collect surname and given names SEPARATELY ────────────────
      // Do NOT use a single "nameArabic" variable that stops on first match.
      // Collect both parts independently so we can compose correctly.
      String? surnameArabic; // "اشرف يوسف عبدالحميد يوسف"
      String? givenNamesArabic; // "مصطفى"
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
          final fieldTypeInt = field.fieldType;
          final fieldName = field.fieldName.toLowerCase();

          for (final value in field.values) {
            final v = value.value;
            if (v == null || v.trim().isEmpty) continue;

            final hasArabic = _containsArabic(v);

            // ── LAYER 1: Integer field type matching ─────────────────────

            // Arabic surname (1290) — "اشرف يوسف عبدالحميد يوسف"
            if (fieldTypeInt == _EgyptFieldType.surnameLocal && hasArabic) {
              surnameArabic ??= v;
              AppLogger.info('surnameArabic via integer (1290): $v');
            }

            // Arabic given names (1291) — "مصطفى"
            if (fieldTypeInt == _EgyptFieldType.givenNamesLocal && hasArabic) {
              givenNamesArabic ??= v;
              AppLogger.info('givenNamesArabic via integer (1291): $v');
            }

            // Arabic full name (1268) — only use if components not found
            // We check this LAST as a fallback below after the loop

            // Arabic address (1501)
            if (fieldTypeInt == _EgyptFieldType.addressLocal && hasArabic) {
              addressArabic ??= v;
            }

            // ── LAYER 2: fieldName string matching (confirmed working) ────

            // Arabic surname fallback — "surname" field with Arabic value
            if (surnameArabic == null &&
                hasArabic &&
                fieldName.contains('surname')) {
              surnameArabic = v;
              AppLogger.info('surnameArabic via fieldName ("$fieldName"): $v');
            }

            // Arabic given names fallback — "given" field with Arabic value
            if (givenNamesArabic == null &&
                hasArabic &&
                (fieldName.contains('given') ||
                    fieldName.contains('first name'))) {
              givenNamesArabic = v;
              AppLogger.info(
                'givenNamesArabic via fieldName ("$fieldName"): $v',
              );
            }

            // Arabic address fallback
            if (addressArabic == null &&
                hasArabic &&
                fieldName.contains('address')) {
              addressArabic = v;
            }

            // ── Non-name fields ──────────────────────────────────────────
            if (fieldName.contains('mother') || fieldName.contains('أم')) {
              mothersName = v;
            }
            if (fieldName.contains('marital') || fieldName.contains('social')) {
              maritalStatus = v;
            }
            if (fieldName.contains('religion')) {
              religion = v;
            }
            if (fieldName.contains('profession') ||
                fieldName.contains('occupation')) {
              profession = v;
            }
            if (fieldName.contains('issuing authority') ||
                fieldName.contains('authority')) {
              issuingAuthority = v;
            }
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

        // ── LAYER 3: ft_Name_Local (1268) as last resort ──────────────────
        // If we still don't have both components, check field type 1268
        // which may contain the full combined Arabic name.
        if (surnameArabic == null && givenNamesArabic == null) {
          for (final field in results.textResult!.fields) {
            if (field.fieldType == _EgyptFieldType.nameLocal) {
              for (final value in field.values) {
                final v = value.value;
                if (v != null && _containsArabic(v)) {
                  // Full name in one field — store in surname for composition
                  surnameArabic = v;
                  AppLogger.info('Full Arabic name via 1268 fallback: $v');
                  break;
                }
              }
            }
            if (surnameArabic != null) break;
          }
        }
      }

      // ── FIX: Compose Arabic name in correct order ─────────────────────
      // Egyptian Arabic name order: given name FIRST, then family/surname
      // مصطفى (given) + اشرف يوسف عبدالحميد يوسف (surname)
      // = مصطفى اشرف يوسف عبدالحميد يوسف ✅
      final String? fullNameArabic = isEgyptian
          ? _composeArabicName(
              givenNamesArabic: givenNamesArabic,
              surnameArabic: surnameArabic,
            )
          : null;

      // ── FIX: Compose Latin name in correct order ──────────────────────
      // givenNames FIRST, then surname (matches Arabic order above).
      // Note: Latin values use Egyptian MRZ encoding — cannot be prettified.
      // They are stored for AML/backend matching, not for display.
      final String fullNameLatin = [
        if (givenNamesLatin != null && givenNamesLatin.isNotEmpty)
          givenNamesLatin,
        if (surnameLatin != null && surnameLatin.isNotEmpty) surnameLatin,
      ].join(' ');

      // Primary display name: Arabic for Egyptian, Latin for passport
      final String displayName = isEgyptian
          ? (fullNameArabic ?? fullNameLatin)
          : fullNameLatin;

      AppLogger.info(
        'Name composition:\n'
        '  givenNamesArabic: "${givenNamesArabic ?? "NOT FOUND"}"\n'
        '  surnameArabic:    "${surnameArabic ?? "NOT FOUND"}"\n'
        '  fullNameArabic:   "${fullNameArabic ?? "NOT FOUND"}"\n'
        '  fullNameLatin:    "$fullNameLatin"\n'
        '  displayName:      "$displayName"',
      );

      if (isEgyptian && fullNameArabic == null) {
        AppLogger.warning(
          'Arabic name not composed. Check FIELD DUMP above for '
          'surname/given name fields containing Arabic text.',
        );
      }

      // ── Document metadata ──────────────────────────────────────────────
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

      // ── Verification status ────────────────────────────────────────────
      final statusObj = results.status;
      final overallStatus = _mapCheckResult(statusObj.overallStatus);
      final mrzValid = statusObj.detailsOptical.mrz == CheckResult.OK;
      final textValid = statusObj.detailsOptical.text == CheckResult.OK;
      final imageQualityOk = statusObj.detailsOptical.imageQA == CheckResult.OK;
      final expiryCheck = statusObj.detailsOptical.expiry;
      final documentExpired =
          expiryCheck != CheckResult.OK &&
          expiryCheck != CheckResult.WAS_NOT_DONE;

      // ── Portrait ───────────────────────────────────────────────────────
      final portraitBytes = await results.graphicFieldImageByType(
        GraphicFieldType.PORTRAIT,
      );

      AppLogger.success(
        'Extraction complete — '
        'display: "$displayName" | '
        'arabic: "${fullNameArabic ?? "N/A"}" | '
        'status: ${overallStatus.name}',
      );

      return VerificationResultModel(
        // Latin (MRZ encoding — backend/AML use only)
        surname: surnameLatin,
        givenNames: givenNamesLatin,
        fullName: displayName,
        fullNameLatin: fullNameLatin.isNotEmpty ? fullNameLatin : null,

        // Arabic (display — Egyptian ID only)
        fullNameArabic: fullNameArabic,
        surnameArabic: surnameArabic,
        givenNamesArabic: givenNamesArabic,
        addressArabic: addressArabic,

        // Egypt back-side fields
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

        // Verification
        overallStatus: overallStatus,
        mrzValid: mrzValid,
        textValid: textValid,
        documentExpired: documentExpired,
        imageQualityOk: imageQualityOk,
        portraitBytes: portraitBytes,
      );
    } catch (e) {
      AppLogger.error('Result extraction failed', e);
      return VerificationResultModel(overallStatus: VerificationStatus.failed);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEBUG dump — logs every field with type int, name, arabic flag, value.
  // Gate behind kDebugMode — will not run in release builds.
  // After confirming field integers, this can be removed.
  // ─────────────────────────────────────────────────────────────────────────
  void _debugDumpAllFields(List<TextField> fields) {
    AppLogger.info('═══ FIELD DUMP (${fields.length} fields) ═══');
    for (final field in fields) {
      for (final value in field.values) {
        final v = value.value;
        if (v == null || v.trim().isEmpty) continue;
        AppLogger.info(
          'FIELD | '
          'type: ${field.fieldType} | '
          'name: "${field.fieldName}" | '
          'arabic: ${_containsArabic(v)} | '
          'value: "$v"',
        );
      }
    }
    AppLogger.info('═══ END FIELD DUMP ═══');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FIX: Compose Arabic full name from SEPARATE surname and given name parts.
  //
  // Egyptian Arabic name order: given name first, then family name.
  //   givenNamesArabic = "مصطفى"
  //   surnameArabic    = "اشرف يوسف عبدالحميد يوسف"
  //   result           = "مصطفى اشرف يوسف عبدالحميد يوسف" ✅
  //
  // Old _composeArabicName was (surname, givenNames) — wrong order.
  // New signature is explicit named params to avoid ordering mistakes.
  // ─────────────────────────────────────────────────────────────────────────
  String? _composeArabicName({
    required String? givenNamesArabic,
    required String? surnameArabic,
  }) {
    final parts = [
      givenNamesArabic,
      surnameArabic,
    ].whereType<String>().where((s) => s.isNotEmpty).toList();

    if (parts.isEmpty) return null;

    final composed = parts.join(' ');
    AppLogger.info('Composed Arabic name: "$composed"');
    return composed;
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
  // Deinitialize — only after full KYC session completes
  // ─────────────────────────────────────────────────────────────────────────
  void deinitialize() {
    if (_isInitialized) {
      _reader.deinitializeReader();
      _isInitialized = false;
      AppLogger.info('Regula SDK deinitialized');
    }
  }
}

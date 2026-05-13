import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import '../model/verification_result_model.dart';
import '../../core/utils/logger.dart';

class RegulaService {
  static final RegulaService _instance = RegulaService._internal();
  factory RegulaService() => _instance;
  RegulaService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── STEP 1: Prepare database ─────────────────────────────────
  /// Downloads the document database if needed.
  /// Must be called before initializeReader.
  Future<bool> prepareDatabase({Function(double progress)? onProgress}) async {
    try {
      AppLogger.info('Preparing Regula database...');

      var (success, error) = await DocumentReader.instance.prepareDatabase(
        'Full',
        (progress) {
          AppLogger.info('DB download: ${(progress * 100).toInt()}%');
          onProgress?.call(progress);
        },
      );

      if (success) {
        AppLogger.success('Regula database ready');
      } else {
        AppLogger.error('Database preparation failed: ${error?.message}');
      }
      return success;
    } catch (e) {
      AppLogger.error('prepareDatabase exception', e);
      return false;
    }
  }

  // ── STEP 2: Initialize SDK ───────────────────────────────────
  /// Must be called once, after prepareDatabase.
  /// Reads license from assets/regula.license
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Regula already initialized — skipping');
      return true;
    }

    try {
      AppLogger.info('Initializing Regula SDK...');

      // Load license from Flutter assets — exactly as per official docs
      final licenseData = await rootBundle.load('assets/regula.license');
      final initConfig = InitConfig(licenseData);

      var (success, error) = await DocumentReader.instance.initializeReader(
        initConfig,
      );

      if (success) {
        _isInitialized = true;
        AppLogger.success('Regula SDK initialized successfully');

        // Log available scenarios for debugging
        final scenarios = DocumentReader.instance.availableScenarios;
        AppLogger.info(
          'Available scenarios: ${scenarios.map((s) => s.name).join(', ')}',
        );
      } else {
        AppLogger.error('Regula init failed: ${error?.message}');
      }

      return success;
    } catch (e) {
      AppLogger.error('Regula initialization exception', e);
      return false;
    }
  }

  // ── STEP 3: Start scanner ────────────────────────────────────
  /// Opens Regula's native camera UI.
  /// Returns null if cancelled or failed.
  Future<Results?> startScanner({bool isPassport = false}) async {
    if (!_isInitialized) {
      AppLogger.error('Regula not initialized — call initialize() first');
      return null;
    }

    try {
      AppLogger.info('Starting Regula scanner...');

      // Choose scenario based on document type
      // FullProcess: Visual OCR + MRZ + Barcode + Security — best for KYC
      final scenario = isPassport
          ? Scenario
                .FULL_PROCESS // Passport: MRZ is primary
          : Scenario.FULL_PROCESS; // National ID: Visual OCR + MRZ

      final config = ScannerConfig.withScenario(scenario);

      Results? scanResults;

      await DocumentReader.instance.startScanner(config, (
        action,
        results,
        error,
      ) {
        if (action == DocReaderAction.COMPLETE) {
          AppLogger.success('Regula scan completed');
          scanResults = results;
        } else if (action == DocReaderAction.TIMEOUT) {
          AppLogger.warning('Regula scan timed out');
          scanResults = results; // results may still have partial data
        } else if (action == DocReaderAction.CANCEL) {
          AppLogger.info('Regula scan cancelled by user');
          scanResults = null;
        } else if (error != null) {
          AppLogger.error('Regula scan error: ${error.message}');
          scanResults = null;
        }
      });

      return scanResults;
    } catch (e) {
      AppLogger.error('startScanner exception', e);
      return null;
    }
  }

  // ── STEP 4: Process gallery image (fallback) ─────────────────
  /// Processes one or more images from gallery/binary.
  Future<Results?> recognizeImages(List<Uint8List> images) async {
    if (!_isInitialized) return null;

    try {
      AppLogger.info('Running Regula recognition on ${images.length} image(s)');

      final config = RecognizeConfig.withScenario(
        Scenario.FULL_PROCESS,
        images: images,
      );

      Results? results;

      await DocumentReader.instance.recognize(config, (action, r, error) {
        if (action == DocReaderAction.COMPLETE) {
          results = r;
        }
      });

      return results;
    } catch (e) {
      AppLogger.error('recognizeImages exception', e);
      return null;
    }
  }

  // ── STEP 5: Extract structured data from results ─────────────
  /// Maps Regula's raw Results into our clean VerificationResultModel.
  Future<VerificationResultModel> extractResults(Results results) async {
    AppLogger.info('Extracting data from Regula results...');

    try {
      // ── Text fields ─────────────────────────────────────────
      final surname = await results.textFieldValueByType(FieldType.SURNAME);
      final givenNames = await results.textFieldValueByType(
        FieldType.GIVEN_NAMES,
      );
      final fullName =
          await results.textFieldValueByType(
            FieldType.MRZ_SURNAME_AND_GIVEN_NAMES,
          ) ??
          '${surname ?? ''} ${givenNames ?? ''}'.trim();
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
      final address = await results.textFieldValueByType(FieldType.ADDRESS);
      final sex = await results.textFieldValueByType(FieldType.SEX);
      final issuingState = await results.textFieldValueByType(
        FieldType.ISSUING_STATE_CODE,
      );
      final issuingAuthority = await results.textFieldValueByType(
        FieldType.ISSUING_AUTHORITY,
      );
      final dateOfIssue = await results.textFieldValueByType(
        FieldType.DATE_OF_ISSUE,
      );

      // MRZ lines
      final mrz1 = await results.textFieldValueByType(
        FieldType.MRZ_STRINGS_WITH_CORRECT_CHECKDIGITS,
      );
      final mrz2 = await results.textFieldValueByType(FieldType.MRZ_LINES);

      // ── Document type metadata ───────────────────────────────
      final docType = results.documentType;
      final docTypeName = docType?.isNotEmpty == true
          ? docType!.first.name
          : null;
      final countryName = docType?.isNotEmpty == true
          ? docType!.first.countryName
          : null;
      final icaoCode = docType?.isNotEmpty == true
          ? docType!.first.iCAOCode
          : null;

      // ── Status mapping ───────────────────────────────────────
      // Regula CheckResult: 1 = OK, 2 = WAS_READ_WITH_ERRORS, 0 = NOT_DONE
      final status = results.status;
      final overallStatus = _mapOverallStatus(status?.overallStatus);
      final mrzValid = status?.detailsOptical?.mrz == CheckResult.OK;
      final textValid = status?.detailsOptical?.text == CheckResult.OK;
      final imageQualityOk = status?.detailsOptical?.imageQA == CheckResult.OK;

      // Expiry check
      final expiryStatus = status?.detailsOptical?.expiry;
      final documentExpired = expiryStatus == CheckResult.WAS_READ_WITH_ERRORS;

      // ── Portrait image ───────────────────────────────────────
      final portrait = await results
          .graphicFieldImageByTypeSourcePageIndexLight(
            GraphicFieldType.PORTRAIT,
            ResultType.RAWIMAGE,
            0,
            Lights.WHITE_FULL,
          );

      // Convert portrait to base64 if available
      String? portraitBase64;
      if (portrait != null) {
        final bytes = portrait.readAsBytesSync();
        portraitBase64 = 'data:image/jpeg;base64,${_encodeBase64(bytes)}';
      }

      final model = VerificationResultModel(
        surname: surname,
        givenNames: givenNames,
        fullName: fullName,
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
        mrzLine1: mrz1,
        mrzLine2: mrz2,
        documentTypeName: docTypeName,
        countryName: countryName,
        icaoCode: icaoCode,
        overallStatus: overallStatus,
        mrzValid: mrzValid,
        textValid: textValid,
        documentExpired: documentExpired,
        imageQualityOk: imageQualityOk,
        portraitImageBase64: portraitBase64,
      );

      AppLogger.success(
        'Extraction complete — ${model.fullName}, status: ${model.overallStatus.name}',
      );

      return model;
    } catch (e) {
      AppLogger.error('Result extraction failed', e);
      // Return failed result rather than crashing
      return VerificationResultModel(overallStatus: VerificationStatus.failed);
    }
  }

  // ── Deinitialize ─────────────────────────────────────────────
  /// Call when done with document verification to free memory.
  void deinitialize() {
    if (_isInitialized) {
      DocumentReader.instance.deinitializeReader();
      _isInitialized = false;
      AppLogger.info('Regula SDK deinitialized');
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  VerificationStatus _mapOverallStatus(CheckResult? result) {
    switch (result) {
      case CheckResult.OK:
        return VerificationStatus.genuine;
      case CheckResult.WAS_READ_WITH_ERRORS:
        return VerificationStatus.suspicious;
      default:
        return VerificationStatus.needsReview;
    }
  }

  String _encodeBase64(List<int> bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final result = StringBuffer();
    for (var i = 0; i < bytes.length; i += 3) {
      final b0 = bytes[i];
      final b1 = i + 1 < bytes.length ? bytes[i + 1] : 0;
      final b2 = i + 2 < bytes.length ? bytes[i + 2] : 0;
      result.write(chars[(b0 >> 2) & 0x3F]);
      result.write(chars[((b0 << 4) | (b1 >> 4)) & 0x3F]);
      result.write(
        i + 1 < bytes.length ? chars[((b1 << 2) | (b2 >> 6)) & 0x3F] : '=',
      );
      result.write(i + 2 < bytes.length ? chars[b2 & 0x3F] : '=');
    }
    return result.toString();
  }
}

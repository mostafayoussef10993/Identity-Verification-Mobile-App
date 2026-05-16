import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_document_reader_api/flutter_document_reader_api.dart';
import '../model/verification_result_model.dart';
import '../../core/utils/logger.dart';

class RegulaService {
  static final RegulaService _instance = RegulaService._internal();
  factory RegulaService() => _instance;
  RegulaService._internal();

  // Use the instance directly
  final _reader = DocumentReader.instance;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ── STEP 1: Prepare database ─────────────────────────────────
  Future<bool> prepareDatabase({Function(double progress)? onProgress}) async {
    try {
      AppLogger.info('Preparing Regula database...');

      var (success, error) = await _reader.prepareDatabase(
        'Full',
        // FIX: callback receives PrepareProgress object, not double
        // Extract the fraction value from the object
        (PrepareProgress progress) {
          final fraction = progress.totalBytes > 0
              ? progress.downloadedBytes / progress.totalBytes
              : 0.0;
          AppLogger.info('DB: ${(fraction * 100).toInt()}%');
          onProgress?.call(fraction.toDouble());
        },
      );

      if (!success) {
        AppLogger.error('DB prep failed: ${error?.message}');
      } else {
        AppLogger.success('Regula database ready');
      }
      return success;
    } catch (e) {
      AppLogger.error('prepareDatabase exception', e);
      return false;
    }
  }

  // ── STEP 2: Initialize SDK ───────────────────────────────────
  // FIX: method is `initialize()` not `initializeReader()`
  Future<bool> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Regula already initialized');
      return true;
    }

    try {
      AppLogger.info('Initializing Regula SDK...');

      final licenseData = await rootBundle.load('assets/regula.license');
      final initConfig = InitConfig(licenseData);
      // Recommended by official example for faster startup
      initConfig.delayedNNLoad = true;

      // FIX: correct method name is `initialize`, not `initializeReader`
      var (success, error) = await _reader.initialize(initConfig);

      if (success) {
        _isInitialized = true;
        AppLogger.success('Regula initialized');
        for (var s in _reader.availableScenarios) {
          AppLogger.info('Scenario available: ${s.name}');
        }
      } else {
        AppLogger.error('Regula init failed: ${error?.message}');
      }

      return success;
    } catch (e) {
      AppLogger.error('Regula init exception', e);
      return false;
    }
  }

  // ── STEP 3: Start scanner ────────────────────────────────────
  // FIX: startScanner does NOT return a Future — it's callback-based
  // We wrap it in a Completer to make it awaitable in our cubit
  Future<Results?> startScanner({bool isPassport = false}) async {
    if (!_isInitialized) {
      AppLogger.error('Regula not initialized');
      return null;
    }

    // Check SDK is ready
    if (!await _reader.isReady) {
      AppLogger.error('Regula reader not ready');
      return null;
    }

    AppLogger.info('Starting Regula scanner...');

    // Use a Completer to bridge the callback-based API into a Future
    final completer = Completer<Results?>();

    // FIX: no `await` on startScanner — it's void, callback-based
    _reader.startScanner(ScannerConfig.withScenario(Scenario.FULL_PROCESS), (
      DocReaderAction action,
      Results? results,
      DocReaderException? error,
    ) {
      if (error != null) {
        AppLogger.error('Scanner error: ${error.message}');
      }

      // FIX: use action.stopped() and action.finished() as shown
      // in official example — not raw enum comparisons
      if (action.stopped()) {
        // stopped() = COMPLETE or TIMEOUT — processing is done
        AppLogger.success('Scan stopped — results available');
        if (!completer.isCompleted) completer.complete(results);
      } else if (action == DocReaderAction.CANCEL) {
        AppLogger.info('Scan cancelled by user');
        if (!completer.isCompleted) completer.complete(null);
      }
      // Other actions (PROCESS, MORE_PAGES_AVAILABLE, etc.)
      // are intermediate — we just wait for stopped()
    });

    return completer.future;
  }

  // ── STEP 4: Process gallery image (fallback) ─────────────────
  // FIX: recognize() also returns void — same Completer pattern
  Future<Results?> recognizeImage(Uint8List imageBytes) async {
    if (!_isInitialized) return null;
    if (!await _reader.isReady) return null;

    AppLogger.info('Running Regula recognition on image...');
    final completer = Completer<Results?>();

    // FIX: no `await`, use Completer
    _reader.recognize(
      RecognizeConfig.withScenario(Scenario.FULL_PROCESS, image: imageBytes),
      (DocReaderAction action, Results? results, DocReaderException? error) {
        if (error != null) AppLogger.error('Recognize error: ${error.message}');
        if (action.stopped()) {
          if (!completer.isCompleted) completer.complete(results);
        }
      },
    );

    return completer.future;
  }

  // ── STEP 5: Extract structured data from results ─────────────
  Future<VerificationResultModel> extractResults(Results results) async {
    AppLogger.info('Extracting Regula results...');

    try {
      // ── Text fields ─────────────────────────────────────────
      // FIX: correct constant is SURNAME_AND_GIVEN_NAMES (not MRZ_...)
      final fullName = await results.textFieldValueByType(
        FieldType.SURNAME_AND_GIVEN_NAMES,
      );
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
      final address = await results.textFieldValueByType(FieldType.ADDRESS);
      final sex = await results.textFieldValueByType(FieldType.SEX);
      final issuingState = await results.textFieldValueByType(
        FieldType.ISSUING_STATE_CODE,
      );
      final dateOfIssue = await results.textFieldValueByType(
        FieldType.DATE_OF_ISSUE,
      );

      // FIX: ISSUING_AUTHORITY and MRZ line constants don't exist
      // Get them by iterating all fields instead
      String? issuingAuthority;
      String? mrzLine1;
      String? mrzLine2;

      if (results.textResult != null) {
        for (var field in results.textResult!.fields) {
          for (var value in field.values) {
            final v = value.value;
            if (v == null) continue;
            // Field names are human-readable strings we can match
            final name = field.fieldName.toLowerCase();
            if (name.contains('issuing authority') ||
                name.contains('authority')) {
              issuingAuthority = v;
            }
            if (name.contains('mrz line 1') || name.contains('mrz string 1')) {
              mrzLine1 = v;
            }
            if (name.contains('mrz line 2') || name.contains('mrz string 2')) {
              mrzLine2 = v;
            }
          }
        }
      }

      // ── Document type metadata ───────────────────────────────
      final docTypes = results.documentType;
      final docTypeName = docTypes != null && docTypes.isNotEmpty
          ? docTypes.first.name
          : null;
      final countryName = docTypes != null && docTypes.isNotEmpty
          ? docTypes.first.countryName
          : null;
      final icaoCode = docTypes != null && docTypes.isNotEmpty
          ? docTypes.first.iCAOCode
          : null;

      // ── Status mapping ───────────────────────────────────────
      // FIX: use null-safe access correctly
      // results.status CAN be null — keep ?. but fix CheckResult constants
      final statusObj = results.status;
      final overallStatus = _mapCheckResult(statusObj.overallStatus);

      // FIX: CheckResult values — use .ok, not .OK
      // In newer API: CheckResult has values like ok, failed, etc.
      final mrzValid = statusObj.detailsOptical.mrz == CheckResult.OK;
      final textValid = statusObj.detailsOptical.text == CheckResult.OK;
      final imageQualityOk = statusObj.detailsOptical.imageQA == CheckResult.OK;

      // FIX: expiry check — NOT_DONE (0) means good, errors mean expired
      final expiryCheck = statusObj.detailsOptical.expiry;
      final documentExpired =
          expiryCheck != CheckResult.OK &&
          expiryCheck != CheckResult.WAS_NOT_DONE;

      // ── Portrait image ───────────────────────────────────────
      // FIX: graphicFieldImageByType returns Uint8List? directly
      // NOT a File — so NO .readAsBytesSync()
      // FIX: correct method name from official example
      final portraitBytes = await results.graphicFieldImageByType(
        GraphicFieldType.PORTRAIT,
      );

      AppLogger.success(
        'Extraction done — name: ${fullName ?? "unknown"}, '
        'status: ${overallStatus.name}',
      );

      return VerificationResultModel(
        surname: surname,
        givenNames: givenNames,
        fullName: fullName ?? '${surname ?? ''} ${givenNames ?? ''}'.trim(),
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
        documentTypeName: docTypeName,
        countryName: countryName,
        icaoCode: icaoCode,
        overallStatus: overallStatus,
        mrzValid: mrzValid,
        textValid: textValid,
        documentExpired: documentExpired,
        imageQualityOk: imageQualityOk,
        // FIX: portraitBytes is already Uint8List — encode directly
        portraitBytes: portraitBytes,
      );
    } catch (e) {
      AppLogger.error('Result extraction failed', e);
      return VerificationResultModel(overallStatus: VerificationStatus.failed);
    }
  }

  // ── Deinitialize ─────────────────────────────────────────────
  void deinitialize() {
    if (_isInitialized) {
      _reader.deinitializeReader();
      _isInitialized = false;
      AppLogger.info('Regula deinitialized');
    }
  }

  // ── Map CheckResult to our VerificationStatus ─────────────────
  // FIX: correct CheckResult constant names (lowercase in newer API)
  VerificationStatus _mapCheckResult(CheckResult? result) {
    if (result == CheckResult.OK) return VerificationStatus.genuine;
    if (result == null || result == CheckResult.WAS_NOT_DONE) {
      return VerificationStatus.needsReview;
    }
    return VerificationStatus.suspicious;
  }
}

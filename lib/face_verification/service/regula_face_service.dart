// lib/face_verification/service/regula_face_service.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// REGULA FACE SERVICE — Fixed
// ══════════════════════════════════════════════════════════════════════════════
//
// ROOT CAUSE OF "FaceSDK core is missing":
//   Old code passed InitConfig(licenseData) to FaceSDK.initialize().
//   InitConfig belongs to the Document Reader SDK — not the Face SDK.
//   The Face SDK does NOT use a .license file at all.
//   It is licensed via the app's Android package name / iOS bundle ID
//   registered on the Regula portal.
//
// FIX:
//   FaceSDK.initialize() takes NO parameters in flutter_face_api ^8.2.1092.
//   Simply call: await FaceSDK.instance.initialize()
//   Remove all InitConfig, rootBundle, and flutter/services.dart references.
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'package:flutter_face_api/flutter_face_api.dart';

import '../../core/utils/logger.dart';

class RegulaFaceService {
  static final RegulaFaceService _instance = RegulaFaceService._internal();
  factory RegulaFaceService() => _instance;
  RegulaFaceService._internal();

  final FaceSDK _faceSdk = FaceSDK.instance;

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // ══════════════════════════════════════════════════════════════════════════
  // INITIALIZE — No license file, no InitConfig
  // ══════════════════════════════════════════════════════════════════════════
  //
  // The Face SDK is licensed via your Android package name (com.mostafa.kyc)
  // and iOS bundle ID registered on the Regula developer portal.
  // No .license file is needed or accepted here.
  //
  // flutter_face_api ^8.2.1092 signature:
  //   Future<(bool, FaceException?)> initialize()
  //
  // ══════════════════════════════════════════════════════════════════════════
  Future<bool> initialize() async {
    if (_initialized) {
      AppLogger.info('Face SDK already initialized — skipping');
      return true;
    }

    try {
      AppLogger.info('Initializing Regula Face SDK...');

      // FIX: No config, no license file — just initialize()
      final (success, error) = await _faceSdk.initialize();

      if (success) {
        _initialized = true;
        AppLogger.success('Regula Face SDK initialized successfully');
      } else {
        AppLogger.error(
          'Face SDK initialization failed: ${error?.message}',
        );
      }

      return success;
    } catch (e) {
      AppLogger.error('Face SDK init exception', e);
      return false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LIVENESS — Passive liveness capture
  // ══════════════════════════════════════════════════════════════════════════
  Future<LivenessResponse> startLiveness() async {
    if (!_initialized) {
      throw StateError('Face SDK is not initialized. Call initialize() first.');
    }

    AppLogger.info('Starting Regula passive liveness...');

    // LivenessConfig with only confirmed-safe parameters for ^8.2.1092.
    // Parameters like cameraSwitchEnabled, torchButtonEnabled,
    // preventScreenRecording may not exist — using minimal safe config.
    final config = LivenessConfig();
    config.livenessType = LivenessType.PASSIVE;
    config.attemptsCount = 3;

    return _faceSdk.startLiveness(config: config);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FACE MATCHING — Compare live selfie against document portrait
  // ══════════════════════════════════════════════════════════════════════════
  Future<double?> matchFaces({
    required Uint8List liveImage,
    required Uint8List documentPortrait,
  }) async {
    if (!_initialized) {
      throw StateError('Face SDK is not initialized. Call initialize() first.');
    }

    AppLogger.info('Sending face match request to Regula...');

    final request = MatchFacesRequest([
      MatchFacesImage(liveImage, ImageType.LIVE),
      MatchFacesImage(documentPortrait, ImageType.DOCUMENT_WITH_LIVE),
    ]);

    final response = await _faceSdk.matchFaces(request);

    if (response.error != null) {
      AppLogger.error('Face match failed', response.error);
      return null;
    }

    if (response.results.isEmpty) {
      AppLogger.warning('Face match returned no results');
      return null;
    }

    final similarity = response.results.first.similarity;
    final scorePercent = similarity * 100;

    AppLogger.success('Face match similarity: ${scorePercent.toStringAsFixed(1)}%');

    return scorePercent;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ══════════════════════════════════════════════════════════════════════════
  void stopLiveness() {
    if (_initialized) {
      _faceSdk.stopLiveness();
      AppLogger.info('Regula face liveness stopped');
    }
  }

  void deinitialize() {
    if (_initialized) {
      _faceSdk.deinitialize();
      _initialized = false;
      AppLogger.info('Regula Face SDK deinitialized');
    }
  }
}

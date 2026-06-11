// lib/face_verification/service/regula_face_service.dart
//
// Sprint 4 — Regula Face SDK integration service.
// Provides face SDK initialization, passive liveness, and face matching.
// The flow is designed to be called from the face verification cubit.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_face_api/flutter_face_api.dart';

import '../../core/utils/logger.dart';

class RegulaFaceService {
  static final RegulaFaceService _instance = RegulaFaceService._internal();
  factory RegulaFaceService() => _instance;
  RegulaFaceService._internal();

  final FaceSDK _faceSdk = FaceSDK.instance;
  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<bool> initialize() async {
    if (_initialized) {
      AppLogger.info('Face SDK already initialized — skipping');
      return true;
    }

    try {
      AppLogger.info('Loading Regula face license...');
      final licenseData = await rootBundle.load('assets/regula.license');
      final initConfig = InitConfig(licenseData);

      AppLogger.info('Initializing Regula Face SDK...');
      final (success, error) = await _faceSdk.initialize(config: initConfig);
      if (success) {
        _initialized = true;
        AppLogger.success('Regula Face SDK initialized');
      } else {
        AppLogger.error('Face SDK initialization failed: ${error?.message}');
      }
      return success;
    } catch (e) {
      AppLogger.error('Face SDK init exception', e);
      return false;
    }
  }

  Future<LivenessResponse> startLiveness({LivenessConfig? config}) async {
    if (!_initialized) {
      throw StateError('Face SDK is not initialized');
    }

    AppLogger.info('Starting Regula face liveness');
    return _faceSdk.startLiveness(config: config);
  }

  Future<double?> matchFaces({
    required Uint8List liveImage,
    required Uint8List documentPortrait,
  }) async {
    if (!_initialized) {
      throw StateError('Face SDK is not initialized');
    }

    final request = MatchFacesRequest([
      MatchFacesImage(liveImage, ImageType.LIVE),
      MatchFacesImage(documentPortrait, ImageType.DOCUMENT_WITH_LIVE),
    ]);

    AppLogger.info('Sending face match request to Regula');
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
    AppLogger.success('Face match similarity: ${similarity * 100}%');
    return similarity * 100;
  }

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

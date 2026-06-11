# Sprint 4 — Face Verification Module & Configuration Updates

## Project Structure

```text
lib/
├── face_verification/
│   ├── service/
│   │   └── regula_face_service.dart
│   ├── cubit/
│   │   ├── face_verification_cubit.dart
│   │   └── face_verification_state.dart
│   ├── model/
│   │   └── face_verification_result_model.dart
│   ├── repository/
│   │   └── face_verification_repository.dart
│   └── ui/
│       ├── face_liveness_screen.dart
│       └── face_result_screen.dart
│
├── app/
│   └── router.dart
│
android/
└── app/
    └── build.gradle.kts

pubspec.yaml
```

---

# File: lib/face_verification/service/regula_face_service.dart

```dart
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

      final licenseData =
          await rootBundle.load('assets/regula.license');

      final initConfig = InitConfig(licenseData);

      AppLogger.info('Initializing Regula Face SDK...');

      final (success, error) =
          await _faceSdk.initialize(config: initConfig);

      if (success) {
        _initialized = true;
        AppLogger.success('Regula Face SDK initialized');
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

  Future<LivenessResponse> startLiveness({
    LivenessConfig? config,
  }) async {
    if (!_initialized) {
      throw StateError(
        'Face SDK is not initialized',
      );
    }

    AppLogger.info('Starting Regula face liveness');

    return _faceSdk.startLiveness(config: config);
  }

  Future<double?> matchFaces({
    required Uint8List liveImage,
    required Uint8List documentPortrait,
  }) async {
    if (!_initialized) {
      throw StateError(
        'Face SDK is not initialized',
      );
    }

    final request = MatchFacesRequest([
      MatchFacesImage(
        liveImage,
        ImageType.LIVE,
      ),
      MatchFacesImage(
        documentPortrait,
        ImageType.DOCUMENT_WITH_LIVE,
      ),
    ]);

    AppLogger.info('Sending face match request to Regula');

    final response =
        await _faceSdk.matchFaces(request);

    if (response.error != null) {
      AppLogger.error(
        'Face match failed',
        response.error,
      );
      return null;
    }

    if (response.results.isEmpty) {
      AppLogger.warning(
        'Face match returned no results',
      );
      return null;
    }

    final similarity =
        response.results.first.similarity;

    AppLogger.success(
      'Face match similarity: ${similarity * 100}%',
    );

    return similarity * 100;
  }

  void stopLiveness() {
    if (_initialized) {
      _faceSdk.stopLiveness();

      AppLogger.info(
        'Regula face liveness stopped',
      );
    }
  }

  void deinitialize() {
    if (_initialized) {
      _faceSdk.deinitialize();

      _initialized = false;

      AppLogger.info(
        'Regula Face SDK deinitialized',
      );
    }
  }
}
```
---

# File: lib/face_verification/cubit/face_verification_cubit.dart

```dart
// lib/face_verification/cubit/face_verification_cubit.dart
//
// Sprint 4 — Face verification cubit.
// Manages Regula Face SDK initialization, liveness flow, face matching,
// and persistence of face verification results.

import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_face_api/flutter_face_api.dart';

import '../../core/utils/logger.dart';
import '../model/face_verification_result_model.dart';
import '../repository/face_verification_repository.dart';
import '../service/regula_face_service.dart';
import 'face_verification_state.dart';

class FaceVerificationCubit extends Cubit<FaceVerificationState> {
  final RegulaFaceService _faceService;
  final FaceVerificationRepository _repository;

  FaceVerificationCubit({
    RegulaFaceService? faceService,
    FaceVerificationRepository? repository,
  })  : _faceService = faceService ?? RegulaFaceService(),
        _repository = repository ?? FaceVerificationRepository(),
        super(const FaceVerificationInitial());

  Future<void> initializeSdk() async {
    if (_faceService.isInitialized) {
      emit(const FaceVerificationReady());
      return;
    }

    emit(
      const FaceVerificationLoading(
        'Initializing face engine...',
      ),
    );

    final initialized = await _faceService.initialize();

    if (initialized) {
      emit(const FaceVerificationReady());
    } else {
      emit(
        const FaceVerificationError(
          message:
              'Face verification engine failed to initialize. '
              'Please restart the app.',
          canRetry: true,
        ),
      );
    }
  }

  Future<void> startFaceVerification({
    required Uint8List documentPortraitBytes,
    required String applicationId,
    required String userId,
  }) async {
    if (!_faceService.isInitialized) {
      emit(
        const FaceVerificationLoading(
          'Loading face engine...',
        ),
      );

      final initialized = await _faceService.initialize();

      if (!initialized) {
        emit(
          const FaceVerificationError(
            message:
                'Face verification engine failed to initialize. '
                'Please try again.',
            canRetry: true,
          ),
        );

        return;
      }
    }

    if (documentPortraitBytes.isEmpty) {
      emit(
        const FaceVerificationError(
          message:
              'Document portrait is missing. '
              'Cannot continue face verification.',
          canRetry: false,
        ),
      );

      return;
    }

    emit(
      const FaceVerificationLoading(
        'Starting liveness check...',
      ),
    );

    try {
      final livenessResponse =
          await _faceService.startLiveness(
        config: LivenessConfig(
          livenessType: LivenessType.PASSIVE,
          cameraSwitchEnabled: true,
          torchButtonEnabled: true,
          attemptsCount: 3,
          preventScreenRecording: true,
          closeButtonEnabled: false,
        ),
      );

      if (livenessResponse.liveness !=
          LivenessStatus.PASSED) {
        emit(
          const FaceVerificationError(
            message:
                'Liveness check did not pass. '
                'Please retry and follow the '
                'on-screen instructions.',
            canRetry: true,
          ),
        );

        return;
      }

      if (livenessResponse.image == null) {
        emit(
          const FaceVerificationError(
            message:
                'Could not capture a valid selfie. '
                'Please try again in good lighting.',
            canRetry: true,
          ),
        );

        return;
      }

      emit(
        const FaceVerificationLoading(
          'Matching face to document portrait...',
        ),
      );

      final matchScore =
          await _faceService.matchFaces(
        liveImage: livenessResponse.image!,
        documentPortrait: documentPortraitBytes,
      );

      if (matchScore == null) {
        emit(
          const FaceVerificationError(
            message:
                'Face matching failed. '
                'Please make sure your face is '
                'clearly visible and try again.',
            canRetry: true,
          ),
        );

        return;
      }

      final result = FaceVerificationResultModel(
        livenessPassed:
            livenessResponse.liveness ==
                LivenessStatus.PASSED,
        livenessStatus:
            livenessResponse.liveness.name,
        matchScore: matchScore,
        applicationId: applicationId,
        userId: userId,
      );

      await _repository.saveFaceResult(
        applicationId: applicationId,
        result: result,
      );

      emit(
        FaceVerificationSuccess(result),
      );
    } catch (e) {
      AppLogger.error(
        'Face verification failed',
        e,
      );

      emit(
        FaceVerificationError(
          message:
              'Face verification failed. '
              '${e.toString()}',
          canRetry: true,
        ),
      );
    }
  }

  void retry() {
    emit(
      const FaceVerificationInitial(),
    );
  }
}
```

---

# File: lib/face_verification/cubit/face_verification_state.dart

```dart
// lib/face_verification/cubit/face_verification_state.dart
//
// Sprint 4 — Face verification cubit states.
// Captures liveness, matching, and result flow statuses for the UI.

import '../model/face_verification_result_model.dart';

abstract class FaceVerificationState {
  const FaceVerificationState();
}

class FaceVerificationInitial
    extends FaceVerificationState {
  const FaceVerificationInitial();
}

class FaceVerificationLoading
    extends FaceVerificationState {
  final String message;

  const FaceVerificationLoading(
    this.message,
  );
}

class FaceVerificationReady
    extends FaceVerificationState {
  const FaceVerificationReady();
}

class FaceVerificationSuccess
    extends FaceVerificationState {
  final FaceVerificationResultModel result;

  const FaceVerificationSuccess(
    this.result,
  );
}

class FaceVerificationError
    extends FaceVerificationState {
  final String message;
  final bool canRetry;

  const FaceVerificationError({
    required this.message,
    this.canRetry = true,
  });
}

class FaceVerificationNotInitialized
    extends FaceVerificationState {
  const FaceVerificationNotInitialized();
}
```
---

# File: lib/face_verification/model/face_verification_result_model.dart

```dart
// lib/face_verification/model/face_verification_result_model.dart
//
// Sprint 4 — Face verification result model.
// This model encapsulates the Regula face liveness and match response
// data needed for UI, persistence, and the final face result screen.

class FaceVerificationResultModel {
  final bool livenessPassed;
  final String livenessStatus;
  final double matchScore;
  final String applicationId;
  final String userId;
  final String? errorMessage;

  const FaceVerificationResultModel({
    required this.livenessPassed,
    required this.livenessStatus,
    required this.matchScore,
    required this.applicationId,
    required this.userId,
    this.errorMessage,
  });

  bool get isPassed => livenessPassed && matchScore >= 75.0;

  Map<String, dynamic> toMap() => {
        'livenessPassed': livenessPassed,
        'livenessStatus': livenessStatus,
        'faceMatchScore': matchScore,
        'applicationId': applicationId,
        'userId': userId,
        'errorMessage': errorMessage,
      };
}
```

---

# File: lib/face_verification/repository/face_verification_repository.dart

```dart
// lib/face_verification/repository/face_verification_repository.dart
//
// Sprint 4 — Face verification persistence repository.
// Saves the face match score and liveness pass state to Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/utils/logger.dart';
import '../model/face_verification_result_model.dart';

class FaceVerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FaceVerificationResultModel> saveFaceResult({
    required String applicationId,
    required FaceVerificationResultModel result,
  }) async {
    try {
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .update({
            'faceMatchScore': result.matchScore,
            'livenessPasssed': result.livenessPassed,
            'updatedAt': DateTime.now().toIso8601String(),
          });

      AppLogger.success(
        'Face verification saved: $applicationId',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to save face verification result',
        e,
      );
    }

    return result;
  }
}
```
---

# File: lib/face_verification/ui/face_liveness_screen.dart

```dart
// lib/face_verification/ui/face_liveness_screen.dart
//
// Sprint 4 — Face verification UI.
// Uses FaceVerificationCubit and Regula Face SDK to perform passive liveness
// and face matching, then routes to the result screen.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../core/widgets/segmented_progress_bar.dart';
import '../cubit/face_verification_cubit.dart';
import '../cubit/face_verification_state.dart';

class FaceLivenessScreen extends StatelessWidget {
  final Uint8List? documentPortraitBytes;
  final String applicationId;
  final String userId;

  const FaceLivenessScreen({
    super.key,
    this.documentPortraitBytes,
    required this.applicationId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(
        title: 'Face verification',
        showClose: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SegmentedProgressBar(
              current: 4,
              total: 4,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  28,
                  24,
                  0,
                ),
                child: BlocConsumer<
                    FaceVerificationCubit,
                    FaceVerificationState>(
                  listener: (context, state) {
                    if (state is FaceVerificationSuccess) {
                      context.goNamed(
                        'faceResult',
                        extra: {
                          'matchScore':
                              state.result.matchScore,
                          'livenessStatus':
                              state.result.livenessStatus,
                          'applicationId':
                              state.result.applicationId,
                        },
                      );
                    }
                  },
                  builder: (context, state) {
                    final hasPortrait =
                        documentPortraitBytes != null &&
                        documentPortraitBytes!.isNotEmpty;

                    final errorMessage =
                        state is FaceVerificationError
                            ? state.message
                            : null;

                    final isLoading =
                        state is FaceVerificationLoading;

                    final loadingMessage =
                        state is FaceVerificationLoading
                            ? state.message
                            : null;

                    return Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 28),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(
                            color: AppColors.backgroundMint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face_rounded,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Face verification',
                          style: AppTextStyles.heading1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasPortrait
                              ? 'Follow the on-screen instructions '
                                'to capture a selfie. We will compare '
                                'it to your document portrait.'
                              : 'Document portrait is missing. '
                                'Face verification cannot proceed '
                                'without a captured portrait.',
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),

                        if (errorMessage != null) ...[
                          Container(
                            padding:
                                const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.error
                                  .withAlpha(26),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                color: AppColors.error,
                              ),
                              textAlign:
                                  TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        Expanded(
                          child: Center(
                            child: isLoading
                                ? Column(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(
                                        height: 16,
                                      ),
                                      Text(
                                        loadingMessage ??
                                            'Working...',
                                        style:
                                            AppTextStyles.body,
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.camera_front_rounded,
                                        size: 64,
                                        color:
                                            AppColors.primary,
                                      ),
                                      const SizedBox(
                                        height: 18,
                                      ),
                                      Text(
                                        'Ready for selfie capture',
                                        style:
                                            AppTextStyles.label,
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Text(
                                        'Tap continue when you are in '
                                        'a well-lit area and your face '
                                        'is centered on the screen.',
                                        style: AppTextStyles.bodySmall,
                                        textAlign:
                                            TextAlign.center,
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 24,
                          ),
                          child: ElevatedButton(
                            onPressed: hasPortrait &&
                                    !isLoading
                                ? () => context
                                    .read<
                                        FaceVerificationCubit>()
                                    .startFaceVerification(
                                      documentPortraitBytes:
                                          documentPortraitBytes!,
                                      applicationId:
                                          applicationId,
                                      userId: userId,
                                    )
                                : null,
                            child: Text(
                              hasPortrait
                                  ? 'Start face scan'
                                  : 'Cannot start',
                              style:
                                  AppTextStyles.buttonText,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

# File: lib/face_verification/ui/face_result_screen.dart

```dart
// lib/face_verification/ui/face_result_screen.dart
//
// Sprint 4 — Face verification result UI.
// Displays the Regula face matching score and liveness status.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';

class FaceResultScreen extends StatelessWidget {
  final double matchScore;
  final String livenessStatus;
  final String applicationId;

  const FaceResultScreen({
    super.key,
    required this.matchScore,
    required this.livenessStatus,
    required this.applicationId,
  });

  @override
  Widget build(BuildContext context) {
    const passThreshold = 75.0;

    final passed =
        matchScore >= passThreshold &&
        livenessStatus == 'PASSED';

    final badgeColor =
        passed
            ? AppColors.success
            : AppColors.warning;

    final badgeIcon =
        passed
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded;

    final statusText =
        passed
            ? 'Face verification passed'
            : 'Face verification needs review';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(
        title: 'Verification result',
        showClose: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                badgeIcon,
                size: 80,
                color: badgeColor,
              ),
              const SizedBox(height: 24),

              Text(
                statusText,
                style: AppTextStyles.heading1,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Match score: '
                '${matchScore.toStringAsFixed(1)}%\n'
                'Liveness: $livenessStatus\n'
                'Application: $applicationId',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () =>
                    context.goNamed('home'),
                child: const Text(
                  'Done',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
---

# File: lib/app/router.dart

```dart
// lib/app/router.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// ROUTER — Updated
// ══════════════════════════════════════════════════════════════════════════════
//
// Changes:
//   + Added /face-liveness route (was missing — caused crash after doc scan)
//   + Added /face-result route
//   All face SDK screens are stubs pending Sprint 4 implementation
//
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../applicant_classification/ui/applicant_type_screen.dart';
import '../authentication/ui/otp_verification_screen.dart';
import '../authentication/ui/phone_entry_screen.dart';
import '../device_intelligence/ui/vpn_blocked_screen.dart';
import '../document_upload/ui/id_upload_screen.dart';
import '../document_upload/ui/readiness_confirmation_screen.dart';
import '../document_verification/cubit/document_verification_cubit.dart';
import '../document_verification/model/verification_result_model.dart';
import '../document_verification/ui/document_scan_screen.dart';
import '../document_verification/ui/verification_result_screen.dart';
import '../home/ui/home_screen.dart';
import '../kyc_application/model/kyc_application_model.dart';
import '../onboarding/ui/onboarding_screen.dart';

// ── Face verification screens (Sprint 4 — stubs until implemented) ────────────
// Sprint 4 — Face verification screens and flow wiring
import '../face_verification/cubit/face_verification_cubit.dart';
import '../face_verification/ui/face_liveness_screen.dart';
import '../face_verification/ui/face_result_screen.dart';

GoRouter buildRouter({
  required bool onboardingDone,
  required bool isAuthenticated,
  required bool isSuspiciousNetwork,
}) {
  return GoRouter(
    initialLocation: _getInitialRoute(
      onboardingDone: onboardingDone,
      isAuthenticated: isAuthenticated,
      isSuspiciousNetwork: isSuspiciousNetwork,
    ),
    routes: [
      // ── Security ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/vpn-blocked',
        name: 'vpnBlocked',
        builder: (context, state) => VpnBlockedScreen(
          reason: state.extra as String? ??
              'Suspicious network detected',
        ),
      ),

      // ── Onboarding & Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) =>
            const OnboardingScreen(),
      ),

      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) =>
            const PhoneEntryScreen(),
      ),

      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final verificationId =
              state.extra as String;

          return OtpVerificationScreen(
            verificationId: verificationId,
          );
        },
      ),

      // ── Home ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) =>
            const HomeScreen(),
      ),

      // ── KYC Flow ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/applicant-type',
        name: 'applicantType',
        builder: (context, state) =>
            const ApplicantTypeScreen(),
      ),

      GoRoute(
        path: '/id-upload',
        name: 'idUpload',
        builder: (context, state) {
          final application =
              state.extra as KycApplicationModel;

          return IdUploadScreen(
            application: application,
          );
        },
      ),

      GoRoute(
        path: '/readiness',
        name: 'readiness',
        builder: (context, state) =>
            const ReadinessConfirmationScreen(),
      ),

      GoRoute(
        path: '/document-scan',
        name: 'documentScan',
        builder: (context, state) {
          final application =
              state.extra as KycApplicationModel;

          return BlocProvider(
            create: (_) =>
                DocumentVerificationCubit(),
            child: DocumentScanScreen(
              application: application,
            ),
          );
        },
      ),

      GoRoute(
        path: '/verification-result',
        name: 'verificationResult',
        builder: (context, state) {
          final result =
              state.extra as VerificationResultModel;

          return VerificationResultScreen(
            result: result,
          );
        },
      ),

      // ── Face Verification (Sprint 4) ──────────────────────────────────────
      // FIXED: These routes were missing — caused crash after document scan.
      GoRoute(
        path: '/face-liveness',
        name: 'faceLiveness',
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>?;

          return BlocProvider(
            create: (_) => FaceVerificationCubit(),
            child: FaceLivenessScreen(
              documentPortraitBytes:
                  extra?['portraitBytes'],
              applicationId:
                  extra?['applicationId'] as String? ?? '',
              userId:
                  extra?['userId'] as String? ?? '',
            ),
          );
        },
      ),

      GoRoute(
        path: '/face-result',
        name: 'faceResult',
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>;

          return FaceResultScreen(
            matchScore:
                extra['matchScore'] as double,
            livenessStatus:
                extra['livenessStatus'] as String,
            applicationId:
                extra['applicationId'] as String,
          );
        },
      ),
    ],
  );
}

String _getInitialRoute({
  required bool onboardingDone,
  required bool isAuthenticated,
  required bool isSuspiciousNetwork,
}) {
  if (isSuspiciousNetwork) {
    return '/vpn-blocked';
  }

  if (isAuthenticated) {
    return '/home';
  }

  if (!onboardingDone) {
    return '/onboarding';
  }

  return '/auth';
}
```
---

# File: android/app/build.gradle.kts

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // Firebase
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mostafa.kyc"
    compileSdk = 36

    // Stable NDK version (recommended for camera, ML, KYC SDKs)
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.mostafa.kyc"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Replace with your release keystore later
            signingConfig = signingConfigs.getByName("debug")

            // Optional: enable shrinking later for production
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    // Firebase BoM (manage versions automatically)
    implementation(
        platform("com.google.firebase:firebase-bom:34.11.0")
    )

    // Firebase services
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-storage")

    // Optional analytics/debugging
    implementation("com.google.firebase:firebase-analytics")

    // Regula Core package is large and requires multidex
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
```

---

# File: pubspec.yaml

```yaml
name: kyc

description: "Production KYC Application"

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter

  # ── Firebase ─────────────────────────────────────────
  firebase_core: ^3.13.1
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  firebase_storage: ^12.4.5

  # ── Regula Document Reader SDK ───────────────────────
  flutter_document_reader_api: ^9.4.0
  flutter_document_reader_core_fullrfid: ^9.0.0

  # ── Regula Face SDK (Sprint 4) ───────────────────────
  flutter_face_api: ^8.2.1092

  # ── State Management ─────────────────────────────────
  flutter_bloc: ^9.1.1

  # ── Navigation ───────────────────────────────────────
  go_router: ^14.6.3

  # ── Networking ───────────────────────────────────────
  dio: ^5.8.0+1

  # ── Local Storage ────────────────────────────────────
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^9.2.4

  # ── Media ────────────────────────────────────────────
  image_picker: ^1.1.2
  camera: ^0.11.1
  image: ^4.3.0

  # ── Device Information ───────────────────────────────
  device_info_plus: ^11.3.3

  # ── Utilities ────────────────────────────────────────
  uuid: ^4.5.1

  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^5.0.0
  mocktail: ^1.0.4

flutter:
  uses-material-design: true

  assets:
    - assets/regula.license
    - assets/regula/db.dat
    - assets/
```

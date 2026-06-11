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
          reason: state.extra as String? ?? 'Suspicious network detected',
        ),
      ),

      // ── Onboarding & Auth ─────────────────────────────────────────────────
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpVerificationScreen(verificationId: verificationId);
        },
      ),

      // ── Home ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // ── KYC Flow ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/applicant-type',
        name: 'applicantType',
        builder: (context, state) => const ApplicantTypeScreen(),
      ),
      GoRoute(
        path: '/id-upload',
        name: 'idUpload',
        builder: (context, state) {
          final application = state.extra as KycApplicationModel;
          return IdUploadScreen(application: application);
        },
      ),
      GoRoute(
        path: '/readiness',
        name: 'readiness',
        builder: (context, state) => const ReadinessConfirmationScreen(),
      ),
      GoRoute(
        path: '/document-scan',
        name: 'documentScan',
        builder: (context, state) {
          final application = state.extra as KycApplicationModel;
          return BlocProvider(
            create: (_) => DocumentVerificationCubit(),
            child: DocumentScanScreen(application: application),
          );
        },
      ),
      GoRoute(
        path: '/verification-result',
        name: 'verificationResult',
        builder: (context, state) {
          final result = state.extra as VerificationResultModel;
          return VerificationResultScreen(result: result);
        },
      ),

      // ── Face Verification (Sprint 4) ───────────────────────────────────────
      // FIXED: These routes were missing — caused crash after document scan.
      GoRoute(
        path: '/face-liveness',
        name: 'faceLiveness',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BlocProvider(
            create: (_) => FaceVerificationCubit(),
            child: FaceLivenessScreen(
              documentPortraitBytes: extra?['portraitBytes'],
              applicationId: extra?['applicationId'] as String? ?? '',
              userId: extra?['userId'] as String? ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: '/face-result',
        name: 'faceResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return FaceResultScreen(
            matchScore: extra['matchScore'] as double,
            livenessStatus: extra['livenessStatus'] as String,
            applicationId: extra['applicationId'] as String,
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
  if (isSuspiciousNetwork) return '/vpn-blocked';
  if (isAuthenticated) return '/home';
  if (!onboardingDone) return '/onboarding';
  return '/auth';
}

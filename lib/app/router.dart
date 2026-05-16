import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/applicant_classification/ui/applicant_type_screen.dart';
import 'package:kyc/document_upload/ui/id_upload_screen.dart';
import 'package:kyc/document_upload/ui/readiness_confirmation_screen.dart';
import 'package:kyc/document_verification/cubit/document_verification_cubit.dart';
import 'package:kyc/document_verification/model/verification_result_model.dart';
import 'package:kyc/document_verification/ui/document_scan_screen.dart';
import 'package:kyc/document_verification/ui/verification_result_screen.dart';
import 'package:kyc/kyc_application/model/kyc_application_model.dart';
import '../onboarding/ui/onboarding_screen.dart';
import '../authentication/ui/phone_entry_screen.dart';
import '../authentication/ui/otp_verification_screen.dart';
import '../home/ui/home_screen.dart';
import '../device_intelligence/ui/vpn_blocked_screen.dart';

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
      GoRoute(
        path: '/vpn-blocked',
        name: 'vpnBlocked',
        builder: (context, state) => VpnBlockedScreen(
          reason: state.extra as String? ?? 'Suspicious network detected',
        ),
      ),
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
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
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

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'authentication/cubit/auth_cubit.dart';
import 'authentication/repository/auth_repository.dart';
import 'device_intelligence/repository/device_intelligence_repository.dart';
import 'onboarding/cubit/onboarding_cubit.dart';
import 'app/router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Run all startup checks in parallel for speed
  final results = await Future.wait([
    DeviceIntelligenceRepository().runCheck(),
    OnboardingCubit.isOnboardingDone(),
  ]);

  final networkCheck = results[0] as dynamic;
  final onboardingDone = results[1] as bool;
  final authRepo = AuthRepository();
  final isAuthenticated = authRepo.currentFirebaseUser != null;

  AppLogger.info(
    'App start — onboarding: $onboardingDone, '
    'authenticated: $isAuthenticated, '
    'suspicious: ${networkCheck.isSuspicious}',
  );

  runApp(
    MyApp(
      onboardingDone: onboardingDone,
      isAuthenticated: isAuthenticated,
      isSuspiciousNetwork: networkCheck.isSuspicious,
      authRepository: authRepo,
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool onboardingDone;
  final bool isAuthenticated;
  final bool isSuspiciousNetwork;
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.onboardingDone,
    required this.isAuthenticated,
    required this.isSuspiciousNetwork,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // AuthCubit provided at root so ALL screens can access it
      create: (_) => AuthCubit(repository: authRepository),
      child: Builder(
        builder: (context) {
          // Listen to auth state changes to handle sign-out navigation
          context.read<AuthCubit>().stream.listen((state) {
            if (state is AuthUnauthenticated) {
              appRouter.goNamed('auth');
            }
            if (state is AuthAuthenticated) {
              appRouter.goNamed('home');
            }
          });

          return MaterialApp.router(
            title: 'KYC App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }

  GoRouter get appRouter => buildRouter(
    onboardingDone: onboardingDone,
    isAuthenticated: isAuthenticated,
    isSuspiciousNetwork: isSuspiciousNetwork,
  );
}

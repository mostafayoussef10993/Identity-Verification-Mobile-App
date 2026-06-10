// lib/main.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// MAIN — Fixed stream leak
// ══════════════════════════════════════════════════════════════════════════════
//
// FIXED: Auth stream listener was inside build() — created multiple subscriptions
// on every rebuild. Moved to StatefulWidget with proper dispose() cleanup.
//
// ══════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/router.dart';
import 'authentication/cubit/auth_cubit.dart';
import 'authentication/repository/auth_repository.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'device_intelligence/repository/device_intelligence_repository.dart';
import 'firebase_options.dart';
import 'kyc_application/cubit/kyc_application_cubit.dart';
import 'onboarding/cubit/onboarding_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase app already initialized (common during hot reload in development)
    if (!e.toString().contains('already exists')) {
      rethrow;
    }
  }

  // Run startup checks in parallel for speed
  final results = await Future.wait([
    DeviceIntelligenceRepository().runCheck(),
    OnboardingCubit.isOnboardingDone(),
  ]);

  final networkCheck = results[0] as dynamic;
  final onboardingDone = results[1] as bool;
  final authRepo = AuthRepository();
  final isAuthenticated = authRepo.currentFirebaseUser != null;

  AppLogger.info(
    'App start — onboarding: $onboardingDone | '
    'authenticated: $isAuthenticated | '
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

// ══════════════════════════════════════════════════════════════════════════════
// MyApp — StatefulWidget to manage auth stream subscription lifecycle
// FIXED: Was StatelessWidget — stream listener inside build() leaked subscriptions
// ══════════════════════════════════════════════════════════════════════════════
class MyApp extends StatefulWidget {
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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final AuthCubit _authCubit;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    _authCubit = AuthCubit(repository: widget.authRepository);
    _authCubit.checkAuthState();

    _router = buildRouter(
      onboardingDone: widget.onboardingDone,
      isAuthenticated: widget.isAuthenticated,
      isSuspiciousNetwork: widget.isSuspiciousNetwork,
    );

    // FIXED: Single subscription, properly cancelled in dispose()
    _authSubscription = _authCubit.stream.listen((state) {
      if (state is AuthUnauthenticated) {
        _router.goNamed('auth');
      } else if (state is AuthAuthenticated) {
        _router.goNamed('home');
      }
    });
  }

  @override
  void dispose() {
    // FIXED: Cancel subscription to prevent memory leak
    _authSubscription?.cancel();
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<OnboardingCubit>(create: (_) => OnboardingCubit()),
        BlocProvider<KycApplicationCubit>(create: (_) => KycApplicationCubit()),
      ],
      child: MaterialApp.router(
        title: 'KYC App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/onboarding/cubit/onboarding_state.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/onboarding_cubit.dart';
import 'widgets/onboarding_page.dart';

/// The main onboarding screen that guides new users through the app's
/// identity verification process.

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  /// Controller to programmatically control the PageView
  final PageController _pageController = PageController();

  /// Tracks the currently visible page (used for dot indicators and button text)
  int _currentPage = 0;

  // The 3 onboarding pages content
  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Verify Your Identity',
      'description':
          'Complete a secure identity verification process to access all features safely and confidently.',
      'icon': Icons.verified_user_outlined,
      'color': AppColors.primary,
    },
    {
      'title': 'Scan Your Document',
      'description':
          'Take a photo of your ID or passport. Our system reads and verifies your document automatically.',
      'icon': Icons.document_scanner_outlined,
      'color': AppColors.accent,
    },
    {
      'title': 'Quick & Secure',
      'description':
          'Your data is encrypted and protected. Complete verification in just a few minutes.',
      'icon': Icons.shield_outlined,
      'color': AppColors.info,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          // Navigate to auth when onboarding is done
          context.goNamed('auth');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button (top right)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    context.read<OnboardingCubit>().completeOnboarding();
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),

              // PageView — the 3 screens
              // Main Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    context.read<OnboardingCubit>().pageChanged(index);
                  },
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return OnboardingPage(
                      title: page['title'],
                      description: page['description'],
                      icon: page['icon'],
                      iconColor: page['color'],
                    );
                  },
                ),
              ),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      // Go to next page
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      // Last page — complete onboarding
                      context.read<OnboardingCubit>().completeOnboarding();
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

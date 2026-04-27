import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/onboarding/cubit/onboarding_state.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/onboarding_cubit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'Verify Your Identity',
      description:
          "Complete a secure identity check to access all features. It only takes a few minutes — don't worry, it shouldn't take long.",
      icon: Icons.verified_user_rounded,
      bgColor: Color(0xFFE8F5F0), // mint tint
      iconColor: AppColors.primary,
    ),
    _OnboardingData(
      title: 'Scan Your Document',
      description:
          "We'll need to see your national ID or passport. Our system reads and verifies it automatically.",
      icon: Icons.document_scanner_rounded,
      bgColor: Color(0xFFFFF3E0), // warm tint
      iconColor: Color(0xFFE65100),
    ),
    _OnboardingData(
      title: 'Quick & Secure',
      description:
          "Your data is encrypted and protected. We'll ask a few questions to confirm who you are.",
      icon: Icons.shield_rounded,
      bgColor: Color(0xFFE8EAF6), // blue tint
      iconColor: Color(0xFF3949AB),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingCubit(),
      child: BlocListener<OnboardingCubit, OnboardingState>(
        listener: (context, state) {
          if (state is OnboardingCompleted) {
            context.goNamed('auth');
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (_, index) =>
                      _OnboardingPageView(data: _pages[index]),
                ),
              ),

              // Bottom section — dots + buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                child: Column(
                  children: [
                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.primary
                                : AppColors.divider,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Primary button
                    Builder(
                      builder: (context) {
                        return ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              context
                                  .read<OnboardingCubit>()
                                  .completeOnboarding();
                            }
                          },
                          child: Text(
                            _currentPage < _pages.length - 1
                                ? 'Continue'
                                : "Let's get started",
                            style: AppTextStyles.buttonText,
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Skip text button
                    if (_currentPage < _pages.length - 1)
                      Builder(
                        builder: (context) {
                          return TextButton(
                            onPressed: () => context
                                .read<OnboardingCubit>()
                                .completeOnboarding(),
                            child: const Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}

class _OnboardingPageView extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPageView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Colored illustration area — top 45% of screen
        Expanded(
          flex: 45,
          child: Container(
            width: double.infinity,
            color: data.bgColor,
            child: Center(
              child: Icon(data.icon, size: 100, color: data.iconColor),
            ),
          ),
        ),

        // White content area — bottom 55%
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.heading1),
                const SizedBox(height: 12),
                Text(data.description, style: AppTextStyles.body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

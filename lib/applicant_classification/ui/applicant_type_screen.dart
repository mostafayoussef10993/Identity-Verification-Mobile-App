// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/core/widgets/segmented_progress_bar.dart';
import 'package:kyc/kyc_application/cubit/kyc_application_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../../kyc_application/cubit/kyc_application_cubit.dart';
import '../../kyc_application/model/applicant_type.dart';
import '../../authentication/cubit/auth_cubit.dart';

class ApplicantTypeScreen extends StatefulWidget {
  const ApplicantTypeScreen({super.key});

  @override
  State<ApplicantTypeScreen> createState() => _ApplicantTypeScreenState();
}

class _ApplicantTypeScreenState extends State<ApplicantTypeScreen> {
  ApplicantType? _selected;

  final List<_TypeOption> _options = [
    _TypeOption(
      type: ApplicantType.egyptian,
      icon: Icons.person_rounded,
      title: 'Egyptian',
      subtitle: 'Verify using your National ID card',
      documentLabel: 'National ID — front & back',
    ),
    _TypeOption(
      type: ApplicantType.resident,
      icon: Icons.badge_rounded,
      title: 'Resident',
      subtitle: 'Non-Egyptian resident in Egypt',
      documentLabel: 'Passport — single page',
    ),
    _TypeOption(
      type: ApplicantType.foreigner,
      icon: Icons.language_rounded,
      title: 'Foreigner',
      subtitle: 'Foreign national visiting or working in Egypt',
      documentLabel: 'Passport — single page',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(
        title: 'Create an account',
        showBack: false,
        showClose: false,
      ),
      body: BlocConsumer<KycApplicationCubit, KycApplicationState>(
        listener: (context, state) {
          if (state is KycApplicationActive) {
            // Navigate to ID upload, passing applicant type
            context.goNamed('idUpload', extra: state.application);
          }
          if (state is KycApplicationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is KycApplicationLoading;

          return SafeArea(
            child: Column(
              children: [
                // Segmented progress
                const SegmentedProgressBar(current: 1, total: 4),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What describes\nyou best?',
                          style: AppTextStyles.heading1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This helps us determine which document we need to verify your identity.',
                          style: AppTextStyles.body,
                        ),
                        const SizedBox(height: 28),

                        // Type selection cards
                        ...(_options.map(
                          (option) => _TypeCard(
                            option: option,
                            isSelected: _selected == option.type,
                            onTap: () =>
                                setState(() => _selected = option.type),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                // Continue button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _selected == null
                              ? null // disabled until selection made
                              : () {
                                  final authState = context
                                      .read<AuthCubit>()
                                      .state;
                                  if (authState is AuthAuthenticated) {
                                    context
                                        .read<KycApplicationCubit>()
                                        .startApplication(
                                          userId: authState.user.uid,
                                          applicantType: _selected!,
                                        );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please sign in to continue.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                          child: const Text(
                            'Continue',
                            style: AppTextStyles.buttonText,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────
class _TypeOption {
  final ApplicantType type;
  final IconData icon;
  final String title;
  final String subtitle;
  final String documentLabel;
  const _TypeOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.documentLabel,
  });
}

// ── Selection card ────────────────────────────────────────────
class _TypeCard extends StatelessWidget {
  final _TypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceGrey,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                option.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(option.subtitle, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 4),
                  // Document type tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option.documentLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kyc/core/widgets/kyc_app_bar.dart';
import 'package:kyc/core/widgets/segmented_progress_bar.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/auth_cubit.dart';

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: KycAppBar(title: 'Create an account', closeRoute: 'onboarding'),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.goNamed('otp', extra: state.verificationId);
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Segmented progress bar
                          const SegmentedProgressBar(current: 1, total: 4),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "What's your\nphone number?",
                                      style: AppTextStyles.heading1,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "We'll send you a one-time verification code.",
                                      style: AppTextStyles.body,
                                    ),
                                    const SizedBox(height: 32),

                                    // Label above field
                                    const Text(
                                      'Phone number',
                                      style: AppTextStyles.label,
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        hintText: '01XXXXXXXXX',
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 14,
                                          ),
                                          child: const Text(
                                            '+20',
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (v.length < 10) {
                                          return 'Please enter a valid phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Button pinned to bottom
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                            child: state is AuthLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState!.validate()) {
                                        context.read<AuthCubit>().sendOtp(
                                          '+20${_phoneController.text.trim()}',
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
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

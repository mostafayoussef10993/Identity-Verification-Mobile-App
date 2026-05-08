// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kyc_app_bar.dart';
import '../cubit/auth_cubit.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String verificationId;
  const OtpVerificationScreen({super.key, required this.verificationId});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _code = '';
  static const int _codeLength = 6;

  void _onKeyTap(String key) {
    if (_code.length < _codeLength) {
      setState(() => _code += key);
      if (_code.length == _codeLength) _submit();
    }
  }

  void _onDelete() {
    if (_code.isNotEmpty) {
      setState(() => _code = _code.substring(0, _code.length - 1));
    }
  }

  void _submit() {
    context.read<AuthCubit>().verifyOtp(
      verificationId: widget.verificationId,
      otpCode: _code,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const KycAppBar(
        title: 'Sign in',
        showBack: false,
        showClose: false,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.goNamed('home');
          }
          if (state is AuthError) {
            setState(() => _code = '');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),

                // Title & subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'Enter the code',
                        style: AppTextStyles.heading1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code sent to your phone.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 6 individual square boxes showing digits
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (i) {
                      final hasDigit = i < _code.length;
                      final isActive = i == _code.length; // current box

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 46,
                        height: 56,
                        decoration: BoxDecoration(
                          color: hasDigit
                              ? AppColors.primary.withOpacity(0.05)
                              : AppColors.surfaceGrey,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? AppColors
                                      .primary // active = dark green border
                                : hasDigit
                                ? AppColors
                                      .primary // filled = dark green border
                                : AppColors.divider, // empty = grey border
                            width: isActive || hasDigit ? 2 : 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: hasDigit
                            ? Text(
                                _code[i], // visible digit
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : isActive
                            ? Container(
                                // blinking cursor bar
                                width: 1.5,
                                height: 24,
                                color: AppColors.primary,
                              )
                            : null,
                      );
                    }),
                  ),
                ),

                const Spacer(),

                // Loading or numpad
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 48),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else
                  _buildNumpad(),

                const SizedBox(height: 16),

                // Resend
                TextButton(
                  onPressed: isLoading ? null : () => context.pop(),
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumpad() {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: rows.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 80, height: 64);
              }

              return SizedBox(
                width: 80,
                height: 64,
                child: TextButton(
                  style: TextButton.styleFrom(
                    overlayColor: AppColors.primary.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: key == 'del' ? _onDelete : () => _onKeyTap(key),
                  child: key == 'del'
                      ? const Icon(
                          Icons.backspace_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        )
                      : Text(
                          key,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}

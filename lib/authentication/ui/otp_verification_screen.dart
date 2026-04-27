import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        title: const Text('Sign in'),
        automaticallyImplyLeading: false,
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
          return SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),

                // Title
                Text(
                  state is AuthLoading ? 'Verifying...' : 'Enter the code',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to your phone.',
                  style: AppTextStyles.body,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // 6 dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_codeLength, (i) {
                    final filled = i < _code.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: filled ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: filled ? AppColors.primary : AppColors.divider,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),

                const Spacer(),

                if (state is AuthLoading)
                  const CircularProgressIndicator(color: AppColors.primary)
                else
                  // Custom numpad
                  _buildNumpad(),

                const SizedBox(height: 32),

                // Resend option
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNumpad() {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 80, height: 64);

              return SizedBox(
                width: 80,
                height: 64,
                child: TextButton(
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

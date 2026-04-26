import 'package:flutter_bloc/flutter_bloc.dart';
import '../repository/auth_repository.dart';
import '../model/user_model.dart';
import '../../core/utils/logger.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit({AuthRepository? repository})
    : _authRepository = repository ?? AuthRepository(),
      super(AuthInitial());

  // ─── Check session on app start ──────────────────────────────
  void checkAuthState() {
    final user = _authRepository.currentFirebaseUser;
    if (user != null) {
      AppLogger.info('Existing session found: ${user.uid}');
      emit(
        AuthAuthenticated(
          UserModel(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? '',
            createdAt: DateTime.now(),
          ),
        ),
      );
    } else {
      emit(AuthUnauthenticated());
    }
  }

  // ─── Send OTP ─────────────────────────────────────────────────
  Future<void> sendOtp(String phoneNumber) async {
    emit(AuthLoading());

    await _authRepository.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        // OTP sent — move to OTP entry screen
        emit(AuthOtpSent(verificationId));
      },
      onError: (error) {
        emit(AuthError(error));
      },
    );
  }

  // ─── Verify OTP ───────────────────────────────────────────────
  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyOtp(
        verificationId: verificationId,
        otpCode: otpCode,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(AuthUnauthenticated());
  }
}

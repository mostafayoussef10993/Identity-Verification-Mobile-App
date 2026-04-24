import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user_model.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/logger.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Current user ────────────────────────────────────────────
  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Step 1: Send OTP to phone number ────────────────────────
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      AppLogger.info('Sending OTP to $phoneNumber');

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,

        // Called when OTP is sent successfully
        codeSent: (String verificationId, int? resendToken) {
          AppLogger.success('OTP sent — verificationId received');
          onCodeSent(verificationId);
        },

        // Called if verification completes automatically (rare, Android only)
        verificationCompleted: (PhoneAuthCredential credential) {
          AppLogger.info('Auto-verification completed');
        },

        // Called if sending OTP fails
        verificationFailed: (FirebaseAuthException e) {
          AppLogger.error('OTP send failed', e);
          onError(_mapFirebaseError(e));
        },

        // Called when the code expires (default 60 seconds)
        codeAutoRetrievalTimeout: (String verificationId) {
          AppLogger.warning('OTP auto-retrieval timed out');
        },

        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      AppLogger.error('Unexpected error sending OTP', e);
      onError('Failed to send OTP. Please try again.');
    }
  }

  // ─── Step 2: Verify OTP and sign in ──────────────────────────
  Future<UserModel> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      AppLogger.info('Verifying OTP code...');

      // Build credential from verificationId + code the user typed
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      // Sign in with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      AppLogger.success('User signed in: ${user.uid}');

      // Save/update user in Firestore
      final userModel = UserModel(
        uid: user.uid,
        phoneNumber: user.phoneNumber ?? '',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap(), SetOptions(merge: true));
      // merge: true means update existing fields, don't overwrite everything

      return userModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('OTP verification failed', e);
      throw AuthException(message: _mapFirebaseError(e), code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error during verification', e);
      throw const UnexpectedException();
    }
  }

  // ─── Sign out ─────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
    AppLogger.info('User signed out');
  }

  // ─── Map Firebase error codes to human-readable messages ─────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'invalid-verification-code':
        return 'Incorrect code. Please check and try again.';
      case 'session-expired':
        return 'The OTP has expired. Please request a new one.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

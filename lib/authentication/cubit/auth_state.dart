part of 'auth_cubit.dart';

abstract class AuthState {}

// App just opened, checking if user is logged in
class AuthInitial extends AuthState {}

// Any loading operation (sending OTP, verifying, etc.)
class AuthLoading extends AuthState {}

// OTP was sent successfully — we now have a verificationId
class AuthOtpSent extends AuthState {
  final String verificationId;
  AuthOtpSent(this.verificationId);
}

// User fully authenticated
class AuthAuthenticated extends AuthState {
  final UserModel user;
  AuthAuthenticated(this.user);
}

// User is not logged in
class AuthUnauthenticated extends AuthState {}

// Something went wrong
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

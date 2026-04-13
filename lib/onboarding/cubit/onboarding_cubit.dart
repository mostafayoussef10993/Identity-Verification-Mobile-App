import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyc/onboarding/cubit/onboarding_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  static const String _onboardingKey = 'onboarding_completed';
  OnboardingCubit() : super(OnboardingInitial());
  // Called on every page swipe
  void pageChanged(int page) {
    emit(OnboardingInProgress(page));
  }

  // Called when user taps "Get Started" on the last page
  Future<void> completeOnboarding() async {
    // Save flag locally so we never show onboarding again
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    emit(OnboardingCompleted());
  }

  // Called at app start to check if onboarding was already done
  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }
}

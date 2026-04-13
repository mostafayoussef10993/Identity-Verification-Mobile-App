/// Base class for all onboarding states.
abstract class OnboardingState {}

/// Represents the initial state of the onboarding screen.
class OnboardingInitial extends OnboardingState {}

/// Represents the state when the user is actively going through the onboarding
/// pages (swiping or navigating between pages).
///
/// This state carries the current page index, allowing the UI to reflect the
/// user's progress and update indicators
class OnboardingInProgress extends OnboardingState {
  final int currentPage;
  OnboardingInProgress(this.currentPage);
}

/// Represents the final state when the user has successfully completed the
/// entire onboarding process.
class OnboardingCompleted extends OnboardingState {}

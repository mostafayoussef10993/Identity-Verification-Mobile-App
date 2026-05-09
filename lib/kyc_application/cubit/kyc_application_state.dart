import 'package:kyc/kyc_application/model/kyc_application_model.dart';

abstract class KycApplicationState {}
// the default state before anything happens

class KycApplicationInitial extends KycApplicationState {}
//A submission or data fetch is in progress

class KycApplicationLoading extends KycApplicationState {}

//The user is actively filling out the form
class KycApplicationActive extends KycApplicationState {
  final KycApplicationModel application;
  KycApplicationActive(this.application);
}

//Something went wrong
class KycApplicationError extends KycApplicationState {
  final String message;
  KycApplicationError(this.message);
}

//The application was successfully sent
class KycApplicationSubmitted extends KycApplicationState {
  final KycApplicationModel application;
  KycApplicationSubmitted(this.application);
}

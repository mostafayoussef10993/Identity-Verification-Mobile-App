import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kyc/kyc_application/cubit/kyc_application_state.dart';
import 'package:uuid/uuid.dart';
import '../model/kyc_application_model.dart';
import '../model/applicant_type.dart';
import '../../core/utils/logger.dart';

class KycApplicationCubit extends Cubit<KycApplicationState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  KycApplicationCubit() : super(KycApplicationInitial());

  // Convenience getter
  KycApplicationModel? get currentApplication => state is KycApplicationActive
      ? (state as KycApplicationActive).application
      : null;

  // ── Create a new KYC application ─────────────────────────────
  Future<void> startApplication({
    required String userId,
    required ApplicantType applicantType,
  }) async {
    emit(KycApplicationLoading());
    try {
      final applicationId = const Uuid().v4();
      final now = DateTime.now();

      final application = KycApplicationModel(
        applicationId: applicationId,
        userId: userId,
        applicantType: applicantType,
        createdAt: now,
        updatedAt: now,
      );

      // Save initial record to Firestore
      await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .set(application.toMap());

      AppLogger.success('KYC application created: $applicationId');
      emit(KycApplicationActive(application));
    } catch (e) {
      AppLogger.error('Failed to start KYC application', e);
      emit(
        KycApplicationError('Failed to start application. Please try again.'),
      );
    }
  }

  // ── Update any field(s) and persist to Firestore ─────────────
  Future<void> updateApplication(
    KycApplicationModel Function(KycApplicationModel) updater,
  ) async {
    final current = currentApplication;
    if (current == null) return;

    try {
      final updated = updater(current);

      await _firestore
          .collection('kyc_applications')
          .doc(updated.applicationId)
          .update(updated.toMap());

      AppLogger.info('KYC application updated');
      emit(KycApplicationActive(updated));
    } catch (e) {
      AppLogger.error('Failed to update KYC application', e);
      // Don't emit error — keep current state, just log it
    }
  }

  // ── Resume an existing application ──────────────────────────
  Future<void> resumeApplication(String applicationId) async {
    emit(KycApplicationLoading());
    try {
      final doc = await _firestore
          .collection('kyc_applications')
          .doc(applicationId)
          .get();

      if (doc.exists) {
        final application = KycApplicationModel.fromMap(doc.data()!);
        emit(KycApplicationActive(application));
        AppLogger.success('Application resumed: $applicationId');
      } else {
        emit(KycApplicationError('Application not found.'));
      }
    } catch (e) {
      AppLogger.error('Failed to resume application', e);
      emit(KycApplicationError('Failed to load application.'));
    }
  }

  // ── Final submission ─────────────────────────────────────────
  Future<void> submitApplication() async {
    final current = currentApplication;
    if (current == null) return;

    emit(KycApplicationLoading());
    try {
      final submitted = current.copyWith(status: 'pending');

      await _firestore
          .collection('kyc_applications')
          .doc(submitted.applicationId)
          .update({
            'status': 'pending',
            'updatedAt': DateTime.now().toIso8601String(),
          });

      AppLogger.success('KYC application submitted');
      emit(KycApplicationSubmitted(submitted));
    } catch (e) {
      AppLogger.error('Failed to submit application', e);
      emit(KycApplicationError('Failed to submit. Please try again.'));
    }
  }
}

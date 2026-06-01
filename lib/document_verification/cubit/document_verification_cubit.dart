// lib/document_verification/cubit/document_verification_cubit.dart
//
// ══════════════════════════════════════════════════════════════════════════════
// DOCUMENT VERIFICATION CUBIT
// ══════════════════════════════════════════════════════════════════════════════
//
// Changes:
//   • initializeSdk() — single call, offline DB loaded inside RegulaService
//   • startScan() — passes applicantType for dual-workflow (Egyptian vs Passport)
//   • Calls saveVerificationResults() (text-only Firestore) — no image upload
//   • Portrait bytes remain in result object for Face SDK in Sprint 4
//
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/verification_result_model.dart';
import '../service/regula_service.dart';
import '../repository/document_verification_repository.dart';
import '../cubit/document_verification_state.dart';
import '../../kyc_application/model/applicant_type.dart';
import '../../core/utils/logger.dart';

class DocumentVerificationCubit extends Cubit<DocumentVerificationState> {
  final RegulaService _regulaService;
  final DocumentVerificationRepository _repository;

  DocumentVerificationCubit({
    RegulaService? regulaService,
    DocumentVerificationRepository? repository,
  }) : _regulaService = regulaService ?? RegulaService(),
       _repository = repository ?? DocumentVerificationRepository(),
       super(const DocumentVerificationInitial());

  // ── Initialize SDK ─────────────────────────────────────────────────────────
  // Loads offline db.dat from assets — no network download.
  Future<void> initializeSdk() async {
    if (_regulaService.isInitialized) {
      emit(const DocumentVerificationReady());
      return;
    }

    emit(
      const DocumentVerificationInitializing(
        message: 'Loading verification engine...',
        progress: null,
      ),
    );

    final initialized = await _regulaService.initialize();

    if (initialized) {
      emit(const DocumentVerificationReady());
    } else {
      emit(
        const DocumentVerificationError(
          message:
              'Failed to initialize document verification.\n\n'
              'Please ensure the app is fully installed and try again.',
          canRetry: true,
        ),
      );
    }
  }

  // ── Start scan ─────────────────────────────────────────────────────────────
  // applicantType drives dual-workflow SDK configuration:
  //   Egyptian  → double-sided, Arabic BiDi enabled
  //   Passport  → single-sided, MRZ only
  Future<void> startScan({
    required ApplicantType applicantType,
    required String userId,
    required String applicationId,
  }) async {
    if (!_regulaService.isInitialized) {
      emit(const DocumentVerificationNotInitialized());
      return;
    }

    emit(const DocumentVerificationScanning());

    final rawResults = await _regulaService.startScanner(
      applicantType: applicantType,
    );

    // User cancelled
    if (rawResults == null) {
      emit(const DocumentVerificationCancelled());
      return;
    }

    emit(const DocumentVerificationProcessing());

    final verificationResult = await _regulaService.extractResults(
      rawResults,
      applicantType: applicantType,
    );

    if (verificationResult.overallStatus == VerificationStatus.failed) {
      emit(
        const DocumentVerificationError(
          message:
              'Could not read the document. Please ensure:\n'
              '• All four corners are visible\n'
              '• There is no glare on the document\n'
              '• You are in a well-lit area',
          canRetry: true,
        ),
      );
      return;
    }

    // Save text fields to Firestore — no image upload
    emit(const DocumentVerificationUploading(progress: 0.0));

    final savedResult = await _repository.saveVerificationResults(
      result: verificationResult,
      userId: userId,
      applicationId: applicationId,
      onProgress: (p) => emit(DocumentVerificationUploading(progress: p)),
    );

    // Portrait bytes remain in savedResult.portraitBytes (in memory)
    // They will be passed to Face SDK screen in Sprint 4
    AppLogger.info(
      'Portrait bytes available for face matching: '
      '${savedResult.portraitBytes != null ? "${savedResult.portraitBytes!.length} bytes" : "none"}',
    );

    emit(DocumentVerificationSuccess(savedResult));
  }

  void retry() => emit(const DocumentVerificationReady());
  void retryInit() => initializeSdk();

  @override
  Future<void> close() {
    // Do NOT deinitialize — SDK stays warm for face verification
    return super.close();
  }
}

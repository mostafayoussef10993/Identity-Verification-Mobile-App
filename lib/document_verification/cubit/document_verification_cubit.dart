// ignore_for_file: unused_import

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kyc/document_verification/cubit/document_verification_state.dart';
import '../model/verification_result_model.dart';
import '../service/regula_service.dart';
import '../repository/document_verification_repository.dart';
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

  // ── Initialize SDK ───────────────────────────────────────────
  /// Call this when DocumentScanScreen loads.
  Future<void> initializeSdk() async {
    if (_regulaService.isInitialized) {
      emit(const DocumentVerificationReady());
      return;
    }

    // Step 1 — Download database
    emit(
      const DocumentVerificationInitializing(
        message: 'Preparing document database...',
        progress: 0,
      ),
    );

    final dbReady = await _regulaService.prepareDatabase(
      onProgress: (p) => emit(
        DocumentVerificationInitializing(
          message: 'Downloading database ${(p * 100).toInt()}%',
          progress: p,
        ),
      ),
    );

    if (!dbReady) {
      emit(
        const DocumentVerificationError(
          message:
              'Failed to download the document database. Please check your internet connection.',
          canRetry: true,
        ),
      );
      return;
    }

    // Step 2 — Initialize SDK
    emit(
      const DocumentVerificationInitializing(
        message: 'Initializing verification engine...',
      ),
    );

    final initialized = await _regulaService.initialize();

    if (initialized) {
      emit(const DocumentVerificationReady());
    } else {
      emit(
        const DocumentVerificationError(
          message:
              'Failed to initialize document verification. Please check your license.',
          canRetry: false, // License issues can't be retried by the user
        ),
      );
    }
  }

  // ── Start scanning ───────────────────────────────────────────
  /// Opens the Regula native scanner.
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

    final isPassport = applicantType != ApplicantType.egyptian;
    final rawResults = await _regulaService.startScanner(
      isPassport: isPassport,
    );

    // User cancelled
    if (rawResults == null) {
      emit(const DocumentVerificationCancelled());
      return;
    }

    // Extract structured data from raw Regula results
    emit(const DocumentVerificationProcessing());

    final verificationResult = await _regulaService.extractResults(rawResults);

    // Failed extraction
    if (verificationResult.overallStatus == VerificationStatus.failed) {
      emit(
        const DocumentVerificationError(
          message: 'Could not read the document. Please try again.',
          canRetry: true,
        ),
      );
      return;
    }

    // Upload portrait + document images to Cloudinary
    emit(const DocumentVerificationUploading(progress: 0.0));

    final uploadedResult = await _repository.uploadVerificationAssets(
      result: verificationResult,
      userId: userId,
      applicationId: applicationId,
      onProgress: (p) => emit(DocumentVerificationUploading(progress: p)),
    );

    emit(DocumentVerificationSuccess(uploadedResult));
  }

  // ── Retry ────────────────────────────────────────────────────
  void retry() => emit(const DocumentVerificationReady());

  // ── Cleanup ──────────────────────────────────────────────────
  @override
  Future<void> close() {
    // Don't deinitialize here — SDK may be reused in same session
    // Deinitialize explicitly from the screen when KYC flow completes
    return super.close();
  }
}

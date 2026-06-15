KYC Identity Verification App

A production-grade Flutter application for KYC (Know Your Customer) identity verification, built with Clean Architecture and powered by the Regula Document Reader SDK and Regula Face SDK for on-device document and biometric verification.

✨ Features


Phone authentication — Firebase Auth with OTP verification
Applicant classification — dynamic flows for Egyptian, Resident, and Foreigner applicants
Document verification (Regula Document Reader SDK)

National ID (front & back) and passport scanning
OCR, MRZ parsing, barcode reading, and authenticity checks
Portrait extraction for biometric matching
Egyptian-specific dual-language (Arabic/English) name handling



Face verification (Regula Face SDK)

Passive/active liveness detection
1:1 face matching against the extracted document portrait



Device intelligence — VPN/proxy/TOR detection before sensitive flows
Privacy by design — document and selfie images are processed locally only; only extracted text fields and verification results are stored in Firestore
Resumable onboarding with progress tracking


🛠 Tech Stack


Flutter (Dart)
Clean Architecture — Presentation / Domain / Data layers
BLoC / Cubit for state management
go_router for navigation
Firebase — Authentication & Firestore
Regula Document Reader SDK (flutter_document_reader_api)
Regula Face SDK (flutter_face_api)


📂 Project Structure

lib/
├── app/                     # App entry, routing
├── authentication/          # Phone/OTP auth
├── applicant_classification/
├── device_intelligence/     # VPN/network checks
├── document_verification/   # Regula Document Reader integration
├── document_upload/          # Readiness & confirmation screens
├── kyc_application/          # Application model & cubit
├── onboarding/
└── home/

🚀 Getting Started

Prerequisites


Flutter SDK (>= 3.8)
A configured Firebase project (firebase_options.dart / google-services.json)
A valid Regula SDK license file (assets/regula.license)


Setup

bashgit clone <repo-url>
cd kyc
flutter pub get


Add your Regula license file to assets/regula.license
Configure Firebase using the FlutterFire CLI or by adding your own google-services.json / firebase_options.dart
Run the app:


bashflutter run


⚠️ Android note: Ensure aaptOptions { noCompress("Regula/faceSdkResource.dat") } is set in android/app/build.gradle.kts to avoid Face SDK initialization errors.



🔒 Security & Compliance


Document and selfie images never leave the device
Only structured, extracted data is transmitted to Firestore
Designed with KYC/AML and data-minimization principles in mind


📌 Status

Actively in development — core authentication, applicant classification, and document verification are complete. Face verification (liveness + matching) is in progress.

📄 License

Private project — all rights reserved.

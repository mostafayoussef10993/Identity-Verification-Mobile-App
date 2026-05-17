Here is your final, complete technical summary for Claude AI. It now includes your business rules for handling Egyptian National IDs vs. Foreign Passports, along with a dedicated instruction for Claude to audit your existing codebase.
------------------------------
## 📋 Technical Summary for Claude AI: Regula Flutter Integration (ID vs. Passport Routing)## 1. Current Project Issues & Audit Request

* Scanning Problem: The Regula Document Reader SDK currently only captures/scans the front side of the Egyptian National ID. It needs to dynamically handle a double-sided workflow.
* Arabic OCR Corruption: Arabic visual text from the front layer of the Egyptian ID renders as garbled symbols or disconnected characters.
* Incorrect Latin Transliteration: The SDK converts Arabic characters into incorrect or confusing Latin strings during extraction.
* Database Dependency: The application relies on downloading the Regula document template database online at runtime. It needs to be converted into an offline, local asset embedded directly inside the Flutter bundle.
* 🤖 CODE AUDIT REQUIRED: Review my current Flutter implementation to check if I have correctly separated the document workflows between Egyptian Citizens (National ID) and Foreigners/Residents (Passports), or if I forgot to build this logic.

## 2. Workflow Routing & Document Specifications
Your Flutter app must implement two distinct workflows depending on the user's nationality:

* Workflow A: Egyptian Citizens (National ID)
* Requirement: Double-Sided Scan Required. The layout of the Egyptian National ID splits biographical data. The front contains the actual Arabic name, photo, and 14-digit National ID number. The back contains the profession, marital status, religion, and the Machine-Readable Zone (MRZ). Both sides are mandatory to construct a complete profile.
   * Barcode Limitation: The barcode/PDF417 on the back only duplicates the MRZ data (standardized Latin transliteration). It does not contain full native Arabic text or complete home addresses.
   * Text Processing Conflict: Arabic uses a Right-to-Left (RTL) script, while numbers (like the 14-digit National ID) run Left-to-Right (LTR). The SDK engine requires specific Multilingual/Bi-directional (BiDi) properties activated to avoid text character scrambling.
* Workflow B: Residents & Foreigners (Passports)
* Requirement: Single-Sided Scan Only (Front/Data Page). The SDK only needs to process the main bio-data page containing the MRZ text blocks. It should complete the scanning session immediately after this single capture without prompting for a card flip.

## 3. Project Architecture & Requirements

* Framework: Flutter (Cross-platform iOS & Android).
* Dual SDK Workflow: The app uses both the Regula Document Reader SDK (for identity documents) and the Regula Face SDK (for facial matching and liveness checks).
* Selected Database: FullLiveness (Version 320065, ~84 MB). This package provides offline text-extraction templates while enabling document-side liveness checks to compliment the Face SDK workflow.

## 4. Required Flutter SDK Configurations
To resolve text extraction, routing, and multi-page scanning, implement the following configurations:

* Workflow Scenario: Change the scanning configuration scenario property to Regula.DocReaderScenario.fullProcess. Do not use barcode-only processing scenarios.
* Dynamic Page Processing Setup:
* For Passports, configure the capture session parameters or document type filters to complete on a single page.
   * For Egyptian IDs, enable multi-page/double-sided scanning properties so the SDK blocks completion after the front scan and explicitly prompts the user to flip the card to scan the back layer.
* Field Extraction Routing:
* To get true, proper Arabic script text from the Egyptian ID, fetch the Regula.ResultType.lexicalAnalysis or look for the field tagged ft_Name_Local in the parsed JSON output.
   * The ft_Name_Id field outputs the Latin translit code (e.g., MXHMWD EBDAL RXHYM). Do not rely on ft_Name_Id for localized client registration.

------------------------------
## 💾 Offline Database (FullLiveness) Installation Guide for Flutter
To skip the runtime internet download requirement, you must host and read the binary database (db.dat) locally within your Flutter assets tree.
## Step A: Preparation

   1. Download the FullLiveness database from the Regula portal.
   2. Rename the downloaded file to exactly db.dat.

## Step B: Project File Structure
Place the file into your Flutter assets folder. A clean layout looks like this:

my_kyc_app/
├── assets/
│   └── regula/
│       └── db.dat          <-- Place the 84 MB db.dat file here
├── pubspec.yaml

## Step C: Pubspec.yaml Declaration
Register the folder directory path explicitly inside your pubspec.yaml file so Flutter bundles it into the build output:

flutter:
  assets:
    - assets/regula/

## Step D: Flutter Initialization Code Pattern
Before starting the camera UI, initialize the Document Reader using the bundled local asset database to prevent any network download triggers:

// 1. Get the binary database byte data from Flutter assets
ByteData bytes = await rootBundle.load('assets/regula/db.dat');
Uint8List dbBytes = bytes.buffer.asUint8List();
// 2. Initialize the Regula Document Reader with the local database bytesvar initResult = await Regula.DocumentReader.initializeReader({
    "license": myRegulaLicenseString,
    "database": dbBytes // Passes the db offline to the native iOS/Android sides
});

------------------------------



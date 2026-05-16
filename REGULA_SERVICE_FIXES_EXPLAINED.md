# RegulaService Critical Errors - Simple Explanations & Solutions

## Overview
There were **6 major critical errors** in the `regula_service.dart` file. Below I explain each one simply and show the solution.

---

## ❌ ERROR 1: Wrong Type in prepareDatabase Callback
**Lines: 27-28**

### What Was Wrong?
```dart
// ❌ WRONG - Original Error
(progress) {
  AppLogger.info('DB download: ${(progress * 100).toInt()}%');  // ERROR: Can't multiply PrepareProgress
  onProgress?.call(progress);  // ERROR: Can't pass PrepareProgress when double expected
}
```

### Why It Failed?
- The callback receives a `PrepareProgress` object (not a simple number)
- You can't multiply an object: `progress * 100` doesn't work
- The `onProgress` function expects a `double`, not `PrepareProgress`

### ✅ Solution:
```dart
// ✅ CORRECT - Extract the percentage from the object
(PrepareProgress progress) {
  final fraction = progress.totalBytesCount > 0
      ? progress.bytesLoaded / progress.totalBytesCount
      : 0.0;
  AppLogger.info('DB: ${(fraction * 100).toInt()}%');
  onProgress?.call(fraction.toDouble());
}
```

**What changed:**
- Extract the actual percentage: `bytesLoaded / totalBytesCount`
- Pass the `fraction` (a `double`) to the callback
- Now the math works! 📊

---

## ❌ ERROR 2: Wrong Constant Names for FieldType
**Lines: 175, 197, 205, 207**

### What Was Wrong?
```dart
// ❌ WRONG - These constants DON'T EXIST
FieldType.MRZ_SURNAME_AND_GIVEN_NAMES,  // Line 175 - Doesn't exist!
FieldType.ISSUING_AUTHORITY,             // Line 197 - Doesn't exist!
FieldType.MRZ_STRINGS_WITH_CORRECT_CHECKDIGITS,  // Line 205 - Doesn't exist!
FieldType.MRZ_LINES,                     // Line 207 - Doesn't exist!
```

### Why It Failed?
- These constant names are **incorrect** for the Regula API version you're using
- The library doesn't have these exact names

### ✅ Solution:
```dart
// ✅ CORRECT - Use the right constant names
FieldType.SURNAME_AND_GIVEN_NAMES,  // (Not MRZ_SURNAME_AND_GIVEN_NAMES)

// For ISSUING_AUTHORITY, MRZ lines - iterate through results instead:
String? issuingAuthority;
String? mrzLine1;
String? mrzLine2;

if (results.textResult != null) {
  for (var field in results.textResult!.fields) {
    for (var value in field.values) {
      final v = value.value;
      if (v == null) continue;
      final name = field.fieldName?.toLowerCase() ?? '';
      
      // Search by field name instead of constant
      if (name.contains('issuing authority')) {
        issuingAuthority = v;
      }
      if (name.contains('mrz line 1')) {
        mrzLine1 = v;
      }
      if (name.contains('mrz line 2')) {
        mrzLine2 = v;
      }
    }
  }
}
```

**What changed:**
- Removed `MRZ_` prefix from incorrect names
- For missing constants, **loop through all fields** and find them by name
- More flexible and compatible with different API versions 🔄

---

## ❌ ERROR 3: Wrong CheckResult Constants
**Lines: 231, 225-227, 230, 303**

### What Was Wrong?
```dart
// ❌ WRONG - These constants DON'T EXIST
final documentExpired = expiryStatus == CheckResult.WAS_READ_WITH_ERRORS;
final mrzValid = status?.detailsOptical?.mrz == CheckResult.OK;  // .OK doesn't exist!
final textValid = status?.detailsOptical?.text == CheckResult.OK;
final imageQualityOk = status?.detailsOptical?.imageQA == CheckResult.OK;

case CheckResult.WAS_READ_WITH_ERRORS:  // Doesn't exist!
```

### Why It Failed?
- `CheckResult.OK` is wrong (should be `.ok` - lowercase)
- `CheckResult.WAS_READ_WITH_ERRORS` doesn't exist
- The API uses different constant names

### ✅ Solution:
```dart
// ✅ CORRECT - Use the right constant names (lowercase)
final mrzValid = statusObj?.detailsOptical?.mrz == CheckResult.ok;  // lowercase!
final textValid = statusObj?.detailsOptical?.text == CheckResult.ok;
final imageQualityOk = statusObj?.detailsOptical?.imageQA == CheckResult.ok;

// For expiry check - use wasNotDone instead:
final expiryCheck = statusObj?.detailsOptical?.expiry;
final documentExpired = expiryCheck != null &&
    expiryCheck != CheckResult.ok &&
    expiryCheck != CheckResult.wasNotDone;
```

**What changed:**
- `.OK` → `.ok` (lowercase)
- `.WAS_READ_WITH_ERRORS` → `.wasNotDone` (correct constant)
- Simpler logic: if expiry is not `ok` and not `wasNotDone`, it's expired ✅

---

## ❌ ERROR 4: Wrong ResultType Constant
**Line: 237**

### What Was Wrong?
```dart
// ❌ WRONG - RAWIMAGE doesn't exist
ResultType.RAWIMAGE,
```

### Why It Failed?
- `ResultType.RAWIMAGE` is not a valid constant in the library
- This was likely the wrong constant name

### ✅ Solution:
```dart
// ✅ CORRECT - Don't use RAWIMAGE
// Instead, use graphicFieldImageByType() method directly
final portraitBytes = await results.graphicFieldImageByType(
  GraphicFieldType.PORTRAIT,
);
```

**What changed:**
- Removed the invalid `ResultType.RAWIMAGE` reference
- Used the correct method `graphicFieldImageByType()` directly 📸

---

## ❌ ERROR 5: Calling readAsBytesSync() on Uint8List
**Line: 245**

### What Was Wrong?
```dart
// ❌ WRONG - portrait is already Uint8List, not a File!
final bytes = portrait.readAsBytesSync();
```

### Why It Failed?
- `Uint8List` (a list of bytes) doesn't have `.readAsBytesSync()` method
- That method is only for `File` objects
- The portrait data is already in byte format!

### ✅ Solution:
```dart
// ✅ CORRECT - portraitBytes is already Uint8List
final portraitBytes = await results.graphicFieldImageByType(
  GraphicFieldType.PORTRAIT,
);
// Use it directly - no conversion needed!

return VerificationResultModel(
  portraitBytes: portraitBytes,  // Already bytes!
);
```

**What changed:**
- Removed `.readAsBytesSync()` call
- The bytes from the API are ready to use immediately ✅

---

## ❌ ERROR 6: Unnecessary Null-Aware Operators
**Lines: 224-227, 230**

### What Was Wrong?
```dart
// ❌ WRONG - status CAN be null, but these use unnecessary ?. operators
final mrzValid = status?.detailsOptical?.mrz == CheckResult.OK;  // ?. not needed here
final textValid = status?.detailsOptical?.text == CheckResult.OK;  // ?. not needed
```

### Why It Failed?
- The code checks `status?.overallStatus` but then assumes status isn't null
- Mixing null-safe (`?.`) and non-null-safe (`.`) is inconsistent
- The analyzer warns these operators are unnecessary

### ✅ Solution:
```dart
// ✅ CORRECT - Be consistent with null handling
final statusObj = results.status;  // Get it once

// Now use consistent null-safe access
final mrzValid = statusObj?.detailsOptical?.mrz == CheckResult.ok;  // ✅ Consistent
final textValid = statusObj?.detailsOptical?.text == CheckResult.ok;
final imageQualityOk = statusObj?.detailsOptical?.imageQA == CheckResult.ok;
final expiryCheck = statusObj?.detailsOptical?.expiry;  // ✅ Consistent
```

**What changed:**
- Store `status` in a variable first
- Use consistent null-safe operators (`?.`) throughout
- Clearer and more predictable code 🎯

---

## ❌ ERROR 7: Await on Void Return Methods
**Lines: 107, 149**

### What Was Wrong?
```dart
// ❌ WRONG - These methods return void, not Future!
await DocumentReader.instance.startScanner(config, (  // ERROR: Can't await void!

await DocumentReader.instance.recognize(config, (action, r, error) {  // ERROR: Can't await void!
```

### Why It Failed?
- `startScanner()` and `recognize()` are **callback-based** (not Futures)
- You can't `await` a void method
- These methods call your callback when done, they don't return a Future

### ✅ Solution:
```dart
// ✅ CORRECT - Wrap callback-based APIs in a Future using Completer
Future<Results?> startScanner({bool isPassport = false}) async {
  if (!_isInitialized) return null;
  if (!await _reader.isReady) return null;

  // Create a Completer to convert callback to Future
  final completer = Completer<Results?>();

  // NO await here - just call the void method
  _reader.startScanner(
    ScannerConfig.withScenario(Scenario.FULL_PROCESS),
    (DocReaderAction action, Results? results, DocReaderException? error) {
      if (error != null) {
        AppLogger.error('Scanner error: ${error.message}');
      }
      
      // When scan finishes, complete the future
      if (action.stopped()) {
        if (!completer.isCompleted) completer.complete(results);
      }
    },
  );

  // Return a Future that will complete when callback fires
  return completer.future;
}
```

**What changed:**
- Used `Completer<Results?>()` to wrap the callback-based API
- Called the void method WITHOUT `await`
- The `completer.complete()` inside the callback finishes the Future
- Now you can `await` this method! ⏳

---

## Summary: All 6 Errors Fixed ✅

| Error | Problem | Solution |
|-------|---------|----------|
| 1️⃣ PrepareProgress | Wrong type in callback | Extract `bytesLoaded / totalBytesCount` |
| 2️⃣ FieldType constants | Wrong constant names | Use correct names or iterate through fields |
| 3️⃣ CheckResult constants | `.OK` vs `.ok` | Use lowercase `.ok`, `.wasNotDone` |
| 4️⃣ ResultType.RAWIMAGE | Doesn't exist | Use `graphicFieldImageByType()` directly |
| 5️⃣ readAsBytesSync() | Can't call on Uint8List | Remove call - bytes already ready! |
| 6️⃣ Await on void | Can't await void return | Wrap in Completer to make it a Future |

---

## Now Your App Should Compile! 🎉

All errors in `regula_service.dart` are now fixed. The file is ready to use!

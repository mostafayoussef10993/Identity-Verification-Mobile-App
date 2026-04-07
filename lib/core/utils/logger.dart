// A simple logger so you can track what's happening without using raw print()

import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    if (kDebugMode) debugPrint('ℹ️ [INFO] $message');
  }

  static void success(String message) {
    if (kDebugMode) debugPrint('✅ [SUCCESS] $message');
  }

  static void warning(String message) {
    if (kDebugMode) debugPrint('⚠️ [WARNING] $message');
  }

  static void error(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR] $message${error != null ? ' → $error' : ''}');
    }
  }
}

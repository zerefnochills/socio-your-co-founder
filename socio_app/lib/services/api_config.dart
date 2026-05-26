// services/api_config.dart
// Socio — Unified API URL Configuration

import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Toggle this to `true` to switch the entire application to the live Render backend.
  static const bool useProduction = false;

  /// Deployed FastAPI production URL on Render.
  static const String _productionUrl = 'https://socio-backend.onrender.com';

  /// Local development server address.
  /// Works for Web, iOS Simulator, and physical Android devices using 'adb reverse tcp:8000 tcp:8000'.
  /// For Android emulator specifically, if 'adb reverse' is not used, it is 'http://10.0.2.2:8000'.
  static const String _localUrl = kIsWeb ? 'http://localhost:8000' : 'http://localhost:8000';

  /// Returns the active API base URL.
  static String get baseUrl => useProduction ? _productionUrl : _localUrl;
}

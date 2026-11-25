import 'package:flutter/material.dart';
import 'main_admin.dart';
import 'main_app.dart';

/// Strict build-time isolation:
/// - `--dart-define=ENTRY=app`   -> Standalone Halaa User App (zero admin UI/routes)
/// - `--dart-define=ENTRY=admin` -> Standalone Halaa Admin App (zero user-app UI)
const String kEntryMode = String.fromEnvironment('ENTRY', defaultValue: 'app');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kEntryMode == 'admin') {
    runApp(const HalaaAdminStandaloneApp());
  } else {
    runApp(const HalaaUserApp());
  }
}

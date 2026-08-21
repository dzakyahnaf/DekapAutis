import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Where this build points and how it was configured.
///
/// The Supabase URL and publishable key belong here and travel inside the APK
/// on purpose: the publishable key is designed to be public and is worthless
/// without RLS, which is default-deny in this project. That is a different
/// thing from the rule in CLAUDE.md §4 - the language model keys (Gemini,
/// Groq) never appear on the client at any point. They live only in Edge
/// Function secrets, and CI fails the branch if that pattern shows up in the
/// tree.
abstract final class AppConfig {
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Local `supabase start` defaults. The port block is 553xx rather than the
  /// usual 543xx because another Supabase project on this machine holds 543xx.
  static const _urlLokalHost = 'http://127.0.0.1:55321';

  /// The Android emulator reaches the host machine at 10.0.2.2, never at
  /// 127.0.0.1 - which on the emulator is the emulator itself.
  static const _urlLokalEmulator = 'http://10.0.2.2:55321';

  static const _keyLokal = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  /// True when no --dart-define was supplied, i.e. a developer build against
  /// the local stack. Release builds must always pass both.
  static bool get isLokal => _url.isEmpty || _key.isEmpty;

  static String get supabaseUrl {
    if (_url.isNotEmpty) return _url;
    if (kIsWeb) return _urlLokalHost;
    return Platform.isAndroid ? _urlLokalEmulator : _urlLokalHost;
  }

  static String get supabasePublishableKey => _key.isEmpty ? _keyLokal : _key;

  /// Deep link scheme registered in AndroidManifest.xml. Supabase hands control
  /// to an external browser for Google sign-in and comes back through this.
  static const skemaTautan = 'dekapautis';
  static const redirectMasuk = '$skemaTautan://masuk';
}

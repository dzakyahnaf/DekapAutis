/// How the local database is opened, chosen at compile time.
///
/// `database.dart` used to import `dart:io` and `package:drift/native.dart`
/// directly, which made the whole web build fail: those pull in `dart:ffi`, and
/// there is no FFI in a browser. CLAUDE.md lists Web as a target next to the
/// APK, so the import has to be conditional rather than the target dropped.
///
/// The two implementations are not equivalent, and deliberately so - see
/// `koneksi_web.dart` for why the browser gets no persistence.
library;

export 'koneksi_native.dart' if (dart.library.js_interop) 'koneksi_web.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session storage backed by the platform keystore, which degrades to memory
/// rather than taking the app down with it.
///
/// supabase_flutter defaults to SharedPreferences, which on Android is a plain
/// XML file readable by anything with the same uid and by anyone with a rooted
/// device. A persisted session is a bearer token for a child's records, so it
/// goes in the Android Keystore instead. PLAN.md F1 asks for
/// flutter_secure_storage specifically, and KNF-03 is the reason.
///
/// WHY THE FALLBACK EXISTS
/// -----------------------
/// The Keystore is not guaranteed. It refuses to decrypt after some OEM
/// backup-and-restore flows, on a few vendor ROMs, and whenever its key
/// material has been invalidated underneath us. Those calls then throw a
/// PlatformException - and because `Supabase.initialize` reads the session
/// while starting, that exception used to escape `main()` before `runApp` had
/// ever been reached. The result on the device is a white screen that cannot
/// be tapped: no error dialog, no way back, nothing to report.
///
/// Losing persistence means the person signs in again next time they open the
/// app. Losing the app entirely means they cannot use it at all. The first is
/// an inconvenience; the second is the product not working.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({this.kunci = 'dekapautis.sesi'});

  /// Key the session JSON is stored under.
  final String kunci;

  // Defaults in flutter_secure_storage 11 are already AES-GCM data encryption
  // with RSA-OAEP key wrapping held in the Android Keystore. The older
  // encryptedSharedPreferences flag is gone, and this is the stronger scheme it
  // was standing in for.
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  /// Holds the session for this run once the keystore has refused once.
  static String? _dalamMemori;

  /// Set on the first refusal. Every later call goes straight to memory rather
  /// than paying for another platform round trip that will fail the same way.
  static bool _keystoreMenolak = false;

  /// True when the session is being kept in memory only, so it will not
  /// survive closing the app. Read by the status strip.
  static bool get sesiTidakTersimpan => _keystoreMenolak;

  @visibleForTesting
  static void lupakanKegagalan() {
    _keystoreMenolak = false;
    _dalamMemori = null;
  }

  Future<T> _coba<T>(
    Future<T> Function() lewatKeystore,
    T Function() lewatMemori,
  ) async {
    if (_keystoreMenolak) return lewatMemori();
    try {
      return await lewatKeystore();
    } on Object catch (e) {
      // Any failure at all, not just PlatformException: a plugin that is
      // missing on this device throws MissingPluginException, and the outcome
      // for the person holding the phone is identical.
      debugPrint('Keystore tidak dapat dipakai, sesi disimpan di memori: $e');
      _keystoreMenolak = true;
      return lewatMemori();
    }
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() =>
      _coba(() => _storage.containsKey(key: kunci), () => _dalamMemori != null);

  @override
  Future<String?> accessToken() =>
      _coba(() => _storage.read(key: kunci), () => _dalamMemori);

  @override
  Future<void> removePersistedSession() => _coba(() async {
    await _storage.delete(key: kunci);
    _dalamMemori = null;
  }, () => _dalamMemori = null);

  @override
  Future<void> persistSession(String persistSessionString) => _coba(() async {
    await _storage.write(key: kunci, value: persistSessionString);
    _dalamMemori = persistSessionString;
  }, () => _dalamMemori = persistSessionString);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session storage backed by the platform keystore.
///
/// supabase_flutter defaults to SharedPreferences, which on Android is a plain
/// XML file readable by anything with the same uid and by anyone with a rooted
/// device. A persisted session is a bearer token for a child's records, so it
/// goes in the Android Keystore instead. PLAN.md F1 asks for
/// flutter_secure_storage specifically, and KNF-03 is the reason.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({this.kunci = 'dekapautis.sesi'});

  /// Key the session JSON is stored under.
  final String kunci;

  // Defaults in flutter_secure_storage 11 are already AES-GCM data encryption
  // with RSA-OAEP key wrapping held in the Android Keystore. The older
  // encryptedSharedPreferences flag is gone, and this is the stronger scheme it
  // was standing in for.
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: kunci);

  @override
  Future<String?> accessToken() => _storage.read(key: kunci);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: kunci);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: kunci, value: persistSessionString);
}

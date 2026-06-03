import 'native_bridge.dart';

class AuthStore {
  static const _tokenKey = 'token';
  static const _expiresAtKey = 'expires_at';

  static Future<String?> get token => NativeBridge.getString(_tokenKey);

  static Future<void> save(String token, String? expiresAt) async {
    await NativeBridge.setString(_tokenKey, token);
    if (expiresAt != null) {
      await NativeBridge.setString(_expiresAtKey, expiresAt);
    }
  }

  static Future<void> clear() async {
    await NativeBridge.remove(_tokenKey);
    await NativeBridge.remove(_expiresAtKey);
  }
}

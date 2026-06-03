import 'package:flutter/services.dart';

class NativeBridge {
  static const _channel = MethodChannel('wuthering_wares/native');

  static void setDeepLinkHandler(void Function(Uri uri) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'deepLink' && call.arguments is String) {
        handler(Uri.parse(call.arguments as String));
      }
    });
  }

  static Future<Uri?> initialLink() async {
    final value = await _channel.invokeMethod<String>('initialLink');
    if (value == null || value.isEmpty) return null;
    return Uri.parse(value);
  }

  static Future<bool?> openUrl(String url) =>
      _channel.invokeMethod<bool>('openUrl', url);
  static Future<String?> pickImage() =>
      _channel.invokeMethod<String>('pickImage');
  static Future<String?> getString(String key) =>
      _channel.invokeMethod<String>('getString', key);
  static Future<void> setString(String key, String value) =>
      _channel.invokeMethod<void>('setString', {'key': key, 'value': value});
  static Future<void> remove(String key) =>
      _channel.invokeMethod<void>('remove', key);
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveLocale(String locale) async {
    await _storage.write(key: 'locale', value: locale);
  }

  static Future<String?> getLocale() async {
    return await _storage.read(key: 'locale');
  }
}
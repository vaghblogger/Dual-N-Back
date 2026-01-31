import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> storeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> retrieveSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }
}

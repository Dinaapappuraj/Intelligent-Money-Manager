import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class EncryptionService {
  final _secureStorage = const FlutterSecureStorage();
  static const _secretKeyStorageIdentifier = 'app_secret_key';

  Future<String?> encryptData(String plainText) async {
    final key = await _getSecretKeyForEncryption();
    if (key == null) {
      debugPrint("Encryption failed: Secret key not found.");
      return null;
    }

    final iv = encrypt.IV.fromLength(16); // A new random IV for each encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    // Prepend the IV to the encrypted data for decryption
    return '${iv.base64}:${encrypted.base64}';
  }

  Future<String?> decryptData(String encryptedText) async {
    final key = await _getSecretKeyForEncryption();
    if (key == null) {
      debugPrint("Decryption failed: Secret key not found.");
      return null;
    }

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return null;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      debugPrint("Decryption failed: $e");
      return null;
    }
  }

  Future<encrypt.Key?> _getSecretKeyForEncryption() async {
    final secretKeyString = await getSecretKey();
    if (secretKeyString == null) return null;
    // Ensure the key is padded or truncated to 32 bytes for AES-256
    return encrypt.Key.fromUtf8(secretKeyString.padRight(32).substring(0, 32));
  }

  Future<String?> getSecretKey() async {
    return await _secureStorage.read(key: _secretKeyStorageIdentifier);
  }

  Future<bool> setSecretKey(String key) async {
    if (key.length != 32) {
      return false;
    }
    await _secureStorage.write(key: _secretKeyStorageIdentifier, value: key);
    return true;
  }
}


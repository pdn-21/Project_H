import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // สร้าง key จาก password (ใช้ในการเข้ารหัส config)
  static const String _secretKey = 'HospitalVisitManager2024Secret!';

  late encrypt.Key _key;
  late encrypt.IV _iv;

  void initialize() {
    // สร้าง 256-bit key จาก secret
    final keyBytes = sha256.convert(utf8.encode(_secretKey)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));

    // สร้าง IV
    final ivBytes =
        sha256.convert(utf8.encode(_secretKey.substring(0, 16))).bytes;
    _iv = encrypt.IV(Uint8List.fromList(ivBytes.sublist(0, 16)));
  }

  /// เข้ารหัสข้อความ
  String encryptText(String plainText) {
    if (plainText.isEmpty) return '';

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final encrypted = encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      return '';
    }
  }

  /// ถอดรหัสข้อความ
  String decryptText(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_key));
      final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      return '';
    }
  }

  /// เข้ารหัส JSON object
  String encryptJson(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      print('🔐 Encrypting JSON (${jsonString.length} chars)');

      final encrypted = encryptText(jsonString);

      if (encrypted.isEmpty) {
        print('❌ Encryption returned empty string');
      } else {
        print('✅ Encryption successful (${encrypted.length} chars)');
      }

      return encrypted;
    } catch (e) {
      print('❌ JSON encryption error: $e');
      return '';
    }
  }

  /// ถอดรหัส JSON object
  Map<String, dynamic> decryptJson(String encryptedData) {
    try {
      print('🔓 Decrypting JSON (${encryptedData.length} chars)');

      final decryptedString = decryptText(encryptedData);

      if (decryptedString.isEmpty) {
        print('❌ Decryption returned empty string');
        return {};
      }

      print('✅ Decryption successful (${decryptedString.length} chars)');

      final decoded = json.decode(decryptedString);
      print('✅ JSON parsing successful');

      return decoded;
    } catch (e) {
      print('❌ JSON decryption error: $e');
      return {};
    }
  }
}

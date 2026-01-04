import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // * Create key from password (encrypt config)
  static const String _secretKey = '';

  late encrypt.Key _key;
  late encrypt.IV _iv;

  void initialize() {
    // * Create 256-bit key from secret
    final keyBytes = sha256.convert(utf8.encode(_secretKey)).bytes;
    _key = encrypt.Key(Uint8List.fromList(keyBytes));

    // * Create IV
    final ivBytes =
        sha256.convert(utf8.encode(_secretKey.substring(0, 16))).bytes;
    _iv = encrypt.IV(Uint8List.fromList(ivBytes.sublist(0, 16)));
  }

  // * encode text
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

  // * decode text
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

  // * encrypt JSON object
  String encryptJson(Map<String, dynamic> data) {
    final jsonString = json.encode(data);
    return encryptText(jsonString);
  }

  // * decrypt JSON object
  Map<String, dynamic> decryptJson(String encryptedData) {
    try {
      final decryptedString = decryptText(encryptedData);
      if (decryptedString.isEmpty) return {};
      return json.decode(decryptedString);
    } catch (e) {
      print('JSON decryption error: $e');
      return {};
    }
  }
}

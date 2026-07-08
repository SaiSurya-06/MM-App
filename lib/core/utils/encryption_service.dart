import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();

  static const int keyStretchingIterations = 5000;

  /// Derives a 32-byte key from password (PIN) and a salt using SHA-256 stretching.
  enc.Key deriveKey(String password, String salt) {
    List<int> keyBytes = utf8.encode(password + salt);
    for (int i = 0; i < keyStretchingIterations; i++) {
      keyBytes = sha256.convert(keyBytes).bytes;
    }
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypts a plaintext string using AES-256 (CBC mode) with derived key.
  /// Prepends a random 16-byte IV to the ciphertext.
  String encrypt(String plaintext, String password, String salt) {
    final key = deriveKey(password, salt);
    final iv = enc.IV.fromLength(16); // Generates random IV
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    
    // Combine IV bytes and ciphertext bytes
    final combinedBytes = Uint8List(iv.bytes.length + encrypted.bytes.length);
    combinedBytes.setRange(0, iv.bytes.length, iv.bytes);
    combinedBytes.setRange(iv.bytes.length, combinedBytes.length, encrypted.bytes);
    
    return base64Url.encode(combinedBytes);
  }

  /// Decrypts a base64url-encoded ciphertext using AES-256 (CBC mode) with derived key.
  String decrypt(String ciphertextBase64, String password, String salt) {
    try {
      final combinedBytes = base64Url.decode(ciphertextBase64.trim());
      if (combinedBytes.length < 16) {
        throw Exception('Ciphertext too short');
      }
      
      final key = deriveKey(password, salt);
      
      // Extract IV and encrypted bytes
      final ivBytes = combinedBytes.sublist(0, 16);
      final encryptedBytes = combinedBytes.sublist(16);
      
      final iv = enc.IV(ivBytes);
      final encrypted = enc.Encrypted(encryptedBytes);
      
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Decryption failed: check password/PIN. $e');
    }
  }
}

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pbkdf2/pbkdf2.dart';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._internal();
  EncryptionService._internal();
  
  static const int pbkdf2Iterations = 100000;
  static const int saltLength = 32;
  
  /// Generates a cryptographically secure random salt
  String generateSalt() {
    final random = Random.secure();
    final saltBytes = Uint8List(saltLength);
    for (int i = 0; i < saltLength; i++) {
      saltBytes[i] = random.nextInt(256);
    }
    return base64Url.encode(saltBytes);
  }
  
  /// Derives a 32-byte key from password (PIN) and salt using PBKDF2-HMAC-SHA256.
  enc.Key deriveKey(String password, String salt) {
    final saltBytes = base64Url.decode(salt);
    final hmac = Hmac(sha256, saltBytes);
    final keyBytes = pbkdf2(
      hmac,
      utf8.encode(password),
      pbkdf2Iterations,
      32,
    );
    return enc.Key(Uint8List.fromList(keyBytes));
  }

  /// Encrypts a plaintext string using AES-256 (CBC mode) with derived key.
  /// Prepends a random 16-byte IV to the ciphertext.
  String encrypt(String plaintext, String password, String salt) {
    final key = deriveKey(password, salt);
    final iv = enc.IV.fromLength(16); // Generates random IV
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    
    final payload = 'MM_ENC:$plaintext';
    final encrypted = encrypter.encrypt(payload, iv: iv);
    
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
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      
      if (!decrypted.startsWith('MM_ENC:')) {
        throw Exception('Invalid magic header');
      }
      
      return decrypted.substring(7);
    } catch (e) {
      throw Exception('Decryption failed: check password/PIN. $e');
    }
  }
}

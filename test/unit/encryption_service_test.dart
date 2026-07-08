import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/utils/encryption_service.dart';

void main() {
  group('EncryptionService Tests', () {
    final encryptionService = EncryptionService.instance;
    const password = '1234';
    const salt = 'random_test_salt';

    test('Key derivation is consistent and deterministic', () {
      final key1 = encryptionService.deriveKey(password, salt);
      final key2 = encryptionService.deriveKey(password, salt);
      
      expect(key1.bytes, equals(key2.bytes));
      expect(key1.bytes.length, 32); // 256 bits
    });

    test('Encryption and Decryption roundtrip succeeds', () {
      const plaintext = 'Secret database content or private ledger details';
      final encrypted = encryptionService.encrypt(plaintext, password, salt);
      
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plaintext)));

      final decrypted = encryptionService.decrypt(encrypted, password, salt);
      expect(decrypted, equals(plaintext));
    });

    test('Decryption with wrong password/PIN fails with Exception', () {
      const plaintext = 'Highly confidential transaction notes';
      final encrypted = encryptionService.encrypt(plaintext, password, salt);

      expect(
        () => encryptionService.decrypt(encrypted, 'wrong_pin', salt),
        throwsA(isA<Exception>()),
      );
    });

    test('Decryption with wrong salt fails with Exception', () {
      const plaintext = 'Another secret message';
      final encrypted = encryptionService.encrypt(plaintext, password, salt);

      expect(
        () => encryptionService.decrypt(encrypted, password, 'different_salt'),
        throwsA(isA<Exception>()),
      );
    });
  });
}

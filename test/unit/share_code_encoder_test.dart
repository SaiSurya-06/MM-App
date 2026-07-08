import 'package:flutter_test/flutter_test.dart';
import 'package:money_manager/core/utils/share_code_encoder.dart';

void main() {
  group('ShareCodeEncoder Tests', () {
    test('Encode and Decode roundtrip (starts with H)', () {
      final payload = {
        'url': 'https://script.google.com/macros/s/123/exec',
        'room': 'ROOM12',
        'slot': 'A',
        'password': 'secret_password_123',
        'salt': 'salt_value_456',
      };

      final encoded = ShareCodeEncoder.encode(payload);
      // Gzipped payloads always start with ID1=0x1f, which base64Url encodes to starting with 'H'
      expect(encoded.startsWith('H'), isTrue);

      final decoded = ShareCodeEncoder.decode(encoded);
      expect(decoded['url'], equals('https://script.google.com/macros/s/123/exec'));
      expect(decoded['room'], equals('ROOM12'));
      expect(decoded['slot'], equals('A'));
      expect(decoded['password'], equals('secret_password_123'));
      expect(decoded['salt'], equals('salt_value_456'));
    });

    test('Decode unpadded base64Url string', () {
      final payload = {
        'test': 'unpadded_base64url_decoding_test_data',
      };
      final encoded = ShareCodeEncoder.encode(payload);
      // Strip padding
      final unpadded = encoded.replaceAll('=', '');
      
      final decoded = ShareCodeEncoder.decode(unpadded);
      expect(decoded['test'], equals('unpadded_base64url_decoding_test_data'));
    });

    test('Decode empty code throws FormatException', () {
      expect(() => ShareCodeEncoder.decode(''), throwsFormatException);
      expect(() => ShareCodeEncoder.decode('   \n  '), throwsFormatException);
    });

    test('Decode HTML payload throws FormatException', () {
      expect(() => ShareCodeEncoder.decode('<!doctype html><html><body>Error</body></html>'), throwsFormatException);
      expect(() => ShareCodeEncoder.decode('<script>alert("hello");</script>'), throwsFormatException);
      expect(() => ShareCodeEncoder.decode('<html>some content'), throwsFormatException);
    });

    test('Decode invalid base64url characters throws FormatException', () {
      // '+' and '/' are valid base64 but invalid base64url (which uses '-' and '_')
      expect(() => ShareCodeEncoder.decode('H4sIAAAAAAAA/w=='), throwsFormatException);
      expect(() => ShareCodeEncoder.decode('H4sIAAAAAAAA+w=='), throwsFormatException);
      expect(() => ShareCodeEncoder.decode('H4sIAAAAAAAA!w=='), throwsFormatException);
    });

    test('Decode non-gzip payload (missing H4 signature) throws FormatException', () {
      expect(() => ShareCodeEncoder.decode('AABBCC'), throwsFormatException);
    });

    test('Decode strips whitespaces and newlines correctly', () {
      final payload = {
        'url': 'https://script.google.com/macros/s/123/exec',
        'room': 'ROOM12',
        'slot': 'A',
        'password': 'secret_password_123',
        'salt': 'salt_value_456',
      };

      final encoded = ShareCodeEncoder.encode(payload);
      // Introduce whitespace and newlines inside the encoded code
      final dirtyEncoded = '\n  ${encoded.substring(0, 5)} \n ${encoded.substring(5)}\n';
      
      final decoded = ShareCodeEncoder.decode(dirtyEncoded);
      expect(decoded['url'], equals('https://script.google.com/macros/s/123/exec'));
    });
  });
}

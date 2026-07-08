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
  });
}

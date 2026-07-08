import 'dart:convert';
import 'dart:io';

class ShareCodeEncoder {
  /// Encodes a map payload into a compact Gzipped Base64Url string.
  static String encode(Map<String, dynamic> payload) {
    try {
      final jsonString = jsonEncode(payload);
      final bytes = utf8.encode(jsonString);
      final compressedBytes = gzip.encode(bytes);
      return base64Url.encode(compressedBytes);
    } catch (e) {
      throw Exception('Failed to generate sharing code: $e');
    }
  }

  /// Decodes a Gzipped Base64Url string back into a map payload.
  static Map<String, dynamic> decode(String code) {
    try {
      final cleanCode = code.trim();
      final normalizedCode = base64Url.normalize(cleanCode);
      final compressedBytes = base64Url.decode(normalizedCode);
      final decompressedBytes = gzip.decode(compressedBytes);
      final jsonString = utf8.decode(decompressedBytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid or corrupted sharing code: $e');
    }
  }
}

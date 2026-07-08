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
    final cleanCode = code.replaceAll(RegExp(r'\s+'), '');
    if (cleanCode.isEmpty) {
      throw const FormatException('Sharing code is empty.');
    }

    final lowerCode = cleanCode.toLowerCase();
    if (cleanCode.startsWith('<') ||
        lowerCode.startsWith('<!doctype html') ||
        lowerCode.contains('<html') ||
        lowerCode.contains('<head') ||
        lowerCode.contains('<body') ||
        lowerCode.contains('<script')) {
      throw const FormatException('HTML response detected instead of valid share code payload.');
    }

    final base64UrlRegex = RegExp(r'^[A-Za-z0-9\-_=]+$');
    if (!base64UrlRegex.hasMatch(cleanCode)) {
      throw const FormatException('Invalid characters detected in sharing code. Only base64url characters are allowed.');
    }

    if (!cleanCode.startsWith('H4')) {
      throw const FormatException('Invalid sharing code: must start with GZIP magic header signature "H4".');
    }

    try {
      final normalizedCode = base64Url.normalize(cleanCode);
      final compressedBytes = base64Url.decode(normalizedCode);
      final decompressedBytes = gzip.decode(compressedBytes);
      final jsonString = utf8.decode(decompressedBytes);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw FormatException('Invalid Base64Url format or HTML response: ${e.message}');
    } catch (e) {
      throw FormatException('Invalid or corrupted sharing code: $e');
    }
  }
}

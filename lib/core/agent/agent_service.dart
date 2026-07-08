import 'package:flutter/services.dart';

class AgentService {
  static const MethodChannel _channel = MethodChannel('com.example.money_manager/agent');

  /// Sends a message to the native Android ADK agent and returns its response.
  static Future<String> sendMessage(String prompt) async {
    try {
      final String response = await _channel.invokeMethod('sendMessage', prompt);
      return response;
    } on PlatformException catch (e) {
      return 'Error from agent: ${e.message}';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }
}

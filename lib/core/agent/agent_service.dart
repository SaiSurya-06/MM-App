class AgentService {
  static int? activeProfileId;
  static String? activeSessionId;

  /// Sends a message to the native Android ADK agent and returns its response.
  static Future<String> sendMessage(String prompt) async {
    throw UnsupportedError("Online AI is deprecated. Use RulePlanner for offline response generation.");
  }
}

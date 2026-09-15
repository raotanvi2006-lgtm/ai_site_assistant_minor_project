enum ChatRole { user, assistant }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final List<String> citedSources; // document titles cited
  final double? confidenceScore; // 0.0 - 1.0

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.citedSources = const [],
    this.confidenceScore,
  });

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
}

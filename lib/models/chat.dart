class ChatMessage {
  final String role;    // "system", "user", "assistant"
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'],
    content: json['content'],
  );
}

/// Chat 요청 전체 구조
class ChatRequest {
  final String model;               // ex: "gpt-3.5-turbo"
  final List<ChatMessage> messages;

  ChatRequest({this.model = "gpt-3.5-turbo", required this.messages});

  Map<String, dynamic> toJson() => {
    'model': model,
    'messages': messages.map((m) => m.toJson()).toList(),
  };
}

/// Chat 응답 내 choice 하나
class ChatChoice {
  final int index;
  final ChatMessage message;

  ChatChoice({required this.index, required this.message});

  factory ChatChoice.fromJson(Map<String, dynamic> json) => ChatChoice(
    index: json['index'],
    message: ChatMessage.fromJson(json['message']),
  );
}

/// Chat 응답 전체 구조
class ChatResponse {
  final String id;
  final List<ChatChoice> choices;

  ChatResponse({required this.id, required this.choices});

  factory ChatResponse.fromJson(Map<String, dynamic> json) => ChatResponse(
    id: json['id'],
    choices: (json['choices'] as List)
        .map((c) => ChatChoice.fromJson(c))
        .toList(),
  );
}

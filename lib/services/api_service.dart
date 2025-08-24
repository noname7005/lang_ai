// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';
import '../models/chat.dart';

class ApiService {
  // Open AI 공용
  static const String apiKey  = String.fromEnvironment('OPENAI_API_KEY') ?? '';
  final uri     = Uri.parse('https://api.openai.com/v1/chat/completions');
  // 백엔드 서버 주소
  static const String _baseUrl = 'http://10.0.2.2:3000';


  // AI 예문 생성 (OpenAI GPT 호출)
  Future<List<String>> generateExamplesWithAI(String word) async {
    final messages = [
      ChatMessage(
          role: 'system',
          content: '너는 영어 교사야. 주어진 단어를 사용하여 3개의 간결한 예문을 생성해줘.'
      ),
      ChatMessage(
          role: 'user',
          content: '3개의 예제 문장을 만들어줘. : "$word". 문장만 새 줄에 반환하도록해.'
      ),
    ];

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(ChatRequest(messages: messages).toJson()),
    );

    if (res.statusCode != 200) {
      throw Exception('OpenAI API Error ${res.statusCode}: ${res.body}');
    }

    final chatResp = ChatResponse.fromJson(jsonDecode(res.body));
    final text     = chatResp.choices.first.message.content.trim();

    return text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .take(3)
        .toList();
  }

  // AI 대화
  Future<String> sendMessage(String message) async {
    const endpoint = "https://api.openai.com/v1/chat/completions";

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $apiKey",
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": message}
        ],
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final content = decoded["choices"][0]["message"]["content"];
      return content.trim();
    } else {
      throw Exception("Failed to fetch ChatGPT response: ${response.body}");
    }
  }
}

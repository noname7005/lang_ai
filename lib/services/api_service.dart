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

  // 단어 목록 조회
  Future<List<Word>> fetchWords() async {
    final uri = Uri.parse('$_baseUrl/words');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => Word.fromJson(e)).toList();
    } else {
      throw Exception('단어 목록 조회 실패: ${response.statusCode}');
    }
  }

  // 단어 추가
  Future<Word> addWord(Word word) async {
    final uri = Uri.parse('$_baseUrl/words');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(word.toJson()),
    );

    if (response.statusCode == 201) {
      return Word.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('단어 추가 실패: ${response.statusCode}');
    }
  }

  // 단어 수정
  Future<Word> updateWord(Word word) async {
    final uri = Uri.parse('$_baseUrl/words/${word.id}');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(word.toJson()),
    );

    if (response.statusCode == 200) {
      return Word.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('단어 수정 실패: ${response.statusCode}');
    }
  }

  // 단어 삭제
  Future<void> deleteWord(int id) async {
    final uri = Uri.parse('$_baseUrl/words/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception('단어 삭제 실패: ${response.statusCode}');
    }
  }

  // 즐겨찾기 토글
  Future<Word> toggleFavorite(Word word) async {
    word.favorite = !word.favorite;
    return updateWord(word);
  }

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

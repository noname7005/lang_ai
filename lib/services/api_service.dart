// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word.dart';
import '../models/chat.dart';

class DialogueTurn {
  final String speaker; // 'A' or 'B'
  final String text;
  DialogueTurn({required this.speaker, required this.text});

  factory DialogueTurn.fromJson(Map<String, dynamic> j) =>
      DialogueTurn(speaker: j['speaker'] as String, text: j['text'] as String);
}

class LineEdit {
  final int index;       // 몇 번째 줄인지(0-based)
  final String original; // 원문(영어)
  final String suggested;// 교정문(영어)
  final String reasonKo; // 이유/설명(한국어)

  const LineEdit({
    required this.index,
    required this.original,
    required this.suggested,
    required this.reasonKo,
  });

  factory LineEdit.fromJson(Map<String, dynamic> j) => LineEdit(
    index: (j['index'] as num).toInt(),
    original: (j['original'] ?? '').toString().trim(),
    suggested: (j['suggested'] ?? '').toString().trim(),
    // 서버에서 reason_ko 또는 reasonKo 둘 중 하나로 올 수 있음
    reasonKo: (j['reason_ko'] ?? j['reasonKo'] ?? '').toString().trim(),
  );

  Map<String, dynamic> toJson() => {
    'index': index,
    'original': original,
    'suggested': suggested,
    'reason_ko': reasonKo,
  };
}


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

  /// 영어 회화 스크립트 생성
  Future<List<DialogueTurn>> generateScript({
    required String topic,
    required String situation,
    int turns = 6,              // 총 발화 수(짝수 권장)
    String level = 'A2',        // CEFR 레벨 힌트
    double temperature = 0.7,
  }) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    // 모델에게 "JSON으로만" 내놓게 강하게 유도
    final system = '''
You are an English conversation script generator.
Return ONLY valid JSON following this schema exactly:

{
  "script": [
    {"speaker":"A","text":"..."},
    {"speaker":"B","text":"..."}
  ]
}

Rules:
- Exactly $turns turns, alternating speakers A and B.
- Topic: "$topic"
- Situation: "$situation"
- Level (CEFR hint): $level (keep vocabulary/simple grammar appropriate)
- 1 sentence per turn; natural, concise; no extra explanations.
- Output JSON only, no markdown fences, no extra keys.
''';

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": "Generate the script JSON now."}
        ],
        "temperature": temperature,
        "stream": false,
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final choices = root['choices'] as List?;
      final content = (choices?[0]?['message']?['content'] ?? '') as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final script = (parsed['script'] as List)
          .map((e) => DialogueTurn.fromJson(e as Map<String, dynamic>))
          .toList();
      return script;
    } catch (_) {
      // 2) 모델이 텍스트를 뱉은 경우 대비(라인 파싱 fallback)
      // 예상 포맷: A: Hello ... / B: ...
      final lines = body.split('\n');
      final List<DialogueTurn> script = [];
      for (final line in lines) {
        final m = RegExp(r'^\s*([AB])\s*[:\-]\s*(.+)$').firstMatch(line);
        if (m != null) {
          script.add(DialogueTurn(speaker: m.group(1)!, text: m.group(2)!.trim()));
        }
      }
      if (script.isEmpty) {
        // 그래도 못 파싱하면 통째로 하나의 턴으로 묶어서 보여주기
        return [DialogueTurn(speaker: 'A', text: body.trim())];
      }
      return script;
    }
  }

  // ApiService 내
  Future<List<String>> generateExamplesWithAI(String term) async {
    const endpoint = "https://api.openai.com/v1/chat/completions";
    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {
            "role": "system",
            "content": """
You are an English teacher. Return ONLY valid JSON:
{"examples":["...","...","..."]}
Rules: 3 short, natural example sentences using the user's term. No markdown fences, no extra keys.
"""
          },
          {"role": "user", "content": term}
        ],
        "temperature": 0.7
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}: $body");
    }

    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final content = (root['choices'][0]['message']['content'] as String);
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final list = (parsed['examples'] as List).cast<String>();
      return list.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } catch (_) {
      // 모델이 JSON 대신 텍스트로 준 경우 라인 파싱 fallback
      return body
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => l.replaceFirst(RegExp(r'^\s*(?:[-*•]|\d+\.)\s*'), ''))
          .toList();
    }
  }

  // AI 대화
  Future<String> sendMessage(
      String message, {
        String? topicPrompt,      // ⬅️ 추가: 주제 프롬프트
        double temperature = 0.7,
      }) async
  {
    const endpoint = "https://api.openai.com/v1/chat/completions";

    final messages = <Map<String, String>>[];
    if (topicPrompt != null && topicPrompt.isNotEmpty) {
      messages.add({
        "role": "system",
        "content": """
You are an English conversation partner. 
Topic: $topicPrompt
Keep replies concise (1-2 sentences), natural, and ask a short follow-up question.
Only respond in English.
"""
      });
    } else {
      messages.add({
        "role": "system",
        "content":
        "You are an English conversation partner. Keep replies concise (1-2 sentences) and ask a short follow-up question. Only respond in English."
      });
    }
    messages.add({"role": "user", "content": message});

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": messages,
        "temperature": temperature,
        "stream": false,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final content = decoded["choices"][0]["message"]["content"];
      return (content as String).trim();
    } else {
      throw Exception("Failed: ${utf8.decode(response.bodyBytes)}");
    }
  }

  Future<String> getConversationFeedback({
    required String content,           // 저장된 .txt 또는 .json 원문
    required String mode,              // 'overall' | 'lineEdits' | 'rewrite'
    String levelHint = 'B1',
    double temperature = 0.3,
  }) async
  {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    // ✅ 한글 설명 강제 + 모드별 형식 규정
    final system = '''
You are an expert ESL tutor for Korean learners (Korean L1).
All meta/explanatory text MUST be written in KOREAN.
Keep the actual English examples/rewrites in ENGLISH.
Write in Markdown (no code fences).

Modes:
- overall:
  - 한국어로 핵심 요약 2~3문장.
  - "주요 문제" 섹션(3~6개). 각 항목마다: 한국어 설명 + 짧은 영어 예문 1~2개 + 자연스러운 대체 표현 2~3개(영어).
- lineEdits:
  - 각 사용자 발화(가능하면 User 라인 위주)를 다음 포맷으로 나열:
    - Original: <영어 원문>
    - Suggested: <영어 수정문>
    - 이유: <한국어 한 줄 설명>
  - 항목 사이에 빈 줄.
- rewrite:
  - 대화 전체를 자연스럽게 "영어"로 재작성.
  - 마지막에 "메모" 섹션을 한국어로 3~5개 bullet로 요약 팁 제시.

General rules:
- CEFR hint: $levelHint (어휘/문법 난이도 참고)
- 과도한 장문 피하기(핵심 위주, 실용적).
- 추측으로 내용 추가 금지(원문에 근거).
''';

    final user = '''
Mode: $mode

Transcript:
$content
''';

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": temperature,
        "stream": false,
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    final root = jsonDecode(body) as Map<String, dynamic>;
    final txt = (root['choices']?[0]?['message']?['content'] ?? '') as String;
    return txt.trim();
  }

  /// 한 줄(사용자 발화)에 대한 교정 + 한국어 이유를 반환
  Future<LineEdit> getLineEditForLine({
    required int index,        // 몇 번째 줄인지 (0-based)
    required String original,  // 원문(영어)
    String? context,           // 앞뒤 컨텍스트(선택)
    String levelHint = 'B1',   // CEFR 힌트
    double temperature = 0.2,  // 피드백은 낮은 온도 권장
  }) async
  {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final system = '''
You are an ESL tutor for Korean learners (Korean L1).
Return ONLY valid JSON exactly like:
{"edit":{"index":<int>,"original":"...","suggested":"...","reason_ko":"..."}}

Rules:
- "suggested": improved ENGLISH sentence (one line).
- "reason_ko": short KOREAN explanation (1–2 lines).
- Keep meaning; fix grammar/word choice/tone.
- Consider given context if provided. CEFR hint: $levelHint.
- No markdown fences, no extra keys.
''';

    final user = '''
index: $index
original: $original
${(context == null || context.trim().isEmpty) ? '' : 'context:\n$context'}
''';

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey', // ApiService의 apiKey 사용
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user},
        ],
        "temperature": temperature,
        "stream": false,
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    try {
      // OpenAI 응답 → choices[0].message.content (문자열) → 그 안의 JSON 파싱
      final root = jsonDecode(body) as Map<String, dynamic>;
      final content = (root['choices']?[0]?['message']?['content'] ?? '') as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      return LineEdit.fromJson(parsed['edit'] as Map<String, dynamic>);
    } catch (_) {
      // ✅ fallback: 모델이 텍스트를 내놓았을 때 간이 파싱 시도
      // 예) "Original: ...\nSuggested: ...\n이유: ..."
      final text = body; // 디버깅용으로 원문 유지
      final orig = RegExp(r'Original\s*:\s*(.+)', caseSensitive: false)
          .firstMatch(text)
          ?.group(1)
          ?.trim();
      final sugg = RegExp(r'Suggested\s*:\s*(.+)', caseSensitive: false)
          .firstMatch(text)
          ?.group(1)
          ?.trim();
      final reason = RegExp(r'(?:이유|Reason|reason_ko)\s*:\s*(.+)')
          .firstMatch(text)
          ?.group(1)
          ?.trim();

      if (orig != null && sugg != null && reason != null) {
        return LineEdit(index: index, original: orig, suggested: sugg, reasonKo: reason);
      }

      // 그래도 실패하면 최소한 구조는 채워서 반환
      return LineEdit(
        index: index,
        original: original,
        suggested: original, // 변경 불가 시 원문 유지
        reasonKo: '파싱 실패: 모델 응답 형식이 JSON 규격과 다릅니다.',
      );
    }
  }

  /// 한글 입력을 바탕으로 자연스러운 영어 예문을 생성 (설명은 한국어)
  Future<List<Map<String, dynamic>>> getSentenceExamples({
    required String korean,
    int count = 5,
    String levelHint = 'B1',
    String tone = 'neutral', // neutral/polite/casual/formal
    double temperature = 0.4,
  }) async
  {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final system = '''
You are a bilingual English coach for Korean learners (Korean L1).
Return ONLY valid JSON like:
{"examples":[ {"en":"...","note_ko":"..."}, ... ]}

Rules:
- Given a Korean input, infer intent and produce $count natural ENGLISH sentences (field "en") that fit the intent, CEFR $levelHint, tone=$tone.
- Keep sentences concise and practical for conversation.
- Add a short KOREAN explanation for each in "note_ko" (why it's natural/when to use).
- No markdown fences, no extra keys.
''';

    final user = 'KR: $korean';

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": temperature,
        "stream": false,
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    // OpenAI 응답 파싱
    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final content = (root['choices']?[0]?['message']?['content'] ?? '') as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final list = (parsed['examples'] as List?) ?? const [];
      // 각 항목을 Map으로 보장
      return list.map<Map<String, dynamic>>((e) {
        if (e is Map<String, dynamic>) return e;
        return {"en": e.toString(), "note_ko": ""};
      }).toList();
    } catch (_) {
      // 모델이 규격을 안 지킨 경우: 라인 분리 폴백
      final lines = body.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      return lines.map((l) => {"en": l, "note_ko": ""}).toList();
    }
  }

  /// 영어 문장 문법 검사 + 추천(한국어 설명 포함)
  Future<Map<String, dynamic>> analyzeGrammar({
    required String english,
    int count = 5,                // 최대 이슈/추천 개수
    String levelHint = 'B1',
    String tone = 'neutral',      // rewrite 톤
    bool includeRewrite = true,
    double temperature = 0.25,
  }) async
  {
    const endpoint = 'https://api.openai.com/v1/chat/completions';

    final system = '''
You are an expert ESL writing tutor for Korean learners (Korean L1).
Return ONLY valid JSON like:
{
  "corrected": "quickly corrected version in ENGLISH (keep meaning)",
  "issues": [
    {"original":"...","suggested":"...","reason_ko":"...","alternatives":["...","..."]}
  ],
  "rewrite": "polished rewrite in ENGLISH with tone=$tone"  // optional if includeRewrite=true
}

Rules:
- Analyze the given ENGLISH input.
- "corrected": small fixes (grammar/tense/prep) with minimal changes.
- "issues": up to $count items. For each:
  - original (snippet or sentence),
  - suggested (improved ENGLISH),
  - reason_ko (KOREAN explanation; 1–2 lines),
  - alternatives: 1–3 natural alternatives in ENGLISH (optional).
- If includeRewrite=$includeRewrite, add "rewrite": a more polished version in ENGLISH with tone=$tone.
- Consider CEFR level: $levelHint (avoid too advanced vocabulary if not needed).
- No markdown fences, no extra keys.
''';

    final user = 'INPUT:\n$english';

    final res = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": system},
          {"role": "user", "content": user}
        ],
        "temperature": temperature,
        "stream": false,
      }),
    );

    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: $body');
    }

    try {
      final root = jsonDecode(body) as Map<String, dynamic>;
      final content = (root['choices']?[0]?['message']?['content'] ?? '') as String;
      final parsed = jsonDecode(content) as Map<String, dynamic>;

      // 최소 필드 보정
      parsed['corrected'] = (parsed['corrected'] ?? '').toString();
      if (includeRewrite) {
        parsed['rewrite'] = (parsed['rewrite'] ?? '').toString();
      } else {
        parsed.remove('rewrite');
      }
      parsed['issues'] = (parsed['issues'] is List) ? parsed['issues'] : <dynamic>[];

      return parsed;
    } catch (_) {
      // 폴백: JSON 실패 시 텍스트 통째로 반환
      return {
        'corrected': '',
        'issues': const [],
        'rewrite': body,
      };
    }
  }
}

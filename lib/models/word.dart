import 'package:cloud_firestore/cloud_firestore.dart';

class Word {
  final String id;        // Firestore 문서 ID 또는 REST API id
  String term;            // 단어
  String meaning;         // 의미
  String topic;           // 주제
  bool favorite;          // 즐겨찾기 여부
  DateTime createdAt;     // 생성 시각
  DateTime updatedAt;     // 수정 시각
  String termNorm;        // 중복 체크용 (소문자+trim)

  Word({
    required this.id,
    required this.term,
    required this.meaning,
    this.topic = '',
    this.favorite = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? termNorm,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        termNorm = termNorm ?? normalize(term);

  /// 단어 정규화 (소문자 + trim)
  static String normalize(String input) {
    return input.trim().toLowerCase();
  }

  // ---------------- Firestore ----------------
  factory Word.fromMap(Map<String, dynamic> map, String documentId) {
    return Word(
      id: documentId,
      term: map['term'] ?? '',
      meaning: map['meaning'] ?? '',
      topic: map['topic'] ?? '',
      favorite: map['favorite'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      termNorm: map['termNorm'] ?? normalize(map['term'] ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'term': term,
      'meaning': meaning,
      'topic': topic,
      'favorite': favorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'termNorm': termNorm,
    };
  }

  // ---------------- REST API ----------------
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'].toString(), // int → String 변환
      term: json['term'] ?? '',
      meaning: json['meaning'] ?? '',
      topic: json['topic'] ?? '',
      favorite: json['favorite'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      termNorm: json['termNorm'] ?? normalize(json['term'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'term': term,
      'meaning': meaning,
      'topic': topic,
      'favorite': favorite,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'termNorm': termNorm,
    };
  }

  // ---------------- copyWith ----------------
  Word copyWith({
    String? term,
    String? meaning,
    String? topic,
    bool? favorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? termNorm,
  }) {
    return Word(
      id: id,
      term: term ?? this.term,
      meaning: meaning ?? this.meaning,
      topic: topic ?? this.topic,
      favorite: favorite ?? this.favorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      termNorm: termNorm ?? this.termNorm,
    );
  }
}

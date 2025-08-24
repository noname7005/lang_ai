import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/word.dart';

class WordRepository {
  final CollectionReference _wordCollection;

  WordRepository({required String userId})
      : _wordCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('words');

  /// Firestore 문서 id 생성기
  String generateId() {
    return _wordCollection
        .doc()
        .id;
  }

  /// 단어 추가 (중복 검사 포함)
  Future<void> addWord(Word word) async {
    final duplicate = await _wordCollection
        .where('termNorm', isEqualTo: Word.normalize(word.term))
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw Exception('이미 존재하는 단어입니다.');
    }

    await _wordCollection.doc(word.id).set(word.toMap());
  }

  /// 단어 업데이트
  Future<void> updateWord(Word word) async {
    await _wordCollection.doc(word.id).update({
      ...word.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 단어 삭제
  Future<void> deleteWord(String id) async {
    await _wordCollection.doc(id).delete();
  }

  /// 즐겨찾기 토글
  Future<void> toggleFavorite(Word word) async {
    await _wordCollection.doc(word.id).update({
      'favorite': !word.favorite,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// 단어 목록 스트리밍 (최신순 정렬, topic 필터 가능)
  Stream<List<Word>> streamWords({String? topic}) {
    Query query = _wordCollection.orderBy('createdAt', descending: true);

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    return query.snapshots().map(
          (snapshot) =>
          snapshot.docs
              .map((doc) =>
              Word.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList(),
    );
  }

  /// 중복 체크 (단어 존재 여부)
  Future<bool> checkDuplicate(String term) async {
    final snapshot = await _wordCollection
        .where('termNorm', isEqualTo: Word.normalize(term))
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// 퀴즈 오답
  Future<Word?> getWordById(String id) async {
    final doc = await _wordCollection.doc(id).get();
    if (!doc.exists) return null;
    return Word.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/services/word_repository.dart';
import 'package:lang_ai/services/api_service.dart'; // 👈 AI 서비스 import

class TopicWordListScreen extends StatefulWidget {
  final String topicKey;
  final int day;

  const TopicWordListScreen({
    super.key,
    required this.topicKey,
    required this.day,
  });

  @override
  State<TopicWordListScreen> createState() => _TopicWordListScreenState();
}

class _TopicWordListScreenState extends State<TopicWordListScreen> {
  List<Word> words = [];
  late WordRepository _wordRepo;
  final _api = ApiService(); // 👈 AI 서비스 준비

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인 필요");
    _wordRepo = WordRepository(userId: user.uid);
    _loadWords();
  }

  Future<void> _loadWords() async {
    final filePath =
        "assets/topics/${widget.topicKey.toLowerCase()}_day${widget.day}.json";

    try {
      final data = await rootBundle.loadString(filePath);
      final list = jsonDecode(data) as List;

      setState(() {
        words = list.map((e) {
          return Word(
            id: "${widget.topicKey}_day${widget.day}_${e['term']}",
            term: e['term'],
            meaning: e['meaning'],
            topic: "${widget.topicKey}_Day${widget.day}",
          );
        }).toList();
      });
    } catch (e) {
      debugPrint("파일 로드 실패: $e");
      setState(() => words = []);
    }
  }

  Future<void> _showExamples(Word w) async {
    try {
      final examples = await _api.generateExamplesWithAI(w.term);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('"${w.term}" 예문'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: examples.map((e) => Text("• $e")).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("예문 생성 실패: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      AppBar(title: Text("${widget.topicKey} - Day ${widget.day}")),
      body: words.isEmpty
          ? const Center(child: Text("단어 데이터를 불러올 수 없습니다."))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final w = words[i];
          return ListTile(
            title: Text(w.term, style: const TextStyle(fontSize: 18)),
            subtitle: Text(w.meaning),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.star_border),
                  onPressed: () async {
                    final newWord = Word(
                      id: _wordRepo.generateId(),
                      term: w.term,
                      meaning: w.meaning,
                      topic: w.topic,
                      favorite: true,
                    );
                    await _wordRepo.addWord(newWord);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("즐겨찾기에 추가됨")),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.auto_stories),
                  onPressed: () => _showExamples(w), // 예문 생성
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

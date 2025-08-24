import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/services/word_repository.dart';
import 'package:lang_ai/screens/word/quiz_mistakes_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late WordRepository _wordRepo;
  List<Word> _words = [];
  int _current = 0;
  int _correct = 0;
  int _wrong = 0;
  final _random = Random();

  // 정답/오답 추적용
  final List<String> _correctIds = [];
  final List<String> _mistakeIds = [];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인 필요");
    _wordRepo = WordRepository(userId: user.uid);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favs = await _wordRepo.streamWords().first;
    setState(() {
      _words = favs.where((w) => w.favorite).toList()..shuffle();
    });
  }

  void _answer(bool isCorrect) {
    final currentWord = _words[_current];
    setState(() {
      if (isCorrect) {
        _correct++;
        _correctIds.add(currentWord.id);
      } else {
        _wrong++;
        _mistakeIds.add(currentWord.id);
      }
      _current++;
    });
  }

  Future<void> _saveQuizResult() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("quiz_sessions")
        .doc(sessionId)
        .set({
      "createdAt": DateTime.now(),
      "source": "favorites",
      "correctCount": _correct,
      "wrongCount": _wrong,
      "mistakes": _mistakeIds, // 오답 단어 id 리스트
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_words.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("퀴즈")),
        body: const Center(child: Text("즐겨찾기된 단어가 없습니다.")),
      );
    }

    if (_current >= _words.length) {
      _saveQuizResult(); // quiz 결과 저장
      final rate = (_correct / _words.length * 100).toStringAsFixed(1);
      return Scaffold(
        appBar: AppBar(title: const Text("퀴즈 결과")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("정답: $_correct / ${_words.length}"),
              Text("오답: $_wrong"),
              Text("정답률: $rate%"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("돌아가기")
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MistakesScreen()),
                  );
                },
                child: const Text("오답노트 보기"),
              ),
            ],
          ),
        ),
      );
    }

    final word = _words[_current];
    final fakeMeaning = _words[_random.nextInt(_words.length)].meaning;
    final showCorrect = _random.nextBool();
    final displayedMeaning =
    showCorrect ? word.meaning : fakeMeaning; // 가짜 뜻 출제

    return Scaffold(
      appBar: AppBar(title: Text("문제 ${_current + 1}/${_words.length}")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(word.term,
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            Text(displayedMeaning, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _answer(showCorrect == true),
                  child: const Text("O"),
                ),
                ElevatedButton(
                  onPressed: () => _answer(showCorrect == false),
                  child: const Text("X"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
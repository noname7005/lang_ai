import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/services/word_repository.dart';

class WordEditScreen extends StatefulWidget {
  final Word? word;
  const WordEditScreen({super.key, this.word}); // super.key 권장

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  late TextEditingController _textController;
  late TextEditingController _meaningController;
  late WordRepository _wordRepo;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.word?.term ?? '');
    _meaningController = TextEditingController(text: widget.word?.meaning ?? '');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("로그인이 필요합니다.");
    }
    _wordRepo = WordRepository(userId: user.uid);
  }

  @override
  void dispose() {
    _textController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  Future<void> _saveWord() async {
    final term = _textController.text.trim();
    final meaning = _meaningController.text.trim();

    if (term.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('단어를 입력해주세요')),
      );
      return;
    }
    if (meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('뜻을 입력해주세요')),
      );
      return;
    }

    try {
      if (widget.word == null) {
        // 신규 추가
        final newWord = Word(
          id: _wordRepo.generateId(),
          term: term,
          meaning: meaning,
          favorite: false,
          topic: '',
        );

        final isDup = await _wordRepo.checkDuplicate(term);
        if (isDup) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 존재하는 단어입니다')),
          );
          return;
        }

        await _wordRepo.addWord(newWord);
      } else {
        // 수정
        final updated = widget.word!.copyWith(
          term: term,
          meaning: meaning,
          updatedAt: DateTime.now(),
          termNorm: Word.normalize(term),
        );
        await _wordRepo.updateWord(updated);
      }

      Navigator.pop(context); // 성공 후 돌아가기
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.word != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '단어 수정' : '단어 추가'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveWord),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '단어를 작성해주세요.',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _meaningController,
              decoration: const InputDecoration(
                labelText: '뜻을 작성해주세요.',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.multiline,
              maxLines: null,
              onSubmitted: (_) => _saveWord(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveWord,
        child: const Icon(Icons.save),
      ),
    );
  }
}

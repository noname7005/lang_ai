// 단어 추가/수정 화면, 입력 필드, 유효성 검사, 저장 크리거, 결과 반환
import 'package:flutter/material.dart';
import 'package:lang_ai/models/word.dart';

class WordEditScreen extends StatefulWidget {
  final Word? word;
  const WordEditScreen({Key? key, this.word}) : super(key: key);

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  late TextEditingController _textController;
  late TextEditingController _meaningController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.word?.term ?? '');
    _meaningController = TextEditingController(text: widget.word?.meaning ?? '');
  }

  @override
  void dispose() {
    _textController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  void _saveWord() {
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
        const SnackBar(content: Text('의미를 입력해주세요')),
      );
      return;
    }

    final newWord = Word(
      id: widget.word?.id ?? DateTime.now().millisecondsSinceEpoch,
      term: term,
      meaning: meaning,
      favorite: widget.word?.favorite ?? false, // ← 대소문자 수정
      topic: widget.word?.topic ?? '',
    );

    Navigator.pop(context, newWord);
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
              onSubmitted: (_) => _saveWord(), // 엔터로 저장
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

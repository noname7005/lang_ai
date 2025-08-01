import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/api_service.dart';
import 'ai_examples_screen.dart';

class WordEditScreen extends StatefulWidget {
  final Word? word;
  const WordEditScreen({super.key, this.word});

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _term;
  late String _meaning;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _term = widget.word?.term ?? '';
    _meaning = widget.word?.meaning ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (widget.word == null) {
      await _api.addWord(Word(id: 0, term: _term, meaning: _meaning));
    } else {
      final w = widget.word!..term = _term..meaning = _meaning;
      await _api.updateWord(w);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word == null ? '단어 추가' : '단어 수정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _term,
                decoration: const InputDecoration(labelText: '단어'),
                validator: (v) => (v == null || v.isEmpty) ? '단어를 입력하세요.' : null,
                onSaved: (v) => _term = v!,
              ),
              TextFormField(
                initialValue: _meaning,
                decoration: const InputDecoration(labelText: '뜻'),
                validator: (v) => (v == null || v.isEmpty) ? '뜻을 입력하세요.' : null,
                onSaved: (v) => _meaning = v!,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('저장'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book),
                    label: const Text('AI 예문 보기'),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiExamplesScreen(term: _term),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

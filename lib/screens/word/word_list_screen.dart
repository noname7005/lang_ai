import 'package:flutter/material.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/screens/word/word_edit_screen.dart';
import 'package:lang_ai/screens/word/my_screen.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({Key? key}) : super(key: key);

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<Word> words = [];
  String? _selectedTopic; // null = 전체

  // 현재 선택된 주제에 맞춰 필터링된 목록
  List<Word> get _visibleWords {
    if (_selectedTopic == null || _selectedTopic!.isEmpty) return words;
    return [
      for (final w in words)
        if (w.topic.trim() == _selectedTopic) w,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어장'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              // words에서 주제 목록 수집(중복 제거/빈값 제외)
              final topics = words
                  .map((w) => w.topic.trim())
                  .where((t) => t.isNotEmpty)
                  .toSet()
                  .toList();

              final picked = await Navigator.push<String?>(
                context,
                MaterialPageRoute(
                  builder: (_) => MyScreen(
                    topics: topics,
                    selectedTopic: _selectedTopic,
                  ),
                ),
              );
              setState(() => _selectedTopic = picked); // null이면 전체
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedTopic != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Text('필터: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Chip(
                    label: Text(_selectedTopic!),
                    onDeleted: () => setState(() => _selectedTopic = null), // X로 해제
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _visibleWords.isEmpty
                ? const Center(
              child: Text('해당 조건의 단어가 없습니다', style: TextStyle(fontSize: 16)),
            )
                : ListView.separated(
              itemCount: _visibleWords.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final w = _visibleWords[i];
                return ListTile(
                  key: ValueKey(w.id),
                  title: Text(w.term, style: const TextStyle(fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (w.meaning.trim().isNotEmpty) Text(w.meaning),
                      if (w.topic.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            children: [Chip(label: Text(w.topic))],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(w.favorite ? Icons.star : Icons.star_border),
                        onPressed: () {
                          setState(() => w.favorite = !w.favorite);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final updated = await Navigator.push<Word>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WordEditScreen(word: w),
                            ),
                          );
                          if (updated != null) {
                            setState(() {
                              // 원본 words에서 id로 찾아 교체
                              final idx = words.indexWhere((e) => e.id == updated.id);
                              if (idx != -1) words[idx] = updated;
                            });
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteById(w.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // TODO: 상세 페이지로 이동 등
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('단어 추가'),
              onPressed: () async {
                final newWord = await Navigator.push<Word>(
                  context,
                  MaterialPageRoute(builder: (_) => const WordEditScreen()),
                );
                if (newWord != null) {
                  setState(() => words.insert(0, newWord));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteById(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('단어 삭제'),
        content: const Text('정말 이 단어를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => words.removeWhere((e) => e.id == id));
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

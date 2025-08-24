import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/screens/word/word_edit_screen.dart';
import 'package:lang_ai/screens/word/my_screen.dart';
import 'package:lang_ai/services/word_repository.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({Key? key}) : super(key: key);

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  late WordRepository _wordRepo;
  String? _selectedTopic; // null = 전체

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("로그인된 유저가 필요합니다.");
    }
    _wordRepo = WordRepository(userId: user.uid);
  }

  void _openEditScreen({Word? word}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordEditScreen(word: word),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('단어 삭제'),
        content: const Text('정말 이 단어를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _wordRepo.deleteWord(id);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
              // Firestore에서 topics 목록 수집
              final snapshot = await _wordRepo.streamWords().first;
              final topics = snapshot
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
                    onDeleted: () => setState(() => _selectedTopic = null),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Word>>(
              stream: _wordRepo.streamWords(topic: _selectedTopic),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("오류 발생: ${snapshot.error}"));
                }

                final words = snapshot.data ?? [];
                if (words.isEmpty) {
                  return const Center(
                    child: Text('해당 조건의 단어가 없습니다', style: TextStyle(fontSize: 16)),
                  );
                }

                return ListView.separated(
                  itemCount: words.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final w = words[i];
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
                            onPressed: () async {
                              await _wordRepo.toggleFavorite(w);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _openEditScreen(word: w),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(w.id),
                          ),
                        ],
                      ),
                    );
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
              onPressed: () => _openEditScreen(),
            ),
          ),
        ],
      ),
    );
  }
}

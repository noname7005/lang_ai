import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/services/word_repository.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late WordRepository _wordRepo;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");
    _wordRepo = WordRepository(userId: user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("저장된 단어")),
      body: StreamBuilder<List<Word>>(
        stream: _wordRepo.streamWords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("데이터를 불러오지 못했습니다."));
          }

          final favorites = snapshot.data!.where((w) => w.favorite).toList();

          if (favorites.isEmpty) {
            return const Center(child: Text("즐겨찾기한 단어가 없습니다."));
          }

          return ListView.separated(
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final w = favorites[i];
              return ListTile(
                title: Text(w.term, style: const TextStyle(fontSize: 18)),
                subtitle: Text(w.meaning),
                trailing: IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    // 체크 누르면 즐겨찾기 해제 → 즉시 목록에서 사라짐
                    final updated = w.copyWith(
                      favorite: false,
                      updatedAt: DateTime.now(),
                    );
                    await _wordRepo.updateWord(updated);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

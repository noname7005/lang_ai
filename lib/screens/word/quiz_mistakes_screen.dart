import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lang_ai/models/word.dart';
import 'package:lang_ai/services/word_repository.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  late WordRepository _wordRepo;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("로그인 필요");
    _wordRepo = WordRepository(userId: user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("로그인이 필요합니다.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("오답노트")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .collection("quiz_sessions")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("아직 퀴즈 기록이 없습니다."));
          }

          final sessions = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, i) {
              final data = sessions[i].data() as Map<String, dynamic>;
              final mistakes = (data["mistakes"] as List).cast<String>();

              return ExpansionTile(
                title: Text(
                  "퀴즈: ${data["createdAt"].toDate().toString().substring(0, 16)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "정답 ${data["correctCount"]} / 오답 ${data["wrongCount"]}",
                ),
                children: mistakes.isEmpty
                    ? [const ListTile(title: Text("오답 없음"))]
                    : mistakes.map((id) {
                  return FutureBuilder<Word?>(
                    future: _wordRepo.getWordById(id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const ListTile(title: Text("불러오는 중..."));
                      }
                      if (!snap.hasData) {
                        return ListTile(title: Text("삭제된 단어 (id=$id)"));
                      }
                      final word = snap.data!;
                      return ListTile(
                        title: Text(word.term),
                        subtitle: Text(word.meaning),
                      );
                    },
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}


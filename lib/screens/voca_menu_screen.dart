import 'package:flutter/material.dart';
import 'package:lang_ai/screens/word/topic_screen.dart';
import 'package:lang_ai/screens/word/word_list_screen.dart';
import 'package:lang_ai/screens/word/quiz_screen.dart';

class VocaMenuScreen extends StatelessWidget {
  const VocaMenuScreen({super.key});

  void _onMenuTap(BuildContext context, String title) {
    if (title == 'User') { //사용자 단어장
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WordListScreen()),
      );
    }
    else if (title == 'Topic') { //주제별 단어장
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TopicMenuScreen()),
      );
    }
    else if (title == 'Quiz') { //구현 필요
      Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizScreen()));
    }

    else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title 기능은 아직 준비 중입니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('단어 학습'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.list_alt,
            title: 'Topic',
            subtitle: '주제별 단어를 학습해보세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.person,
            title: 'User',
            subtitle: '내가 저장한 단어를 복습하세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.question_answer,
            title: 'Quiz',
            subtitle: '단어 퀴즈로 복습해보세요',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _onMenuTap(context, title),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

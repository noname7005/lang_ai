//주제별 단어장
import 'package:flutter/material.dart';

class TopicMenuScreen extends StatelessWidget {
  const TopicMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = const ['TOEIC', 'TOEFL', 'CONVERSATION', 'BUSINESS'];

    return Scaffold(
      appBar: AppBar(title: const Text('TOPIC')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final t = topics[i];
          return ElevatedButton(
            onPressed: () {
              // TODO: Day1~Day10 화면으로 이동
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$t: Day 화면 연결 예정')),
              );
              // 예: Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => DayListScreen(topicKey: t),
              // ));
            },
            child: Text(t),
          );
        },
      ),
    );
  }
}

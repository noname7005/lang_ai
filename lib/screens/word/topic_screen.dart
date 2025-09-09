import 'package:flutter/material.dart';
import 'day_screen.dart';

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
              // 여기서 DayListScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DayListScreen(topicKey: t),
                ),
              );
            },
            child: Text(t),
          );
        },
      ),
    );
  }
}

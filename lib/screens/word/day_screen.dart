import 'package:flutter/material.dart';
import 'topic_word_list_screen.dart';

class DayListScreen extends StatelessWidget {
  final String topicKey;
  const DayListScreen({super.key, required this.topicKey});

  @override
  Widget build(BuildContext context) {
    // Day1 ~ Day10
    final days = List.generate(10, (i) => "Day ${i + 1}");

    return Scaffold(
      appBar: AppBar(title: Text(topicKey)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final d = days[i];
          return ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TopicWordListScreen(
                    topicKey: topicKey,
                    day: i + 1,
                  ),
                ),
              );
            },
            child: Text(d),
          );
        },
      ),
    );
  }
}

//나만의 단어장
import 'package:flutter/material.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({
    super.key,
    required this.topics,
    this.selectedTopic,
  });

  final List<String> topics;    // 필수: 표시할 주제 목록
  final String? selectedTopic;  // 선택: 현재 선택값(null = 전체)

  @override
  Widget build(BuildContext context) {
    final uniqueSorted = <String>[
      for (final t in topics)
        if (t.trim().isNotEmpty) t.trim(),
    ]..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('주제 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: uniqueSorted.isEmpty
            ? Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('등록된 주제가 없습니다', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('전체 보기'),
              onPressed: () => Navigator.pop(context, null),
            ),
          ]),
        )
            : SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('전체'),
                selected: selectedTopic == null,
                onSelected: (_) => Navigator.pop(context, null),
                labelStyle: TextStyle(
                  fontWeight: selectedTopic == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              for (final t in uniqueSorted)
                ChoiceChip(
                  label: Text(t),
                  selected: selectedTopic == t,
                  onSelected: (_) => Navigator.pop(context, t),
                  labelStyle: TextStyle(
                    fontWeight: selectedTopic == t
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

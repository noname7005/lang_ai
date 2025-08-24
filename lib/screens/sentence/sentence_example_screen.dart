// lib/screens/sentence_example_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lang_ai/services/api_service.dart'; // ApiService 사용

/// 한글 입력 → 자연스러운 영어 문장 예문 제시 화면
class SentenceExampleScreen extends StatefulWidget {
  const SentenceExampleScreen({super.key});

  @override
  State<SentenceExampleScreen> createState() => _SentenceExampleScreenState();
}

class _SentenceExampleScreenState extends State<SentenceExampleScreen> {
  final _api = ApiService();
  final _krController = TextEditingController();

  String _level = 'B1';           // CEFR 힌트
  String _tone = 'neutral';       // 말투
  double _count = 5;              // 예문 개수
  bool _isLoading = false;

  /// 화면 표시용 예문 모델
  List<_SentenceExample> _examples = [];

  @override
  void dispose() {
    _krController.dispose();
    super.dispose();
  }

  Future<void> _requestExamples() async {
    final kr = _krController.text.trim();
    if (kr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('한글 문장을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final raw = await _api.getSentenceExamples(
        korean: kr,
        count: _count.toInt(),
        levelHint: _level,
        tone: _tone,
        temperature: 0.4,
      );

      final list = raw.map((m) {
        final en = (m['en'] ?? '').toString().trim();
        final noteKo = (m['note_ko'] ?? m['noteKo'] ?? '').toString().trim();
        return _SentenceExample(en: en, noteKo: noteKo);
      }).where((e) => e.en.isNotEmpty).toList();

      if (!mounted) return;
      setState(() => _examples = list);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToFile() async {
    if (_examples.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 내용이 없습니다.')),
      );
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final ts =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final file = File('${dir.path}/examples_$ts.md');
      final buf = StringBuffer('# Sentence Examples (${_level}, ${_tone})\n\n');
      buf.writeln('**KR:** ${_krController.text.trim()}\n');
      for (var i = 0; i < _examples.length; i++) {
        final ex = _examples[i];
        buf.writeln('**${i + 1}.** ${ex.en}');
        if (ex.noteKo.isNotEmpty) {
          buf.writeln('  - 설명: ${ex.noteKo}');
        }
        buf.writeln();
      }
      await file.writeAsString(buf.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장 완료: ${file.path}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  void _reset() {
    setState(() {
      _krController.clear();
      _level = 'B1';
      _tone = 'neutral';
      _count = 5;
      _examples.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Examples'),
        actions: [
          IconButton(
            tooltip: '예문 생성',
            icon: const Icon(Icons.auto_mode),
            onPressed: _isLoading ? null : _requestExamples,
          ),
          IconButton(
            tooltip: '파일로 저장',
            icon: const Icon(Icons.save_alt),
            onPressed: _examples.isEmpty ? null : _exportToFile,
          ),
          IconButton(
            tooltip: '초기화',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _reset,
          ),
        ],
      ),
      body: Column(
        children: [
          // 입력 영역
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              children: [
                TextField(
                  controller: _krController,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: '한글 문장/상황 입력',
                    hintText: '예) 친구에게 늦어서 미안하다고 공손하게 말하고 싶어',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _requestExamples(),
                ),
                const SizedBox(height: 10),

                // ★ 반응형 필드/컨트롤 (LayoutBuilder)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 700;

                    final levelField = DropdownButtonFormField<String>(
                      value: _level,
                      items: const ['A1', 'A2', 'B1', 'B2', 'C1']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _level = v!),
                      decoration: const InputDecoration(
                        labelText: '레벨(CEFR 힌트)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );

                    final toneField = DropdownButtonFormField<String>(
                      value: _tone,
                      items: const [
                        DropdownMenuItem(value: 'neutral', child: Text('neutral')),
                        DropdownMenuItem(value: 'polite', child: Text('polite')),
                        DropdownMenuItem(value: 'casual', child: Text('casual')),
                        DropdownMenuItem(value: 'formal', child: Text('formal')),
                      ],
                      onChanged: (v) => setState(() => _tone = v!),
                      decoration: const InputDecoration(
                        labelText: '톤',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );

                    final countField = InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '예문 개수',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _count,
                              divisions: 7, // 1~8
                              min: 1,
                              max: 8,
                              label: _count.toInt().toString(),
                              onChanged: (v) => setState(() => _count = v),
                            ),
                          ),
                          Text('${_count.toInt()}'),
                        ],
                      ),
                    );

                    final generateBtn = FilledButton.icon(
                      onPressed: _isLoading ? null : _requestExamples,
                      icon: const Icon(Icons.auto_fix_high),
                      label: const Text('예문 생성'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    );

                    if (isNarrow) {
                      // 좁은 화면: 위→아래로 배치
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          levelField,
                          const SizedBox(height: 8),
                          toneField,
                          const SizedBox(height: 8),
                          countField,
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: generateBtn,
                          ),
                        ],
                      );
                    } else {
                      // 넓은 화면: 한 줄 배치
                      return Row(
                        children: [
                          Expanded(child: levelField),
                          const SizedBox(width: 8),
                          Expanded(child: toneField),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: countField),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: FittedBox(child: generateBtn),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 결과 영역
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _examples.isEmpty
                ? Center(
              child: Text(
                '한글 문장을 입력하고 [예문 생성]을 눌러보세요.',
                style: theme.textTheme.bodyMedium,
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: _examples.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final ex = _examples[i];
                return Card(
                  elevation: 0,
                  color: Colors.blue[50],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}. ${ex.en}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (ex.noteKo.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ex.noteKo,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SentenceExample {
  final String en;      // 영어 예문
  final String noteKo;  // 한국어 설명(선택)
  const _SentenceExample({required this.en, required this.noteKo});
}

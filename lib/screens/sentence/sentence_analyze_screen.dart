import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lang_ai/services/api_service.dart'; // ApiService 사용

/// 영어 문장을 입력 받아 문법 검사 + 더 자연스러운 표현 추천
class SentenceAnalyzeScreen extends StatefulWidget {
  const SentenceAnalyzeScreen({super.key});

  @override
  State<SentenceAnalyzeScreen> createState() => _SentenceAnalyzeScreenState();
}

class _SentenceAnalyzeScreenState extends State<SentenceAnalyzeScreen> {
  final _api = ApiService(); // TODO: 안전한 키 주입으로 교체
  final _enController = TextEditingController();

  String _level = 'B1';        // CEFR 힌트
  String _tone = 'neutral';    // 재작성 시 톤
  double _count = 5;           // 이슈/추천 최대 개수
  bool _includeRewrite = true; // 자연스러운 전체 재작성 포함 여부
  bool _isLoading = false;

  // 결과 상태
  String _corrected = ''; // 문법 교정된 문장(간단 수정)
  String _rewrite   = ''; // 전체 재작성(톤 반영)
  List<_GrammarIssue> _issues = [];

  @override
  void dispose() {
    _enController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _enController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('영어 문장을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _api.analyzeGrammar(
        english: text,
        count: _count.toInt(),
        levelHint: _level,
        tone: _tone,
        includeRewrite: _includeRewrite,
        temperature: 0.25,
      );

      // 파싱
      final corrected = (res['corrected'] ?? '').toString().trim();
      final rewrite   = (res['rewrite'] ?? '').toString().trim();

      final issues = <_GrammarIssue>[];
      final rawIssues = (res['issues'] as List?) ?? const [];
      for (final it in rawIssues) {
        if (it is Map<String, dynamic>) {
          issues.add(_GrammarIssue(
            original: (it['original'] ?? '').toString().trim(),
            suggested: (it['suggested'] ?? '').toString().trim(),
            reasonKo: (it['reason_ko'] ?? it['reasonKo'] ?? '').toString().trim(),
            alternatives: ((it['alternatives'] as List?) ?? const [])
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList(),
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        _corrected = corrected;
        _rewrite   = rewrite;
        _issues    = issues;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('검사 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToFile() async {
    if (_corrected.isEmpty && _rewrite.isEmpty && _issues.isEmpty) {
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

      final file = File('${dir.path}/grammar_${ts}.md');
      final buf = StringBuffer('# Grammar Suggestions ($_level, $_tone)\n\n');
      buf.writeln('**Input:** ${_enController.text.trim()}\n');

      if (_corrected.isNotEmpty) {
        buf.writeln('## Corrected (Quick Fix)');
        buf.writeln(_corrected);
        buf.writeln();
      }
      if (_issues.isNotEmpty) {
        buf.writeln('## Issues & Suggestions');
        for (var i = 0; i < _issues.length; i++) {
          final it = _issues[i];
          buf.writeln('**${i + 1}.**');
          if (it.original.isNotEmpty) {
            buf.writeln('- Original: ${it.original}');
          }
          if (it.suggested.isNotEmpty) {
            buf.writeln('- Suggested: ${it.suggested}');
          }
          if (it.reasonKo.isNotEmpty) {
            buf.writeln('- 이유: ${it.reasonKo}');
          }
          if (it.alternatives.isNotEmpty) {
            buf.writeln('- 대안:');
            for (final alt in it.alternatives) {
              buf.writeln('  - $alt');
            }
          }
          buf.writeln();
        }
      }
      if (_includeRewrite && _rewrite.isNotEmpty) {
        buf.writeln('## Polished Rewrite');
        buf.writeln(_rewrite);
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
      _enController.clear();
      _level = 'B1';
      _tone = 'neutral';
      _count = 5;
      _includeRewrite = true;
      _corrected = '';
      _rewrite = '';
      _issues.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grammar Checker'),
        actions: [
          IconButton(
            tooltip: '검사 실행',
            icon: const Icon(Icons.fact_check),
            onPressed: _isLoading ? null : _analyze,
          ),
          IconButton(
            tooltip: '파일로 저장',
            icon: const Icon(Icons.save_alt),
            onPressed: (_corrected.isEmpty && _rewrite.isEmpty && _issues.isEmpty)
                ? null
                : _exportToFile,
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
                  controller: _enController,
                  minLines: 3,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'English sentence(s)',
                    hintText: '예) I goes to school yesterday.',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _analyze(),
                ),
                const SizedBox(height: 10),

                // ★ 반응형 컨트롤: 좁으면 Column, 넓으면 Row
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
                        labelText: '톤(재작성)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    );

                    final countField = InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '이슈/추천 개수',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _count,
                              divisions: 9, // 1~10
                              min: 1,
                              max: 10,
                              label: _count.toInt().toString(),
                              onChanged: (v) => setState(() => _count = v),
                            ),
                          ),
                          Text('${_count.toInt()}'),
                        ],
                      ),
                    );

                    final rewriteSwitch = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('재작성 포함'),
                        Switch(
                          value: _includeRewrite,
                          onChanged: (v) => setState(() => _includeRewrite = v),
                        ),
                      ],
                    );

                    final runBtn = FilledButton.icon(
                      onPressed: _isLoading ? null : _analyze,
                      icon: const Icon(Icons.fact_check),
                      label: const Text('검사 실행'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    );

                    if (isNarrow) {
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
                            alignment: Alignment.centerLeft,
                            child: rewriteSwitch,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: runBtn,
                          ),
                        ],
                      );
                    } else {
                      return Row(
                        children: [
                          Expanded(child: levelField),
                          const SizedBox(width: 8),
                          Expanded(child: toneField),
                          const SizedBox(width: 8),
                          Expanded(flex: 2, child: countField),
                          const SizedBox(width: 8),
                          Flexible(child: rewriteSwitch),
                          const SizedBox(width: 8),
                          Flexible(flex: 0, child: FittedBox(child: runBtn)),
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
                : (_corrected.isEmpty && _rewrite.isEmpty && _issues.isEmpty)
                ? Center(
              child: Text(
                '영어 문장을 입력하고 [검사 실행]을 눌러보세요.',
                style: theme.textTheme.bodyMedium,
              ),
            )
                : ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              children: [
                if (_corrected.isNotEmpty) ...[
                  Text('Corrected (Quick Fix)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _bubble(_corrected, theme, color: Colors.green[50]),
                  const SizedBox(height: 12),
                ],
                if (_issues.isNotEmpty) ...[
                  Text('Issues & Suggestions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._issues.asMap().entries.map((e) {
                    final i = e.key;
                    final it = e.value;
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
                              '${i + 1}.',
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (it.original.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Original: ${it.original}', style: theme.textTheme.bodyMedium),
                            ],
                            if (it.suggested.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Suggested: ${it.suggested}', style: theme.textTheme.bodyMedium),
                            ],
                            if (it.reasonKo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('이유: ${it.reasonKo}', style: theme.textTheme.bodySmall),
                            ],
                            if (it.alternatives.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('대안:', style: theme.textTheme.labelMedium),
                              const SizedBox(height: 4),
                              ...it.alternatives.map((alt) => Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 2),
                                child: Text('• $alt', style: theme.textTheme.bodySmall),
                              )),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
                if (_includeRewrite && _rewrite.isNotEmpty) ...[
                  Text('Polished Rewrite', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _bubble(_rewrite, theme, color: Colors.orange[50]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(String text, ThemeData theme, {Color? color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SelectableText(text, style: theme.textTheme.bodyMedium),
    );
  }
}

class _GrammarIssue {
  final String original;
  final String suggested;
  final String reasonKo;
  final List<String> alternatives;
  const _GrammarIssue({
    required this.original,
    required this.suggested,
    required this.reasonKo,
    required this.alternatives,
  });
}

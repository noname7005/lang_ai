// lib/screens/feedback_chat_screen.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:lang_ai/services/api_service.dart'; // ApiService, LineEdit 사용

enum FeedbackMode { overall, lineEdits, rewrite }

class FeedbackChatScreen extends StatefulWidget {
  const FeedbackChatScreen({super.key});

  @override
  State<FeedbackChatScreen> createState() => _FeedbackChatScreenState();
}

class _FeedbackChatScreenState extends State<FeedbackChatScreen> {
  final _api = ApiService(); // TODO: 실제 키 주입 방식으로 교체
  FeedbackMode _mode = FeedbackMode.overall;

  String? _selectedFilePath;
  String _conversationRaw = '';      // 파일 원문(.txt/.json)
  String _conversationPreview = '';  // 화면 미리보기용(정리된 텍스트)
  String _feedback = '';             // AI 피드백 결과 (Markdown 등)
  bool _isLoading = false;

  // ---- line-by-line 전용 상태 ----
  List<_LineItem> _userLines = [];            // 사용자 발화만 인덱싱
  int _currentUserLineIdx = 0;                // 다음으로 요청할 라인 인덱스
  final Map<int, LineEdit> _lineEdits = {};   // 수신된 라인별 피드백 캐시

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileLabel = _selectedFilePath == null
        ? 'No file selected'
        : _selectedFilePath!.split(Platform.pathSeparator).last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback Assistant'),
        actions: [
          IconButton(
            tooltip: 'Load saved conversation',
            icon: const Icon(Icons.folder_open),
            onPressed: _pickFromDocuments,
          ),
          IconButton(
            tooltip: 'Save feedback to file',
            icon: const Icon(Icons.save_alt),
            onPressed: _feedback.isEmpty ? null : _exportFeedbackToFile,
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 컨트롤: 파일명 / 모드 / 실행 버튼(+ line-by-line 전용 버튼)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200, maxWidth: 420),
                  child: Text(
                    'File: $fileLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                DropdownButton<FeedbackMode>(
                  value: _mode,
                  items: const [
                    DropdownMenuItem(
                      value: FeedbackMode.overall,
                      child: Text('Overall feedback'),
                    ),
                    DropdownMenuItem(
                      value: FeedbackMode.lineEdits,
                      child: Text('Line-by-line edits'),
                    ),
                    DropdownMenuItem(
                      value: FeedbackMode.rewrite,
                      child: Text('Polished rewrite'),
                    ),
                  ],
                  onChanged: (m) => setState(() => _mode = m!),
                ),
                FilledButton.icon(
                  onPressed: _conversationPreview.isEmpty || _isLoading
                      ? null
                      : _requestFeedback,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Get feedback'),
                ),
                if (_mode == FeedbackMode.lineEdits)
                  FilledButton.icon(
                    onPressed: (_userLines.isEmpty || _isLoading)
                        ? null
                        : _requestNextUserLineFeedback,
                    icon: const Icon(Icons.navigate_next),
                    label: Text('다음 줄 피드백 (${_currentUserLineIdx}/${_userLines.length})'),
                  ),
                if (_mode == FeedbackMode.lineEdits)
                  OutlinedButton.icon(
                    onPressed: (_userLines.isEmpty || _isLoading)
                        ? null
                        : () {
                      setState(() {
                        _currentUserLineIdx = 0;
                        _lineEdits.clear();
                        _feedback = '';
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('라인 진행 초기화'),
                  ),
              ],
            ),
          ),

          // 대화 미리보기
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Conversation preview',
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(minHeight: 100, maxHeight: 180),
            child: SingleChildScrollView(
              child: SelectableText(
                _conversationPreview.isEmpty
                    ? 'Load a saved .txt or .json file to begin.'
                    : _conversationPreview,
              ),
            ),
          ),

          const Divider(height: 1),

          // 결과
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: _feedback.isEmpty
                  ? Center(
                child: Text(
                  _mode == FeedbackMode.lineEdits
                      ? 'Line-by-line 모드: [다음 줄 피드백]을 눌러 순차적으로 받아보세요.\n또는 [Get feedback]으로 일괄 결과를 받을 수 있습니다.'
                      : 'Press [Get feedback] to see suggestions.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              )
                  : SingleChildScrollView(
                child: SelectableText(
                  _feedback,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================== 액션 ===================

  Future<void> _pickFromDocuments() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final entries = Directory(dir.path)
          .listSync()
          .whereType<File>()
          .where((f) {
        final name = f.path.toLowerCase();
        return name.endsWith('.txt') || name.endsWith('.json');
      })
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (!mounted) return;

      final selected = await showModalBottomSheet<File?>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          if (entries.isEmpty) {
            return const SizedBox(
              height: 160,
              child: Center(child: Text('No saved .txt/.json files found.')),
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final f = entries[i];
              final name = f.path.split(Platform.pathSeparator).last;
              final info = f.statSync();
              final dt = info.modified;
              final stamp =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              return ListTile(
                leading: Icon(name.endsWith('.json') ? Icons.data_object : Icons.description),
                title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('Modified: $stamp'),
                onTap: () => Navigator.of(ctx).pop(f),
              );
            },
          );
        },
      );

      if (selected == null) return;
      final content = await File(selected.path).readAsString();
      final preview = _normalizeConversationPreview(content);

      setState(() {
        _selectedFilePath = selected.path;
        _conversationRaw = content;
        _conversationPreview = preview;
        _feedback = '';
        // ---- line-by-line 준비 ----
        _userLines = _extractUserLines(content);
        _currentUserLineIdx = 0;
        _lineEdits.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('파일 불러오기 실패: $e')),
      );
    }
  }

  /// 전체 피드백(모드별) 요청: overall/lineEdits/rewrite
  Future<void> _requestFeedback() async {
    if (_conversationPreview.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final feedback = await _api.getConversationFeedback(
        content: _conversationRaw,        // 원문(.txt 또는 .json 그대로)
        mode: _mode.name,                 // overall / lineEdits / rewrite
      );
      if (!mounted) return;
      setState(() => _feedback = feedback);
    } catch (e) {
      if (!mounted) return;
      setState(() => _feedback = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// line-by-line: 다음 사용자 발화 한 줄에 대한 피드백 요청
  Future<void> _requestNextUserLineFeedback() async {
    if (_currentUserLineIdx >= _userLines.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마지막 줄까지 완료했습니다.')),
      );
      return;
    }

    final item = _userLines[_currentUserLineIdx];

    setState(() => _isLoading = true);
    try {
      final ctx = _contextWindow(_currentUserLineIdx);
      final edit = await _api.getLineEditForLine(
        index: item.index,
        original: item.text,
        context: ctx,
        levelHint: 'B1',
      );
      _lineEdits[item.index] = edit; // OK
      _currentUserLineIdx++; // 다음 줄로 이동
      setState(() {
        _feedback = _renderLineEditsMarkdown(_lineEdits);
      });
    } catch (e) {
      setState(() => _feedback = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 피드백을 파일로 저장(.md)
  Future<void> _exportFeedbackToFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final ts =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final base = _selectedFilePath == null
          ? 'feedback_$ts.md'
          : 'feedback_${_selectedFilePath!.split(Platform.pathSeparator).last}_$ts.md';

      final file = File('${dir.path}/$base');
      await file.writeAsString(_feedback);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드백 저장 완료: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  // =================== 유틸 ===================

  /// 우리가 저장해 둔 .json / .txt를 공통 포맷으로 미리보기용 텍스트로 변환
  String _normalizeConversationPreview(String raw) {
    // JSON 포맷 예: {"messages":[{"role":"user","text":"..."},{"role":"assistant","text":"..."}]}
    try {
      final obj = jsonDecode(raw);
      if (obj is Map && obj['messages'] is List) {
        final list = (obj['messages'] as List)
            .whereType<Map>()
            .map((m) {
          final role = (m['role'] ?? '').toString();
          final text = (m['text'] ?? '').toString();
          final tag = switch (role) {
            'user' => 'User',
            'assistant' => 'AI',
            _ => role.isEmpty ? '-' : role,
          };
          return '$tag: $text';
        })
            .join('\n');
        return list;
      }
    } catch (_) {
      // JSON 아니면 그냥 진행
    }

    // 텍스트(.txt)는 그대로 사용
    return raw;
  }

  /// 저장한 .json/.txt로부터 'user' 라인만 뽑아 인덱싱
  List<_LineItem> _extractUserLines(String raw) {
    // 1) json 포맷 시도: {"messages":[{"role":"user","text":"..."} ...]}
    try {
      final obj = jsonDecode(raw);
      if (obj is Map && obj['messages'] is List) {
        int i = 0;
        return (obj['messages'] as List)
            .whereType<Map>()
            .where((m) => (m['role'] ?? '').toString() == 'user')
            .map((m) => _LineItem(
          index: i++,
          role: 'user',
          text: (m['text'] ?? '').toString().trim(),
        ))
            .toList();
      }
    } catch (_) {}
    // 2) txt 포맷: "User: ..." 라인만 추출
    final lines = raw.split('\n');
    int i = 0;
    return lines
        .map((l) => l.trim())
        .where((l) =>
    l.isNotEmpty &&
        RegExp(r'^(User|U)[:\-]\s+', caseSensitive: false).hasMatch(l))
        .map((l) =>
        l.replaceFirst(RegExp(r'^(User|U)[:\-]\s+', caseSensitive: false), ''))
        .map((t) => _LineItem(index: i++, role: 'user', text: t))
        .toList();
  }

  /// 주변 컨텍스트 몇 줄 제공(간단 버전)
  String _contextWindow(int idx, {int radius = 2}) {
    final all = _conversationPreview.split('\n');
    final from = (idx - radius).clamp(0, all.length - 1);
    final to = (idx + radius).clamp(0, all.length - 1);
    return all.sublist(from, to + 1).join('\n');
  }

  /// 수신된 라인 편집들을 Markdown으로 렌더
  String _renderLineEditsMarkdown(Map<int, LineEdit> edits) {
    final keys = edits.keys.toList()..sort();
    final buf = StringBuffer('# Line-by-line feedback\n');
    for (final k in keys) {
      final e = edits[k]!;
      buf.writeln('\n**#${e.index + 1}**');
      buf.writeln('- Original: ${e.original}');
      buf.writeln('- Suggested: ${e.suggested}');
      buf.writeln('- 이유: ${e.reasonKo}');
    }
    return buf.toString();
  }
}

// 내부 전용: 사용자 발화 라인 표현
class _LineItem {
  final int index;   // 0,1,2...
  final String role; // 'user'
  final String text;
  _LineItem({required this.index, required this.role, required this.text});
}

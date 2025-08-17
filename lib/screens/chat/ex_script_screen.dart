// lib/screens/ex_script_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lang_ai/services/api_service.dart';

class ExScriptScreen extends StatefulWidget {
  const ExScriptScreen({super.key});

  @override
  State<ExScriptScreen> createState() => _ExScriptScreenState();
}

enum _MenuAction { newScript, copyAll, settings }

class _ExScriptScreenState extends State<ExScriptScreen> {
  final _topicController = TextEditingController();
  final _situationController = TextEditingController();

  String _level = 'A2'; // 간단 레벨 힌트
  double _turns = 6;    // 총 발화 수
  bool _isLoading = false;
  List<DialogueTurn> _script = [];

  // TODO: 실제 API 키를 안전하게 주입하세요.
  final api = ApiService();

  @override
  void dispose() {
    _topicController.dispose();
    _situationController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    final situation = _situationController.text.trim();

    if (topic.isEmpty || situation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주제와 상황을 모두 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final script = await api.generateScript(
        topic: topic,
        situation: situation,
        turns: _turns.toInt(),
        level: _level,
      );
      if (!mounted) return;
      setState(() => _script = script);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onMenu(_MenuAction a) async {
    switch (a) {
      case _MenuAction.newScript:
        setState(() {
          _topicController.clear();
          _situationController.clear();
          _level = 'A2';
          _turns = 6;
          _script.clear();
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('새 스크립트를 시작합니다.')));
        break;
      case _MenuAction.copyAll:
        if (_script.isEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('복사할 스크립트가 없습니다.')));
          return;
        }
        final text = _script.map((t) => '${t.speaker}: ${t.text}').join('\n');
        await Clipboard.setData(ClipboardData(text: text));
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('스크립트를 복사했습니다.')));
        break;
      case _MenuAction.settings:
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('설정은 추후 연결 예정입니다.')));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSuffix = _topicController.text.trim().isEmpty
        ? 'No Topic'
        : _topicController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text('ExScript • $titleSuffix'),
        actions: [
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: _MenuAction.newScript, child: Text('새로 만들기')),
              PopupMenuItem(value: _MenuAction.copyAll, child: Text('스크립트 전체 복사')),
              PopupMenuItem(value: _MenuAction.settings, child: Text('설정')),
            ],
            icon: const Icon(Icons.more_vert),
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
                // 주제
                TextField(
                  controller: _topicController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '주제 (Topic)',
                    hintText: '예) Weekend trip planning',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                // 상황
                TextField(
                  controller: _situationController,
                  textInputAction: TextInputAction.done,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: '상황 (Situation)',
                    hintText: '예) Two friends discussing budget and itinerary',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _generate(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // 레벨
                    Expanded(
                      child: DropdownButtonFormField<String>(
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 턴 수
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '턴 수',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _turns,
                                divisions: 8, // 2~10
                                min: 2,
                                max: 10,
                                label: _turns.toInt().toString(),
                                onChanged: (v) => setState(() => _turns = v),
                              ),
                            ),
                            Text('${_turns.toInt()}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _generate,
                      icon: const Icon(Icons.auto_mode),
                      label: const Text('생성'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 결과 영역
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _script.isEmpty
                ? Center(
              child: Text(
                '주제와 상황을 입력한 뒤 [생성]을 눌러 스크립트를 만들어보세요.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              itemCount: _script.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final item = _script[i];
                final isA = item.speaker == 'A';
                return Align(
                  alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Card(
                      color: isA ? Colors.grey[200] : Colors.blue[50],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: isA ? Colors.black87 : Colors.blue,
                                      child: Text(
                                        item.speaker,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isA ? 'Speaker A' : 'Speaker B',
                                      style: theme.textTheme.labelMedium,
                                    ),
                                  ],
                                ),
                                IconButton(
                                  tooltip: '이 대사 복사',
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: item.text),
                                    );
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '복사됨: ${item.text.length > 24 ? '${item.text.substring(0,24)}...' : item.text}',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.text, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
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

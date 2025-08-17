// lib/screens/ai_chat_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

enum _MenuAction { newChat, saveLocal, settings }

class _AiChatScreenState extends State<AiChatScreen> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  final apiService = ApiService();

  String? _topicText; // 사용자가 직접 입력한 주제 텍스트

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openTopicInputDialog() async {
    final topicController = TextEditingController(text: _topicText ?? "");
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set Conversation Topic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '예: Trip to Tokyo on a budget for 3 days',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => Navigator.of(ctx).pop(topicController.text.trim()),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tip: 간단히 상황/역할/목표를 써 주세요.\n예) Casual small talk with a new colleague.\n예) Practice job interview for junior developer.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null), // 변경 없이 닫기
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''), // 주제 제거
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(topicController.text.trim()),
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _topicText = result.isEmpty ? null : result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_topicText == null ? 'Topic cleared (Free Talk)' : 'Topic set: $_topicText'),
      ),
    );
  }


  Future<File> _saveConversationToFile({bool asJson = false}) async {
    // 1) 대화 텍스트/JSON 만들기
    final now = DateTime.now();
    final timestamp = "${now.year}${now.month.toString().padLeft(2,'0')}"
        "${now.day.toString().padLeft(2,'0')}_${now.hour.toString().padLeft(2,'0')}"
        "${now.minute.toString().padLeft(2,'0')}${now.second.toString().padLeft(2,'0')}";

    late final String filename;
    late final String contents;

    if (asJson) {
      filename = "chat_$timestamp.json";
      final data = _messages.map((m) => {
        "role": m.isUser ? "user" : "assistant",
        "text": m.text,
        "timestamp": now.toIso8601String(), // 필요 시 각 메시지의 시간으로 교체
      }).toList();
      contents = JsonEncoder.withIndent('  ').convert({"messages": data});
    } else {
      filename = "chat_$timestamp.txt";
      contents = _messages
          .map((m) => "${m.isUser ? 'User' : 'AI'}: ${m.text}")
          .join("\n");
    }

    // 2) 앱 문서 폴더 경로 얻기 (권한 불필요)
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/$filename");

    // 3) 파일 쓰기
    return file.writeAsString(contents);
  }

  void _onMenuSelected(_MenuAction action) async {
    switch (action) {
      case _MenuAction.newChat:
        setState(() => _messages.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('새 대화를 시작했습니다.')),
        );
        break;
      case _MenuAction.saveLocal:
        if (_messages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('저장할 대화가 없습니다.')),
          );
          return;
        }
        try {
          // txt로 저장 (JSON으로 원하면 asJson: true)
          final file = await _saveConversationToFile(asJson: false);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 완료: ${file.path}')),
          );

          // 선택: 바로 공유하기
          // await Share.shareXFiles([XFile(file.path)], text: '대화 내보내기');

        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장 실패: $e')),
          );
        }
        break;

      case _MenuAction.settings:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('설정은 추후 연결 예정입니다.')),
        );
        break;
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _controller.clear();

    try {
      final reply = await apiService.sendMessage(
        text,
        topicPrompt: _topicText, // ⬅️ 직접 입력한 주제를 시스템 프롬프트로 전달
        temperature: 0.7,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: 'Error: $e', isUser: false));
      });
    }
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicLabel = _topicText?.isNotEmpty == true ? _topicText! : 'Free Talk';
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Conversation • $topicLabel'),
        actions: [
          IconButton(
            tooltip: 'Set topic',
            icon: const Icon(Icons.edit_note),
            onPressed: _openTopicInputDialog, // ⬅️ 주제 직접 입력 다이얼로그
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(value: _MenuAction.newChat, child: Text('새 대화 시작')),
              PopupMenuItem(value: _MenuAction.saveLocal, child: Text('대화 전체 저장')),
              PopupMenuItem(value: _MenuAction.settings, child: Text('설정')),
            ],
            icon: const Icon(Icons.more_vert),
            tooltip: '메뉴',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final i = _messages.length - 1 - index;
                return _buildMessageBubble(_messages[i]);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: _topicText == null
                          ? '메시지를 입력하세요...'
                          : '(Topic) $_topicText',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

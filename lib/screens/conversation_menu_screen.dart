import 'package:flutter/material.dart';
import 'ai_chat_screen.dart';

class ConversationMenuScreen extends StatelessWidget {
  const ConversationMenuScreen({super.key});

  void _onMenuTap(BuildContext context, String title) {

    if (title == 'AI Chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AiChatScreen()),
      );
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
        title: const Text('회화 연습'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.chat,
            title: 'AI Chat',
            subtitle: 'GPT와 자연스럽게 대화해보세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.book,
            title: 'Dialog Scripts',
            subtitle: '상황별 예시 회화를 읽어보세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.record_voice_over,
            title: 'Role Play',
            subtitle: '역할극처럼 대화 연습을 해보세요',
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
              Icon(icon, size: 40, color: Colors.indigo),
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

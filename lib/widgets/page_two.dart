import 'package:flutter/material.dart';
import '../screens/conversation_menu_screen.dart';
import '../screens/voca_menu_screen.dart';
import '../screens/sentence_menu_screen.dart';

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});


  void _onMenuTap(BuildContext context, String title) {
    if (title == 'Conversation') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ConversationMenuScreen()),
      );
    } else if (title == 'Voca') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const VocaMenuScreen()),
      );
    } else if (title == 'Sentence') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SentenceMenuScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title 기능은 아직 준비 중입니다.')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMenuCard(
          context,
          icon: Icons.spellcheck,
          title: 'Voca',
          subtitle: '단어를 외우고 테스트해보세요',
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          icon: Icons.text_fields,
          title: 'Sentence',
          subtitle: '문장을 만들고 연습해보세요',
        ),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          icon: Icons.chat_bubble_outline,
          title: 'Conversation',
          subtitle: 'GPT와 회화 연습을 시작하세요',
        ),
      ],
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
              Icon(icon, size: 40, color: Colors.blueAccent),
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

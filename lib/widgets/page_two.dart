import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lang_ai/screens/login_screen.dart';
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

  // 표시용 사용자 이름 생성
  String _displayName(User user) {
    // 1순위 : Firebase User.displayName
    final userName = user.displayName?.trim();
    if (userName != null && userName.isNotEmpty) return userName;

    // 2순위 : '사용자' 기본값
    return "사용자";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text('상태를 불러오는 중 오류가 발생했습니다: ${snap.error}'),
          );
        }

        final user = snap.data;

        if (user == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '로그인이 필요하신가요?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildMenuList(context)),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_displayName(user)}님, 반갑습니다.',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('로그아웃되었습니다.')),
                          );
                        }
                      },
                      child: const Text('로그아웃'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildMenuList(context)),
            ],
          );
        }
      },
    );
  }

  // 기존 ListView를 함수로 분리함
  Widget _buildMenuList(BuildContext context) {
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
      {required IconData icon,
      required String title,
      required String subtitle}) {
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
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54),
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

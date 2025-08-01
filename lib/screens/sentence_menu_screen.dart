import 'package:flutter/material.dart';

class SentenceMenuScreen extends StatelessWidget {
  const SentenceMenuScreen({super.key});

  void _onMenuTap(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$title 기능은 아직 준비 중입니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문장 학습'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMenuCard(
            context,
            icon: Icons.school,
            title: 'Example',
            subtitle: '예시 문장을 학습해보세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.edit,
            title: 'Writing',
            subtitle: '문장을 직접 작성해보세요',
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            icon: Icons.repeat,
            title: 'Correction',
            subtitle: 'AI가 문장을 교정해줍니다',
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
              Icon(icon, size: 40, color: Colors.deepPurple),
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

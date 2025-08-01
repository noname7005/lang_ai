import 'package:flutter/material.dart';
import 'main_screen.dart'; // 로그인 후 진입할 메인 화면을 연결한다고 가정

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToMain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('로그인'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              '소셜 계정으로 로그인하세요',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            _buildSocialButton(
              context,
              label: '카카오로 로그인',
              color: const Color(0xFFFEE500),
              textColor: Colors.black87,
              icon: Icons.chat_bubble,
              onPressed: () {
                // 카카오 로그인 함수 추후 연결하기
              },
            ),
            const SizedBox(height: 20),
            _buildSocialButton(
              context,
              label: '구글로 로그인',
              color: Colors.white,
              textColor: Colors.black87,
              icon: Icons.account_circle,
              onPressed: () {
                // 구글 로그인 함수 추후 연결하기
              },
            ),


            // 비로그인 모드로 이동
            TextButton(
              onPressed: () {
                _goToMain(context);
              },
              child: const Text('비로그인으로 계속하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      BuildContext context, {
        required String label,
        required Color color,
        required Color textColor,
        required IconData icon,
        required VoidCallback onPressed,
      }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: textColor),
        label: Text(label, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

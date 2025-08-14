import 'package:flutter/material.dart';
import 'package:lang_ai/services/google_login_service.dart';
import 'main_screen.dart'; // 로그인 후 진입할 메인 화면을 연결한다고 가정

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _goToMain(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final userCredential = await GoogleAuthService().signInWithGoogle(context);
    if (userCredential != null) {
      print('구글 로그인 성공: ${userCredential.user?.email}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인되었습니다.')),
        );
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false, // 스택 비움
      );
    } else {
      // 실패/취소 시 처리
      debugPrint('구글 로그인 실패 또는 취소');
    }
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
            GestureDetector(
                onTap: () => _handleGoogleSignIn(context),
                child: Image.asset(
                  'assets/images/android_light_sq_SI@1x.png',
                  width: double.infinity,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildSocialButton(
                      context,
                      label: '구글로 로그인',
                      color: Colors.white,
                      textColor: Colors.black87,
                      icon: Icons.account_circle,
                      onPressed: () => _handleGoogleSignIn(context),
                    );
                  },
                )),

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

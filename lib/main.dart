import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // const 생성자 추가

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '영어 학습 앱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // 선택사항 (Flutter 3.10 이상에서 Material3 사용)
      ),
      home: const SplashScreen(), // 앱 시작 화면
    );
  }
}

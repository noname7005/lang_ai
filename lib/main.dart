import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/notification/study_storage.dart';
import 'screens/notification/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final dates = await loadStudyDates(); // 저장한 날짜들
  for (final d in dates) { await scheduleDailyStudyNotification(d); }
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

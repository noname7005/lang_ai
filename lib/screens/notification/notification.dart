// lib/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata; // ← 변경: tzdata
import 'package:timezone/timezone.dart' as tz;        // ← tz

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// 알림설정 초기화
Future<void> initNotifications() async {
  // 타임존 초기화
  tzdata.initializeTimeZones();
  // 한국 시간대
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(
    android: androidInit,
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    // onDidReceiveNotificationResponse: ... (필요시 추가)
  );
}

// 보조 함수
int _idFromDate(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

tz.TZDateTime _at7AM(DateTime d) {
  // 학습일 오전 7시 알림
  return tz.TZDateTime(tz.local, d.year, d.month, d.day, 7, 0, 0);
}

Future<void> scheduleDailyStudyNotification(
    DateTime date, {
      String? title,
      String? body,
    }) async {
  final tz.TZDateTime scheduled = _at7AM(date);
  if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

  const androidDetails = AndroidNotificationDetails(
    'study_channel_id',
    '학습 알림',
    channelDescription: '선택한 날짜에 학습 알림을 보냅니다',
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    _idFromDate(date),
    title ?? '학습 예정',
    body ?? '${date.year}년 ${date.month}월 ${date.day}일 학습을 시작해요!',
    scheduled,                       // tz.TZDateTime 이어야 함
    details,                         // NotificationDetails
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
    UILocalNotificationDateInterpretation.absoluteTime,
    payload: null,
  );
}

Future<void> cancelStudyNotification(DateTime date) async {
  await flutterLocalNotificationsPlugin.cancel(_idFromDate(date));
}

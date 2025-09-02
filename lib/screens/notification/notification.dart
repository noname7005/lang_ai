// lib/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

//알림설정 초기화
Future<void> initNotifications() async {
  tz.initializeTimeZones();
  // 한국 시간대
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit, iOS: DarwinInitializationSettings());

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    // 알림 탭 시 라우팅이 필요하면 여기서 onDidReceiveNotificationResponse 처리
  );
}
// 보조 함수
int _idFromDate(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

tz.TZDateTime _at9AM(DateTime d) {
  return tz.TZDateTime(tz.local, d.year, d.month, d.day, 7, 0, 0);// 학습일 오전 7시 알림
}

Future<void> scheduleDailyStudyNotification(
    DateTime date, {
      String? title,
      String? body,
    }) async {
  final scheduled = _at9AM(date);
  if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

  final androidDetails = AndroidNotificationDetails(
    'study_channel_id',
    '학습 알림',
    channelDescription: '선택한 날짜에 학습 알림을 보냅니다',
    importance: Importance.high,
    priority: Priority.high,
  );
//-----------------------------------------------------------------------------------------------------
  final details = NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.zonedSchedule(
    _idFromDate(date),
    title ?? '학습 예정',
    body ?? '${date.year}년 ${date.month}월 ${date.day}일 학습을 시작해요!',
    scheduled,
    details,
// 19.x API: 정확한 스케줄을 보장, 절전 중에도 울리게
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: null,
  );
}

Future<void> cancelStudyNotification(DateTime date) async {
  await flutterLocalNotificationsPlugin.cancel(_idFromDate(date));
}

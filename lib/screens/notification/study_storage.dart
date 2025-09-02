// lib/study_storage.dart
import 'package:shared_preferences/shared_preferences.dart';

const _kStudyDatesKey = 'study_dates';

Future<Set<DateTime>> loadStudyDates() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(_kStudyDatesKey) ?? [];
  return list.map((s) {
    final parts = s.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]); // 버그 수정
  }).toSet();
}

Future<void> saveStudyDates(Set<DateTime> dates) async {
  final prefs = await SharedPreferences.getInstance();
  final strs = dates
      .map((d) =>
  '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}')
      .toList();
  await prefs.setStringList(_kStudyDatesKey, strs);
}

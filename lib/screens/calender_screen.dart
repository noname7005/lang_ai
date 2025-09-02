import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Google Calendar 관련 추가
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;

import 'package:lang_ai/screens/notification/study_storage.dart';


//학습 예정일
const String kStudySummaryPrefix = "[study] 학습 예정";
const String kStudySourceTag = "source=flutter_demo";

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
//

class CalendarScreenDemoPage extends StatefulWidget {
  //구글 캘린더 연동후 기능
  /*
  Future<void> createStudyEventsTopLevel(
      Set<DateTime> dates, {
        required Future<gcal.CalendarApi> Function() getApi,
        required Future<List<gcal.Event>> Function(gcal.CalendarApi, DateTime, DateTime) listStudyEventsByRange,
        required void Function(String message) showSnack, // dcontext 대신 메시지 처리
      }) async {
    if (dates.isEmpty) return;
    try {
      final api = await getApi();
      final sorted = dates.map(normalize).toSet().toList()..sort();

      final start = sorted.first;
      final end = sorted.last.add(const Duration(days: 1));
      final existing = await listStudyEventsByRange(api, start, end);
      final existingDates = existing
          .map((e) => e.start?.date ?? e.start?.dateTime)
          .whereType<DateTime>()
          .map(normalize)
          .toSet();

      for (final d in sorted) {
        if (existingDates.contains(d)) continue;
        await api.events.insert(
          gcal.Event(
            summary: kStudySummaryPrefix,
            description: "Flutter 달력에서 선택한 학습일\n$kStudySourceTag",
            start: gcal.EventDateTime(date: d),
            end: gcal.EventDateTime(date: d.add(const Duration(days: 1))),
          ),
          "primary",
        );
      }
      showSnack("Google 캘린더에 학습일을 등록했습니다.");
    } catch (e) {
      showSnack("캘린더 등록 실패: $e");
    }
  }
   */
  const CalendarScreenDemoPage({super.key});
  @override
  State<CalendarScreenDemoPage> createState() => _CalendarScreenDemoPageState();
}

class _CalendarScreenDemoPageState extends State<CalendarScreenDemoPage> {
  DateTime? _picked; // 단일 표시는 유지(가장 최근 선택한 날짜 등으로 표시)
  Set<DateTime> _selectedDates = {}; // 다중 선택 결과

  // Google Sign-In 인스턴스 (웹/모바일용 클라이언트 ID는 별도 설정 필요)
  // 최신 문서/이슈 제안

// 1) 인스턴스 생성 (Web은 clientId 필수)
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: <String>[gcal.CalendarApi.calendarEventsScope],
  );

// 2) CalendarApi 얻기 (최신 메서드 대응)
  Future<gcal.CalendarApi> _getCalendarApi() async {
    GoogleSignInAccount? account;

    try {
      account = await _googleSignIn.signInSilently();
    } catch (_) {
      account = null;
    }

    if (account == null) {
      final ok = await _googleSignIn.requestScopes(
        <String>[gcal.CalendarApi.calendarEventsScope],
      );
      if (!ok) {
        throw Exception('사용자 동의가 필요합니다.');
      }
      // 일부 버전에서는 requestScopes 이후 currentUser가 설정됨
      account = _googleSignIn.currentUser;
    }

    if (account == null) {
      throw Exception('Google 로그인 실패');
    }

    final authHeaders = await account.authHeaders;
    final httpClient = _GoogleAuthClient(authHeaders);
    return gcal.CalendarApi(httpClient);
  }

  // 선택된 날짜들을 Google Calendar에 종일 이벤트로 생성
  Future<void> _createEventsOnGoogleCalendar(Set<DateTime> dates) async {
    if (dates.isEmpty) return;
    try {
      final api = await _getCalendarApi();

      // 날짜 정렬(가독성)
      final sorted = dates.toList()
        ..sort((a, b) => a.compareTo(b));

      for (final d in sorted) {
        final startDate = DateTime(d.year, d.month, d.day);
        final endDate = startDate.add(const Duration(days: 1)); // 종일 이벤트는 end가 다음날

        final event = gcal.Event(
          summary: "학습 예정",
          description: "Flutter 달력에서 선택한 학습일",
          start: gcal.EventDateTime(date: DateTime(startDate.year, startDate.month, startDate.day)),
          end: gcal.EventDateTime(date: DateTime(endDate.year, endDate.month, endDate.day)),
        );

        await api.events.insert(event, "primary");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Google 캘린더에 학습일을 등록했습니다.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("캘린더 등록 실패: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastPicked = _picked;
    return Scaffold(
      appBar: AppBar(title: const Text('달력 데모')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CalendarScreen(
              initialDate: DateTime.now(),
              onDateSelected: (date, allSelected) async{
                await saveStudyDates(allSelected);
                setState(() {
                  _picked = date;
                  _selectedDates = allSelected;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              lastPicked != null
                  ? '선택됨: ${lastPicked.year}년 ${lastPicked.month}월 ${lastPicked.day}일'
                  : '날짜를 선택하세요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_selectedDates.isNotEmpty)
              Text(
                '총 ${_selectedDates.length}일 선택됨',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedDates.isEmpty
                    ? null
                    : () async {
                  await _createEventsOnGoogleCalendar(_selectedDates);
                },
                icon: const Icon(Icons.event_available),
                label: const Text('학습일 설정'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// OAuth 헤더 기반 http.Client
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._headers);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    this.initialDate,
    this.onDateSelected,
    this.locale = 'ko_KR',
  });

  final DateTime? initialDate;
  final void Function(DateTime selectedOne, Set<DateTime> allSelected)? onDateSelected;
  final String locale;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentDate; // 달력의 현재 year/month 기준
  late DateTime _today;       // 오늘
  Set<DateTime> _selectedDates = {};    // 다중 선택
//토글해제시 알람해제

//endregion

  final List<String> _months = const [
    '1월','2월','3월','4월','5월','6월','7월','8월','9월','10월','11월','12월'
  ];
  final List<String> _days = const ['일','월','화','수','목','금','토'];

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentDate = DateTime(
      (widget.initialDate ?? _today).year,
      (widget.initialDate ?? _today).month,
      1,
    );
    if (widget.initialDate != null) {
      _selectedDates = {_normalize(widget.initialDate!)};
    }
    Intl.defaultLocale = widget.locale;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _navigateMonth(bool next) {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + (next ? 1 : -1), 1);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSelected(DateTime d) {
    final nd = _normalize(d);
    return _selectedDates.any((e) => _isSameDay(e, nd));
  }

  void _toggleSelect(DateTime d) {
    final nd = _normalize(d);
    final exists = _selectedDates.any((e) => _isSameDay(e, nd));
    setState(() {
      if (exists) {
        _selectedDates.removeWhere((e) => _isSameDay(e, nd));
      } else {
        _selectedDates.add(nd);
      }
    });
    widget.onDateSelected?.call(nd, _selectedDates);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = _currentDate.year;
    final month = _currentDate.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 일:0, 월:1 ... 토:6
    final daysInMonth = lastDayOfMonth.day;

    final prevMonthLastDay = DateTime(year, month, 0);
    final daysInPrevMonth = prevMonthLastDay.day;

    final List<_DayCell> cells = [];

    for (int i = firstWeekday - 1; i >= 0; i--) {
      final day = daysInPrevMonth - i;
      final date = DateTime(year, month - 1, day);
      cells.add(_DayCell(date: date, isCurrentMonth: false));
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(year, month, d);
      cells.add(_DayCell(date: date, isCurrentMonth: true));
    }

    final remaining = 42 - cells.length;
    for (int d = 1; d <= remaining; d++) {
      final date = DateTime(year, month + 1, d);
      cells.add(_DayCell(date: date, isCurrentMonth: false));
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: kElevationToShadow[1],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _iconButton(
                context,
                icon: Icons.chevron_left,
                onTap: () => _navigateMonth(false),
              ),
              Text(
                '$year년 ${_months[month - 1]}',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              _iconButton(
                context,
                icon: Icons.chevron_right,
                onTap: () => _navigateMonth(true),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 요일 헤더
          Row(
            children: List.generate(7, (index) {
              final isSun = index == 0;
              final isSat = index == 6;
              final color = isSun
                  ? Colors.red
                  : isSat
                  ? Colors.blue
                  : theme.colorScheme.onSurface.withOpacity(0.6);
              return Expanded(
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  child: Text(
                    _days[index],
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // 그리드
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 6) / 7; // gap 보정
              return Wrap(
                spacing: 1,
                runSpacing: 1,
                children: cells.map((c) {
                  final isToday = _isSameDay(_normalize(c.date), _normalize(_today));
                  final isSelected = _isSelected(c.date);

                  Color fg;
                  BoxDecoration? deco;

                  if (isSelected) {
                    deco = BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    );
                    fg = theme.colorScheme.onPrimary;
                  } else if (isToday && c.isCurrentMonth) {
                    deco = BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.primary),
                    );
                    fg = theme.colorScheme.onSurface;
                  } else {
                    deco = BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    );
                    fg = c.isCurrentMonth
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.4);
                  }

                  return GestureDetector(
                    onTap: () => _toggleSelect(c.date),
                    child: Container(
                      width: cellWidth,
                      height: 40,
                      decoration: deco,
                      alignment: Alignment.center,
                      child: Text(
                        '${c.date.day}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: fg,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          // 안내 문구
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            alignment: Alignment.center,
            child: Text(
              '학습 예정인 날짜를 여러 개 선택할 수 있어요',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      splashRadius: 18,
      tooltip: 'navigate',
    );
  }
}

class _DayCell {
  final DateTime date;
  final bool isCurrentMonth;
  _DayCell({required this.date, required this.isCurrentMonth});
}




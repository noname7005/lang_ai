import 'package:flutter/material.dart';
import 'package:lang_ai/screens/calender_screen.dart';


class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    // 원본 dashboard.txt의 props 대체용 더미 데이터
    final stats = DashboardStats(
      totalCourses: 10,
      completedCourses: 7,
      totalStudyTime: "15시간",
      streak: 5,
      averageScore: 88,
      badges: ["기초 영어 마스터", "단어 마스터"],
    );

    final recentActivity = [
      RecentActivityItem(
        id: '1',
        type: 'course',
        title: '기초 영어 회화',
        date: '2025-08-05',
      ),
      RecentActivityItem(
        id: '2',
        type: 'quiz',
        title: '단어 암기',
        date: '2025-08-06',
        score: 92,
      ),
      RecentActivityItem(
        id: '3',
        type: 'lesson',
        title: '실생활 영어 테스트',
        date: '2025-08-07',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Dashboard(stats: stats, recentActivity: recentActivity),
      ),
    );
  }
}

// ---------------- 데이터 모델 ----------------
class DashboardStats {
  final int totalCourses;
  final int completedCourses;
  final String totalStudyTime;
  final int streak;
  final int averageScore;
  final List<String> badges;
  DashboardStats({
    required this.totalCourses,
    required this.completedCourses,
    required this.totalStudyTime,
    required this.streak,
    required this.averageScore,
    required this.badges,
  });
}

class RecentActivityItem {
  final String id;
  final String type; // 'course', 'quiz', 'lesson'
  final String title;
  final String date;
  final int? score;
  RecentActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.score,
  });
}

// ---------------- Dashboard 위젯 ----------------
class Dashboard extends StatelessWidget {
  final DashboardStats stats;
  final List<RecentActivityItem> recentActivity;

  const Dashboard({
    super.key,
    required this.stats,
    required this.recentActivity,
  });

  @override
  Widget build(BuildContext context) {
    final completionRate =
    ((stats.completedCourses / stats.totalCourses) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== 통계 카드 =====
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _statCard(
              title: '완료한 코스',
              value: '${stats.completedCourses}',
              subtitle: '총 ${stats.totalCourses}개 중',
              colors: [Colors.blue, Colors.indigo],
              icon: Icons.menu_book,
              progress: completionRate / 100,
            ),
            _statCard(
              title: '학습 시간',
              value: stats.totalStudyTime,
              subtitle: '이번 주 학습량',
              colors: [Colors.green, Colors.teal],
              icon: Icons.access_time,
            ),
            _statCard(
              title: '학습 캘린더',
              value: '${stats.streak}일',
              subtitle: '다음 학습일',
              colors: [Colors.purple, Colors.pink],
              icon: Icons.calendar_today,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarScreen()),
                );
              },
            ),
            _statCard(
              title: '평균 점수',
              value: '${stats.averageScore}%',
              subtitle: '퀴즈 평균 점수',
              colors: [Colors.orange, Colors.red],
              icon: Icons.track_changes,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ===== 최근 활동 + 배지 =====
        Column(
          children: [
            _recentActivityCard(recentActivity),
            const SizedBox(height: 16),
            _badgesCard(stats.badges),
          ],
        ),

      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required List<Color> colors,
    required IconData icon,
    double? progress,
    VoidCallback? onTap, // 추가
  }) {
    final cardContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              Icon(icon, color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  minHeight: 6,
                ),
              ),
            ),
        ],
      ),
    );

    // onTap이 있을 경우 래핑
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: cardContent,
      );
    } else {
      return cardContent;
    }
  }

  Widget _recentActivityCard(List<RecentActivityItem> activities) {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                SizedBox(width: 8),
                Text('최근 활동',
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...activities.map((a) {
              Color dotStart;
              Color dotEnd;
              if (a.type == 'course') {
                dotStart = Colors.blue;
                dotEnd = Colors.indigo;
              } else if (a.type == 'quiz') {
                dotStart = Colors.green;
                dotEnd = Colors.teal;
              } else {
                dotStart = Colors.orange;
                dotEnd = Colors.red;
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [dotStart, dotEnd],
                            ),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(a.date,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                    if (a.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: a.score! >= 80
                                  ? [Colors.green, Colors.teal]
                                  : [Colors.grey, Colors.grey.shade600]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${a.score}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _badgesCard(List<String> badges) {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.emoji_events, color: Colors.orange),
                const SizedBox(height: 8),
                const Text(
                  '획득한 배지',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),
            if (badges.isEmpty)
              const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('아직 획득한 배지가 없습니다.'),
                  )),
            ...badges.map((badge) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.orange.shade50,
                        blurRadius: 3,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.orange, Colors.deepOrange],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(badge,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

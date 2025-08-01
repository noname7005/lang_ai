import 'package:flutter/material.dart';

class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '메인 통계 등 현황 전시',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

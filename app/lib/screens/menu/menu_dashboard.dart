import 'package:app/meta/app_theme.dart';
import 'package:app/screens/menu/page_detail.dart';
import 'package:flutter/material.dart';

import '../../data/run_record.dart';



/// 2. 대시보드 메인 메뉴 (불필요한 State 제거 -> StatelessWidget 변경)
class DashboardMenu extends StatelessWidget {
  const DashboardMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        RunHistoryWidget(),
      ],
    );
  }
}

/// 3. 러닝 히스토리 섹션 위젯
class RunHistoryWidget extends StatefulWidget {
  const RunHistoryWidget({super.key});

  @override
  State<RunHistoryWidget> createState() => _RunHistoryWidgetState();
}

class _RunHistoryWidgetState extends State<RunHistoryWidget> {
  // 더미 데이터 목록
  final List<RunRecord> _records = [
    RunRecord(
      distance: 5.2,
      time: const Duration(minutes: 24, seconds: 32),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: const Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: const Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
  ];

  void addRecord(RunRecord record) {
    setState(() {
      _records.insert(0, record);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.midTitle(" 러닝 기록"),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final record = _records[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RunRecordCard(
                record: record,
                onTap: () => _navigateToDetail(context, record),
              ),
            );
          },
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, RunRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RunDetailPage(record: record),
      ),
    );
  }
}

/// 4. 러닝 기록 개별 카드 컴포넌트 (가독성의 핵심)
class RunRecordCard extends StatelessWidget {
  final RunRecord record;
  final VoidCallback onTap;

  const RunRecordCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes분 $seconds초';
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE8FFFA),
        foregroundColor: const Color(0xFF1E293B),
        padding: const EdgeInsets.all(20),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: onTap,
      child: Row(
        children: [
          const Icon(
            Icons.directions_run,
            size: 32,
            color: Color(0xFF00C7BE),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.distance} km',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDuration(record.time),
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // 날짜 표시 추가
          Text(
            _formatDate(record.date),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../meta/app_theme.dart';


class RecordListView extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> recordsFuture;
  final Future<void> Function() onRefresh;
  final Future<void> Function(dynamic id) onDelete;
  final void Function(Map<String, dynamic> record) onTap;

  const RecordListView({
    super.key,
    required this.recordsFuture,
    required this.onRefresh,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: recordsFuture,
      builder: (context, snapshot) {
        // 데이터 로딩 중
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // 에러 발생
        if (snapshot.hasError) {
          return Center(
            child: Text(
              '기록을 불러오는 중 오류가 발생했습니다.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final records = snapshot.data ?? [];

        // 기록이 없는 경우
        if (records.isEmpty) {
          return const Center(
            child: Text(
              '저장된 러닝 기록이 없습니다.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          );
        }

        // 기록 목록
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];

              return RecordTile(
                record: record,
                onDelete: () => onDelete(record['id']),
                onTap: () => onTap(record),
              );
            },
          ),
        );
      },
    );
  }
}


/// 러닝 기록 목록 개별 아이템 카드 위젯
class RecordTile extends StatelessWidget {
  final Map<String, dynamic> record;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const RecordTile({
    super.key,
    required this.record,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final recordId = record['id'];
    final dateStr = record['createdAt']?.toString() ?? '날짜 정보 없음';
    final rawDistance = record['distanceKm'];
    final distanceStr = rawDistance != null
        ? '${(rawDistance as num).toStringAsFixed(2)} km'
        : '0.00 km';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.directions_run, color: Colors.black),
        ),
        title: Text(
          distanceStr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          dateStr,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: '삭제',
              onPressed: recordId != null ? onDelete : null,
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
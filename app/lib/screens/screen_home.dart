import 'package:app/data/DataController.dart';
import 'package:app/meta/app_theme.dart';
import 'package:app/screens/menu/menu.dart';
import 'package:app/screens/menu/screen_record.dart';
import 'package:app/screens/setting_modal.dart';
import 'package:app/screens/utility/db_helper.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Map<String, dynamic>>> _recordsFuture;
  String? _username;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      animationDuration: const Duration(milliseconds: 500),
    );

    _loadUserInfo();
    _refreshData();

    // 탭 전환 완료 시 자동 새로고침
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final pref = Pref();
    try {
      final name = await pref.getData('username');
      if (mounted) setState(() => _username = name);
    } catch (_) {
      if (mounted) setState(() => _username = "Anonymous");
    }
  }

  void _refreshData() {
    setState(() {
      _recordsFuture = DBHelper.getRecords();
    });
  }

  Future<void> _deleteRecord(dynamic id) async {
    await DBHelper.deleteRecord(id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('러닝 기록이 삭제되었습니다.')),
    );
    _refreshData();
  }

  void _confirmDelete(dynamic id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 러닝 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteRecord(id);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openSettingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. 상단 헤더 분리
            HomeHeader(
              username: _username,
              onSettingPressed: _openSettingModal,
            ),
            // 2. 탭 바
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryColor,
              dividerColor: Colors.transparent,
              indicatorWeight: 5,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: "대시 보드"),
                Tab(text: "러닝"),
              ],
            ),
            // 3. 탭 뷰 영역
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecordListView(),
                  const ExerciseMenu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 대시보드 (최근 러닝 기록) 리스트 뷰
  Widget _buildRecordListView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _recordsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final records = snapshot.data ?? [];
        if (records.isEmpty) {
          return const Center(
            child: Text(
              '저장된 러닝 기록이 없습니다.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return RecordTile(
                record: record,
                onDelete: () => _confirmDelete(record['id']),
                onTap: () => _navigateToDetail(record),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('러닝 상세 기록'),
            backgroundColor: AppTheme.primaryColor,
          ),
          body: RecordDetailTab(record: record),
        ),
      ),
    );
  }
}

// =============================================================================
// 분리된 커스텀 위젯들
// =============================================================================

/// [1] 상단 헤더 위젯 (로고, 유저이름, 설정 버튼)
class HomeHeader extends StatelessWidget {
  final String? username;
  final VoidCallback onSettingPressed;

  const HomeHeader({
    super.key,
    required this.username,
    required this.onSettingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Image.asset('asset/img/WayRunning_text.png'),
          ),
          const Spacer(),
          // 유저 정보 버튼
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(80, 28),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: Text(
              '${username ?? "..."} 님',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 설정 아이콘 버튼
          IconButton(
            icon: Image.asset(
              'asset/img/wheel2.png',
              width: 28,
              height: 28,
            ),
            onPressed: onSettingPressed,
          ),
        ],
      ),
    );
  }
}

/// [2] 러닝 기록 목록 개별 아이템 카드 위젯
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
    final rawDistance = record['distance'];
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
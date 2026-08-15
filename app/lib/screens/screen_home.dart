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
    _recordsFuture = _loadRecords();


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
  /// shared preferences에서 사용자 기본정보 가져오는 함수
  Future<void> _loadUserInfo() async {
    final pref = Pref();
    try {
      final name = await pref.getData('username');
      if (mounted) setState(() => _username = name);
    } catch (_) {
      if (mounted) setState(() => _username = "Anonymous");
    }
  }

  /// DB 에 저장된 러닝 기록 다루는 함수
  Future<List<Map<String, dynamic>>> _loadRecords() async {
    return DBHelper.getRecords();
  }

  Future<void> _refreshData() async {
    setState(() {
      _recordsFuture = DBHelper.getRecords();
    });
    await _recordsFuture;
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
                  RecordListView(
                    recordsFuture: _recordsFuture,
                    onRefresh: _refreshData,
                    onDelete: _deleteRecord,
                    onTap: _navigateToDetail,
                  ),
                  const ExerciseMenu(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


}

// 위젯

/// 상단 헤더 위젯 (로고, 유저이름, 설정 버튼)
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


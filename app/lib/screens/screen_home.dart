import 'package:app/meta/app_theme.dart';
import 'package:app/screens/menu/screen_record.dart';
import 'package:app/screens/utility/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/menu/menu.dart';
import 'package:app/screens/setting_modal.dart';
import 'package:app/data/DataController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _recordsFuture;
  late TabController tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: 0,
      animationDuration: const Duration(milliseconds: 500));
  String? username;

  Future<void> loadUserInfo() async {
    Pref pref = Pref();
    late String name;
    try {
      name = await pref.getData('username');
    } catch (e) {
      name = "Anonymous";
    }
    setState(() {
      username = name;
    });
  }

  @override
  void initState() {
    super.initState();

    loadUserInfo();
    // 초기 데이터 로드
    _refreshData();

    // 💡 탭이 전환될 때마다 새로고침 실행
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        _refreshData();
      }
    });
  }

  void _refreshData() {
    setState(() {
      _recordsFuture = _fetchRecords();
    });
  }

  // 💡 DB에서 최근 정렬된 모든 러닝 기록 가져오기
  Future<List<Map<String, dynamic>>> _fetchRecords() async {
    final records = await DBHelper.getRecords();
    return records;
  }

  // 💡 DB 삭제 수행 메서드
  Future<void> _deleteRecord(dynamic id) async {
    // DBHelper에 있는 삭제 메서드 호출 (메서드명이 다를 경우 맞춰 수정하세요, 예: deleteRecord(id))
    await DBHelper.deleteRecord(id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('러닝 기록이 삭제되었습니다.')),
      );
    }

    // 삭제 후 목록 새로고침
    _refreshData();
  }

  // 💡 삭제 확인 다이얼로그 표시
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          children: [
            // 상단부
            _head(),
            // 탭 하위 항목들
            _tabBar(),
            Expanded(child: _tabBarView()),
            Container(height: 12, width: 1, color: Colors.transparent)
          ],
        ));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _tabBar() {
    return TabBar(
      controller: tabController,
      indicatorColor: AppTheme.primaryColor,
      dividerColor: Colors.transparent,
      indicatorWeight: 5,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: "대시 보드"),
        Tab(text: "러닝")
      ],
    );
  }

  Widget _tabBarView() {
    return TabBarView(
      controller: tabController,
      children: [
        // 1. 대시보드 탭: 최근 러닝 기록 리스트 뷰
        _buildRecordListView(),

        // 2. 러닝 탭
        ExerciseMenu(),
      ],
    );
  }

  // 최근 러닝 기록 리스트를 보여주는 위젯
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
          onRefresh: () async {
            _refreshData();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];

              // DB의 식별자 PK (id 컬럼명 확인 필요)
              final dynamic recordId = record['id'];
              final String dateStr = record['date']?.toString() ?? '날짜 정보 없음';
              final String distanceStr = record['distance'] != null
                  ? '${(record['distance'] as num).toStringAsFixed(2)} km'
                  : '0.00 km';

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  // 💡 오른쪽 영역: 삭제(쓰레기통) 아이콘 및 상세화면 이동 화살표
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: '삭제',
                        onPressed: () {
                          if (recordId != null) {
                            _confirmDelete(recordId);
                          }
                        },
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  // 아이템 클릭 시 지도/상세 경로 화면(RecordDetailTab)으로 이동
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: const Text('러닝 상세 기록'),
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          body: RecordDetailTab(record: record),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _head() {
    return Container(
        width: double.infinity,
        height: 55,
        margin: const EdgeInsets.only(top: 20, left: 5, right: 2),
        child: Row(
          children: [
            SizedBox(
                width: 120,
                height: 80,
                child: Image.asset('asset/img/WayRunning_text.png')),
            const Spacer(flex: 1),
            userInfoBtn(),
            iconBtn(0)
          ],
        ));
  }

  ElevatedButton userInfoBtn() {
    return ElevatedButton(
      onPressed: () {},
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        minimumSize: const Size(80, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: const StadiumBorder(),
      ),
      child: Text(
        '$username 님',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  IconButton iconBtn(int iconIdx) {
    var imgName = ['wheel2.png', 'note.png', 'glass.png'];
    var imgSize = [30.0, 30.0, 30.0];
    var path = "asset/img/${imgName[iconIdx]}";

    return IconButton(
      icon: Image.asset(path, width: imgSize[iconIdx], height: imgSize[iconIdx]),
      onPressed: () {
        if (iconIdx == 0) {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return SettingModal();
              });
        }
      },
    );
  }
}
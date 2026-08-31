import 'dart:async';
import 'package:app/screens/utility/audio_manager.dart';
import 'package:app/screens/utility/bluetooth_manager.dart';
import 'package:app/screens/utility/bluetooth_tracking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'utility/db_helper.dart';

// ======================
// 러닝 중 보여지는 스크린
// 기능 총 3가지
// 1. 블루투스 연결 상태 시각적확인 (정보량 표시)
// 2. 러닝 시간 타이머
// 3. 기록종료 버튼
// 4. 현재 위치
// 5. 경고 음성 장치 (스크린 표시는 아님)
// =====================
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  //블루투스 수신정보
  final List<RunningPacket> left = [], right = [];
  //GPS 정보
  final List<LatLng> _routePoints = [];
  Position? _currentPosition;

  //스탑워치용
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTracking();
    // 페이지 로드되자마자 바로 시작. 추후 변경될 수 있음
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100),(timer){
      if(mounted){
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  /// GPS 추적 시작 및 권한 체크
  Future<void> _startTracking() async {
    // 1. 위치 권한 확인
    final status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) {
        _showSnackBar('위치 권한이 필요합니다.');
        Navigator.pop(context);
      }
      return;
    }

    // GPS 서비스 활성화 여부 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showSnackBar('GPS를 활성화해 주세요.');
      }
      return;
    }

    // 위치 수신 스트림 구독 (3m 이동 시 갱신)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
          if (!mounted) return;
          setState(() {
            _currentPosition = position;
            _routePoints.add(LatLng(position.latitude, position.longitude));
          });
        });
  }

  /// Tracking 종료 및 지도 결과 화면으로 이동
  void _stopTracking() {
    _positionStreamSubscription?.cancel();

    if (_routePoints.isEmpty) {
      _showSnackBar('수신된 위치 데이터가 없습니다.');
      Navigator.pop(context);
      return;
    }
    // 시간 계산
    _timer?.cancel();
    _stopwatch.stop();
    int runningTime = _stopwatch.elapsedMilliseconds ~/ 1000;
    // 결과 화면으로 이동하며 현 화면 교체
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapResultScreen(
          runningTime: runningTime,
          routePoints: _routePoints,
          left: left,
          right: right,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  //스탑워치 위젯
  Widget _buildStopwatch(){
    // 경과 시간을 분, 초, 1/10초로 계산
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundreds = (elapsed.inMilliseconds.remainder(1000) ~/ 100)
        .toString(); // 0.1초 단위

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.black87, size: 24),
          const SizedBox(width: 8),
          Text(
            '$minutes:$seconds.$hundreds',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()], // 숫자가 변해도 너비 고정
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Running')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStopwatch(),
            const SizedBox(height: 24),
            const Text(
              'GPS가 가동 중입니다...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '수신된 좌표 수: ${_routePoints.length}개',
              style: const TextStyle(fontSize: 16),
            ),
            if (_currentPosition != null) ...[
              const SizedBox(height: 8),
              Text(
                '현재 위치: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                    '${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _stopTracking,
              icon: const Icon(Icons.stop),
              label: const Text('기록 종료 및 지도 보기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),

            // 블루투스 모니터링 위젯. 모니터링 뿐만 아니라 데이터 저장/계산도 수행함
            RunningMonitor(left: left,right : right),

            // 음성 장치 디버깅용 버튼 위젯 (추후 삭제필요)

            ElevatedButton(
                onPressed: (){
                  AudioManager.instance.playSoundWarningBoth();
                }, child: null,
            ),

          ],
        ),
      ),
    );
  }
}





// ================================
// 2. flutter_map 기반 지도 결과 화면
// ================================
class MapResultScreen extends StatelessWidget {
  final List<LatLng> routePoints;
  final List<RunningPacket> left, right;
  final int runningTime;

  const MapResultScreen({
    super.key,
    required this.routePoints,
    required this.left,
    required this.right,
    required this.runningTime,
  });

  Future<void> _handleSaveRecord(BuildContext context) async {
    final recordId = await saveTrackingDataToDB(runningTime,routePoints,left,right);

    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (recordId > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('러닝 기록이 성공적으로 저장되었습니다! (ID: $recordId)'),
        ),
      );
      Navigator.pop(context); // 저장 후 메인 화면으로 돌아가기
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('저장할 위치 데이터가 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (routePoints.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('러닝 경로')),
        body: const Center(child: Text('표시할 이동 경로가 없습니다.')),
      );
    }

    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    return Scaffold(
      appBar: AppBar(title: const Text('러닝 경로')),
      body: Column(
        children: [
          // 1. 지도 영역
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: startPoint,
                initialZoom: 16.0,
              ),
              children: [
                // 배경 지도 타일
                TileLayer(
                  urlTemplate:
                  'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'io.github.quizoverflow',
                ),
                // 이동 경로 선
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                // 출발 / 도착 지점 마커
                MarkerLayer(
                  markers: [
                    Marker(
                      point: startPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 40,
                      ),
                    ),
                    Marker(
                      point: endPoint,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 2. 하단 저장 버튼
          _SaveBottomBar(onSave: () => _handleSaveRecord(context)),
        ],
      ),
    );
  }
}

/// 하단 '기록 저장하기' 영역 바
class _SaveBottomBar extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveBottomBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_alt),
            label: const Text(
              '기록 저장하기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================
// 3. 비즈니스 로직 (거리 계산 및 DB 저장)
// ===================================

/// GPS 좌표 목록으로 총 거리를 계산한 후 DB에 저장
Future<int> saveTrackingDataToDB(
    int runningTime,
    List<LatLng> routePoints,
    List<RunningPacket> left,
    List<RunningPacket> right) async {

  // ======== 먼저 경로 길이 계산 =====
  if (routePoints.isEmpty) return -1;
  double totalDistanceInMeters = 0.0;
  // 총 이동 거리 계산 (Haversine formula 기반)
  for (int i = 0; i < routePoints.length - 1; i++) {
    final start = routePoints[i];
    final end = routePoints[i + 1];
    totalDistanceInMeters += Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
  // km 단위 변환 (소수점 2자리)
  final distanceInKm = double.parse(
    (totalDistanceInMeters / 1000).toStringAsFixed(2),
  );

  // 좌표 데이터 JSON 구조화
  final pathData = routePoints
      .map((point) => {'lat': point.latitude, 'lng': point.longitude})
      .toList();
  // ======= 블루투스 수신 정보 left, right 평균화 =====
  // 두 데이터의 수신 정보 차이가 더 많은 쪽의 데이터 사이즈 * 0.5 보다 크면 계산을 취소
  List<RunningPacket> avg = [];
  List<double> balance = [];
  final List<RunningPacket> longer,shorter;
  if(left.length >= right.length){
    longer = left; shorter = right;
  }
  else{
    longer = right; shorter = left;
  }
  if((left.length - right.length).abs() < 0.5 * longer.length){
    int indexLong = 0 , indexShort = 0;
    while(indexLong < longer.length && indexShort < shorter.length){
      int packetNumLong = longer[indexLong].packetNumber;
      int packetNumShort = shorter[indexShort].packetNumber;
      // 패킷넘버 같으면 삽입
      if(packetNumShort == packetNumLong){
        avg.add(longer[indexLong].getAvg(shorter[indexShort]));
        balance.add(longer[indexLong].getBalanceScore(shorter[indexShort]));
        indexLong++;
        indexShort++;
      }
      else if(packetNumShort > packetNumLong){
        indexLong++;
      }
      else if(packetNumLong > packetNumShort){
        indexShort++;
      }
    }
  }
  else{
    avg = longer;
  }

  // DB에 저장
  return await DBHelper.insertRecord(
    runningTime: runningTime,
    distanceKm: distanceInKm,
    pointCount: routePoints.length,
    pathData: pathData,
    impactData: avg.map((packet) => packet.impact).toList(),
    cadenceData: avg.map((packet) => packet.cadence).toList(),
    groundTimeData: avg.map((packet) => packet.groundTime).toList(),
    balanceData: balance,
  );
}
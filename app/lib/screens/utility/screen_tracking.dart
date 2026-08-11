import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'db_helper.dart';

// =============================================================================
// 1. GPS 가동 화면 (위치 추적 화면)
// =============================================================================
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
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

    // 2. GPS 서비스 활성화 여부 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showSnackBar('GPS를 활성화해 주세요.');
      }
      return;
    }

    // 3. 위치 수신 스트림 구독 (5m 이동 시 갱신)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
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

    // 결과 화면으로 이동하며 현 화면 교체
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MapResultScreen(routePoints: _routePoints),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GPS 위치 추적 중')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
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
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. flutter_map 기반 지도 결과 화면
// =============================================================================
class MapResultScreen extends StatelessWidget {
  final List<LatLng> routePoints;

  const MapResultScreen({super.key, required this.routePoints});

  Future<void> _handleSaveRecord(BuildContext context) async {
    final recordId = await saveTrackingDataToDB(routePoints);

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

// =============================================================================
// 3. 비즈니스 로직 (거리 계산 및 DB 저장)
// =============================================================================

/// GPS 좌표 목록으로 총 거리를 계산한 후 DB에 저장
Future<int> saveTrackingDataToDB(List<LatLng> routePoints) async {
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

  // DB에 저장
  return await DBHelper.insertRecord(
    distanceKm: distanceInKm,
    pointCount: routePoints.length,
    pathData: pathData,
  );
}
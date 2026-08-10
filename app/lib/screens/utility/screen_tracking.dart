import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import 'db_helper.dart';

// -------------------------------------------------------------
// 1. GPS 가동 화면 (기록 화면)
// -------------------------------------------------------------
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _routePoints = [];
  bool _isTracking = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    // 1. 위치 권한 확인
    var status = await Permission.location.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치 권한이 필요합니다.')));
        Navigator.pop(context);
      }
      return;
    }

    // 2. GPS 서비스 활성화 여부 확인
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('GPS를 활성화해 주세요.')));
      }
      return;
    }

    setState(() {
      _isTracking = true;
    });

    // 3. 위치 수신 스트림 구독 (5m 이동 시 갱신)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            setState(() {
              _currentPosition = position;
              _routePoints.add(LatLng(position.latitude, position.longitude));
            });
          },
        );
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isTracking = false;
    });

    if (_routePoints.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('수신된 위치 데이터가 없습니다.')));
      Navigator.pop(context);
      return;
    }

    // 결과 화면으로 좌표 목록 전달
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MapResultScreen(routePoints: _routePoints),
      ),
    );
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
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

// -------------------------------------------------------------
// 2. flutter_map 기반 지도 결과 화면
// -------------------------------------------------------------
class MapResultScreen extends StatelessWidget {
  final List<LatLng> routePoints;

  const MapResultScreen({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    // 경로 전체를 한눈에 볼 수 있도록 바운더리(영역) 계산
    final bounds = LatLngBounds.fromPoints(routePoints);

    return Scaffold(
      appBar: AppBar(title: const Text('러닝 경로')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                // 수신된 경로 전체에 맞추어 카메라 영역 자동 설정
                initialCenter: startPoint,
                initialZoom: 16.0,
              ),
              children: [
                // 1.배경 지도 타일 레이어
                TileLayer(
                  urlTemplate:
                      'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                  userAgentPackageName: 'io.github.quizoverflow',
                ),

                // 2. 이동 경로 선 레이어
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blue,
                    ),
                  ],
                ),

                // 3. 출발 / 도착 지점 마커 레이어
                MarkerLayer(
                  markers: [
                    // 출발지 마커
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
                    // 도착지 마커
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
          // 2. 하단 '기록 저장하기' 버튼 영역
          Container(
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
                  onPressed: () async {
                    // DB 저장 실행
                    int recordId = await saveTrackingDataToDB(routePoints);

                    if (context.mounted) {
                      if (recordId > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '러닝 기록이 DB에 성공적으로 저장되었습니다! (ID: $recordId)',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('저장할 위치 데이터가 없습니다.')),
                        );
                      }
                    }
                  }, // 전달받은 동작 수행
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
          ),
        ],
      ),
    );
  }
}

/// GPS 계산 후 sqflite DB에 저장하는 함수
Future<int> saveTrackingDataToDB(List<LatLng> routePoints) async {
  if (routePoints.isEmpty) return -1;

  double totalDistanceInMeters = 0.0;

  // 1. 총 이동 거리 계산
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

  // 2. km 단위 변환 (소수점 2자리)
  double distanceInKm = double.parse(
    (totalDistanceInMeters / 1000).toStringAsFixed(2),
  );

  // 3. 좌표 데이터 구조화
  List<Map<String, double>> pathData = routePoints.map((point) {
    return {'lat': point.latitude, 'lng': point.longitude};
  }).toList();

  // 4. sqflite DB에 저장 실행
  int savedId = await DBHelper.insertRecord(
    distanceKm: distanceInKm,
    pointCount: routePoints.length,
    pathData: pathData,
  );

  return savedId; // 저장된 행(Row)의 ID 반환
}

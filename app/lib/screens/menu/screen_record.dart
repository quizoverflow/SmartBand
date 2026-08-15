/*
러닝 기록 보여주는 스크린

 */


import 'dart:convert';
import 'package:app/screens/menu/screen_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RecordDetailTab extends StatelessWidget {
  final Map<String, dynamic> record;

  const RecordDetailTab({super.key, required this.record});

  /// 데이터 파싱 로직을 별도 메서드로 추출 (build 메서드 명확화)
  List<LatLng> _parseRoutePoints(String pathJsonStr) {
    final List<dynamic> pathJson = jsonDecode(pathJsonStr);
    return pathJson.map((point) {
      return LatLng(
        (point['lat'] as num).toDouble(),
        (point['lng'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = _parseRoutePoints(record['pathJson']);
    if (routePoints.isEmpty) {
      return const Center(child: Text('경로 데이터가 없습니다.'));
    }

    return Column(
      children: [
        // 1. 지도 영역 분리
        Expanded(
          child: RecordMapView(routePoints: routePoints),
        ),
        // 2. 하단 요약 정보 영역 분리
        RecordSummaryView(
          distanceKm: record['distanceKm']?.toString() ?? '0',
          pointCount: record['pointCount']?.toString() ?? '0',
          record: record,
        ),
      ],
    );
  }
}

/// 지도 관련 UI를 담당하는 위젯
class RecordMapView extends StatelessWidget {
  final List<LatLng> routePoints;

  const RecordMapView({super.key, required this.routePoints});

  @override
  Widget build(BuildContext context) {
    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    return FlutterMap(
      options: MapOptions(
        initialCenter: startPoint,
        initialZoom: 16.0,
      ),
      children: [
        TileLayer(
          urlTemplate:
          'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'io.github.quizoverflow',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: routePoints,
              strokeWidth: 5.0,
              color: Colors.blue,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            LocationMarker(point: startPoint, color: Colors.green),
            LocationMarker(point: endPoint, color: Colors.red),
          ],
        ),
      ],
    );
  }
}

/// 출발/도착 마커 아이콘 위젯 (중복 제거)
class LocationMarker extends Marker {
  LocationMarker({
    super.key,
    required LatLng point,
    required Color color,
  }) : super(
    point: point,
    width: 40,
    height: 40,
    child: Icon(
      Icons.location_on,
      color: color,
      size: 40,
    ),
  );
}

/// 하단 요약 정보 전체 패널 위젯
class RecordSummaryView extends StatelessWidget {
  final String distanceKm;
  final String pointCount;
  final Map<String,dynamic> record;

  const RecordSummaryView({
    super.key,
    required this.distanceKm,
    required this.pointCount,
    required this.record
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          SummaryItem(title: '총 이동 거리', value: '$distanceKm km'),
          SummaryItem(title: '수신 좌표 수', value: '$pointCount 개'),
          ElevatedButton(
              onPressed:(){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailScreen(record: record))
                );
              },
              child: Text("분석하기"))
        ],
      ),
    );
  }
}

/// 요약 정보의 각 항목(제목 + 값) 컴포넌트
class SummaryItem extends StatelessWidget {
  final String title;
  final String value;

  const SummaryItem({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

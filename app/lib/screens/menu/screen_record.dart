import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RecordDetailTab extends StatelessWidget {
  final Map<String, dynamic> record;

  const RecordDetailTab({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    // DB의 JSON 문자열 좌표 목록을 List<LatLng> 형태로 파싱
    final List<dynamic> pathJson = jsonDecode(record['pathJson']);
    final List<LatLng> routePoints = pathJson.map((point) {
      return LatLng(
        (point['lat'] as num).toDouble(),
        (point['lng'] as num).toDouble(),
      );
    }).toList();

    final startPoint = routePoints.first;
    final endPoint = routePoints.last;

    // TabBarView 내부용이므로 Scaffold/AppBar를 제거하고 Column으로 구성
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
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
        // 하단 요약 정보
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('총 이동 거리', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '${record['distanceKm']} km',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('수신 좌표 수', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '${record['pointCount']} 개',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
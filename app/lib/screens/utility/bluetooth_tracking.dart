import 'dart:async';

import 'package:flutter/material.dart';
import 'bluetooth_manager.dart';

class RunningMonitor extends StatefulWidget {
  // 좌우 러닝 정보 (블루투스 수신정보)
  final List<RunningPacket> left;
  final List<RunningPacket> right;

  RunningMonitor({
    super.key,
    required this.left,
    required this.right,
  });

  final BluetoothManager btManager = BluetoothManager();

  final Stream<String> leftStream = BluetoothManager().dataStream1;
  final Stream<String> rightStream = BluetoothManager().dataStream2;

  @override
  State<RunningMonitor> createState() => _RunningMonitorState();
}

class _RunningMonitorState extends State<RunningMonitor> {

  String _leftBuffer = '';
  String _rightBuffer = '';

  // StreamSubscription
  StreamSubscription<String>? _leftSubscription;
  StreamSubscription<String>? _rightSubscription;

  // 현재 화면에 표시할 최신 데이터
  RunningPacket? _leftPacket;
  RunningPacket? _rightPacket;


  @override
  void initState() {
    super.initState();

    _startBluetoothStreams();
  }

  void _startBluetoothStreams() {
    _leftSubscription = widget.leftStream.listen(
          (data) {
        _receiveLeftData(data);
      },
      onError: (error) {
        debugPrint('왼쪽 BLE 오류: $error');
      },
    );

    _rightSubscription = widget.rightStream.listen(
          (data) {
        _receiveRightData(data);
      },
      onError: (error) {
        debugPrint('오른쪽 BLE 오류: $error');
      },
    );
  }

  // ============================================================
  // 왼쪽 기기 데이터
  // ============================================================

  void _receiveLeftData(String data) {
    _leftBuffer += data;

    while (_leftBuffer.contains('\n')) {
      final index = _leftBuffer.indexOf('\n');

      final line = _leftBuffer.substring(0, index).trim();

      _leftBuffer = _leftBuffer.substring(index + 1);

      if (line.isEmpty) {
        continue;
      }

      // 문자열에서 패킷 파싱
      final packet = _parsePacket(line);

      if (packet == null) {
        continue;
      }

      // 최신 데이터 갱신
      setState(() {
        _leftPacket = packet;
      });

      // 리스트에 저장
      widget.left.add(packet);
    }
  }

  // ============================================================
  // 오른쪽 기기 데이터
  // ============================================================

  void _receiveRightData(String data) {
    _rightBuffer += data;

    while (_rightBuffer.contains('\n')) {
      final index = _rightBuffer.indexOf('\n');

      final line = _rightBuffer.substring(0, index).trim();

      _rightBuffer = _rightBuffer.substring(index + 1);

      if (line.isEmpty) {
        continue;
      }

      final packet = _parsePacket(line);

      if (packet == null) {
        continue;
      }

      // 최신 데이터 갱신
      setState(() {
        _rightPacket = packet;
      });

      // 리스트에 저장
      widget.right.add(packet);
    }
  }

  // ============================================================
  // 패킷 파싱
  // ============================================================

  RunningPacket? _parsePacket(String data) {
    try {
      final values = data.split(',');

      if (values.length != 5) {
        debugPrint('잘못된 패킷: $data');
        return null;
      }

      return RunningPacket(
        packetNumber: int.parse(values[0].trim()),
        peak: double.parse(values[1].trim()),
        cadence: double.parse(values[2].trim()),
        impact: double.parse(values[3].trim()),
        groundTime: double.parse(values[4].trim()),
      );
    } catch (e) {
      debugPrint('패킷 파싱 오류: $data / $e');
      return null;
    }
  }

  @override
  void dispose() {
    _leftSubscription?.cancel();
    _rightSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
           Row(
            children: [
              Expanded(
                child: _buildDeviceCard(
                  title: 'LEFT',
                  packet: _leftPacket,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _buildDeviceCard(
                  title: 'RIGHT',
                  packet: _rightPacket,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required RunningPacket? packet,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            if (packet == null)
              const Center(
                child: Text('데이터 수신 대기 중...'),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildValue('Peak', packet.peak),
                  _buildValue('Cadence', packet.cadence),
                  _buildValue('Impact', packet.impact),
                  _buildValue('Ground Time', packet.groundTime),
                  _buildValue(
                    'Packet',
                    packet.packetNumber,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildValue(String title, num value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';
import 'bluetooth_manager.dart'; // 싱글톤 파일 임포트

class BluetoothPermissionScreen extends StatefulWidget {
  const BluetoothPermissionScreen({super.key});

  @override
  State<BluetoothPermissionScreen> createState() => _BluetoothPermissionScreenState();
}

class _BluetoothPermissionScreenState extends State<BluetoothPermissionScreen> {
  final _btManager = BluetoothManager();

  final List<BluetoothDevice> _scanResults = [];
  StreamSubscription<BluetoothDevice>? _scanSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanSubscription = _btManager.plugin.scanResults.listen((device) {
      debugPrint('🔍 [기기 발견] 이름: ${device.name ?? "이름없음"}, 주소: ${device.address}');
      setState(() {
        if (!_scanResults.any((element) => element.address == device.address)) {
          _scanResults.add(device);
        }
      });
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _btManager.plugin.stopScan();
    super.dispose();
  }

  void _startScan() async {
    bool? isBluetoothOn = await _btManager.plugin.isEnabled;
    if (isBluetoothOn != true) {
      _showMessage("스마트폰의 블루투스를 켜주세요.");
      return;
    }

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });

    debugPrint('📡 startScan() 호출됨 - 주변 기기를 찾는 중...');
    _btManager.plugin.startScan();

    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _btManager.plugin.stopScan();
        setState(() {
          _isScanning = false;
        });
        debugPrint('⏹️ 10초 타임아웃으로 스캔 자동 종료');
      }
    });
  }

  void _showMessage(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _pairDevice(BluetoothDevice device) async {
    _btManager.plugin.stopScan();
    if (mounted) setState(() => _isScanning = false);

    // 1번 기기 미연결 시
    if (_btManager.device1 == null) {
      bool success = await _btManager.connectDevice(device, 1);
      _showMessage(success ? 'HC-06 #1 연결 성공' : 'HC-06 #1 연결 실패');
      if (mounted) setState(() {});
      return;
    }

    // 2번 기기 미연결 시
    if (_btManager.device2 == null) {
      bool success = await _btManager.connectDevice(device, 2);
      _showMessage(success ? 'HC-06 #2 연결 성공' : 'HC-06 #2 연결 실패');
      if (mounted) setState(() {});
      return;
    }

    _showMessage('이미 두 개의 기기가 연결되어 있습니다.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Scan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isScanning ? null : _startScan,
                  child: Text(_isScanning ? '스캔 중...' : '스캔 시작'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _btManager.plugin.stopScan();
                    setState(() {
                      _isScanning = false;
                    });
                  },
                  child: const Text('스캔 중지'),
                ),
              ],
            ),
          ),
          if (_isScanning) const LinearProgressIndicator(),
          Expanded(
            child: _scanResults.isEmpty
                ? Center(
              child: Text(_isScanning
                  ? '주변 기기를 찾는 중입니다...'
                  : '스캔 버튼을 눌러 주변 기기를 검색하세요.'),
            )
                : ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (context, index) {
                final device = _scanResults[index];
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(device.name ?? '이름 없음 (Unknown)'),
                  subtitle: Text(
                    '${device.address}\nBond: ${device.bondState.name}',
                  ),
                  trailing: _btManager.device1?.address == device.address
                      ? const Text('HC-06 #1 연결됨', style: TextStyle(color: Colors.blue))
                      : _btManager.device2?.address == device.address
                      ? const Text('HC-06 #2 연결됨', style: TextStyle(color: Colors.green))
                      : null,
                  onTap: () => _pairDevice(device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
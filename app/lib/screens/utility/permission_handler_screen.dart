import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class BluetoothPermissionScreen extends StatefulWidget {
  const BluetoothPermissionScreen({super.key});

  @override
  State<BluetoothPermissionScreen> createState() => _BluetoothPermissionScreenState();
}

class _BluetoothPermissionScreenState extends State<BluetoothPermissionScreen> {
  final _flutterBlueClassic = FlutterBlueClassic();
  BluetoothConnection? _connection1;
  BluetoothConnection? _connection2;

  StreamSubscription? _connection1Subscription;
  StreamSubscription? _connection2Subscription;

  BluetoothDevice? _device1;
  BluetoothDevice? _device2;

  // Device 대신 BluetoothDevice 사용
  final List<BluetoothDevice> _scanResults = [];
  StreamSubscription<BluetoothDevice>? _scanSubscription;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    // onDeviceDiscovered 대신 scanResults 스트림 사용
    _scanSubscription = _flutterBlueClassic.scanResults.listen((device) {
      debugPrint('🔍 [기기 발견] 이름: ${device.name ?? "이름없음"}, 주소: ${device.address}');
      setState(() {
        // 중복 기기 추가 방지
        if (!_scanResults.any((element) => element.address == device.address)) {
          _scanResults.add(device);
        }
      });
    });
  }

  @override
  void dispose() {
    _connection1Subscription?.cancel();
    _connection2Subscription?.cancel();

    _connection1?.dispose();
    _connection2?.dispose();

    _scanSubscription?.cancel();

    _flutterBlueClassic.stopScan();
    super.dispose();
  }



  void _startScan() async {


    bool? isBluetoothOn = await _flutterBlueClassic.isEnabled;
    if (isBluetoothOn != true) {
      _showMessage("스마트폰의 블루투스를 켜주세요.");
      return;
    }

    setState(() {
      _scanResults.clear();
      _isScanning = true;
    });
    debugPrint('📡 flutter_blue_classic.startScan() 호출됨 - 주변 기기를 찾는 중...');
    _flutterBlueClassic.startScan();

    // 10초 후 스캔 자동 종료
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _flutterBlueClassic.stopScan();
        setState(() {
          _isScanning = false;
        });
        debugPrint('⏹️ 10초 타임아웃으로 스캔 자동 종료 (총 발견된 기기 수: ${_scanResults.length}개)');
      }
    });
  }

  void _showMessage(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
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
                    _flutterBlueClassic.stopScan();
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
                    '${device.address}\n'
                        'Bond: ${device.bondState.name}',
                  ),

                  trailing: _device1?.address == device.address
                      ? const Text('HC-06 #1 연결됨')
                      : _device2?.address == device.address
                      ? const Text('HC-06 #2 연결됨')
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

  Future<void> _pairDevice(BluetoothDevice device) async {
    try {
      _flutterBlueClassic.stopScan();

      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }

      debugPrint(
        '📱 선택한 기기: ${device.name ?? "이름 없음"} '
            '(${device.address})',
      );

      // 첫 번째 기기
      if (_device1 == null) {
        await _connectDevice(device, 1);
        return;
      }

      // 두 번째 기기
      if (_device2 == null) {
        await _connectDevice(device, 2);
        return;
      }

      _showMessage('이미 두 개의 기기가 선택되었습니다.');
    } catch (e) {
      debugPrint('❌ 기기 선택 오류: $e');

      if (mounted) {
        _showMessage('Bluetooth 오류: $e');
      }
    }
  }
  Future<void> _connectDevice(
      BluetoothDevice device,
      int deviceNumber,
      ) async {
    try {
      debugPrint(
        '🔗 HC-06 #$deviceNumber 연결 시작: ${device.address}',
      );

      // 아직 페어링되지 않았다면 페어링
      if (device.bondState != BluetoothBondState.bonded) {
        debugPrint('🔐 HC-06 #$deviceNumber 페어링 시작');

        await _flutterBlueClassic.bondDevice(device.address);

        debugPrint('🔐 HC-06 #$deviceNumber 페어링 완료');
      }

      // 연결
      final connection =
      await _flutterBlueClassic.connect(device.address);

      if (connection == null || !connection.isConnected) {
        debugPrint('❌ HC-06 #$deviceNumber 연결 실패');
        _showMessage('HC-06 #$deviceNumber 연결 실패');
        connection?.dispose();
        return;
      }

      debugPrint(
        '✅ HC-06 #$deviceNumber 연결 성공',
      );

      if (deviceNumber == 1) {
        _device1 = device;
        _connection1 = connection;

        _connection1Subscription =
            connection.input?.listen((event) {
              final data = utf8.decode(event);

              debugPrint('📥 HC-06 #1: $data');
            });
      } else {
        _device2 = device;
        _connection2 = connection;

        _connection2Subscription =
            connection.input?.listen((event) {
              final data = utf8.decode(event);

              debugPrint('📥 HC-06 #2: $data');
            });
      }

      if (mounted) {
        setState(() {});
      }

    } catch (e) {
      debugPrint(
        '❌ HC-06 #$deviceNumber 연결 오류: $e',
      );

      if (mounted) {
        _showMessage(
          'HC-06 #$deviceNumber 연결 오류',
        );
      }
    }
  }

}
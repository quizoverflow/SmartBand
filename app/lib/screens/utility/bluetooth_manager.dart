import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';


// 싱글톤 패턴 구현
class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  final FlutterBlueClassic _flutterBlueClassic = FlutterBlueClassic();

  // 기기 및 연결 객체 관리
  BluetoothDevice? device1;
  BluetoothDevice? device2;

  BluetoothConnection? connection1;
  BluetoothConnection? connection2;

  StreamSubscription? _subscription1;
  StreamSubscription? _subscription2;

  // 데이터 수신을 알리기 위한 외부 제공 스트림 컨트롤러 (문자열 데이터)
  final _dataStreamController1 = StreamController<String>.broadcast();
  final _dataStreamController2 = StreamController<String>.broadcast();

  Stream<String> get dataStream1 => _dataStreamController1.stream;
  Stream<String> get dataStream2 => _dataStreamController2.stream;

  FlutterBlueClassic get plugin => _flutterBlueClassic;

  /// 기기 연결 및 페어링
  Future<bool> connectDevice(BluetoothDevice device, int deviceNumber) async {
    try {
      debugPrint('🔗 HC-06 #$deviceNumber 연결 시작: ${device.address}');

      // 페어링 진행
      if (device.bondState != BluetoothBondState.bonded) {
        debugPrint('🔐 HC-06 #$deviceNumber 페어링 시작');
        await _flutterBlueClassic.bondDevice(device.address);
        debugPrint('🔐 HC-06 #$deviceNumber 페어링 완료');
      }

      // 연결 시도
      final connection = await _flutterBlueClassic.connect(device.address);

      if (connection == null || !connection.isConnected) {
        debugPrint('❌ HC-06 #$deviceNumber 연결 실패');
        connection?.dispose();
        return false;
      }

      debugPrint('✅ HC-06 #$deviceNumber 연결 성공');

      if (deviceNumber == 1) {
        await disconnect(1); // 기존 연결 정리
        device1 = device;
        connection1 = connection;
        _subscription1 = connection.input?.listen((event) {
          final data = utf8.decode(event);
          debugPrint('📥 HC-06 #1: $data');
          _dataStreamController1.add(data);
        });
      } else {
        await disconnect(2); // 기존 연결 정리
        device2 = device;
        connection2 = connection;
        _subscription2 = connection.input?.listen((event) {
          final data = utf8.decode(event);
          debugPrint('📥 HC-06 #2: $data');
          _dataStreamController2.add(data);
        });
      }

      return true;
    } catch (e) {
      debugPrint('❌ HC-06 #$deviceNumber 연결 오류: $e');
      return false;
    }
  }

  /// 앱 -> 아두이노 시리얼 전송. 필수기능은 아님.
  Future<void> sendData(int deviceNumber, String data) async {
    final connection = deviceNumber == 1 ? connection1 : connection2;
    if (connection != null && connection.isConnected) {
      connection.output.add(utf8.encode(data));
      await connection.output.allSent;
    }
  }

  /// 특정 기기 연결 해제
  Future<void> disconnect(int deviceNumber) async {
    if (deviceNumber == 1) {
      await _subscription1?.cancel();
      _subscription1 = null;
      connection1?.dispose();
      connection1 = null;
      device1 = null;
    } else {
      await _subscription2?.cancel();
      _subscription2 = null;
      connection2?.dispose();
      connection2 = null;
      device2 = null;
    }
  }

  /// 모든 연결 및 리소스 해제
  void dispose() {
    disconnect(1);
    disconnect(2);
    _dataStreamController1.close();
    _dataStreamController2.close();
  }
}
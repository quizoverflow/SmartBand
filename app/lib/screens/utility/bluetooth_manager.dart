import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_classic/flutter_blue_classic.dart';

class RunningPacket {
  final int packetNumber;
  final double peak;
  final double cadence;
  final double impact;
  final double groundTime;

  RunningPacket({
    required this.packetNumber,
    required this.peak,
    required this.cadence,
    required this.impact,
    required this.groundTime,
  });

  RunningPacket getAvg(RunningPacket other){
    return RunningPacket(
        packetNumber: packetNumber,
        peak: (peak + other.peak) / 2,
        cadence: (cadence + other.cadence) / 2,
        impact: (impact + other.impact) / 2,
        groundTime: (groundTime + other.groundTime) / 2);
  }

  double getBalanceScore(RunningPacket other){
      double peakBalance = calculateBalance(peak, other.peak);
      double cadenceBalance = calculateBalance(cadence, other.cadence);
      double impactBalance = calculateBalance(peak, other.impact);
      double groundTimeBalance = calculateBalance(peak, other.groundTime);
      return (peakBalance + cadenceBalance + impactBalance + groundTimeBalance) / 4;
  }
  double calculateBalance(double a, double b){
    return 100 - 200 * (a - b).abs() / (a + b);
  }
}
RunningPacket? parsePacket(String data) {
  try {
    final values = data.trim().split(',');

    if (values.length != 5) {
      return null;
    }

    return RunningPacket(
      packetNumber: int.parse(values[0]),
      peak: double.parse(values[1]),
      cadence: double.parse(values[2]),
      impact: double.parse(values[3]),
      groundTime: double.parse(values[4]),
    );
  } catch (e) {
    return null;
  }
}

class BluetoothManager{
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  final FlutterBlueClassic _flutterBlueClassic = FlutterBlueClassic();

  BluetoothDevice? device1;
  BluetoothDevice? device2;

  BluetoothConnection? connection1;
  BluetoothConnection? connection2;

  StreamSubscription? _subscription1;
  StreamSubscription? _subscription2;

  final _dataStreamController1 = StreamController<String>.broadcast();
  final _dataStreamController2 = StreamController<String>.broadcast();

  Stream<String> get dataStream1 => _dataStreamController1.stream;
  Stream<String> get dataStream2 => _dataStreamController2.stream;

  FlutterBlueClassic get plugin => _flutterBlueClassic;

  /// 기기 연결 및 페어링
  Future<bool> connectDevice(BluetoothDevice device, int deviceNumber) async {
    try {
      debugPrint('HC-06 #$deviceNumber 연결 시도: ${device.address}');

      // 1. 이미 연결되어 있다면 기존 연결 해제
      await disconnect(deviceNumber);

      // 2. 페어링 상태 확인 및 페어링 진행
      if (device.bondState != BluetoothBondState.bonded) {
        debugPrint('HC-06 #$deviceNumber 페어링 요청 중...');
        bool? bonded = await _flutterBlueClassic.bondDevice(device.address);
        debugPrint('HC-06 #$deviceNumber 페어링 결과: $bonded');

        // 🔥 핵심: 페어링 완료 후 OS 블루투스 스택 안정을 위한 지연 시간
        await Future.delayed(const Duration(seconds: 2));
      }

      // 3. 소켓 연결 시도
      // (스캔 중이면 딜레이를 주어야 안정적으로 연결됨)
      await Future.delayed(const Duration(milliseconds: 500));

      final connection = await _flutterBlueClassic.connect(device.address);

      if (connection == null || !connection.isConnected) {
        debugPrint('HC-06 #$deviceNumber 소켓 연결 실패');
        return false;
      }

      debugPrint('✅ HC-06 #$deviceNumber 소켓 연결 성공!');

      // 4. 데이터 수신 스트림 바인딩
      if (deviceNumber == 1) {
        device1 = device;
        connection1 = connection;
        _subscription1 = connection.input?.listen(
              (event) {
            // 🔥 allowMalformed: true 옵션으로 깨진 바이트 수신 시 에러 튕김 방지
            final data = utf8.decode(event, allowMalformed: true);
            debugPrint('HC-06 #1 수신: $data');
            _dataStreamController1.add(data);
          },
          onError: (error) {
            debugPrint('HC-06 #1 수신 에러: $error');
          },
          onDone: () {
            debugPrint('HC-06 #1 연결 끊김 (Stream Closed)');
            disconnect(1);
          },
        );
      } else {
        device2 = device;
        connection2 = connection;
        _subscription2 = connection.input?.listen(
              (event) {
            final data = utf8.decode(event, allowMalformed: true);
            debugPrint('HC-06 #2 수신: $data');
            _dataStreamController2.add(data);
          },
          onError: (error) {
            debugPrint('HC-06 #2 수신 에러: $error');
          },
          onDone: () {
            debugPrint('HC-06 #2 연결 끊김 (Stream Closed)');
            disconnect(2);
          },
        );
      }

      return true;
    } catch (e) {
      debugPrint('HC-06 #$deviceNumber 연결 예외 발생: $e');
      return false;
    }
  }

  /// 앱 -> 아두이노 전송
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
      connection1?.close(); // dispose() 대신 close() 사용
      connection1 = null;
      device1 = null;
      debugPrint('HC-06 #1 해제 완료');
    } else {
      await _subscription2?.cancel();
      _subscription2 = null;
      connection2?.close();
      connection2 = null;
      device2 = null;
      debugPrint('HC-06 #2 해제 완료');
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


// 싱글톤 패턴 구현
/*
class BluetoothManager_ {
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
      debugPrint('HC-06 #$deviceNumber 연결 시작: ${device.address}');

      // 페어링 진행
      if (device.bondState != BluetoothBondState.bonded) {
        debugPrint('HC-06 #$deviceNumber 페어링 시작');
        await _flutterBlueClassic.bondDevice(device.address);
        debugPrint('HC-06 #$deviceNumber 페어링 완료');
      }

      // 연결 시도
      final connection = await _flutterBlueClassic.connect(device.address);

      if (connection == null || !connection.isConnected) {
        debugPrint('HC-06 #$deviceNumber 연결 실패');
        connection?.dispose();
        return false;
      }

      debugPrint('HC-06 #$deviceNumber 연결 성공');

      if (deviceNumber == 1) {
        await disconnect(1); // 기존 연결 정리
        device1 = device;
        connection1 = connection;
        _subscription1 = connection.input?.listen((event) {
          final data = utf8.decode(event);
          debugPrint('HC-06 #1: $data');
          _dataStreamController1.add(data);
        });
      } else {
        await disconnect(2); // 기존 연결 정리
        device2 = device;
        connection2 = connection;
        _subscription2 = connection.input?.listen((event) {
          final data = utf8.decode(event);
          debugPrint('HC-06 #2: $data');
          _dataStreamController2.add(data);
        });
      }

      return true;
    } catch (e) {
      debugPrint('HC-06 #$deviceNumber 연결 오류: $e');
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

 */
import 'dart:convert';

import 'package:latlong2/latlong.dart';

class RunRecord {
  final int id;
  final DateTime? createdAt;
  final int? runningTime;
  final double? distanceKm;
  final int? pointCount;

  final List<double>? path;
  final List<double>? impact;
  final List<double>? cadence;
  final List<double>? groundTime;
  final List<double>? balance;

  RunRecord({
    required this.id,
    this.createdAt,
    this.runningTime,
    this.distanceKm,
    this.pointCount,
    this.path,
    this.impact,
    this.cadence,
    this.groundTime,
    this.balance,
  });

  /// SQLite Map → RunRecord
  factory RunRecord.fromMap(Map<String, dynamic> map) {
    return RunRecord(
      id: map['id'] as int,

      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,

      distanceKm: (map['distanceKm'] as num?)?.toDouble(),

      pointCount: map['pointCount'] as int?,

      path: _jsonToDoubleList(map['pathJson']),
      impact: _jsonToDoubleList(map['impactJson']),
      cadence: _jsonToDoubleList(map['cadenceJson']),
      groundTime: _jsonToDoubleList(map['groundTimeJson']),
    );
  }

  /// RunRecord → SQLite Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'distanceKm': distanceKm,
      'pointCount': pointCount,

      'pathJson': _doubleListToJson(path),
      'impactJson': _doubleListToJson(impact),
      'cadenceJson': _doubleListToJson(cadence),
      'groundTimeJson': _doubleListToJson(groundTime),
    };
  }

  /// JSON 문자열 → List<double>?
  static List<double>? _jsonToDoubleList(dynamic value) {
    if (value == null) {
      return null;
    }

    final List<dynamic> decoded = jsonDecode(value as String);

    return decoded
        .map((e) => (e as num).toDouble())
        .toList();
  }

  /// List<double>? → JSON 문자열
  static String? _doubleListToJson(List<double>? value) {
    if (value == null) {
      return null;
    }

    return jsonEncode(value);
  }
}

//블루투스로 측정되는 정보들
class RunningMetrics {
  final int packetNumber;
  final double impact;
  final double cadence;
  final double groundTime;


  RunningMetrics({
    required this.packetNumber,
    required this.impact,
    required this.cadence,
    required this.groundTime,
  });
}
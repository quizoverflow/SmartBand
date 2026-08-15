import 'dart:convert';

class RunRecord {
  final int id;
  final DateTime? createdAt;
  final double? distanceKm;
  final int? pointCount;

  final List<double>? path;
  final List<double>? impact;
  final List<double>? cadence;
  final List<double>? groundTime;

  RunRecord({
    required this.id,
    this.createdAt,
    this.distanceKm,
    this.pointCount,
    this.path,
    this.impact,
    this.cadence,
    this.groundTime,
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
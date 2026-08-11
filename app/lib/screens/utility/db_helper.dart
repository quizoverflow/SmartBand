import 'dart:convert';
import 'package:app/screens/utility/format.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'running_records.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            distanceKm REAL,
            pointCount INTEGER,
            pathJson TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  /// 러닝 기록 DB 저장
  static Future<int> insertRecord({
    required double distanceKm,
    required int pointCount,
    required List<Map<String, double>> pathData,
  }) async {
    final db = await database;

    // 좌표 리스트를 JSON 문자열로 변환하여 저장
    final String pathJson = jsonEncode(pathData);

    return await db.insert('records', {
      'distanceKm': distanceKm,
      'pointCount': pointCount,
      'pathJson': pathJson,
      'createdAt': formatDateTime(DateTime.now()),
    });
  }

  /// 저장된 모든 러닝 기록 조회 (최신순)
  static Future<List<Map<String, dynamic>>> getRecords() async {
    final db = await database;
    return await db.query('records', orderBy: 'id DESC');
  }
  // 삭제
  static Future<int> deleteRecord(int id) async {
    final db = await database; // 기존 database getter 호출 (또는 본인의 DB 인스턴스 변수)
    return await db.delete(
      'records', // 💡 실제 DB 테이블 이름으로 변경하세요 (예: 'records' 또는 'running_records')
      where: 'id = ?', // 💡 Primary Key 컬럼 이름으로 변경하세요 (예: 'id')
      whereArgs: [id],
    );
  }
}
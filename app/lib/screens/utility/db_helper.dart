import 'dart:convert';
import 'package:app/screens/utility/format.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/run_record.dart';

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
            createdAt TEXT,
            runningTime INTEGER,
            distanceKm REAL,
            pointCount INTEGER,
            pathJson TEXT,
            impactJson TEXT,
            cadenceJson TEXT,
            groundTimeJson TEXT,
            balanceJson TEXT
          )
        ''');
      },
    );
  }

  /// 러닝 기록 DB 저장
  static Future<int> insertRecord({
    required double distanceKm,
    required int pointCount,
    required int runningTime,
    required List<Map<String, double>> pathData,
    required List<double>? impactData,
    required List<double>? cadenceData,
    required List<double>? groundTimeData,
    required List<double>? balanceData
  }) async {
    final db = await database;

    // 좌표 리스트를 JSON 문자열로 변환하여 저장
    final String pathJson = jsonEncode(pathData);
    final String? impactJson = impactData != null ? jsonEncode(impactData) : null;
    final String? cadenceJson = cadenceData != null ? jsonEncode(cadenceData) : null;
    final String? groundTimeJson = groundTimeData != null ? jsonEncode(groundTimeData) : null;
    final String? balanceJson = balanceData != null ? jsonEncode(balanceData) : null;

    return await db.insert('records', {
      'runningTime' : runningTime,
      'distanceKm': distanceKm,
      'pointCount': pointCount,
      'pathJson': pathJson,
      'createdAt': formatDateTime(DateTime.now()),
      'impactJson' : impactJson,
      'cadenceJson' : cadenceJson,
      'groundTimeJson' : groundTimeJson,
      'balanceJson' : balanceJson,
    });
  }

  /// 저장된 모든 러닝 기록 조회 (최신순)
  static Future<List<Map<String, dynamic>>> getRecords() async {
    final db = await database;
    return await db.query('records', orderBy: 'id DESC');
  }

  // RunRecord 클래스로 조회하는 함수
  static Future<List<RunRecord>> getRunRecords() async {
    final db = await _initDB();

    final maps = await db.query(
      'records',
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => RunRecord.fromMap(map)).toList();
  }
  // 삭제
  static Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete(
      'records', // 테이블 이름은 일단 records
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  /// 개발중 초기화용
  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'running_records.db');

    await deleteDatabase(path);

  }

}
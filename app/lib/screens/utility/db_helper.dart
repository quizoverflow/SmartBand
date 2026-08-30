import 'dart:convert';
import 'package:app/screens/utility/format.dart';
import 'package:flutter/cupertino.dart';
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
  
  //이상치 제거
  static void replaceAbnormalValues(List<num>? dataList, int max, int min) {
    if (dataList == null || dataList.isEmpty) {
      return;
    }
    for (int i = 0; i < dataList.length; i++) {
      final value = dataList[i];

      // 200 초과 또는 150 미만이면 이상값
      if (value > max || value < min) {
        if (i == 0) {
          // 첫 번째 값이 이상하면 두 번째 값으로 대체
          if (dataList.length > 1) {
            dataList[i] = dataList[i + 1];
          }
        } else if (i == dataList.length - 1) {
          // 마지막 값이 이상하면 직전 값으로 대체
          dataList[i] = dataList[i - 1];
        } else {
          // 중간 값이 이상하면 앞/뒤 값의 평균
          dataList[i] = (dataList[i - 1] + dataList[i + 1]) / 2;
        }
      }
    }
  }

  /// 러닝 기록 DB 저장
  static Future<int> insertRecord({
    required double distanceKm,
    required int pointCount,
    required int runningTime,
    required List<Map<String, double>> pathData,
    required List<num>? impactData,     // double/int 모두 수용하도록 num으로 설정
    required List<num>? cadenceData,    // double/int 모두 수용하도록 num으로 설정
    required List<num>? groundTimeData, // double/int 모두 수용하도록 num으로 설정
    required List<num>? balanceData,    // double/int 모두 수용하도록 num으로 설정
  }) async {
    try {
      final db = await database;

      replaceAbnormalValues(cadenceData,200,150);
      // replaceAbnormalValues(impactData,200,150);
      replaceAbnormalValues(groundTimeData,150,100);
      // replaceAbnormalValues(balanceData,200,150);

      // 좌표 리스트 및 센서 리스트를 JSON 문자열로 변환
      final String pathJson = jsonEncode(pathData);
      final String? impactJson = impactData != null ? jsonEncode(impactData) : null;
      final String? cadenceJson = cadenceData != null ? jsonEncode(cadenceData) : null;
      final String? groundTimeJson = groundTimeData != null ? jsonEncode(groundTimeData) : null;
      final String? balanceJson = balanceData != null ? jsonEncode(balanceData) : null;

      final id = await db.insert('records', {
        'runningTime': runningTime,
        'distanceKm': distanceKm,
        'pointCount': pointCount,
        'pathJson': pathJson,
        'createdAt': formatDateTime(DateTime.now()),
        'impactJson': impactJson,
        'cadenceJson': cadenceJson,
        'groundTimeJson': groundTimeJson,
        'balanceJson': balanceJson,
      });

      debugPrint('✅ [DB 저장 성공] Record ID: $id');
      return id;
    } catch (e, stackTrace) {
      debugPrint('❌ [DB 저장 실패 에러]: $e');
      debugPrint('StackTrace: $stackTrace');
      return -1;
    }
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
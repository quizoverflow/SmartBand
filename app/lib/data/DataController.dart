import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

//singleton
//shared-preference
class Pref{
  static final Pref _instance = Pref._();
  late SharedPreferences pref;
  Pref._() {
    _loadData();
  }
  factory Pref() => _instance;
  //Pref로 저장할 data type 정리 String, Bool, Int
  static final Map<String,String> _dataType = {
    "isFirstRun": "Bool",
    "username" : "String",
    "isDarkMode" : "Bool",
    "isNoticeOn" : "Bool",
  };
  Future<void> printAll() async{
    pref = await SharedPreferences.getInstance();
    print("========shared preferences=====");
    for (var key in pref.getKeys()){
      final value = pref.get(key);
      print("$key : $value");
    }
    print("===============================");
  }
  Future<void> _loadData() async{
    pref = await SharedPreferences.getInstance();
    //first run check
    if (pref.getBool("isFirstRun") ?? true){
      pref.setBool("isDarkMode",false);
      pref.setBool("isNoticeOn",false);
      pref.setString("username","아무개");
      pref.setBool('isFirstRun', false);
    }
  }
  //load
  Future<dynamic> getData(String key) async{
    pref = await SharedPreferences.getInstance();
    try {
      if (_dataType[key] == "String") {
        return pref.getString(key);
      }
      else if (_dataType[key] == "Bool") {
        return pref.getBool(key);
      }
      else if (_dataType[key] == "Int") {
        return pref.getInt(key);
      }
      }
    catch(e){
        debugPrint('$key 값으로 preference data조회 실패');
    }
  }
  //update
  Future<void> updateData(String itemName, dynamic value) async{
    pref = await SharedPreferences.getInstance();
    if (_dataType[itemName] == "String"){
      pref.setString(itemName,value);
    }
    else if(_dataType[itemName] == "Bool"){
      pref.setBool(itemName,value);
    }
    else if(_dataType[itemName] == "Int"){
      pref.setInt(itemName,value);
    }
  }



}

//singleton
//Database (sqlite)
// folio.db의 current / history 두 개의 table로 구성됨
class DbController{
  //define singleton
  static final DbController _instance = DbController._();
  static Database? _db;
  DbController._();
  factory DbController() => _instance;

  //Getter
  Future<Database> get database async{
    if(_db != null){
      return _db!;
    }
    _db = await _initDB();
    return _db!;
  }
  //init Db
  Future<Database> _initDB() async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath,'folio.db');
    final String sqlCurrent = """
    CREATE TABLE current(
      name TEXT,
      ticker TEXT, 
      type TEXT,
      total_stock INTEGER,
      total INTEGER,
      buy_price INTEGER,
      sell_price INTEGER,
      date TEXT
    )
    """;
    final String sqlHistory = """
    CREATE TABLE history(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      ticker TEXT,
      type TEXT
      total_stock INTEGER,
      total INTEGER,
      buy_price INTEGER,
      sell_price INTEGER,
      date TEXT
    )
    """;
    return await openDatabase(
      path,version: 1,
      onCreate: (db,version) async {
        await db.execute(sqlCurrent);
        await db.execute(sqlHistory);
      }
    );
 }

  //add data (replace)
  Future<void> insertData(String tableName,Map<String,dynamic> data) async{
    final db = await database;
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }
  //fetch data
  Future<List<Map<String,dynamic>>> fetchData(String tableName) async{
    final db = await database;
    return await db.query(tableName);
  }
  //update data
  //update data by column name
  Future<void> updateData(String tableName,String columnName,String columnValue, Map<String,dynamic>data) async{
    final db = await database;
    await db.update(
      tableName,
      data,
      where: '$columnName = ?',
      whereArgs: [columnValue],
    );
  }

  Future <void> deleteData(String tableName, String columnName, String columnValue) async{
    final db = await database;
    await db.delete(
      tableName,
      where: '$columnName = ?',
      whereArgs: [columnValue],
    );
  }


  //for debuging
  Future<void> debugDB() async {
    final db = await database; // 네가 만든 DBHelper 사용한다고 가정
    final List<Map<String, dynamic>> result = await db.query('current');

    String line = "==================";
    for(int i = 0; i < 5; ++i){
      print(line);
    }
    for (var row in result) {
      print(row);
    }
    for(int i = 0; i < 5; ++i){
      print(line);
    }
  }

}
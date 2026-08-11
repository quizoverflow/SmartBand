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


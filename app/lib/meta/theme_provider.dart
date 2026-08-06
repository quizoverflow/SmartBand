import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme(); // 생성 시 저장된 테마 로드
  }

  // 테마 모드 전환
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // ⭐️ 이 함수가 앱 전체에 재빌드를 알립니다.

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
  }

  // 초기값 로드
  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
}
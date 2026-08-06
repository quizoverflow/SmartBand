import 'package:flutter/material.dart';

class AppTheme{
  AppTheme._();

  //테마 컬러
  //진한 민트
  static const primaryColor = const Color(0xFF14B8A6);
  //연한 민트
  static const groundColor = const Color(0xFFE8FFFA);
  static const secondaryColor = const Color(0xFF00C7BE);    // 민트
  static const titleColor = const Color(0xFF1E293B);


  static const lightThemeColor = ColorScheme.light(
    primary: primaryColor,
    secondary: Colors.white,
  );
  static const darkThemeColor = ColorScheme.dark(
      primary:  primaryColor,
      secondary: Colors.black
  );

  static Text showText(String text, {double size = 15.0, Color color = Colors.black}){
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        //color: color,
        fontWeight: FontWeight.bold
      ),
    );
  }

  static Text midTitle(String text,{double size = 20.0}){
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        color: primaryColor,
        fontWeight: FontWeight.bold
      ),
    );
  }
  static Text topTitle(String text,{double size = 25.0}){
    return Text(
      text,
      style: TextStyle(
          fontSize: size,
          color: primaryColor,
          fontWeight: FontWeight.bold
      ),
    );
  }
}
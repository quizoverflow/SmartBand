import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/screens/screen_home.dart';
import 'package:app/screens/start/screen_loading.dart';
import 'package:app/meta/app_theme.dart';
import 'package:app/data/DataController.dart';

import 'meta/theme_provider.dart';

// Managing entire application
// app theme
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Brightness brightness = Brightness.light;

  @override
  void initState() {
    super.initState();

    checkThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final materialApp = MaterialApp(
      title: 'Portfolio',
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
    return materialApp;
  }
  void changeTheme(){
    setState(() {
      checkThemeMode();
    });
  }
  Future<void> checkThemeMode() async{
    Pref pref = Pref();

    try{
      bool isDarkMode = await pref.getData('isDarkMode');
      if (isDarkMode == true){
        brightness = Brightness.dark;
      }
      else{
        brightness = Brightness.light;
      }
    }
    catch(e){}
  }

  ThemeData initThemeData({required Brightness brightness}) {
    if (brightness == Brightness.light) {
      return ThemeData(
          brightness: Brightness.light,
          colorScheme: AppTheme.lightThemeColor
      );
    } else {
      return ThemeData(
          brightness: Brightness.dark,
          colorScheme: AppTheme.darkThemeColor
      );
    }
  }
}



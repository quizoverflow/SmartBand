import 'package:flutter/material.dart';
import 'package:app/meta/theme_provider.dart';
import 'package:provider/provider.dart';
import 'ai/ai_service.dart';
import 'app.dart';

void main() {
  AI.instance.initialize();
  // SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp()
    )
  );
}

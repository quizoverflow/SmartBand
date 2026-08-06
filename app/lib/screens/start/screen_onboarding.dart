import 'package:flutter/material.dart';
import 'package:app/data/DataController.dart';
import 'package:app/screens/screen_home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  late Pref pref;
  @override
  void initState(){
    super.initState();
    pref = Pref();

  }
  Future<void> _finishOnboarding(BuildContext context) async {
    setState(() {
      pref.pref.setBool('isFirstRun',false);
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _finishOnboarding(context),
          child: const Text('시작하기'),
        ),
      ),
    );
  }

}


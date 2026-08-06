import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'menu_dashboard.dart';

class RunDetailPage extends StatelessWidget {

  final RunRecord record;


  const RunDetailPage({
    super.key,
    required this.record,
  });


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "러닝 분석",
        ),
      ),

      body: Center(
        child: Text(
          "${record.distance}km 상세 분석",
          style:
          const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
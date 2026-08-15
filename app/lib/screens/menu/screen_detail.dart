import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/run_record.dart';

class DetailScreen extends StatelessWidget {

  final Map<String,dynamic> record;


  const DetailScreen({
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
          "${record['distanceKm']}km 상세 분석",
          style:
          const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
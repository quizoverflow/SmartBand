import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/run_record.dart';


// 측정값은 record 에 담겨있음
// 분석해야 함.
// fl_chart

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

      body:ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          GraphCard(
            height: 200,
            title: '케이던스',
            description: '시간에 따른 케이던스 변화',
            data: (jsonDecode(record['cadenceJson'] as String) as List).map((e) => (e as num).toDouble()).toList(),
          ),

          GraphCard(
            height: 200,
            title: '충격량',
            description: '시간에 따른 충격량 변화',
            data: (jsonDecode(record['impactJson'] as String) as List).map((e) => (e as num).toDouble()).toList(),
          ),

          GraphCard(
            height: 200,
            title: '지면접촉시간',
            description: '시간에 따른 지면접촉시간 변화',
            data: (jsonDecode(record['groundTimeJson'] as String) as List).map((e) => (e as num).toDouble()).toList(),
          ),

          GraphCard(
            height: 200,
            title: '좌우 밸런스',
            description: '시간에 따른 좌우 밸런스 변화',
            data: (jsonDecode(record['balanceJson'] as String) as List).map((e) => (e as num).toDouble()).toList(),
          ),
        ],
      )
    );
  }

}
class TimePoint {
  final DateTime time;
  final double value;

  const TimePoint({
    required this.time,
    required this.value,
  });
}


class GraphCard extends StatelessWidget {
  final double height;
  final String title;
  final String description;
  final List<double> data;

  const GraphCard({
    super.key,
    required this.title,
    required this.description,
    required this.data,
    required this.height
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그래프 제목
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // 그래프
          SizedBox(
            width: double.infinity,
            height: height,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots:[
                      for(int i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i]),
                    ],

                    isCurved: false,

                    // 1,000개의 점을 모두 그리지 않음
                    dotData: const FlDotData(
                      show: false,
                    ),

                    barWidth: 1.5,
                  ),
                ],

                gridData: const FlGridData(
                  show: true,
                ),

                borderData: FlBorderData(
                  show: true,
                ),

                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
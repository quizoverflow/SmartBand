import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../ai/ai_service.dart';
import '../../meta/app_theme.dart';

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
    // debugPrint("==============${record['cadenceJson'] as String}============");
    // debugPrint(record.keys.toString());

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
            // data : temp_data,
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


class GraphCard extends StatefulWidget {
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
  State<GraphCard> createState() => _GraphCardState();
}

class _GraphCardState extends State<GraphCard> {
  late String _descriptionText;
  bool _isLoading = false; // 답변 생성중인지

  @override
  void initState(){
    super.initState();
    _descriptionText = widget.description;
  }

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
            widget.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // 그래프
          SizedBox(
            width: double.infinity,
            height: widget.height,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots:[
                      for(int i = 0; i < widget.data.length; i++)
                        FlSpot(i.toDouble(), widget.data[i]),
                    ],

                    isCurved: false,

                    // 1,000개의 점을 모두 그리지 않음
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 2.0,
                          strokeWidth: 0,
                          color: AppTheme.secondaryColor
                        );
                      },
                    ),

                    barWidth: 0,
                  ),
                ],

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.12),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: false,
                ),

                titlesData:FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: false,
                    ),
                  ),

                  // X축
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: widget.data.length / 10 != 0 ? widget.data.length / 10 : 10,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),

                  // Y축
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                )
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  _descriptionText,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize : 15,
                    letterSpacing: 0
                  ),
                ),
                ElevatedButton(
                  // onPressed: _askDebug,
                  onPressed: _isLoading ? null : _askAI,
                  child: const Text("AI 물어보기",),

                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
  Future<void> _askDebug() async{
    AI.instance.initialize();

    setState(() async {
      _descriptionText = await AI.instance.ask("");
    });
  }
  Future<void> _askAI() async{
    setState(() {
      _descriptionText = widget.description;
      _isLoading = true;
    });
    final double average = widget.data.reduce((a, b) => a + b) / widget.data.length;

    final double maxValue = widget.data.reduce(max);
    final double minValue = widget.data.reduce(min);
    try {
      await for (final text in AI.instance.askStream(
        '데이터 종류 : $_descriptionText \n 평균 : $average, 최고값 : $maxValue, 최저값 : $minValue',
      )) {
        if (!mounted) return;

        setState(() {
          _descriptionText += text;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
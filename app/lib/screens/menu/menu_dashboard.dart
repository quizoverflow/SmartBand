import 'package:app/screens/menu/page_detail.dart';
import 'package:flutter/material.dart';
import 'package:app/meta/app_theme.dart';

//대시보드 메뉴 stateful widget (운동현황)

class DashboardMenu extends StatefulWidget {
  const DashboardMenu({super.key});
  @override
  State<DashboardMenu> createState() => _DashboardMenuState();
}

class _DashboardMenuState extends State<DashboardMenu> {

  //포트폴리오 탭에 보일 모든 위젯 담을 리스트.
  List<Widget> widgets = [];

  @override
  Widget build(BuildContext context) {

    widgets = [
      RunHistoryWidget(),
    ];
    return ListView(
      padding: EdgeInsets.only(top: 5,bottom: 5,left: 5,right: 5),
      scrollDirection: Axis.vertical,
      children: widgets
    );
  }

}
class RunRecord {
  final double distance;
  final Duration time;
  final DateTime date;

  RunRecord({
    required this.distance,
    required this.time,
    required this.date,
  });
}


class RunHistoryWidget extends StatefulWidget {
  const RunHistoryWidget({
    super.key,
  });

  @override
  State<RunHistoryWidget> createState() =>
      _RunHistoryWidgetState();
}

// ======== 러닝 히스토리 =====


class _RunHistoryWidgetState extends State<RunHistoryWidget> {

  final List<RunRecord> records = [
    RunRecord(
      distance: 5.2,
      time: Duration(minutes: 24, seconds: 32),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
    RunRecord(
      distance: 3.8,
      time: Duration(minutes: 18, seconds: 10),
      date: DateTime.now(),
    ),
  ];


  // 나중에 러닝 종료 후 호출할 함수
  void addRecord(RunRecord record) {
    setState(() {
      records.insert(0, record);
    });
  }


  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        AppTheme.midTitle("  러닝 기록"),

        const SizedBox(height: 16),


        ListView.builder(
          padding: EdgeInsets.only(top: 5,bottom: 5,left: 5,right: 5),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: records.length,

          itemBuilder: (context, index) {

            final record = records[index];

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFE8FFFA),
                  foregroundColor:
                  const Color(0xFF1E293B),

                  padding:
                  const EdgeInsets.all(20),

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(20),
                  ),

                  elevation: 0,
                ),


                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RunDetailPage(
                            record: record,
                          ),
                    ),
                  );

                },


                child: Row(
                  children: [

                    const Icon(
                      Icons.directions_run,
                      size: 32,
                      color: Color(0xFF00C7BE),
                    ),

                    const SizedBox(width: 16),


                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [

                        Text(
                          "${record.distance} km",
                          style:
                          const TextStyle(
                            fontSize: 20,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),


                        Text(
                          formatDuration(
                            record.time,
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }


  String formatDuration(Duration duration) {
    return "${duration.inMinutes}분 "
        "${duration.inSeconds % 60}초";
  }
}

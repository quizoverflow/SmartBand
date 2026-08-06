import 'package:app/meta/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:app/screens/menu/menu.dart';
import 'package:app/screens/setting_modal.dart';
import 'package:app/data/DataController.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: 0,
      animationDuration: const Duration(milliseconds: 500));
  String? username;
  Future<void> loadUserInfo() async{
    Pref pref = Pref();
    late String name;
    try {
      name = await pref.getData('username');
    }
    catch(e){
      name = "Anonymous";
    }
    setState(() {
      username = name;
    });
  }

  @override
  void initState(){
   super.initState();
   loadUserInfo();
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: Column(
          children: [
            //상단부
            _head(),
            //탭 하위 항목들 (화면 아래까지 확장
            _tabBar(),
            Expanded(child: _tabBarView()),
            Container(height: 12,width: 1, color:Colors.transparent)
          ],
        ));
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Widget _tabBar() {
    return TabBar(
      controller: tabController,
      indicatorColor: AppTheme.primaryColor,
      dividerColor: Colors.transparent,
      indicatorWeight: 5,
      indicatorSize: TabBarIndicatorSize.label,
      tabs: const [
        Tab(text: "대시 보드"),
        Tab(text: "러닝")
      ],
    );
  }

  Widget _tabBarView() {
    return TabBarView(
      controller: tabController,
      children: [
        DashboardMenu(),
        ExerciseMenu(
          onTap: (){}
        ),
      ],
    );
  }
  Widget _head(){
    return Container(
      width: double.infinity,
      height: 55,
      margin: const EdgeInsets.only(top: 20,left: 5,right: 2),
      child:
      Row(
        children: [
          //folio logo image
          SizedBox(width: 120, height: 80, child: Image.asset('asset/img/WayRunning_text.png')),
          const Spacer(flex: 1),
          //user info button
          userInfoBtn(),
          iconBtn(0)
        ],
      )
    );
  }

  ElevatedButton userInfoBtn(){
    return ElevatedButton(
      onPressed: () {
        //사용자 정보 수정 페이지 만들어야 함

      },
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        minimumSize: const Size(80, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 6),
        shape: const StadiumBorder(),
      ),
      child: Text(
        '$username 님',
        style: TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  IconButton iconBtn(int iconIdx){
    var imgName = ['wheel2.png','note.png','glass.png'];
    var imgSize =[30.0,30.0,30.0];
    var path = "asset/img/${imgName[iconIdx]}";

    return IconButton(
      icon: Image.asset(path,width: imgSize[iconIdx],height: imgSize[iconIdx]),
      onPressed:(){
        //setting modal
        if (iconIdx == 0) {
          showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) {
                return SettingModal();
              }
          );
        }
      },
    );
  }


}


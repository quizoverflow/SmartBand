import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/meta/theme_provider.dart';
import '../app.dart';
import '../data/DataController.dart';

class SettingModal extends StatefulWidget {
  const SettingModal({super.key});

  @override
  State<SettingModal> createState() => _SettingModalState();
}

class _SettingModalState extends State<SettingModal> {
  Map<String,bool> settings = {"isDarkMode":false,"isNoticeOn":false};
  final Pref pref = Pref();
  @override
  void initState(){
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16, left: 16, right: 16,
          bottom: MediaQuery
              .of(context)
              .viewInsets
              .bottom + 100),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Text('설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          makeSwitch("다크 모드","isDarkMode"),
          makeSwitch("알림 설정","isNoticeOn"),

          SizedBox(height: 12),
        ],
      ),
    );
  }
  Future<void> _loadSettings() async{
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      settings.forEach((name,value) async {
        settings[name] = prefs.getBool(name) ?? false;
      });
    });
  }


  SwitchListTile makeSwitch(String title,String itemName){
    bool switchValue = settings[itemName]!;
    return SwitchListTile(
        title: Text(title),
        value: context.watch<ThemeProvider>().isDarkMode,
        onChanged: (value){
          pref.updateData(itemName, value);
          settings[itemName] = value;
          context.read<ThemeProvider>().toggleTheme();
          setState(() {

          });
        }
    );
  }

}


import 'package:app/screens/utility/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/meta/theme_provider.dart';
import '../data/DataController.dart';

class SettingModal extends StatefulWidget {
  const SettingModal({super.key});

  @override
  State<SettingModal> createState() => _SettingModalState();
}

class _SettingModalState extends State<SettingModal> {
  Map<String,bool> settings = {"isDarkMode":false,"isNoticeOn":false};
  final Pref pref = Pref();
  String? _apiKey;
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
          makeDataResetButton(),
          makeApiKeyTile(context: context),

          SizedBox(height: 12),
        ],
      ),
    );
  }
  Future<void> _loadSettings() async{
    final prefs = await SharedPreferences.getInstance();
    _apiKey = await pref.getApiKey();
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
          setState(() {});
        }
    );
  }

  ListTile makeDataResetButton(){
    return ListTile(
      title: const Text('데이터 일괄삭제'),
      trailing: ElevatedButton(
        onPressed: () async {
          await DBHelper.resetDatabase();
          if(!mounted) return;
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('완료'),
                content: const Text('데이터 삭제완료'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('확인'),
                  ),
                ],
              );
            },
          );
        },
        child: const Text('삭제'),
      ),
    );
  }
  ListTile makeApiKeyTile({
    required BuildContext context,
  }) {
    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('OpenAI API Key'),
      subtitle: Text(
        _apiKey == null || _apiKey == ""
            ? 'API Key가 설정되지 않았습니다.'
            : 'API Key가 설정되어 있습니다.',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController(
              text: _apiKey ?? '',
            );

            return AlertDialog(
              title: const Text('API Key'),
              content: TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'API Key를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    final value = controller.text.trim();

                    if (value.isEmpty) {
                      return;
                    }

                    Navigator.pop(context, value);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );

        if (result != null && result.isNotEmpty) {
          pref.updateApiKey(result);
        }
      },
    );
  }
}


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/model/configs/ml_mode_list.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';

class UserSettingPage extends StatefulWidget {
  const UserSettingPage({Key? key}) : super(key: key);

  @override
  UserSettingPageState createState () => UserSettingPageState();
}

class UserSettingPageState extends State<UserSettingPage> {
  final SharedPreferences prefs = UserSettingPreference().prefs;

  bool? isSaveVideo;
  String? useModel;

  void getPreference()  {
    isSaveVideo = prefs.getBool('isSaveVideo');
    useModel = prefs.getString('useModel');

  }

  void setPreference() async {
    await prefs.setBool('isSaveVideo', isSaveVideo!);
    await prefs.setString('useModel', useModel!);
  }

  @override
  void initState() {
    super.initState();
    getPreference();
  }

  @override
  void dispose() {
    setPreference();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定',),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
         margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: SwitchListTile(
                title: const Text('実行後の動画を保存する'),
                value: isSaveVideo!,
                onChanged: (value) => isSaveVideo = value,
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                children: [
                  const Text('使用する機械学習モデルを選択'),
                  RadioListTile(
                    title: Text(mlDescriptionText[0]),
                    value: MlModels.movenetThunder.toString(),
                    groupValue: useModel,
                    onChanged: (value) {
                      useModel = value.toString();
                    },
                  ),
                  RadioListTile(
                    title: Text(mlDescriptionText[1]),
                    value: MlModels.movenetLightning.toString(),
                    groupValue: useModel,
                    onChanged: (value) {
                      useModel = value.toString();
                    },
                  ),
                ],
              )
            ),
          ],
        ),
      )
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/model/ml_mode_list.dart';
import 'package:walking_analysis/model/preference_keys.dart';
import 'package:walking_analysis/model/global_variable.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';
import 'package:walking_analysis/state/home_providers.dart';

class UserSettingPage extends StatefulWidget {
  const UserSettingPage({Key? key}) : super(key: key);

  @override
  UserSettingPageState createState () => UserSettingPageState();
}

class UserSettingPageState extends State<UserSettingPage> {
  final SharedPreferences prefs = UserSettingPreference().prefs!;

  bool? isSaveVideo;
  String? useModel;

  // 保存してあるプリファレンスを取得
  void getPreference() {
    isSaveVideo = prefs.getBool(PreferenceKeys.isSaveVideo.name);
    useModel = prefs.getString(PreferenceKeys.useModel.name);
  }

  // 変更後のプリファレンスを保存
  void setPreference() async {
    await prefs.setBool('isSaveVideo', isSaveVideo!);
    await prefs.setString('useModel', useModel!);
  }

  // 使用する機械学習モデルをセットする
  void setUseModelProvider() {
    if (useModel == MlModels.movenetThunder.name) {
      GlobalVar.globalRef!.read(useModelProvider.notifier).state = 0;
    } else {
      GlobalVar.globalRef!.read(useModelProvider.notifier).state = 1;
    }
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
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: SwitchListTile(
                title: const Text('実行後の動画を保存する'),
                value: isSaveVideo!,
                onChanged: (value) {
                  setState(() {
                    isSaveVideo = value;
                  }) ;
                }
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('使用する機械学習モデルを選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),),
                  RadioListTile(
                    title: Text(mlDescriptionText[0]),
                    controlAffinity: ListTileControlAffinity.trailing,
                    value: MlModels.movenetThunder.name,
                    groupValue: useModel,
                    onChanged: (value) {
                      setState(() {
                        useModel = value.toString();
                      });
                      setUseModelProvider();
                    },
                  ),
                  RadioListTile(
                    title: Text(mlDescriptionText[1]),
                    controlAffinity: ListTileControlAffinity.trailing,
                    value: MlModels.movenetLightning.name,
                    groupValue: useModel,
                    onChanged: (value) {
                      setState(() {
                        useModel = value.toString();
                      });
                      setUseModelProvider();
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
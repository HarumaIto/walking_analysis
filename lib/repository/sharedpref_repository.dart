import 'package:shared_preferences/shared_preferences.dart';

class UserSettingPreference {
  // staticとしてインスタンスを事前に作成
  static final UserSettingPreference _instance = UserSettingPreference._internal();
  // Factoryコンストラクタ
  factory UserSettingPreference(){
    return _instance;
  }
  // 内部で利用する別名コンストラクタ
  UserSettingPreference._internal();

  late final SharedPreferences prefs;
  bool? isSaveVideo = false;

  void initUserSetting() async {
    prefs = await SharedPreferences.getInstance();

    prefs.setBool('isSaveVideo', false);
    prefs.setString('useModel', 'movenetThunder');
  }
}
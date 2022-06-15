import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/model/preference_keys.dart';

class UserSettingPreference {
  // staticとしてインスタンスを事前に作成
  static final UserSettingPreference _instance = UserSettingPreference._internal();
  // Factoryコンストラクタ
  factory UserSettingPreference(){
    return _instance;
  }
  // 内部で利用する別名コンストラクタ
  UserSettingPreference._internal();

  SharedPreferences? prefs;
  bool? isSaveVideo = false;

  bool checkInitialized() {
    if (prefs!.getBool(PreferenceKeys.isSaveVideoTaken.name) == null) {
      return false;
    } else if (prefs!.getString(PreferenceKeys.useModel.name) == null) {
      return false;
    } else {
      return true;
    }
  }

  void initUserSetting() {
    if (!checkInitialized()) {
      prefs!.setBool(PreferenceKeys.isSaveVideoTaken.name, false);
      prefs!.setString(PreferenceKeys.useModel.name, 'movenetThunder');
    }
  }
}
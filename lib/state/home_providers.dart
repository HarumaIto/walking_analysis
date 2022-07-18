import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/model/ml_mode_list.dart';
import 'package:walking_analysis/model/preference_keys.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';

// ボタン用
final prepareStateProvider = StateProvider((_) => true);

final processStateProvider = StateProvider((_) => false);

final restartStateProvider = StateProvider((_) => true);

final saveVideoStateProvider = StateProvider((_) => false);

// BottomNavigationBar用
final selectedIndexProvider = StateProvider((_) => 1);

// 1画像当たりの実行時間
final runTimeProvider = StateProvider((_) => '0');

// モデル選択用
final useModelProvider = StateProvider((_) {
  SharedPreferences pref = UserSettingPreference().prefs!;
  String? useModelName = pref.getString(PreferenceKeys.useModel.name);
  if (useModelName == null) {
    pref.setString(PreferenceKeys.useModel.name, MlModels.movenetThunder.name);
    return 0;
  } else if(useModelName == MlModels.movenetThunder.name) {
    return 0;
  } else {
    return 1;
  }
});

// 機械学習時に今何をしているか表示
final mlStateProvider = StateProvider((_) => '');

// プログレスバー用
final progressValProvider = ChangeNotifierProvider((_) => ProgressValModel());

// chartのデータの初期位置を変更
final positionSliderProvider = StateProvider((_) => 0);

// chartで使うデータ用
final dataListProvider = ChangeNotifierProvider((_) => DataListModel());

// 結果のスコア用
final scoreProvider = StateProvider((_) => '-----');

// 結果の設定用
final isCheckReversal = StateProvider((_) => false);

// 入力動画のサムネイル用
final inputThumbProvider = ChangeNotifierProvider((_) => InputThumbModel());

class InputThumbModel extends ChangeNotifier {
  Uint8List? bytes;

  void setThumbnail(Uint8List data) {
    bytes = data;
    notifyListeners();
  }

  void reset() {
    bytes = null;
    notifyListeners();
  }

  bool isState() {
    if (bytes == null) {
      return false;
    } else {
      return true;
    }
  }
}

class ProgressValModel extends ChangeNotifier {
  double value = 0.0;
  bool isDeterminate = true;

  void setValue(double _value) {
    value = _value;
    notifyListeners();
  }

  void setIsDeterminate(bool state) {
    isDeterminate = state;
    notifyListeners();
  }

  void reset() {
    value = 0.0;
    isDeterminate = true;
    notifyListeners();
  }
}

class DataListModel extends ChangeNotifier {
  List dataList = [];
  List configuredDataList = [];

  void setValue(List list) {
    dataList = list;
    notifyListeners();
  }

  void setConfiguredData(List list) {
    configuredDataList = list;
    notifyListeners();
  }

  void reset() {
    dataList = [];
    configuredDataList = [];
    notifyListeners();
  }
}
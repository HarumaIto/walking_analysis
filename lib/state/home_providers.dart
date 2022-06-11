import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ボタン用
final prepareStateProvider = StateProvider((_) => true);

final processStateProvider = StateProvider((_) => false);

final restartStateProvider = StateProvider((_) => true);

// BottomNavigationBar用
final selectedIndexProvider = StateProvider((_) => 1);

// モデル選択用
final useModelProvider = StateProvider((_) => 0);

// プログレスバー用
final progressValProvider = ChangeNotifierProvider((_) => ProgressValModel());

// chartで使うデータ用
final dataListProvider = ChangeNotifierProvider((_) => DataListModel());

// 結果のスコア用
final scoreProvider = StateProvider((_) => '-----');

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

  void setValue(List list) {
    dataList = list;
    notifyListeners();
  }

  void reset() {
    dataList = [];
    notifyListeners();
  }
}
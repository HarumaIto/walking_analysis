import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ファイル一覧用
final fileListProvider = ChangeNotifierProvider((_) => FileListModel());

// プレビュー用
final previewProvider = ChangeNotifierProvider((_) => PreviewModel());

class FileListModel extends ChangeNotifier {
  List fileNameList = [];

  void setList(List list) {
    fileNameList.clear();
    fileNameList.addAll(list);
    notifyListeners();
  }
}

class PreviewModel extends ChangeNotifier {
  static const int NONE = 0;
  static const int CSV_EXTENSION = 1;
  static const int MP4_EXTENSION = 2;

  int fileExtension = NONE;

  void setFileExtension(int extension) {
    fileExtension = extension;
    notifyListeners();
  }
}
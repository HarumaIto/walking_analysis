import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/repository/toast_repository.dart';

import 'package:intl/intl.dart' as intl;

import '../model/preference_keys.dart';
import '../repository/sharedpref_repository.dart';
import '../state/file_library_provider.dart';

/// ファイルを作成
String createFile(String path) {
  final file = File(path);
  if (file.existsSync()) {
    // すでにPathが存在する
    return path;
  } else {
    // trueにすると親Pathがなくても作成される
    file.createSync(recursive: true);
    return path;
  }
}

/// 一時ディレクトリへのパス
Future<String> getTemporaryDirectoryPath() async {
  Directory tmpDir = await getTemporaryDirectory();
  var tempDirPath = tmpDir.path;
  final localPath = '$tempDirPath/local';
  await Directory(localPath).create(recursive: true);
  return localPath;
}

/// 撮影した動画を写真またはギャラリーへ保存
void saveVideoTaken(String path) {
  SharedPreferences pref = UserSettingPreference().prefs!;
  // 年月日時間を取得
  DateTime now = DateTime.now();
  String formattedDate = intl.DateFormat('yyyyMMddhhmmss').format(now);
  final newFilePath = '${getDirectoryForPath(path)}/$formattedDate.mp4';
  // 一時的に保存用で別名ファイルを作成
  File(path).copySync(newFilePath);
  bool? isSave = pref.getBool(PreferenceKeys.isSaveVideoTaken.name);
  if (isSave != null && isSave) {
    // ギャラリーや写真に動画を保存
    GallerySaver.saveVideo(newFilePath).then((value) {
      if (value!) {
        showToast('撮影した動画を保存しました');
        // 一時的に作成したファイルを削除
        File(newFilePath).delete(recursive: true);
      }
    });
  }
}

/// 機械学習で使った連番画像を削除
void deleteCache() async {
  // ディレクトリ削除
  Directory directory = await getTemporaryDirectory();
  Directory localDir = Directory('${directory.path}/local');
  int length = localDir.listSync(followLinks: false ).length;
  Directory(localDir.path).delete(recursive: true).then((value) =>
      showToast('$length個の一時的ファイルを削除しました')
  );
}

/// ディレクトリからファイルを取得する
void getFileList(WidgetRef ref, Directory dir) async {
  List<String> list = getOriginalFileNameList(dir);

  // プログラム用のファイルを削除
  list.remove('select.mp4');
  list.remove('input.mp4');
  list.remove('output.mp4');
  list.remove('thumb.jpg');

  // 並べ替えてproviderにセット
  list.sort((a, b) => a.compareTo(b));
  ref.read(fileListProvider.notifier).setList(list);
}

/// pathからdirectoryの部分を取得する
String getDirectoryForPath(String path) {
  final splitList = path.split('/');
  int length = splitList.length;
  String result = splitList[0];
  for (int i=1; i<length-1; i++) {
    result = '$result/${splitList[i]}';
  }
  return result;
}

/// pathからfile名を取得
String getFileNameForPath(String path) {
  final fullSplit = path.split('/');
  return fullSplit[fullSplit.length-1];
}

/// 拡張子を取得
String getExtensionForPath(String path) {
  final splitList = path.split('.');
  return splitList[splitList.length - 1];
}

/// ファイル名チェック
bool checkInputFileName(String text, String extension, Directory directory) {
  if (text.isNotEmpty) {
    String name = '$text.$extension';
    // ファイル名が重複してエラーが出ないようチェック
    List<String> list = getOriginalFileNameList(directory);
    for (int i=0; i<list.length; i++) {
      if (list[i] == name) {
        break;
      } else if (i == list.length - 1) {
        return true;
      }
    }
  }
  return false;
}

/// CSVファイルを作成
void createCSVFile(
    String outputPath,
    List<String> headerList,
    List<dynamic> dataList,) {

  int numItem = headerList.length;

  // 横列を入れるリスト
  List<List<dynamic>> rows = [];

  // ヘッダーを書き込む
  // 横列に入れるデータを入れるリスト
  List<dynamic> headerLow = [];
  for (int i=0; i<numItem; i++) {
    headerLow.add(headerList[i]);
  }
  rows.add(headerLow);

  // データがあれば書き込む
  if (dataList.isNotEmpty) {
    for (int i=0; i<dataList.length; i++) {
      List<dynamic> row = [];
      for (int j=0; j<numItem; j++) {
        row.add(dataList[i][j]);
      }
      rows.add(row);
    }
  }

  String csv = const ListToCsvConverter().convert(rows);

  File file = File(outputPath);
  file.writeAsString(csv);
}

/// アプリ上で作成したファイルたちを取得する
List<String> getOriginalFileNameList(Directory directory) {
  List<String> list = [];

  List fileList = directory.listSync(recursive: true, followLinks: false);

  for (var file in fileList) {
    String fileName = cuttingNameFromPath(file.toString());

    final pos = fileName.length - 1;
    String result = fileName.substring(0, pos);

    list.add(result);
  }

  return list;
}

/// 独自のAssetsのcsvファイルからデータ取得
Future<List> getDataForAssetsCSV(String filePath) async {
  List<List<int>> data = [];

  String csv = await rootBundle.loadString(filePath);
  List rows = csv.split('\n');
  // 一列目はHeaderだから削除
  rows.removeAt(0);

  for (String line in rows) {
    List<int> row = [];
    for (String item in line.split(',')) {
      row.add(double.parse(item).round());
    }
    data.add(row);
  }

  return data;
}

/// 独自の内部ファイルのcsvファイルからデータ取得
List getDataForFileCSV(String filePath) {
  List<List<int>> data = [];

  File file = File(filePath);
  String csv = file.readAsStringSync();
  List rows = csv.split('\n');
  // 一列目はHeaderだから削除
  rows.removeAt(0);

  try {
    for (String line in rows) {
      List<int> row = [];
      for (String item in line.split(',')){
        row.add(double.parse(item).round());
      }
      data.add(row);
    }
  } catch (e) {
    Fluttertoast.showToast(
        msg: 'ファイルを正しく読み込めませんでした',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  return data;
}

/// pathからファイル名だけを受け取る
String cuttingNameFromPath(String filePath) {
  var splitList = filePath.split('/');
  return splitList[splitList.length - 1];
}
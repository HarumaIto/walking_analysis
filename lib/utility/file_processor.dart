import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';

/// 一時ディレクトリへのパス
Future<String> getTemporaryDirectoryPath() async {
  Directory tmpDocDir = await getTemporaryDirectory();
  return tmpDocDir.path;
}

/// アプリケーション専用のディレクトリへのパス
 Future<String> getExternalStoragePath() async {
  Directory? appDocDir = await getExternalStorageDirectory();
  return appDocDir!.path;
}

/// 機械学習で使った連番画像を削除
void deleteCache() async {
  // ディレクトリ削除
  String dirPath = await getTemporaryDirectoryPath();
  Directory(dirPath).deleteSync(recursive: true);
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
    for (String item in line.split(',')){
      row.add(double.parse(item).round());
    }
    data.add(row);
  }

  return data;
}

/// 独自の内部ファイルのcsvファイルからデータ取得
List getDataForFileCSV(String filePath) {
  print(filePath);
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
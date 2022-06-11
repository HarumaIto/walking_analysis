import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walking_analysis/model/video_file_path.dart';
import 'package:walking_analysis/utility/file_processor.dart';
import 'package:walking_analysis/widget/original_icon_button.dart';

import 'package:intl/intl.dart' as intl;

import '../model/configs/preference_keys.dart';
import '../model/configs/static_var.dart';
import '../repository/sharedpref_repository.dart';
import '../state/home_providers.dart';
import '../utility/calculation.dart';

class ResultViewModel extends ConsumerWidget {
  const ResultViewModel({Key? key}) : super(key: key);

  void processResult(List list, WidgetRef ref) {
    // データ取得
    List dataList = dataExtraction(list);
    List compDataList = dataExtraction(StaticVar.comparisonData);

    // データ量の少ない方を調整をする
    dataList.length < compDataList.length
        ? dataList = unification(dataList, compDataList)
        : compDataList = unification(compDataList, dataList);

    // 相関係数から一致率を算出する
    double ccResult = correlationCoefficient(dataList, compDataList);
    String score = '';
    if (ccResult.isNaN) {
      // Not a Number の場合
      score = '0';
    } else {
      // 通常
      score = (ccResult * 100).round().toString();
    }

    /*
    全ての Widget のビルドが終わったタイミングで呼ばれる callback を配置
    理由 : widgetのビルド中に状態を変更して、エラーが発生する
          機械学習処理で追加されるデータを複数ViewModelで参照し、同じタイミングで
          再描画しようとして発生するエラーに対応するため
     */
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoreProvider.notifier).state = score;
    });
  }

  // データ抽出
  List dataExtraction(List list) {
    List results = [];
    for (int i=0; i < list.length; i++) {
      results.add(list[i][0]);
    }
    return results;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String score = ref.watch(scoreProvider);
    List dataList = ref.watch(dataListProvider).dataList;
    if (dataList.isNotEmpty && score == '-----') processResult(dataList, ref);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text('スコア', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(score),
        OriginalIconButton(
          icon: Icons.save_alt,
          onPressed: UserSettingPreference().prefs!.getBool(PreferenceKeys.isSaveVideo.name)! && StaticVar.videoSaveState
              ? () => saveVideoDialog(context)
              : null,
          text: const Text('動画を保存'),
        ),
      ],
    );
  }

  void saveVideoDialog(BuildContext context) async {
    // 動画保存用ダイアログ
    DateTime now = DateTime.now();
    String formattedDate = intl.DateFormat('yyyy-MM-dd–hh-mm-ss').format(now);
    String newFileName = formattedDate;
    Directory? dir = await getExternalStorageDirectory();
    showDialog(context: context, barrierDismissible: false, builder: (_) {
      return AlertDialog(
        title: const Text('ファイル名を入力'),
        content: TextField(
          obscureText: true,
          decoration: InputDecoration(
              hintText: 'ファイル名を入力してください',
              border: const OutlineInputBorder(),
              labelText: formattedDate
          ),
          onChanged: (text) {
            newFileName = text;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (checkInputFileName(newFileName, VideoFilePath.mlOutputPath, dir!)) {
                String dirPath = dir.path;
                String filePath = '$dirPath/$newFileName.mp4';
                File(VideoFilePath.mlOutputPath)
                    .copy(filePath)
                    .then((value) => StaticVar.videoSaveState = false);
              } else {
                showDialog(context: context, builder: (context) {
                  return AlertDialog(
                    title: const Text('ファイル名を変更できませんでした', style: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: Colors.redAccent
                    ),),
                    content: const Text('同名のファイルが存在するか、ファイル名が入力されませんでした'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('OK', style: TextStyle(color: Color(0xffeece01)),)
                      )
                    ],
                  );
                });
              }
            },
            style: TextButton.styleFrom(
              primary: Colors.white54,
            ),
            child: const Text('OK', style: TextStyle(color: Color(0xffeece01)),),
          )
        ],
      );
    });
  }
}
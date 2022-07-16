import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walking_analysis/model/video_file_path.dart';
import 'package:walking_analysis/repository/toast_repository.dart';
import 'package:walking_analysis/utility/file_processor.dart';
import 'package:walking_analysis/widget/original_icon_button.dart';

import 'package:intl/intl.dart' as intl;

import '../model/global_variable.dart';
import '../state/home_providers.dart';
import '../utility/calculation.dart';

class ResultViewModel extends ConsumerWidget {
  ResultViewModel({Key? key}) : super(key: key);

  late bool saveVideoState;

  void processResult(List list, WidgetRef ref) {
    // データ取得
    List dataList = dataExtraction(list, GlobalVar.leftIndex);
    List compDataList = dataExtraction(GlobalVar.comparisonData, 0);

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
  List dataExtraction(List list, int index) {
    List results = [];
    for (int i=0; i < list.length; i++) {
      // indexは左右のこと
      results.add(list[i][index]);
    }
    return results;
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL', style: TextStyle(color: Color(0xffeece01)),)
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (checkInputFileName(newFileName, VideoFilePath.mlOutputPath, dir!)) {
                String dirPath = dir.path;
                String filePath = '$dirPath/$newFileName.mp4';
                File(VideoFilePath.mlOutputPath).copy(filePath).then((value) {
                  saveVideoState = false;
                  showToast('動画を保存しました');
                });
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
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(isCheckReversal);
    String score = ref.watch(scoreProvider);
    List dataList = ref.watch(dataListProvider).dataList;
    saveVideoState = ref.watch(saveVideoStateProvider);
    if (dataList.isNotEmpty) processResult(dataList, ref);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Text('スコア', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(score),
        OriginalIconButton(
          icon: Icons.save_alt,
          onPressed: saveVideoState
              ? () => saveVideoDialog(context)
              : null,
          text: const Text('動画を保存'),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/configs/static_var.dart';
import '../state/home_providers.dart';
import '../utility/calculation.dart';

class ResultViewModel extends ConsumerWidget {
  ResultViewModel({Key? key}) : super(key: key);

  String coincidentRatio = '---';

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
      coincidentRatio = '0';
    } else {
      // 通常
      score = (ccResult * 100).round().toString();
      coincidentRatio = ccResult.toString();
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

    return Container(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Text('スコア', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(score)
            ],
          ),
          ExpansionTile(
            title: const Text('詳細', style: TextStyle(fontSize: 14)),
            textColor: Colors.black87,
            iconColor: const Color(0xffeece01),
            children: <Widget> [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('一致率'),
                  Text(coincidentRatio)
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
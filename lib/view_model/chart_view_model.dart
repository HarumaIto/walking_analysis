import 'package:charts_flutter/flutter.dart' as chart;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/angle_data.dart';
import '../model/configs/static_var.dart';
import '../state/home_providers.dart';
import '../utility/chart_util.dart';

class ChartViewModel extends ConsumerWidget {
  ChartViewModel({Key? key}) : super(key: key);

  List<chart.Series> seriesList = [];

  // chartで使えるようにデータ変換
  List<chart.Series<AngleData, int>> _createDataList(List list) {
    List<AngleData> compDataList = dataExtraction(StaticVar.comparisonData, 0);
    List<AngleData> dataList = dataExtraction(list, 0);
    
    return _createChart(compDataList, dataList);
  }

  // chartを作成する
  List<chart.Series<AngleData, int>> _createChart(
      List<AngleData> compDataList,
      List<AngleData> dataList,) {
    return [
      chart.Series<AngleData, int>(
          id: 'comparison chart',
          domainFn: (data, _) => data.count,
          measureFn: (data, _) => data.value,
          data: compDataList
      ),
      chart.Series<AngleData, int>(
        id: 'angle chart',
        domainFn: (data, _) => data.count,
        measureFn: (data, _) => data.value,
        data: dataList
      ),
    ];
  }

  // 初期化したチャートを作成する
  List<chart.Series<AngleData, int>> _createInitChart() {
    List<AngleData> noDataList = [];

    return [
      chart.Series<AngleData, int>(
        id: 'no data',
        domainFn: (data, _) => data.count,
        measureFn: (data, _) => data.value,
        data: noDataList
      )
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List dataList = ref.watch(dataListProvider).dataList;

    return Container(
      height: 200,
      width: double.infinity,
      child: dataList.isEmpty
          ? chart.LineChart(_createInitChart())
          : chart.LineChart(
          _createDataList(dataList)
      ),
    );
  }
}
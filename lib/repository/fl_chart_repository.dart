import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/global_variable.dart';
import '../utility/calculation.dart';

class FlChartRepository {

  final bool showComparisonData;
  final List dataList;

  FlChartRepository({
    required this.showComparisonData,
    required this.dataList
  });

  // チャートを作成
  LineChartData createChartData() {
    return LineChartData(
      lineTouchData: _lineTouchData,
      titlesData: _titlesData,
      lineBarsData: _getLineBarData(dataList),
      maxX: 100,
      minX: 0,
      maxY: 180,
      minY: 60,
    );
  }

  // さわった時に表示されるデータを設定
  LineTouchData get _lineTouchData => LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
      )
  );

  // 上下左右のタイトルの表示設定
  FlTitlesData get _titlesData => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: _bottomTitles,
    ),
    rightTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: _leftTitles(),
    ),
  );

  // 線グラフに表示するデータを取得
  List<LineChartBarData> _getLineBarData(List dataList) {
    List<LineChartBarData> result = [];
    if (showComparisonData) {
      result.add(_getLineChartBarData(GlobalVar.comparisonData));
    }
    if (dataList.isNotEmpty) {
      result.add(_getLineChartBarData(dataList));
    }
    return result;
  }

  // グラフにするデータを設定
  LineChartBarData _getLineChartBarData(List list) {
    return LineChartBarData(
        isCurved: true,
        barWidth: 4,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
        spots: _flSpotDataExtraction(list, 0)
    );
  }

  // 左のタイトルに表示するテキストを設定
  Widget _leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff75729e),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 60:
        text = '60';
        break;
      case 120:
        text = '120';
        break;
      case 180:
        text = '180';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.center);
  }

  // 左のタイトルの設定
  SideTitles _leftTitles() => SideTitles(
    getTitlesWidget: _leftTitleWidgets,
    showTitles: true,
    interval: 1,
    reservedSize: 40,
  );

  // 下のタイトルに表示するテキストの設定
  Widget _bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff72719b),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 0:
        text = const Text('0', style: style);
        break;
      case 50:
        text = const Text('50', style: style);
        break;
      case 100:
        text = const Text('100', style: style);
        break;
      default:
        text = const Text('');
        break;
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  // 下のタイトルを設定
  SideTitles get _bottomTitles => SideTitles(
      showTitles: true,
      reservedSize: 32,
      interval: 1,
      getTitlesWidget: _bottomTitleWidgets
  );

  // データ抽出
 // columnNum => 必要な縦列のindex
  List<FlSpot> _flSpotDataExtraction(List list, int columnNum) {
    List<FlSpot> result = [];

    int dataLength = list.length;
    for (int i=0; i<dataLength; i++) {
      double count = normalization(i, dataLength);
      result.add(FlSpot(count, list[i][columnNum].toDouble()));
    }

    return result;
  }
}


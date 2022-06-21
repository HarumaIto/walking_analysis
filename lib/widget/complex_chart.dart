import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/global_variable.dart';
import '../repository/fl_chart_repository.dart';

class ComplexChart extends StatelessWidget {
  final bool showComparisonData;
  final List dataList;

  ComplexChart({
    required this.dataList,
    required this.showComparisonData,
    Key? key}) : super(key: key);

  List<Widget> getChildren(double height, double width, List dataList) {
    return [
      SizedBox(
        height: height,
        width: width,
        child: LineChart(
            FlChartRepository(
              showComparisonData: showComparisonData,
              dataList: dataList,
              columnNumber: 0,
            ).createChartData()
        ),
      ),
      SizedBox(
        height: height,
        width: width,
        child: LineChart(
            FlChartRepository(
              showComparisonData: showComparisonData,
              dataList: dataList,
              columnNumber: 1,
            ).createChartData()
        ),
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth  = GlobalVar.screenWidth;

    if (screenWidth > 500) {
      return Container(
        margin: const EdgeInsets.only(top: 4, right: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: getChildren(200, screenWidth/2.3, dataList),
        ),
      );
    } else {
      return Container(
          margin: const EdgeInsets.only(top: 6, right: 12),
          child: Column(
            children: getChildren(120, screenWidth-1.2, dataList),
          )
      );
    }
  }
}
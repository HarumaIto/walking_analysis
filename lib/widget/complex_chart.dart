import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../model/global_variable.dart';
import '../repository/fl_chart_repository.dart';

class ComplexChart extends StatelessWidget {
  final bool showComparisonData;
  final List dataList;

  const ComplexChart({
    required this.dataList,
    required this.showComparisonData,
    Key? key}) : super(key: key);

  List<Widget> createChildren(double height, double width, List dataList) {
    return [
      SizedBox(
        height: height,
        width: width,
        child: LineChart(
            FlChartRepository(
              showComparisonData: showComparisonData,
              dataList: dataList,
              columnCompNumber: 0,
              columnDataNumber: GlobalVar.leftIndex,
            ).createChartData()
        ),
      ),
      const SizedBox(height: 8,),
      SizedBox(
        height: height,
        width: width,
        child: LineChart(
            FlChartRepository(
              showComparisonData: showComparisonData,
              dataList: dataList,
              columnCompNumber: 1,
              columnDataNumber: GlobalVar.rightIndex,
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
          children: createChildren(200, screenWidth/2.3, dataList),
        ),
      );
    } else {
      return Container(
          margin: const EdgeInsets.only(top: 6, left: 4, right: 16),
          child: Column(
            children: createChildren(120, screenWidth-1.2, dataList),
          )
      );
    }
  }
}
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/repository/fl_chart_repository.dart';

import '../model/global_variable.dart';
import '../state/home_providers.dart';

class ChartViewModel extends ConsumerWidget {
  const ChartViewModel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List dataList = ref.watch(dataListProvider).dataList;
    double screenWidth  = GlobalVar.screenWidth;

    return Container(
      height: 200,
      width: screenWidth-50,
      margin: const EdgeInsets.only(top: 4, right: 8),
      child: LineChart(
        FlChartRepository(
            showComparisonData: true,
            dataList: dataList
        ).createChartData()
      ),
    );
  }
}
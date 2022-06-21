import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/home_providers.dart';
import '../widget/complex_chart.dart';

class ChartViewModel extends ConsumerWidget {
  const ChartViewModel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List dataList = ref.watch(dataListProvider).dataList;

    return ComplexChart(dataList: dataList, showComparisonData: true,);
  }
}
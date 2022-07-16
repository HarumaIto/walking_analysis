import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/model/global_variable.dart';

import '../state/home_providers.dart';
import '../widget/complex_chart.dart';

class ChartViewModel extends ConsumerStatefulWidget {
  const ChartViewModel({Key? key}) : super(key: key);

  @override
  ChartViewModelState createState() => ChartViewModelState();
}

class ChartViewModelState extends ConsumerState {

  @override
  Widget build(BuildContext context) {
    bool isChecked = ref.watch(isCheckReversal);
    List dataList = ref.watch(dataListProvider).dataList;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 16),
          child: Row(
            children: [
              const Text('左右反転'),
              Checkbox(
                value: isChecked,
                onChanged: (value) {
                  ref.read(isCheckReversal.notifier).state = value!;
                  GlobalVar.leftIndex = value ? 1 : 0;
                  GlobalVar.rightIndex = value ? 0 : 1;
                },
              ),
            ],
          ),
        ),
        ComplexChart(dataList: dataList, showComparisonData: true,),
      ],
    );
  }

}
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/model/global_variable.dart';

import '../state/home_providers.dart';
import '../widget/complex_chart.dart';

class ChartViewModel extends ConsumerWidget {
  const ChartViewModel({Key? key}) : super(key: key);

  List shiftArray(List sourceData, int deletionEnd) {
    if (sourceData.isEmpty || deletionEnd==0) return sourceData;
    sourceData.removeRange(1, deletionEnd);
    return sourceData;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Material Design 3 の色を取得できる (primary, secondaryなど)
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    bool isChecked = ref.watch(isCheckReversal);
    int positionSlider = ref.watch(positionSliderProvider);
    // 同じ配列を参照するのを防ぐため別の配列にコピーする（=の代入ではだめ）
    List sourceList = [...ref.watch(dataListProvider).dataList];
    List dataList = shiftArray(sourceList, positionSlider.abs());
    // build中のreBuildを防ぐため + 無駄な再描画を防ぐif文
    if (!listEquals(ref.watch(dataListProvider).configuredDataList, dataList)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dataListProvider.notifier).setConfiguredData(dataList);
      });
    }

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
        Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              const SizedBox(height: 16,),
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    child: const Align(
                      alignment:Alignment.centerLeft,
                      child: Text('初期値を変更',),
                    ),
                  ),
                  Align(
                    alignment:Alignment.center,
                    child: Text(
                      '[ ${positionSlider.toString()} ]',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.08),
                  activeTrackColor: colorScheme.primary.withOpacity(0.08),
                  thumbColor: Colors.orange,
                  overlayColor: Colors.orange[100],
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: positionSlider.toDouble(),
                  min: sourceList.isNotEmpty || ref.watch(saveVideoStateProvider)
                      ? -(ref.watch(dataListProvider).dataList.length.toDouble())
                      : 0,
                  max: 0,
                  onChanged: sourceList.isEmpty
                      ? null
                      : (value) {
                    ref.read(positionSliderProvider.notifier).state = value.round();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
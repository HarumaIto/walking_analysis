import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/model/ml_mode_list.dart';

import '../model/global_variable.dart';
import '../repository/ml_repository.dart';
import '../state/home_providers.dart';
import '../widget/original_icon_button.dart';

class SettingItem {
  bool isExpanded;
  String title;
  bool isChecked;
  SettingItem(this.isExpanded, this.title, this.isChecked);
}

class MlViewModel extends ConsumerWidget {
  MlViewModel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var selectedVal = mlDescriptionText[ref.watch(useModelProvider)];
    final canProcess = ref.watch(processStateProvider);
    final runTime = ref.watch(runTimeProvider);
    final progressVal = ref.watch(progressValProvider).value;
    final isDeterminate = ref.watch(progressValProvider).isDeterminate;
    final percentProgress = (ref.watch(progressValProvider).value * 100).round();
    final mlState = ref.watch(mlStateProvider);

    double width = GlobalVar.screenWidth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: width / 1.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                child: isDeterminate
                    ? LinearProgressIndicator(
                  backgroundColor: Colors.grey[400],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  minHeight: 10,
                  value: progressVal,
                ) : LinearProgressIndicator(
                  backgroundColor: Colors.grey[400],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8,),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('$selectedValモデル: $percentProgress%', style: const TextStyle(fontSize: 12),),
                      const Spacer(),
                      Text(mlState, style: const TextStyle(fontSize: 12),)
                    ],
                  ),
                  const SizedBox(height: 2,),
                  Text('実行時間: $runTime [ms]', style: const TextStyle(fontSize: 12),),
                ],
              ),
            ],
          ),
        ),
        OriginalIconButton(
          icon: Icons.auto_awesome_outlined,
          onPressed: canProcess ? () {
            MlRepository.start();
            ref.read(processStateProvider.notifier).state = false;
          } : null,
          text: const Text('実行'),
        )
      ],
    );
  }
}
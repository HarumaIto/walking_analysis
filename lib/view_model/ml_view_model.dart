import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/model/configs/ml_mode_list.dart';

import '../model/configs/static_var.dart';
import '../repository/ml_repository.dart';
import '../state/home_providers.dart';
import '../widget/original_icon_button.dart';

class MlViewModel extends ConsumerWidget {
  const MlViewModel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var selectedVal = mlDescriptionText[ref.watch(useModelProvider)];
    final canProcess = ref.watch(processStateProvider);
    final progressVal = ref.watch(progressValProvider).value;
    final isDeterminate = ref.watch(progressValProvider).isDeterminate;
    final percentProgress = (ref.watch(progressValProvider).value * 100).round();

    double width = StaticVar.screenWidth;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: width / 1.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
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
              Text('$selectedVal : $percentProgress%', style: const TextStyle(fontSize: 14),),
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:walking_analysis/screen/user_setting_page.dart';

import '../../repository/restart_repository.dart';
import '../../state/home_providers.dart';
import '../../home_view_model/chart_view_model.dart';
import '../../home_view_model/ml_view_model.dart';
import '../../home_view_model/prepare_view_model.dart';
import '../../home_view_model/result_view_model.dart';
import '../../widget/card_template.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttonState = ref.watch(restartStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: buttonState
                ? () => RestartRepository.restart(ref)
                : null,
            icon: const Icon(Icons.restart_alt_outlined),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UserSettingPage())
              );
            },
            icon: const Icon(Icons.settings)
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 8,),
            CardTemplate(
                title: '① 選択してください',
                child: const PrepareViewModel()
            ),
            CardTemplate(
                title: '② 機械学習',
                child: MlViewModel()
            ),
            CardTemplate(
                title: '③ 結果のグラフを表示',
                child: ChartViewModel()
            ),
            CardTemplate(
                title: '④ 最終結果',
                child: ResultViewModel()
            ),
            const SizedBox(height: 8,),
          ],
        ),
      ),
    );
  }
}
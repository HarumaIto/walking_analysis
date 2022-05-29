import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'model/configs/static_var.dart';
import 'screen/introduction/introduction_page.dart';
import 'screen/main_page.dart';
import 'state/introduction_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  ThemeData _themeData() {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.orangeAccent[200]
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    StaticVar.globalRef = ref;

    ref.read(introductionProvider.notifier).getPrefIntro();
    final intro = ref.watch(introductionProvider).intro;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: _themeData(),
      home: intro ? IntroductionPage() : const MyMainPage(),
    );
  }
}
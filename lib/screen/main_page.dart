import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/configs/page_list.dart';
import '../model/configs/static_var.dart';
import '../state/home_providers.dart';
import '../utility/file_processor.dart';

class MyMainPage extends ConsumerStatefulWidget {
  const MyMainPage({Key? key}) : super(key: key);

  @override
  MyMainPageState createState() => MyMainPageState();
}

class MyMainPageState extends ConsumerState<MyMainPage> {

  @override
  void dispose() {
    // アプリで作成された一時ファイルの削除
    deleteCache();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // スプラッシュを消す
    FlutterNativeSplash.remove();
  }

  @override
  Widget build(BuildContext context) {
    StaticVar.screenWidth = MediaQuery.of(context).size.width;
    StaticVar.screenHeight = MediaQuery.of(context).size.height;
    final selectedIndex = ref.watch(selectedIndexProvider);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: pageList[selectedIndex],
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            ref.read(selectedIndexProvider.notifier).state = index;
          },
          selectedIndex: selectedIndex,
          destinations: const <Widget>[
            NavigationDestination(
              selectedIcon: Icon(Icons.photo_camera_front),
              icon: Icon(Icons.photo_camera_front_outlined),
              label: 'プレビュー'
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.home),
              icon: Icon(Icons.home_outlined),
              label: 'ホーム',
            ),
            NavigationDestination(
              selectedIcon: Icon(Icons.insert_drive_file),
              icon: Icon(Icons.insert_drive_file_outlined),
              label: 'ファイル操作',
            ),
          ],
        )
    );
  }
}
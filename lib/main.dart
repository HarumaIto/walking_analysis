import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';
import 'package:walking_analysis/utility/file_processor.dart';

import 'app.dart';
import 'model/configs/static_var.dart';
import 'model/video_file_path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async{
  // ここで非同期処理を行えるようにする
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ステータスバー & ナビゲーションバーの設定
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
        child: MyApp(),
    ),
  );

  // pathの設定
  VideoFilePath.trInputPath = '${(await getExternalStorageDirectory())!.path}/select.mp4';
  VideoFilePath.mlInputPath = '${(await getExternalStorageDirectory())!.path}/input.mp4';
  VideoFilePath.mlOutputPath = '${(await getExternalStorageDirectory())!.path}/output.mp4';
  // 比較用データの設定
  StaticVar.comparisonData = await getDataForAssetsCSV('assets/comparison_data.csv');
  // ユーザー設定の初期化
  UserSettingPreference().initUserSetting();
}
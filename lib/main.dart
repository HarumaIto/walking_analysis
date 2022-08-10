import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walking_analysis/repository/sharedpref_repository.dart';
import 'package:walking_analysis/utility/file_processor.dart';

import 'app.dart';
import 'model/global_variable.dart';
import 'model/video_file_path.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // ここで非同期処理を行えるようにする
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Firebaseを初期化
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // crashlyticsにエラーを送信する
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ステータスバー & ナビゲーションバーの設定
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // ユーザー設定の初期化
  UserSettingPreference userSettingPreference = UserSettingPreference();
  userSettingPreference.prefs = await SharedPreferences.getInstance();
  userSettingPreference.initUserSetting();

  // pathの設定
  Directory directory = await getApplicationDocumentsDirectory();
  directory.createSync(recursive: true);
  VideoFilePath.myAppDirectoryPath = '${directory.path}/local';
  VideoFilePath.trimmingInputPath =
      createFile('${VideoFilePath.myAppDirectoryPath}/select.mp4');
  VideoFilePath.mlInputPath =
      createFile('${VideoFilePath.myAppDirectoryPath}/input.mp4');
  VideoFilePath.mlOutputPath =
      createFile('${VideoFilePath.myAppDirectoryPath}/output.mp4');
  // 比較用データの設定
  GlobalVar.comparisonData = await getDataForAssetsCSV('assets/comparison_data.csv');

  runZonedGuarded(() {
    // 最後にUIを構築
    runApp(
      const ProviderScope(
        child: MyApp(),
      ),
    );
  }, (error, stack) =>
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true)
  );
}
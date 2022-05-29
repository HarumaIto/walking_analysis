import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'model/configs/static_var.dart';
import 'model/video_file_path.dart';

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ステータスバー & ナビゲーションバーの設定
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
        child: MyApp(),
    ),
  );

  // pathの設定
  VideoFilePath.setup();
  // 比較用データの設定
  StaticVar().setComparisonData();
}
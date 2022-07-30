import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../model/global_variable.dart';
import '../model/images_info.dart';
import '../model/video_file_path.dart';
import '../state/home_providers.dart';
import '../utility/file_processor.dart';
import '../utility/video_to_image.dart';

class MlRepository {
  final WidgetRef ref = GlobalVar.globalRef!;
  final MethodChannel channel = const MethodChannel('com.hanjukukobo.walking_analysis/ml');

  double runTimeSum = 0;

  MlRepository.start() {
    createImages().then((pathNameList) {
      _processImage(pathNameList);
    });
  }

  // 動画から連番画像生成
  Future createImages() async {
    ref.read(restartStateProvider.notifier).state = false;
    ref.read(progressValProvider.notifier).setIsDeterminate(false);
    ref.read(mlStateProvider.notifier).state = '入力処理中';

    VideoToImage videoToImage = VideoToImage(VideoFilePath.mlInputPath);
    String localDirectoryPath = await getTemporaryDirectoryPath();
    final frameNum = await videoToImage.videoConfig();
    ImagesInfo.FRAME_NUM = frameNum;
    return await videoToImage.convertImage(localDirectoryPath, frameNum);
  }

  // 姿勢推定を実行
  void _processImage(List pathNameList) async {
    ref.read(progressValProvider.notifier).setIsDeterminate(true);
    ref.read(mlStateProvider.notifier).state = 'AI分析中';

    // 機械学習処理を初期化
    channel.invokeMethod("create", ref.read(useModelProvider));
    List<List<dynamic>> angleLists = [];

    final int maxCount = pathNameList.length;
    int nowCount = 0;
    // 分割した画像の枚数分ループ
    // try-catchはなぜかループが一回多く回ってしまうことに対処するため
    try {
      for (String imagePath in pathNameList) {
        Stopwatch stopwatch = Stopwatch();
        stopwatch.start();
        // ネイティブから関節角度を取得
        Uint8List imageBytes = File(imagePath).readAsBytesSync();
        Map map = await channel.invokeMethod('process', imageBytes);
        final List angleList = map['angleList'];

        // データなければ0を入れる
        if (angleList.isEmpty) angleList..add(0)..add(0);
        angleLists.add(angleList);

        // ネイティブから画像を取得
        final Uint8List imageByte = map['image'];
        ui.Image image = await decodeImageFromList(imageByte);

        _overwriteImage(image, imagePath);

        nowCount++;
        double percent = nowCount / maxCount;
        if (!ref.watch(progressValProvider).isDeterminate) {
          ref.read(progressValProvider.notifier).setIsDeterminate(true);
        }
        ref.read(progressValProvider.notifier).setValue(percent);
        stopwatch.stop();
        runTimeSum += stopwatch.elapsedMilliseconds.toDouble();
        ref.read(runTimeProvider.notifier).state = stopwatch.elapsedMilliseconds.toString();
        stopwatch.reset();
      }
    } catch (e) {
      print(e);
    }

    channel.invokeMethod('close');
    ref.read(progressValProvider.notifier).setIsDeterminate(false);
    ref.read(mlStateProvider.notifier).state = '出力処理中';

    String inputPath = ImagesInfo.IMAGES_PATH!;
    int frameNum = ImagesInfo.FRAME_NUM!;
    String outputVideoPath = VideoFilePath.mlOutputPath;
    DateTime now = DateTime.now();
    String formattedDate = intl.DateFormat('yyyy-MM-dd–hh-mm-ss').format(now);

    ref.read(runTimeProvider.notifier).state = '平均 ${runTimeSum~/frameNum}';

    // 動画出力
    await FFmpegKit.execute("-y -i $inputPath -vcodec mpeg4 -q:v 1 -vframes $frameNum $outputVideoPath");
    deleteCache();

    // csvファイルを作成
    String dirPath = await getStorageDirectoryPath();
    String outputPath = "$dirPath/$formattedDate.csv";
    List<String> headerList = ['left knee', 'right knee'];
    createCSVFile(outputPath, headerList, angleLists);

    ref.read(dataListProvider.notifier).setValue(angleLists);
    ref.read(progressValProvider.notifier).setIsDeterminate(true);
    ref.read(restartStateProvider.notifier).state = true;
    ref.read(saveVideoStateProvider.notifier).state = true;
    ref.read(mlStateProvider.notifier).state = '';
  }

  // 元画像と機械学習の結果を合成して書き換える
  void _overwriteImage(ui.Image image, String path) async {
    // 画像を生成
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final file = File(path);
    final buffer = pngBytes?.buffer;
    await file.writeAsBytes(buffer!.asUint8List(pngBytes!.offsetInBytes, pngBytes.lengthInBytes));
  }
}
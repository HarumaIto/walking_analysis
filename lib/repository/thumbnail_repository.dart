import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:walking_analysis/model/global_variable.dart';
import 'package:walking_analysis/state/home_providers.dart';
import 'package:walking_analysis/utility/file_processor.dart';

void createThumbnail(String path, [
  bool isTrimmed = false,
  String start = '0',
]) {
  // iosでトリミング後の動画のサムネイルを取得しようとするとエラーを吐くからその回避策で
  // ffmpegを使って、元動画から画像を切り出しその画像を使う
  if (isTrimmed) {
    String dirPath = getDirectoryForPath(path);
    String imagePath = '$dirPath/thumb.jpeg';
    FFmpegKit
        .executeAsync('-y -i $path -ss $start -vframes 1 -q:v 1 -f image2 $imagePath')
        .then((value) {
      Uint8List imageByte = File(imagePath).readAsBytesSync();
      GlobalVar.globalRef!.read(inputThumbProvider.notifier).setThumbnail(imageByte);
      return;
    });
  } else {
    VideoThumbnail.thumbnailData(video: path).then((value) {
      GlobalVar.globalRef!.read(inputThumbProvider.notifier).setThumbnail(value!);
    });
  }
}
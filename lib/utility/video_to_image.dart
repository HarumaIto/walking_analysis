import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter/media_information.dart';
import 'package:fraction/fraction.dart';
import 'package:intl/intl.dart';

import '../model/images_info.dart';

class VideoToImage {
  String duration = '';
  String realFrameRate = '';
  final String _filePath ;

  VideoToImage(this._filePath);

  Future videoConfig() async {
    try {
      int frameNum = await FFprobeKit.getMediaInformation(_filePath).then((session) {
        MediaInformation information = session.getMediaInformation()!;
        //動画の時間を取得
        duration = information.getDuration()!;
        if (information.getAllProperties()!['streams'][0]['r_frame_rate'] == '0/0') {
          //FPSを取得
          realFrameRate = information.getAllProperties()!['streams'][1]['r_frame_rate'];
        } else {
          //FPSを取得
          realFrameRate = information.getAllProperties()!['streams'][0]['r_frame_rate'];
        }

        //分数を数値として扱えるようにする
        final fracRealFrameRate = Fraction.fromString(realFrameRate);
        //取得した動画の時間は文字列なので変換する
        final durationDouble = double.parse(duration);
        //動画をスプリットするフレーム数を計算する
        int frameNumber = (durationDouble * fracRealFrameRate.toDouble()).toInt();
        return frameNumber;
      });
      return frameNum;
    } catch (e) {
      print('error : $e');
    }
  }

  Future<List?> convertImage(path, frameNumber) async {
    try {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd–kk-mm-ss').format(now);
      //スプリットした画像を保存するパスを指定しておく
      String outputPath = "$path/${formattedDate}output%04d.png";

      ImagesInfo.IMAGES_PATH = outputPath;

      //ここで動画を指定したフレーム数に画像変換する
      await FFmpegKit
          .execute("-i $_filePath -vcodec png -q:v 1 -vframes $frameNumber $outputPath")
          .then((rc) => print("FFmpeg process exited with rc $rc"));

      List pathNameList = [];

      //画像の保存先をリストに追加
      for (int i = 1; i < frameNumber + 1; i++) {
        String pathName =
            '$path/${formattedDate}output${i.toString().padLeft(4, "0")}.png';
        pathNameList.add(pathName);
      }
      return pathNameList;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
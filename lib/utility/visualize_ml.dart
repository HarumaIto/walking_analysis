import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:flutter/material.dart';

// 線を描画するときに使用
final bodyJoints = [
  Pair(0, 1),
  Pair(0, 2),
  Pair(1, 3),
  Pair(2, 4),
  Pair(0, 5),
  Pair(0, 6),
  Pair(5, 7),
  Pair(7, 9),
  Pair(6, 8),
  Pair(8, 10),
  Pair(5, 6),
  Pair(5, 11),
  Pair(6, 12),
  Pair(11, 12),
  Pair(11, 13),
  Pair(13, 15),
  Pair(12, 14),
  Pair(14, 16),
];

// 元画像と機械学習の結果を合成して書き換える
Future<Uint8List> createOutputImage(List? keyPoints, ui.Image image) async {
  // canvasの用意
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..isAntiAlias = true;

  // 画像描画
  canvas.drawImage(image, Offset.zero, paint);

  if (keyPoints != null) {
    // Painterを用意
    final paintCircle = Paint()
      ..strokeWidth = 6
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final paintLine = Paint()
      ..strokeWidth = 4
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    // 点を描画
    for (List keyPoint in keyPoints) {
      canvas.drawCircle(Offset(keyPoint[0], keyPoint[1]), 6, paintCircle);
    }
    // 線を描画
    for (int i=0; i<bodyJoints.length; i++) {
      var point1 = keyPoints[bodyJoints[i].first];
      var point2 = keyPoints[bodyJoints[i].last];
      canvas.drawLine(Offset(point1[0], point1[1]), Offset(point2[0], point2[1]), paintLine);
    }
  }

  // canvasからエンコード
  final picture = recorder.endRecording();
  final ui.Image resultImage = await picture.toImage(image.width, image.height);

  // 画像を生成
  final pngBytes = await resultImage.toByteData(format: ui.ImageByteFormat.png);

  // Uint8List形式でreturn
  final buffer = pngBytes?.buffer;
  return buffer!.asUint8List(pngBytes!.offsetInBytes, pngBytes.lengthInBytes);
}
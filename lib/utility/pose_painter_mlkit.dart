import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {

  PosePainter(this.poses, this.absoluteImageSize, this.rotation,);

  PosePainter.reset();

  List<Pose>? poses;
  Size? absoluteImageSize;
  InputImageRotation? rotation;

  double translateX(
      double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x *
            size.width /
            (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
      case InputImageRotation.rotation270deg:
        return size.width -
            x *
                size.width /
                (Platform.isIOS
                    ? absoluteImageSize.width
                    : absoluteImageSize.height);
      default:
        return x * size.width / absoluteImageSize.width;
    }
  }

  double translateY(
      double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y *
            size.height /
            (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
      default:
        return y * size.height / absoluteImageSize.height;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (poses==null || absoluteImageSize==null || rotation==null) {
      canvas.saveLayer(Rect.largest, Paint());
      canvas.drawPaint(Paint()..blendMode = BlendMode.clear);
      canvas.restore();
      return;
    }

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    for (final pose in poses!) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation!, size, absoluteImageSize!),
              translateY(landmark.y, rotation!, size, absoluteImageSize!),
            ),
            1,
            paint);
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(translateX(joint1.x, rotation!, size, absoluteImageSize!),
                translateY(joint1.y, rotation!, size, absoluteImageSize!)),
            Offset(translateX(joint2.x, rotation!, size, absoluteImageSize!),
                translateY(joint2.y, rotation!, size, absoluteImageSize!)),
            paintType);
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      //Draw legs
      paintLine(
          PoseLandmarkType.leftHip, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightAnkle, rightPaint);

    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}
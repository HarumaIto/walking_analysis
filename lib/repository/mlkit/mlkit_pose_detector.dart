import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'mlkit_pose_painter.dart';


class MlKitPoseDetector {
  final PoseDetector poseDetector = PoseDetector(options: PoseDetectorOptions());

  // CameraImageを使って入力画像を取得
  InputImage initInputImage(CameraImage cameraImage, CameraDescription camera) {
    final inputImage = convertFrameToInputImage(cameraImage, camera);

    return inputImage;
  }

  // 一人分のポーズを取得
  Future<Pose?> runSingleOnFrame(InputImage inputImage) async {
    Pose? result;
    List<Pose> poses = await poseDetector.processImage(inputImage);

    if (poses.isEmpty) {
      result = null;
    } else {
      result = poses[0];
    }

    return result;
  }

  void close() {
    poseDetector.close();
  }

  // 結果からCustomPaintを生成
  CustomPainter? createPainter(InputImage inputImage, Pose pose) {
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      final painter = MlKitPosePainter(
          pose,
          inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
      return painter;
    }
    return null;
  }

  // CameraのFrameからInputImageに変換する
  InputImage convertFrameToInputImage(CameraImage cameraImage, CameraDescription camera) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());

    final InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation)!;

    final InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(cameraImage.format.raw)!;

    final planeData = cameraImage.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          width: plane.width,
          height: plane.height,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }
}
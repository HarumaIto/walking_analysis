import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:walking_analysis/model/global_variable.dart';
import 'package:walking_analysis/utility/image_utils.dart';

import 'dart:math' as math;
import 'package:image/image.dart' as img;

import '../../repository/mlkit/mlkit_pose_detector.dart';
import '../../repository/permission_repository.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  CameraDescription? _camera;
  CameraController? _controller;
  Widget? imageWidget;
  InputImage? inputImage;

  // PoseDetectorのインスタンスを初期化
  final mlKitPoseDetector = MlKitPoseDetector();

  final stopWatch = Stopwatch();
  String timeMs = '';

  bool isUseCamera = false;
  bool _isStreaming = false;
  bool _isDetecting = false;

  // カメラの初期化処理
  void _initializeCamera() async {
    if (await PermissionRequest.cameraRequest()) {
      List<CameraDescription> cameras = await availableCameras();
      _camera = cameras.first;

      if (_controller == null) {
        final CameraController cameraController = CameraController(
          _camera!,
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.bgra8888,
        );
        _controller = cameraController;
        await _controller!.initialize();

        setState(() {
          isUseCamera = true;
        });
      }
    }
  }

  void _start() {
    _controller!.startImageStream(_processCameraImage);
    setState(() {
      _isStreaming = true;
    });
  }

  void _stop() {
    if (_controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
      imageWidget = null;
    }
    if (mounted) {
      setState(() {
        _isStreaming = false;
        timeMs = '';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    if (_isStreaming) _stop();
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller!.dispose();
    mlKitPoseDetector.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size tmp = Size(GlobalVar.screenWidth, GlobalVar.screenHeight);
    double screenH = math.max(tmp.height, tmp.width);
    double screenW = math.min(tmp.height, tmp.width);
    if (isUseCamera) tmp = _controller!.value.previewSize!;
    double previewH = math.max(tmp.height, tmp.width);
    double previewW = math.min(tmp.height, tmp.width);
    double screenRatio = screenH / screenW;
    double previewRatio = previewH / previewW;
    double maxWidth = screenRatio > previewRatio ? screenH / previewH * previewW : screenW;
    double maxHeight = screenRatio > previewRatio ? screenH : screenW / previewW * previewH;

    return Scaffold(
      appBar: AppBar(
        title: const Text('リアルタイム検出'),
        centerTitle: true,
      ),
      body: isUseCamera ? Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(0, 0),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: CameraPreview(_controller!),
            ),
          ),
          _isStreaming && imageWidget != null ? Align(
            alignment: const Alignment(0, 0),
            child: SizedBox(
              width: maxWidth,
              height: maxHeight,
              child: imageWidget
            ),
          ) : Container(),
          _isStreaming ? Align(
            alignment: const Alignment(-0.96, -0.98),
            child: Container(
              color: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              child: Text(
                timeMs,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
            ),
          ) : Container(),
        ],
      ) : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isStreaming ? _stop() : _start(),
        child: _isStreaming
            ? const Icon(Icons.close)
            : const Icon(Icons.add),
      ),
    );
  }

  // CameraImageからInputImageに変更
  Future _processCameraImage(CameraImage cameraImage) async {
    if (_isDetecting) {
      return;
    }
    _isDetecting = true;

    stopWatch.start();

    //Widget image = await compute(convertCameraImageToWidget, cameraImage);
    inputImage = mlKitPoseDetector.initInputImage(cameraImage, _camera!);
    final pose = await mlKitPoseDetector.runSingleOnFrame(inputImage!);
    CustomPainter? customPainter;
    if (pose != null) customPainter = mlKitPoseDetector.createPainter(inputImage!, pose);
    CustomPaint customPaint = CustomPaint(
      painter: customPainter,
    );

    if (mounted) {
      setState(() {
        imageWidget = customPaint;
        stopWatch.stop();
        timeMs = '${stopWatch.elapsedMilliseconds} ms';
      });
    }

    stopWatch.reset();
    _isDetecting = false;
  }

  static Widget convertCameraImageToWidget(CameraImage cameraImage) {
    img.Image image = ImageUtils.convertCameraImage(cameraImage)!;
    if (Platform.isAndroid) image = img.copyRotate(image, 90);
    List<int> intArray = img.encodePng(image);
    Uint8List byteArray = Uint8List.fromList(intArray);
    return Image.memory(byteArray,);
  }
}
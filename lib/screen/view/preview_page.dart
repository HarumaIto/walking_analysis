import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_maven/tflite.dart';
import 'package:walking_analysis/model/global_variable.dart';

import 'dart:math' as math;

import '../../repository/permission_repository.dart';
import '../../utility/visualize_ml.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  CameraDescription? _camera;
  CameraController? _controller;
  Widget? imageWidget;

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
    imageWidget = _controller!.buildPreview();
    _controller!.startImageStream(_processCameraImage);
    _isStreaming = true;
  }

  void _stop() {
    _isStreaming = false;
    if (_controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
      imageWidget = null;
    }
    if (mounted) {
      setState(() {
        timeMs = '';
      });
    }
  }

  void loadModel() {
    Tflite.loadModel(
      model: "assets/posenet.tflite",
      numThreads: 4,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    loadModel();
  }

  @override
  void dispose() {
    if (_isStreaming) _stop();
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller!.dispose();

    Tflite.close();
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
          !_isStreaming ? Align(
            alignment: const Alignment(0, 0),
            child: OverflowBox(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              child: CameraPreview(_controller!),
            ),
          ) : Align(
            alignment: const Alignment(0, 0),
            child: OverflowBox(
              maxWidth: maxWidth,
              maxHeight: maxHeight,
              child: imageWidget,
            ),
          ),
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

    var recognitions = await Tflite.runPoseNetOnFrame(
      bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
      imageWidth: cameraImage.width,
      imageHeight: cameraImage.height
    );

    final List keyPoints = [];
    final widthRatio = cameraImage.width / 125;
    final heightRatio = cameraImage.height / 125;
    if (recognitions!.isNotEmpty) {
      final Map person = recognitions[0];
      for (int i=0; i<person["keypoints"].length; i++) {
        var keyPoint = person["keypoints"][i];
        var row = [];
        row.add((keyPoint["x"] * 125) * widthRatio);
        row.add((keyPoint["y"] * 125) * heightRatio);
        keyPoints.add(row);
      }
      print(keyPoints);
    }

    // image library -> uiImage
    //ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    //ui.FrameInfo frameInfo = await codec.getNextFrame();
    //final uiImage = frameInfo.image;
    final outputImage = await createOutputImage(keyPoints: keyPoints);

    stopWatch.stop();
    if (mounted) {
      setState(() {
        timeMs = '${stopWatch.elapsedMilliseconds} ms';
        imageWidget = Image.memory(outputImage);
      });
    }

    stopWatch.reset();
    _isDetecting = false;
  }
}
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:walking_analysis/model/global_variable.dart';

import 'dart:math' as math;
import 'package:image/image.dart' as imglib;
import 'package:walking_analysis/utility/image_utils.dart';

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

  static const MethodChannel channel = MethodChannel('walking_analysis/ml');

  final stopWatch = Stopwatch();
  String timeMs = '';

  late Future<void> isInitializedCamera;
  bool _isStreaming = false;
  bool _isDetecting = false;

  // カメラの初期化処理
  Future _initializeCamera() async {
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
      return _controller!.initialize();
    }

    return Future.value(true);
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
    setState(() {
      timeMs = '';
    });
  }

  @override
  void initState() {
    super.initState();
    isInitializedCamera = _initializeCamera();

    // 機械学習処理を初期化
    channel.invokeMethod("create", 1);
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller!.dispose();
    channel.invokeMethod('close');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リアルタイム検出'),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: isInitializedCamera,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            Size tmp = Size(GlobalVar.screenWidth, GlobalVar.screenHeight);
            double screenH = math.max(tmp.height, tmp.width);
            double screenW = math.min(tmp.height, tmp.width);
            tmp = _controller!.value.previewSize!;
            double previewH = math.max(tmp.height, tmp.width);
            double previewW = math.min(tmp.height, tmp.width);
            double screenRatio = screenH / screenW;
            double previewRatio = previewH / previewW;
            double maxWidth = screenRatio > previewRatio ? screenH / previewH * previewW : screenW;
            double maxHeight = screenRatio > previewRatio ? screenH : screenW / previewW * previewH;

            return Stack(
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
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
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

    // 入力画像処理
    imglib.Image image = ImageUtils.convertCameraImage(cameraImage)!;
    if (Platform.isAndroid) {
      image = imglib.copyRotate(image, 90);
    }

    // ポーズ推定
    List<int> jpgImage = imglib.encodeJpg(image);
    Uint8List imageBytes = Uint8List.fromList(jpgImage);

    // ネイティブからkeyPointを取得
    Map map = await PreviewPageState.channel.invokeMethod('process', imageBytes);
    final List? keyPoints = map['keyPoint'];

    // image library -> uiImage
    ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    final uiImage = frameInfo.image;
    final outputImage = await createOutputImage(keyPoints, uiImage);

    stopWatch.stop();
    setState(() {
      timeMs = '${stopWatch.elapsedMilliseconds} ms';
      imageWidget = Image.memory(outputImage);
    });

    stopWatch.reset();
    _isDetecting = false;
  }
}
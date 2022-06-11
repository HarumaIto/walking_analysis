import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:walking_analysis/model/global_variable.dart';

import 'dart:math' as math;

import '../../utility/pose_painter_mlkit.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  CameraDescription? _camera;
  CameraController? _controller;

  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  PosePainter? _posePainter;

  final _stopWatch = Stopwatch();
  String _timeMs = '';

  late Future<void> _initializeControllerFuture;
  bool _isStreaming = false;
  bool _isDetecting = false;

  // カメラの初期化処理
  Future _initializeCamera() async {
    debugPrint('initializeCamera');
    List<CameraDescription> cameras = await availableCameras();
    _camera = cameras.first;
    final CameraController cameraController = CameraController(
      _camera!,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _controller = cameraController;
    return _controller!.initialize().then((_) {
      _start();
    });
  }

  void _start() {
    _controller?.startImageStream(_processCameraImage);
    setState(() {
      _isStreaming = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeCamera();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller!.dispose();
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
        future: _initializeControllerFuture,
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

            return Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: const Alignment(0, 0),
                  child: OverflowBox(
                      maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
                      maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
                      child: CustomPaint(
                        foregroundPainter: _posePainter,
                        child: CameraPreview(_controller!),
                      )
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.96, -0.98),
                  child: Container(
                    color: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text(
                      _timeMs,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black87
                      ),
                    ),
                  )
                )
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )
    );
  }

  Future _processCameraImage(CameraImage image) async {
    _stopWatch.start();

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation = InputImageRotationValue.fromRawValue(_camera!.sensorOrientation);
    if (imageRotation == null) return;

    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return;

    final planeData = image.planes.map(
          (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
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

    processImage(inputImage);
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_isStreaming) return;
    if (_isDetecting) return;
    _isDetecting = true;

    final poses = await _poseDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      _posePainter = PosePainter(poses, inputImage.inputImageData!.size,
          inputImage.inputImageData!.imageRotation);
    }
    _isDetecting = false;
    _stopWatch.stop();
    if (mounted) {
      setState(() {
        _timeMs = '${_stopWatch.elapsedMilliseconds} [ms]';
      });
    }
    _stopWatch.reset();
  }
}
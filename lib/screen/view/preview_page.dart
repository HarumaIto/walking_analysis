import'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:walking_analysis/model/global_variable.dart';

import 'dart:math' as math;
import 'package:image/image.dart' as imglib;

import '../../utility/pose_painter_mlkit.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> with WidgetsBindingObserver {
  CameraDescription? _camera;
  CameraController? _controller;
  Uint8List? decodedBytes;

  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  PosePainter? _posePainter;
  InputImage? oldInputImage;

  final _stopWatch = Stopwatch();
  String _timeMs = '';

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
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      _controller = cameraController;
      return _controller!.initialize();
    }

    return Future.value(true);
  }

  void _start() {
    _controller!.startImageStream(_processCameraImage);
    _isStreaming = true;
    setState(() {});
  }

  void _stop() {
    _isStreaming = false;
    if (_controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    setState(() {
      decodedBytes = null;
      _posePainter = PosePainter.reset();
      _timeMs = '';
    });
  }

  @override
  void initState() {
    super.initState();
    isInitializedCamera = _initializeCamera();
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
                Align(
                  alignment: const Alignment(0, 0),
                  child: OverflowBox(
                    maxWidth: maxWidth,
                    maxHeight: maxHeight,
                    child: CustomPaint(
                      foregroundPainter: _posePainter,
                      child: CameraPreview(_controller!),
                    ),
                  ),
                ),
                _isStreaming ? Align(
                  alignment: const Alignment(-0.96, -0.98),
                  child: Container(
                    color: Colors.white70,
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text(
                      _timeMs,
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
    // cameraImage -> imglib.image -> Uint8List
    /*
    setState(() {
      decodedBytes = Uint8List.fromList(
          imglib.encodePng(
              _getImage(image, imageRotation.rawValue)
          ));
      print('setState');
    });
     */
    processImage(inputImage);
  }

  // 機械学習で結果を取得する
  Future<void> processImage(InputImage inputImage) async {
    if (!_isStreaming) return;
    if (_isDetecting) return;
    _isDetecting = true;
    oldInputImage = inputImage;

    final poses = await _poseDetector.processImage(inputImage);
    if (inputImage.inputImageData?.size != null &&
        inputImage.inputImageData?.imageRotation != null) {
      _posePainter = PosePainter(
        poses,
        inputImage.inputImageData!.size,
        inputImage.inputImageData!.imageRotation,);
    }

    _isDetecting = false;
    _stopWatch.stop();
    if (mounted) {
      setState(() {
        _timeMs = '${_stopWatch.elapsedMilliseconds} [ms]';
      });
    }
    _stopWatch.reset();
    if (!_isStreaming) {
      _stop();
    }
  }

  imglib.Image _getImage(CameraImage cameraImage, int rotation) {
    imglib.Image image = _convertYUV420(cameraImage);
    imglib.Image rotated = imglib.copyRotate(image, rotation);

    return rotated;
  }

  imglib.Image _convertYUV420(CameraImage image) {
    const int shift = (0xFF << 24);

    final img = imglib.Image(image.width, image.height);
    Plane plane = image.planes[0];

    // Fill image buffer with plane[0] from YUV420_888
    for (int x = 0; x < image.width; x++) {
      for (int planeOffset = 0;
      planeOffset < image.height * image.width;
      planeOffset += image.width) {
        final pixelColor = plane.bytes[planeOffset + x];
        // color: 0x FF  FF  FF  FF
        //           A   B   G   R
        // Calculate pixel color
        var newVal = shift | (pixelColor << 16) | (pixelColor << 8) | pixelColor;
        img.data[planeOffset + x] = newVal;
      }
    }

    return img;
  }
}
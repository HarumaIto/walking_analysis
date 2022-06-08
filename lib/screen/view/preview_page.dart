import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'dart:math' as math;

import '../../model/configs/static_var.dart';

class PreviewPage extends StatefulWidget {
  const PreviewPage({Key? key}) : super(key: key);

  @override
  PreviewPageState createState() => PreviewPageState();
}

class PreviewPageState extends State<PreviewPage> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    CameraDescription rearCamera = StaticVar.cameras!.firstWhere(
          (description) => description.lensDirection == CameraLensDirection.back,);

    controller = CameraController(rearCamera, ResolutionPreset.high);

    _initializeControllerFuture = controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    controller.dispose();
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
            var tmp = MediaQuery.of(context).size;
            var screenH = math.max(tmp.height, tmp.width);
            var screenW = math.min(tmp.height, tmp.width);
            tmp = controller.value.previewSize!;
            var previewH = math.max(tmp.height, tmp.width);
            var previewW = math.min(tmp.height, tmp.width);
            var screenRatio = screenH / screenW;
            var previewRatio = previewH / previewW;

            return OverflowBox(
                maxHeight: screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
                maxWidth: screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
                child: CameraPreview(controller));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      )
    );
  }
}
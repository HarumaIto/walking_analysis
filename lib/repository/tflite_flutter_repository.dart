import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'package:image/image.dart' as imglib;
import 'package:walking_analysis/model/tflite_models.dart';

class TFLiteFlutterRepository {
  Interpreter? interpreter;

  ImageProcessor? imageProcessor;

  static const int INPUT_SIZE = 257;

  int padSize = 0;

  TFLiteFlutterRepository({this.interpreter}) {
    loadModel(interpreter);
  }

  void loadModel(Interpreter? interpreter) async {
    try {
      this.interpreter = interpreter ??
          await Interpreter.fromAsset(
            'posenet.tflite',
            options: InterpreterOptions()..threads = 4,
          );
    } catch (e) {
      print('error while creating interpreter : $e');
    }
  }

  TensorImage getProcessedImage(TensorImage inputImage) {
    padSize = max(inputImage.height, inputImage.width);
    imageProcessor ??= ImageProcessorBuilder()
          .add(ResizeWithCropOrPadOp(padSize, padSize))
          .add(ResizeOp(INPUT_SIZE, INPUT_SIZE, ResizeMethod.BILINEAR))
          .build();
    inputImage = imageProcessor!.process(inputImage);
    return inputImage;
  }

  double sigmoid(double x) {
    return (1.0 / (1.0 + exp(-x)));
  }

  // 出力を用意
  Map<int, Object> initOutputMap() {
    Map<int, Object> outputMap = {};
    // 1*9*9*34 ヒートマップを含む
    var heatmapsShape = interpreter!.getOutputTensor(0).shape;
    outputMap.putIfAbsent(0, () =>
        List.generate(heatmapsShape[0], (i)=>
            List.generate(heatmapsShape[1], (i)=>
                List.generate(heatmapsShape[2], (i)=>
                    Float32List(heatmapsShape[3])
                )
            )
        )
    );
    // 1*9*9*34 オフセットを含む
    var offsetsShape = interpreter!.getOutputTensor(1).shape;
    outputMap.putIfAbsent(1, () =>
        List.generate(offsetsShape[0], (i)=>
            List.generate(offsetsShape[1], (i)=>
                List.generate(offsetsShape[2], (i)=>
                    Float32List(offsetsShape[3])
                )
            )
        )
    );
    // 1*9*9*32
    var displacementsFwdShape = interpreter!.getOutputTensor(2).shape;
    outputMap.putIfAbsent(2, () =>
        List.generate(displacementsFwdShape[0], (i)=>
            List.generate(displacementsFwdShape[1], (i)=>
                List.generate(displacementsFwdShape[2], (i)=>
                    Float32List(displacementsFwdShape[3])
                )
            )
        )
    );
    // 1*9*9*32
    var displacementBwdShape = interpreter!.getOutputTensor(3).shape;
    outputMap.putIfAbsent(3, () =>
        List.generate(displacementBwdShape[0], (i)=>
            List.generate(displacementBwdShape[1], (i)=>
                List.generate(displacementBwdShape[2], (i)=>
                    Float32List(displacementBwdShape[3])
                )
            )
        )
    );
    return outputMap;
  }

  Person predict(imglib.Image image) {
    // 入力画像を用意
    TensorImage inputImage = TensorImage.fromImage(image);
    inputImage = getProcessedImage(inputImage);

    // 入出力の型を用意
    List<Object> input = [inputImage.buffer];
    Map<int, Object> output = initOutputMap();

    // 推論を実行
    interpreter!.runForMultipleInputs(input, output);

    // 結果を取得
    var heatmaps = output[0] as List<List<List<Float32List>>>;
    var offsets = output[1] as List<List<List<Float32List>>>;

    int height = heatmaps[0].length;
    int width = heatmaps[0][0].length;
    int numKeyPoints = heatmaps[0][0][0].length;

    var keypointPositions = List.filled(numKeyPoints, Pair(0,0));
    for (int keypoint=0; keypoint<numKeyPoints; keypoint++) {
      var maxVar = heatmaps[0][0][0][keypoint];
      var maxRow = 0;
      var maxCol = 0;
      for (int row=0; row<height; row++) {
        for (int col=0; col<width; col++) {
          if (heatmaps[0][row][col][keypoint] > maxVar) {
            maxVar = heatmaps[0][row][col][keypoint];
            maxRow = row;
            maxCol = col;
          }
        }
      }
      keypointPositions[keypoint] = Pair(maxRow, maxCol);
    }

    // オフセット調整したキーポイントのx,y座標を算出する
    var xCoords = Int8List(numKeyPoints);
    var yCoords = Int8List(numKeyPoints);
    var confidenceScores = Float32List(numKeyPoints);
    for (int i=0; i<keypointPositions.length; i++) {
      var position = keypointPositions[i];

      var positionY = keypointPositions[i].first;
      var positionX = keypointPositions[i].last;
      yCoords[i] = (
        position.first / (height - 1).toDouble() * image.height +
          offsets[0][positionY][positionX][i]
      ).toInt();
      xCoords[i] = (
        position.last / (width - 1).toDouble() * image.width +
          offsets[0][positionY][positionX][i+numKeyPoints]
      ).toInt();
      confidenceScores[i] = sigmoid(heatmaps[0][positionY][positionX][i]);
    }

    // 扱いやすい形式に変更
    var person = Person();
    var keypointList = List.filled(numKeyPoints, KeyPoint());
    var totalScore = 0.0;
    var bodyParts = BodyPart.values;
    for (int i=0; i<bodyParts.length; i++) {
      keypointList[i].bodyPart = bodyParts[i];
      keypointList[i].position.x = xCoords[i];
      keypointList[i].position.y = yCoords[i];
      keypointList[i].score = confidenceScores[i];
      totalScore += confidenceScores[i];
    }

    person.keyPoints = keypointList;
    person.score = totalScore / numKeyPoints;

    return person;
  }
}
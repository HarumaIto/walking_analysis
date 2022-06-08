import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../utility/file_processor.dart';

class StaticVar {

  static double screenWidth = 0;
  static double screenHeight = 0;

  static List comparisonData = [];

  static String previewFilePath = '';

  static WidgetRef? globalRef;

  static List<CameraDescription>? cameras;
}

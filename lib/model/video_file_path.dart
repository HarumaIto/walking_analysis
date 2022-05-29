import 'package:path_provider/path_provider.dart';

class VideoFilePath {

  static String trInputPath = '';
  static String mlInputPath = '';
  static String mlOutputPath = '';

  VideoFilePath();

  VideoFilePath.setup() {
    setupPath();
  }

  void setupPath() async {
    trInputPath = (await getExternalStorageDirectory())!.path + '/select.mp4';
    mlInputPath = (await getExternalStorageDirectory())!.path + '/input.mp4';
    mlOutputPath = (await getExternalStorageDirectory())!.path + '/output.mp4';
  }
}
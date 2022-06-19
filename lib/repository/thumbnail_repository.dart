import 'dart:typed_data';

import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:walking_analysis/model/global_variable.dart';
import 'package:walking_analysis/state/home_providers.dart';

Future createThumbnail(String path) async {
  Uint8List? bytes = await VideoThumbnail.thumbnailData(
      video: path
  );
  GlobalVar.globalRef!.read(inputThumbProvider.notifier).setThumbnail(bytes!);
}
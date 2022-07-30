import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:walking_analysis/model/global_variable.dart';
import 'package:walking_analysis/state/home_providers.dart';

Future createThumbnail(String path) async {
  final uint8list = await VideoThumbnail.thumbnailData(video: path);
  GlobalVar.globalRef!.read(inputThumbProvider.notifier).setThumbnail(uint8list!);
}
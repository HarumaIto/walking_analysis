import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future createThumbnail(
    WidgetRef ref,
    ProviderBase provider,
    String path) async {

  Uint8List? bytes = await VideoThumbnail.thumbnailData(
      video: path
  );
  ref.read(provider).setThumbnail(bytes!);
}
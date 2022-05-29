import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inputThumbProvider = ChangeNotifierProvider((_) => InputThumbModel());
final detectedThumbProvider = ChangeNotifierProvider((_) => DetectedThumbModel());

class InputThumbModel extends ChangeNotifier implements ThumbModel{
  @override
  Uint8List? bytes;

  @override
  void setThumbnail(Uint8List _bytes) {
    bytes = _bytes;
    notifyListeners();
  }

  @override
  void reset() {
    bytes = null;
    notifyListeners();
  }

  @override
  bool isState() {
    if (bytes == null) {
      return false;
    } else {
      return true;
    }
  }
}

class DetectedThumbModel extends ChangeNotifier implements ThumbModel{
  @override
  Uint8List? bytes;

  @override
  void setThumbnail(Uint8List _bytes) {
    bytes = _bytes;
    notifyListeners();
  }

  @override
  void reset() {
    bytes = null;
    notifyListeners();
  }

  @override
  bool isState() {
    if (bytes == null) {
      return false;
    } else {
      return true;
    }
  }
}

// 暗示的インターフェース
class ThumbModel extends ChangeNotifier {
  Uint8List? bytes;

  void setThumbnail(Uint8List _bytes) {}

  void reset() {}

  bool isState() {
    return true;
  }
}
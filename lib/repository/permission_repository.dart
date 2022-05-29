import 'package:permission_handler/permission_handler.dart';

enum Permissions {
  camera,
  storage,
}

class PermissionRequest {
  final Function(bool) callback;

  PermissionRequest({
    required Permissions request,
    required this.callback,
  }) {
    switch (request) {
      case Permissions.camera:
        cameraRequest();
        break;
      case Permissions.storage:
        storageRequest();
        break;
    }
  }

  Future cameraRequest() async {
    result(await Permission.camera.request());
  }

  Future storageRequest() async {
    result(await Permission.storage.request());
  }

  void result(PermissionStatus status) {
    if (status.isGranted) {
      callback(true);
    } else {
      callback(false);
    }
  }
}
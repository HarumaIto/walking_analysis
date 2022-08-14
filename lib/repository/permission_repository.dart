import 'package:permission_handler/permission_handler.dart';

class PermissionRequest {
  static Future<bool> cameraRequest() {
    return Permission.camera.request().isGranted;
  }

  static Future<bool> storageRequest() async {
    return Permission.storage.request().isGranted;
  }
}
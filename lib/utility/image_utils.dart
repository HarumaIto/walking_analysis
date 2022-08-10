import 'package:camera/camera.dart';
import 'package:image/image.dart' as imglib;

class ImageUtils {

  /// Convert CameraImage to imglig.Image
  static imglib.Image? convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      return null;
    }
  }

  /// Convert CameraImage for BGRA8888 to imglib.Image
  static imglib.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    imglib.Image image = imglib.Image.fromBytes(
      cameraImage.planes[0].width!,
      cameraImage.planes[0].height!,
      cameraImage.planes[0].bytes,
      format: imglib.Format.bgra
    );
    return image;
  }

  /// Convert CameraImage for YUV420 to imglib.Image
  static imglib.Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = imglib.Image(width, height);

    for (int w=0; w<width; w++) {
      for (int h=0; h<height; h++) {
        final int uvIndex = uvPixelStride * (w/2).floor() + uvRowStride * (h/2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.data[index] = ImageUtils.yuv2rgb(y, u, v);
      }
    }
    return image;
  }

  /// Convert single YUV pixel to RGB
  static int yuv2rgb(int y, int u, int v) {
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 | ((b << 16) & 0xff0000) | ((g << 8) & 0xff00) | (r & 0xff);
  }
}
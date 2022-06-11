import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalVar {
  // 画面のサイズ
  static double screenWidth = 0;
  static double screenHeight = 0;

  // 比較用データ
  static List comparisonData = [];

  // ファイルページのプレビュー用パス
  static String previewFilePath = '';

  // プロバイダー用
  static WidgetRef? globalRef;
}

enum MlModels {
  movenetThunder,
  movenetLightning
}
// 拡張関数
extension on MlModels {
  String get name => toString().split(".").last;
}

final mlDescriptionText = [
  "高精度＆低速",
  "低精度＆高速",
];
import '../model/angle_data.dart';
import 'calculation.dart';

// データ抽出
// columnNum => 必要な縦列のindex
List<AngleData> dataExtraction(List list, int columnNum) {
  List<AngleData> results = [];

  int dataLength = list.length;
  for (int i=0; i<dataLength; i++) {
    int count = normalization(i, dataLength).round();
    results.add(AngleData(count, list[i][columnNum]));
  }

  return results;
}
import 'dart:math' as math;

/// 数値の正規化
double normalization(int position, int length) {
  return (position / length * 100);
}

/// 相関係数を計算
double correlationCoefficient(List itemsA, List itemsB) {
  double sab = _deviationSumOfProduct(itemsA, itemsB);
  double saa = _sumOfSquares(itemsA);
  double sbb = _sumOfSquares(itemsB);
  print(sab.toString());
  print(saa.toString());
  print(sbb.toString());

  return sab / math.sqrt(saa * sbb);
}

/// 偏差積和を計算
double _deviationSumOfProduct(List itemsA, List itemsB) {
  List<double> itemsAB = [];
  int n  = itemsA.length;

  for (int i=0; i<n; i++) {
    itemsAB.add((itemsA[i] * itemsB[i]).toDouble());
  }
  double abSum = _sum(itemsAB);
  double aSum = _sum(itemsA);
  double bSum = _sum(itemsB);

  return abSum - ((aSum * bSum) / n);
}

/// 平方和を計算
double _sumOfSquares(List items) {
  double bar = _average(items);
  List squares = [];

  for (var item in items) {
    double square = (item.toDouble() - bar) * (item.toDouble() - bar);
    squares.add(square);
  }

  return _sum(squares);
}

/// 平均値を計算
double _average(List items) {
  return _sum(items) / items.length;
}

/// 総和を計算
double _sum(List items) {
  double result = 0.0;

  for (var item in items) {
    result += item.toDouble();
  }

  return result;
}

/// データ量を統一
List unification(List changeList, List constList) {
  List result = [];
  List<double> changePositions  = _getNormalizePosition(changeList);
  List<double> constPositions = _getNormalizePosition(constList);

  Map changeMap = _convertListToMap(changePositions, changeList);

  // データ量の多いほうの正規化したx軸を取得
  for (double constPosition in constPositions) {
    double veryNearDif = 0;
    double oldChangedPosition = 0;

    // 少ないほう
    for (double changePosition in changePositions) {
      // 差を絶対値で取得
      double dif = (changePosition - constPosition).abs();
      // 一回目か差が縮まった時
      if (veryNearDif == 0 || dif - veryNearDif < 0) {
        veryNearDif = dif;
        oldChangedPosition = changePosition;
      } else {
        // 差が広がった = 一番近いx軸が確定した
        result.add(changeMap[oldChangedPosition]);
        oldChangedPosition = 0;
        break;
      }
    }
    // 一番最後を追加するため
    if (oldChangedPosition != 0) {
      result.add(changeMap[oldChangedPosition]);
    }
  }

  return  result;
}

List<double> _getNormalizePosition(List list) {
  List<double> results = [];
  int length = list.length;
  for (int i=0; i<length; i++) {
    results.add(normalization(i, length));
  }
  return results;
}

Map _convertListToMap(List key, List value) {
  Map result = <double, int>{};
  for (int i=0; i<key.length; i++) {
    result[key[i]] = value[i];
  }
  return result;
}
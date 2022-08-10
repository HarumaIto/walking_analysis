enum BodyPart {
  NOSE,
  LEFT_EYE,
  RIGHT_EYE,
  LEFT_EAR,
  RIGHT_EAR,
  LEFT_SHOULDER,
  RIGHT_SHOULDER,
  LEFT_ELBOW,
  RIGHT_ELBOW,
  LEFT_WRIST,
  RIGHT_WRIST,
  LEFT_HIP,
  RIGHT_HIP,
  LEFT_KNEE,
  RIGHT_KNEE,
  LEFT_ANKLE,
  RIGHT_ANKLE,
}

class Position {
  int x = 0;
  int y = 0;
}

class KeyPoint {
  BodyPart bodyPart = BodyPart.NOSE;
  Position position = Position();
  double score = 0.0;
}

class Person {
  var keyPoints = <KeyPoint>[];
  double score = 0.0;
}

enum Device {
  CPU,
  NNAPI,
  GPU,
}
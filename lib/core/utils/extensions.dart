extension IntX on int {
  bool get isEvenSafe => this % 2 == 0;
}

extension DoubleX on double {
  double clamp01() => this.clamp(0.0, 1.0) as double;
}

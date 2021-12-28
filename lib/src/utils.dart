import 'package:flutter/material.dart';

Color lerpMultipleColors({
  required final List<Color> colors,
  required final double t,
}) {
  assert(t >= 0 && t <= 1);
  assert(colors.isNotEmpty);

  if (colors.length == 1) return colors.first;
  if (t == 1) return colors.last;

  double scaled = t * (colors.length - 1);

  Color firstColor = colors[scaled.floor()];
  Color secondColor = colors[(scaled + 1.0).floor()];

  return Color.lerp(
    firstColor,
    secondColor,
    scaled - scaled.floor(),
  )!;
}

double clampedInverseLerpDouble(double a, double b, double value) {
  double difference = b - a;
  if (difference == 0) return 1;
  return ((value - a) / difference).clamp(0.0, 1.0);
}
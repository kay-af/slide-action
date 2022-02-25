import 'package:flutter/material.dart';

enum ThumbState {
  idle,
  dragging,
  performingAction,
}

mixin SlideActionStateMixin {
  double get thumbFractionalPosition;
  Size get trackSize;
  Size get thumbSize;
  ThumbState get thumbState;
}

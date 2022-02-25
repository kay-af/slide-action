import 'package:flutter/material.dart';
import 'package:slide_action/slide_action.dart';

/// The state of the thumb.
///
/// * `idle` The thumb is not being interacted with.
///
/// * `dragging` User is dragging the thumb.
enum ThumbState {
  /// The thumb is not being interacted with.
  idle,

  /// The thumb is being dragged.
  dragging,
}

/// Stores the accessible state of the slide action widget.
///
/// Use the state to customize the *track* and *thumb* widgets.
mixin SlideActionStateMixin {
  /// A value from 0-1 indicating the percentage of track covered by the thumb.
  double get thumbFractionalPosition;

  /// Size of the track widget after being laid out.
  Size get trackSize;

  /// Size of the thumb.
  ///
  /// Slide action controls this value so it might not
  /// be same as the value provided to the widget. See [SlideAction] `thumbWidth` for more info
  Size get thumbSize;

  /// Current state of the thumb.
  ThumbState get thumbState;

  /// Is the widget performing some async task.
  bool get isPerformingAction;
}

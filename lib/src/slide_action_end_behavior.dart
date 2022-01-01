/// Defines the behavior of the thumb after the sliding
/// action has been performed.
///
/// The following behaviors are available:
///
/// - ```dart
/// SlideActionEndBehavior.stayIndefinitely()
/// ```
/// The thumb sticks to the end and stays there until the user interacts.
///
/// ___
///
/// - ```dart
/// SlideActionEndBehavior.resetImmediately()
/// ```
/// The thumb resets to the initial postion immediately.
///
/// ___
///
/// - ```dart
/// SlideActionEndBehavior.resetDelayed(duration: ...)
/// ```
/// The thumb resets to the initial postion after the given duration.
/// User can interact with the thumb to cancel this behavior anytime.
class SlideActionEndBehavior {
  /// Defines the duration for which the thumb stays at the end.
  ///
  /// `null` behaves as infinite duration.
  final Duration? stayDuration;

  /// Imply from `stayDuration` whether the thumb should reset immediately.
  bool get resetImmediately =>
      stayDuration == Duration.zero || stayDuration?.isNegative == true;

  /// Imply from `stayDuration` whether the thumb should stay indefinitely.
  bool get stayIndefinitely => stayDuration == null;

  /// Constructs a behavior that commands the [SlideAction] widget
  /// to stay the thumb at the end indefinitely after the action is performed.
  const SlideActionEndBehavior.stayIndefinitely() : stayDuration = null;

  /// Constructs a behavior that commands the [SlideAction] widget
  /// to reset the thumb immediately after the action is performed.
  const SlideActionEndBehavior.resetImmediately()
      : stayDuration = Duration.zero;

  /// Constructs a behavior that commands the [SlideAction] widget
  /// to reset the thumb after the provided `duration` elapses since the action is performed.
  const SlideActionEndBehavior.resetDelayed({required Duration duration})
      : stayDuration = duration;
}

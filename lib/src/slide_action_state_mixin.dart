import 'package:slide_action/slide_action.dart';

/// A *mixin* to abstract out the useful read-only state of the [SlideAction] widget.
///
/// The following details are available inside the state:
///
/// * `isDragging` - Is the thumb curently being dragged by the user?
/// * `isDisabled` - Is the widget disabled?
/// * `thumbFraction` - What percentage of the total length of the track
/// has been covered by the thumb? The value ranges from *0.0* (0% - *start*) to *1.0* (100% - *end*).
///
/// The state can be used to decorate the *track* and *thumb*. See [SlideActionWidgetBuilder] and [SlideAction].
///
/// ## Notes:
///
/// * `thumbFraction` goes from *0.0* to *1.0* moving right to left when `rightToLeft`
/// is enabled in the associated [SlideAction] widget.
mixin SlideActionStateMixin {

  /// What percentage of the total length of the track has been covered by the thumb?
  /// The value ranges from *0.0* (0% - *start*) to *1.0* (100% - *end*).
  ///
  /// It goes from *0.0* to *1.0* moving right to left when `rightToLeft`
  /// is enabled in the associated [SlideAction] widget.
  double get thumbFraction;
}

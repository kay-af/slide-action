import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:slide_action/slide_action.dart';
import 'package:slide_action/src/frame_change_callback_provider.dart';

/// Eyeballed constant for smooth thumb movement.
///
/// Used in combination with [FrameChangeCallbackProvider] to
/// generate a lerp factor used to smoothly move the *thumb* to
/// target position.
const double kThumbMovementSmoothingFactor = 0.015;

/// A builder for creating a widget that utilizes [SlideActionStateMixin] to
/// decorate themself.
///
/// Used to build *track* and *thumb* in [SlideAction] widget.
typedef SlideActionWidgetBuilder = Widget Function(
  BuildContext buildContext,
  SlideActionStateMixin currentState,
);

/// A customizable widget that shows a *track* and a *thumb* that can be
/// slid all the way to perform an *action*.
///
/// ## Description:
///
/// Slide action works by providing a fixed size box for two major components each -
/// The *track* and the *thumb*.
///
/// The height of the track is determined by `trackHeight`
/// and the *track* fills the parent container horizontally.
///
/// The height of the *thumb* matches the `trackHeight` and
/// the `thumbWidth` behaves in the following manner:
///
/// * If `thumbWidth` is **null**, `trackHeight` is used to calculate the width of the thumb.
/// * If `thumbWidth` is **non-null**, `thumbWidth` is used to calculate the width of the thumb.
///
/// Note that if the calculated thumb width exceeds half the laid *track* width, the actual thumb is given a width
/// of half the laid *track* width.
class SlideAction extends StatefulWidget {
  
  /// Creates a **SlideAction** widget.
  ///
  /// * `trackBuilder` - A builder callback to build the track widget using the
  /// current state of the slide action widget.
  /// * `thumbBuilder` - A builder callback to build the thumb widget using the
  /// current state of the slide action widget.
  /// * `onActionPerformed` - The callback which is called when the slide action
  /// is performed. The widget is disabled (Gestures are disabled) when this field is null.
  /// * `trackHeight` - The fixed height given to build the track.
  /// * `thumbWidth` - Custom width for the thumb. `trackHeight` is used when null. Half of the laid track width
  /// is used if the value exceeds the same.
  /// * `snapAnimationDuration` - The duration of the animation which drives the thumb
  /// to the initial / final position on the track depending on the position of the thumb and `actionSnapThreshold` value when it is
  /// released.
  /// * `snapAnimationCurve` - The curve used to drive the snap animation.
  /// * `actionSnapThreshold` - A value ranging 0.0 to 1.0. Specifies the point along the length
  /// of the anchor points for the thumb on the track after which if the finger is released, the thumb
  /// moves to the end and `onActionPerformed` is called.
  /// * `rightToLeft` - The thumb goes from right to left. Note that the `thumbFraction` in [SlideActionStateMixin]
  /// considers right as 0.0 and left as 1.0 when true.
  /// * `stretchThumb` - When true, the thumb stretches when dragged instead of moving.
  /// * `disabledColorTint` - The color to be used to tint the widget when `onActionPerformed` is null.
  /// * `thumbHitTestBehavior` - The hit test behavior to be used by the gesture detector wrapping the thumb.
  /// * `endBehavior` - The behavior of the thumb after the action is performed. See [SlideActionEndBehavior]
  /// for details.
  SlideAction({
    required this.trackBuilder,
    required this.thumbBuilder,
    required this.onActionPerformed,
    this.trackHeight = 64,
    this.thumbWidth,
    this.snapAnimationDuration = const Duration(milliseconds: 400),
    this.snapAnimationCurve = Curves.easeOut,
    this.actionSnapThreshold = 0.85,
    this.rightToLeft = false,
    this.stretchThumb = false,
    this.disabledColorTint = Colors.white54,
    this.thumbHitTestBehavior = HitTestBehavior.opaque,
    this.endBehavior = const SlideActionEndBehavior.resetDelayed(
      duration: Duration(milliseconds: 500),
    ),
    Key? key,
  }) :
    assert(trackHeight > 0 && trackHeight.isFinite && !trackHeight.isNaN, "Invalid track height"),
    assert(thumbWidth == null || (thumbWidth > 0 && !thumbWidth.isNaN), "Invalid thumb width"),
    assert(actionSnapThreshold >= 0.0 && actionSnapThreshold <= 1.0, "Value out of range"),
    super(key: key);

  final SlideActionWidgetBuilder trackBuilder;
  final SlideActionWidgetBuilder thumbBuilder;
  final double trackHeight;
  final double? thumbWidth;
  final double actionSnapThreshold;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final VoidCallback? onActionPerformed;
  final bool rightToLeft;
  final bool stretchThumb;
  final Color disabledColorTint;
  final HitTestBehavior thumbHitTestBehavior;
  final SlideActionEndBehavior endBehavior;

  @override
  _SlideActionState createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction>
    with TickerProviderStateMixin, SlideActionStateMixin {
  late bool _isDragging;
  late double _currentThumbFraction;
  late double _targetThumbFraction;
  late double _fingerOffsetX;
  late GlobalKey _trackGlobalKey;
  late final AnimationController _thumbAnimationController;
  late final FrameChangeCallbackProvider _smoothThumbUpdateCallbackProvider;
  Timer? _endBehaviorTimer;
  RenderBox? _trackRenderBox;

  // #region LifeCycle Methods

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _currentThumbFraction = 0;
    _targetThumbFraction = 0;
    _fingerOffsetX = 0;
    _trackGlobalKey = GlobalKey();
    _thumbAnimationController = AnimationController(vsync: this);
    _smoothThumbUpdateCallbackProvider = FrameChangeCallbackProvider(
      vsync: this,
      callback: _smoothUpdateThumbPosition,
    );
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(() => _trackRenderBox =
          _trackGlobalKey.currentContext!.findRenderObject() as RenderBox);
    });
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _smoothThumbUpdateCallbackProvider.dispose();
    _endBehaviorTimer?.cancel();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  // #endregion

  // #region State Interface

  @override
  bool get isDragging => _isDragging;

  @override
  double get thumbFraction => _currentThumbFraction;

  @override
  bool get isDisabled => widget.onActionPerformed == null;

  // #endregion

  // #region Helpers

  double get _thumbWidth {
    return min(
      _trackRenderBox!.size.width / 2.0,
      widget.thumbWidth ?? widget.trackHeight,
    );
  }

  void _smoothUpdateThumbPosition(Duration delta) {
    final double lerp =
        (kThumbMovementSmoothingFactor * delta.inMilliseconds).clamp(0.0, 1.0);

    setState(
      () => _currentThumbFraction = lerpDouble(
        _currentThumbFraction,
        _targetThumbFraction,
        lerp,
      )!,
    );
  }

  Alignment get _thumbAlignmentStart =>
      widget.rightToLeft ? Alignment.centerRight : Alignment.centerLeft;

  Alignment get _thumbAlignmentEnd =>
      widget.rightToLeft ? Alignment.centerLeft : Alignment.centerRight;

  double get _trackLeftX => _trackRenderBox!.localToGlobal(Offset.zero).dx;

  double get _trackRightX => _trackLeftX + _trackRenderBox!.size.width;

  double get _anchorLeftX => _trackLeftX + _thumbWidth / 2.0;

  double get _anchorRightX => _trackRightX - _thumbWidth / 2.0;

  double get _trackStart => widget.rightToLeft ? _trackRightX : _trackLeftX;

  double get _anchorStart => widget.rightToLeft ? _anchorRightX : _anchorLeftX;

  double get _anchorEnd => widget.rightToLeft ? _anchorLeftX : _anchorRightX;

  double get _thumbCenterPosition => lerpDouble(
        _anchorStart,
        _anchorEnd,
        _currentThumbFraction,
      )!;

  double get _stretchedThumbWidth {
    assert(widget.stretchThumb);
    return (_thumbCenterPosition - _trackStart).abs() + _thumbWidth / 2.0;
  }

  double _clampedInverseLerpDouble(double a, double b, double value) {
    double difference = b - a;
    if (difference == 0) return value < a ? 0 : 1;
    return ((value - a) / difference).clamp(0.0, 1.0);
  }

  void _animationToAlignmentFraction() {
    final double fraction = _thumbAnimationController.value.clamp(0.0, 1.0);
    setState(() {
      _currentThumbFraction = fraction;
      _targetThumbFraction = fraction;
    });
  }

  void _attachAnimationListener() =>
      _thumbAnimationController.addListener(_animationToAlignmentFraction);

  void _detachAnimationListener() =>
      _thumbAnimationController.removeListener(_animationToAlignmentFraction);

  void _stopAnimation() {
    if (_thumbAnimationController.isAnimating) {
      _thumbAnimationController.stop();
    }
  }

  void _animateThumbToStart() {
    _stopAnimation();
    _thumbAnimationController.value = _currentThumbFraction;
    _thumbAnimationController.duration = widget.snapAnimationDuration;
    _attachAnimationListener();
    _thumbAnimationController
        .animateTo(0, curve: widget.snapAnimationCurve)
        .orCancel
        .then((_) {
      _detachAnimationListener();
    }).catchError((_) {
      _detachAnimationListener();
    });
  }

  void _animateThumbToEnd() {
    _stopAnimation();
    _thumbAnimationController.value = _currentThumbFraction;
    _thumbAnimationController.duration = widget.snapAnimationDuration;
    _attachAnimationListener();
    _thumbAnimationController
        .animateTo(1, curve: widget.snapAnimationCurve)
        .orCancel
        .then((_) {
      _detachAnimationListener();
      widget.onActionPerformed!();

      if (widget.endBehavior.resetImmediately) {
        _animateThumbToStart();
      } else if (!widget.endBehavior.stayIndefinitely) {
        _endBehaviorTimer = Timer(
          widget.endBehavior.stayDuration!,
          _animateThumbToStart,
        );
      }
    }).catchError((_) {
      _detachAnimationListener();
    });
  }

  void _onThumbHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _fingerOffsetX = details.globalPosition.dx - _thumbCenterPosition;
    });
    _endBehaviorTimer?.cancel();
    _stopAnimation();
    _smoothThumbUpdateCallbackProvider.start();
  }

  void _onThumbHorizontalDragEnd(DragEndDetails details) {
    setState(() => _isDragging = false);
    _smoothThumbUpdateCallbackProvider.stop();
    if (_targetThumbFraction >= widget.actionSnapThreshold) {
      _animateThumbToEnd();
    } else {
      _animateThumbToStart();
    }
  }

  void _onThumbHorizontalDragCancel() {
    setState(() => _isDragging = false);
    _smoothThumbUpdateCallbackProvider.stop();
    _animateThumbToStart();
  }

  void _onThumbDragUpdate(DragUpdateDetails details) {
    final double fingerPosition = details.globalPosition.dx;
    final double fraction = _clampedInverseLerpDouble(
      _anchorStart,
      _anchorEnd,
      fingerPosition - _fingerOffsetX,
    );

    setState(
      () => _targetThumbFraction = fraction,
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: isDisabled,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.disabledColorTint,
          isDisabled ? BlendMode.srcATop : BlendMode.dst,
        ),
        child: UnconstrainedBox(
          alignment: Alignment.center,
          constrainedAxis: Axis.horizontal,
          child: ConstrainedBox(
            key: _trackGlobalKey,
            constraints: BoxConstraints.tight(
              Size.fromHeight(
                widget.trackHeight,
              ),
            ),
            child: _trackRenderBox == null
                ? null
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: widget.trackBuilder(
                          context,
                          this,
                        ),
                      ),
                      Align(
                        alignment: widget.stretchThumb
                            ? _thumbAlignmentStart
                            : Alignment.lerp(
                                _thumbAlignmentStart,
                                _thumbAlignmentEnd,
                                _currentThumbFraction,
                              )!,
                        child: GestureDetector(
                          behavior: widget.thumbHitTestBehavior,
                          onHorizontalDragStart: _onThumbHorizontalDragStart,
                          onHorizontalDragEnd: _onThumbHorizontalDragEnd,
                          onHorizontalDragCancel: _onThumbHorizontalDragCancel,
                          onHorizontalDragUpdate: _onThumbDragUpdate,
                          child: ConstrainedBox(
                            constraints: BoxConstraints.tight(
                              Size.fromWidth(
                                widget.stretchThumb
                                    ? _stretchedThumbWidth
                                    : _thumbWidth,
                              ),
                            ),
                            child: widget.thumbBuilder(
                              context,
                              this,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

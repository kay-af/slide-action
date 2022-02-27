import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:slide_action/src/frame_change_callback_provider.dart';
import 'package:slide_action/src/slide_action_state_mixin.dart';

/// Eyeballed constant that works well for smooth thumb movement.
const double kThumbMovementSmoothingFactor = 0.010;

/// A builder that utlizes the slide action widget state to
/// build widgets.
///
/// Used to build *Track* and *Thumb* of the [SlideAction] widget.
typedef SlideActionWidgetBuilder = Widget Function(
  BuildContext buildContext,
  SlideActionStateMixin currentState,
);

/// # Slide Action
///
/// Slide action has two major components, *track* and *thumb*.
/// Using the [SlideActionStateMixin] which is provided in the builders
/// for both, any kind of widget can be created that react to user interactions.
class SlideAction extends StatefulWidget {
  /// Create a new [SlideAction] widget
  SlideAction({
    required this.trackBuilder,
    required this.thumbBuilder,
    required this.action,
    this.trackHeight = 64,
    this.thumbWidth,
    this.snapAnimationDuration = const Duration(milliseconds: 400),
    this.snapAnimationCurve = Curves.easeOut,
    this.actionSnapThreshold = 0.85,
    this.rightToLeft = false,
    this.stretchThumb = false,
    this.disabledColorTint = Colors.white54,
    this.thumbHitTestBehavior = HitTestBehavior.opaque,
    this.thumbDragStartBehavior = DragStartBehavior.down,
    Key? key,
  })  : assert(
          trackHeight > 0 && trackHeight.isFinite && !trackHeight.isNaN,
          "Invalid track height",
        ),
        assert(
          thumbWidth == null || (thumbWidth > 0 && !thumbWidth.isNaN),
          "Invalid thumb width",
        ),
        assert(
          actionSnapThreshold > 0.0 && actionSnapThreshold <= 1.0,
          "Value out of range",
        ),
        super(key: key);

  /// A widget builder to create the *track* of the slider.
  /// Use the provided [SlideActionStateMixin] to customize the widget.
  final SlideActionWidgetBuilder trackBuilder;

  /// A widget builder to create the *thumb* over the *track*.
  /// Use the provided [SlideActionStateMixin] to customize the widget.
  final SlideActionWidgetBuilder thumbBuilder;

  /// The **action** to perform when thumb slides to the end. Can be an `async` callback.
  ///
  /// Passing `null` here will disable the interaction with the widget.
  ///
  /// When async operation is being performed, the state passed to the trackBuilder and thumbBuilder
  /// will have `isPerformingAction == true`
  final FutureOr<void> Function()? action;

  /// The height of the track to use. Must be a number strictly greater than 0.
  final double trackHeight;

  /// The width of the thumb to use.
  ///
  /// Must be a number strictly greater than 0.
  ///
  /// Uses `trackHeight` as default value if `null`
  ///
  /// The thumb width may be ignored and set to 50% of the laid `trackWidth` if it exceeds the value.
  final double? thumbWidth;

  /// Specifies the percentage of the track that has to be covered by the thumb to perform the action when released.
  ///
  /// Must be a number strictly greater than 0 and less than or equal to 1. Default value is 0.85 (85% of the track)
  final double actionSnapThreshold;

  /// The time taken to reset the thumb to a resting position when released
  final Duration snapAnimationDuration;

  /// The animation curve to use when snapping the thumb to a resting position
  final Curve snapAnimationCurve;

  /// Enable right to left
  final bool rightToLeft;

  /// Specifies whether thumb stretches when dragged.
  ///
  /// It also affects the `thumbSize` of the state passed to the
  /// *track* and *thumb* builders.
  final bool stretchThumb;

  /// If the widget is diabled (`action == null`), this color will be used to tint the widget
  final Color disabledColorTint;

  /// The *hit test behavior* used by the [GestureDetector] of the thumb
  final HitTestBehavior thumbHitTestBehavior;

  /// The *drag start behavior* used by the [GestureDetector] of the thumb
  final DragStartBehavior thumbDragStartBehavior;

  @override
  _SlideActionState createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction>
    with TickerProviderStateMixin, SlideActionStateMixin {
  // #region Var Declarations

  late bool _isDragging;

  late double _currentThumbFraction;

  late double _targetThumbFraction;

  late double _fingerGlobalOffsetX;

  late GlobalKey _trackGlobalKey;

  late final AnimationController _thumbAnimationController;

  late final FrameChangeCallbackProvider _smoothThumbUpdateCallbackProvider;

  late bool _performingAction;

  RenderBox? _trackRenderBox;

  // #endregion

  // #region LifeCycle Methods

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _performingAction = false;
    _currentThumbFraction = 0;
    _targetThumbFraction = 0;
    _fingerGlobalOffsetX = 0;
    _trackGlobalKey = GlobalKey();
    _thumbAnimationController = AnimationController(vsync: this);
    _smoothThumbUpdateCallbackProvider = FrameChangeCallbackProvider(
      vsync: this,
      callback: _smoothUpdateThumbPosition,
    );
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      setState(
        () => _trackRenderBox =
            _trackGlobalKey.currentContext!.findRenderObject() as RenderBox,
      );
    });
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _smoothThumbUpdateCallbackProvider.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  // #endregion

  // #region State Interface

  @override
  double get thumbFractionalPosition => _currentThumbFraction;

  @override
  Size get thumbSize => Size(
        widget.stretchThumb ? _stretchedThumbWidth : _thumbWidth,
        widget.trackHeight,
      );

  @override
  Size get trackSize => Size(
        (_trackRightX - _trackLeftX).abs(),
        widget.trackHeight,
      );

  @override
  ThumbState get thumbState =>
      _isDragging ? ThumbState.dragging : ThumbState.idle;

  @override
  bool get isPerformingAction => _performingAction;

  // #endregion

  // #region Helpers

  bool get _isDisabled => widget.action == null;

  double get _thumbWidth {
    return math.min(
      _trackRenderBox!.size.width * 0.5,
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
        .then((_) async {
      _detachAnimationListener();
      setState(() {
        _performingAction = true;
      });
      try {
        if (!_isDisabled) {
          await widget.action?.call();
        }
      } catch (_) {
      } finally {
        setState(() {
          _performingAction = false;
        });
        _animateThumbToStart();
      }
    }).catchError((err) {
      _detachAnimationListener();
    });
  }

  void _onThumbHorizontalDragStart(DragStartDetails details) {
    if (_performingAction) return;
    setState(() {
      _isDragging = true;
      _fingerGlobalOffsetX = details.globalPosition.dx - _thumbCenterPosition;
    });
    _stopAnimation();
    _smoothThumbUpdateCallbackProvider.start();
  }

  void _onThumbHorizontalDragEnd(DragEndDetails details) {
    if (_performingAction) return;
    setState(() => _isDragging = false);
    _smoothThumbUpdateCallbackProvider.stop();
    if (_targetThumbFraction >= widget.actionSnapThreshold) {
      _animateThumbToEnd();
    } else {
      _animateThumbToStart();
    }
  }

  void _onThumbHorizontalDragCancel() {
    if (_performingAction) return;
    setState(() => _isDragging = false);
    _smoothThumbUpdateCallbackProvider.stop();
    _animateThumbToStart();
  }

  void _onThumbDragUpdate(DragUpdateDetails details) {
    if (_performingAction) return;
    final double fingerPosition = details.globalPosition.dx;
    final double fraction = _clampedInverseLerpDouble(
      _anchorStart,
      _anchorEnd,
      fingerPosition - _fingerGlobalOffsetX,
    );

    setState(
      () => _targetThumbFraction = fraction,
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isDisabled,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          widget.disabledColorTint,
          _isDisabled ? BlendMode.srcATop : BlendMode.dst,
        ),
        child: NotificationListener<SizeChangedLayoutNotification>(
          onNotification: (_) {
            WidgetsBinding.instance!
                .addPostFrameCallback((_) => setState(() {}));
            return false;
          },
          child: SizeChangedLayoutNotifier(
            child: Align(
              alignment: Alignment.center,
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
                              dragStartBehavior: widget.thumbDragStartBehavior,
                              behavior: widget.thumbHitTestBehavior,
                              onHorizontalDragStart:
                                  _onThumbHorizontalDragStart,
                              onHorizontalDragEnd: _onThumbHorizontalDragEnd,
                              onHorizontalDragCancel:
                                  _onThumbHorizontalDragCancel,
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
        ),
      ),
    );
  }
}

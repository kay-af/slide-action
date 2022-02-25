import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:slide_action/src/frame_change_callback_provider.dart';
import 'package:slide_action/src/slide_action_state_mixin.dart';

const double kThumbMovementSmoothingFactor = 0.010;

typedef SlideActionWidgetBuilder = Widget Function(
  BuildContext buildContext,
  SlideActionStateMixin currentState,
);

class SlideAction extends StatefulWidget {
  SlideAction({
    required this.trackBuilder,
    required this.thumbBuilder,
    this.action,
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

  final SlideActionWidgetBuilder trackBuilder;
  final SlideActionWidgetBuilder thumbBuilder;
  final double trackHeight;
  final double? thumbWidth;
  final double actionSnapThreshold;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final FutureOr<void> Function()? action;
  final bool rightToLeft;
  final bool stretchThumb;
  final Color disabledColorTint;
  final HitTestBehavior thumbHitTestBehavior;
  final DragStartBehavior thumbDragStartBehavior;

  @override
  _SlideActionState createState() => _SlideActionState();
}

class _SlideActionState extends State<SlideAction>
    with TickerProviderStateMixin, SlideActionStateMixin {
  late bool _isDragging;

  late double _currentThumbFraction;

  late double _targetThumbFraction;

  late double _fingerGlobalOffsetX;

  late GlobalKey _trackGlobalKey;

  late final AnimationController _thumbAnimationController;

  late final FrameChangeCallbackProvider _smoothThumbUpdateCallbackProvider;

  late bool _performingAction;

  RenderBox? _trackRenderBox;

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
  ThumbState get thumbState => _performingAction
      ? ThumbState.performingAction
      : _isDragging
          ? ThumbState.dragging
          : ThumbState.idle;

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
        await widget.action?.call();
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

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:slide_to_perform/src/frame_change_callback_provider.dart';
import 'package:slide_to_perform/src/utils.dart' as utils;

const double kThumbMovementSmoothingFactor = 0.015;

mixin SlideToPerformStateMixin {
  bool get isDragging;
  bool get isDisabled;
  double get thumbFraction;
}

typedef SlideToPerformWidgetBuilder = Widget Function(
  BuildContext buildContext,
  SlideToPerformStateMixin currentState,
);

class SlideToPerform extends StatefulWidget {
  const SlideToPerform({
    required this.trackBuilder,
    required this.thumbBuilder,
    required this.onPerform,
    this.trackHeight = 64,
    this.snapAnimationDuration = const Duration(milliseconds: 400),
    this.snapAnimationCurve = Curves.easeOut,
    this.actionSnapThreshold = 0.85,
    this.rightToLeft = false,
    this.thumbWidth,
    this.stretchThumb = false,
    this.thumbHitTestBehavior = HitTestBehavior.opaque,
    Key? key,
  }) : super(key: key);

  final SlideToPerformWidgetBuilder trackBuilder;
  final SlideToPerformWidgetBuilder thumbBuilder;
  final double trackHeight;
  final double? thumbWidth;
  final double actionSnapThreshold;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final VoidCallback? onPerform;
  final bool rightToLeft;
  final bool stretchThumb;
  final HitTestBehavior thumbHitTestBehavior;

  @override
  _SlideToPerformState createState() => _SlideToPerformState();
}

class _SlideToPerformState extends State<SlideToPerform>
    with TickerProviderStateMixin, SlideToPerformStateMixin {
  late bool _isDragging;
  late double _currentThumbFraction;
  late double _targetThumbFraction;
  late double _fingerOffsetX;
  late GlobalKey _trackGlobalKey;
  RenderBox? _trackRenderBox;
  late final AnimationController _thumbAnimationController;
  late final FrameChangeCallbackProvider _smoothThumbUpdateCallbackProvider;

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
  bool get isDisabled => widget.onPerform == null;

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

  double get _thumbCenterPosition => lerpDouble(
        _anchorLeftX,
        _anchorRightX,
        _currentThumbFraction,
      )!;

  double get _stretchedThumbWidth {
    assert(widget.stretchThumb);
    return _thumbCenterPosition - _trackLeftX + _thumbWidth / 2.0;
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
      widget.onPerform?.call();
    }).catchError((_) {
      _detachAnimationListener();
    });
  }

  void _onThumbHorizontalDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _fingerOffsetX = details.globalPosition.dx - _thumbCenterPosition;
    });
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
    final double fraction = utils.clampedInverseLerpDouble(
      _anchorLeftX,
      _anchorRightX,
      fingerPosition - _fingerOffsetX,
    );
    setState(
      () =>
          _targetThumbFraction = widget.rightToLeft ? 1.0 - fraction : fraction,
    );
  }

  // #endregion

  @override
  Widget build(BuildContext context) {
    return UnconstrainedBox(
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
    );
  }
}

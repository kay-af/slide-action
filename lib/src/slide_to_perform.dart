import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:slide_to_perform/src/frame_change_callback_provider.dart';
import 'package:slide_to_perform/src/utils.dart' as utils;

const double kThumbMovementSmoothingFactor = 0.015;

class SlideToPerform extends StatefulWidget {
  const SlideToPerform({
    this.onPerform,
    this.trackHeight = 64,
    this.thumbMargin = 4,
    this.snapAnimationDuration = const Duration(milliseconds: 400),
    this.snapAnimationCurve = Curves.easeOut,
    this.performSnapThreshold = 0.85,
    this.rightToLeft = false,
    this.thumbWidth,
    this.thumbColors = const [Colors.orange, Colors.deepOrange],
    this.trackColors = const [Colors.white],
    this.fillTrack = true,
    this.roundiness = 24,
    Key? key,
  }) : super(key: key);

  final double trackHeight;
  final double thumbMargin;
  final double? thumbWidth;
  final double performSnapThreshold;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final VoidCallback? onPerform;
  final bool rightToLeft;
  final List<Color> thumbColors;
  final List<Color> trackColors;
  final bool fillTrack;
  final double roundiness;

  @override
  _SlideToPerformState createState() => _SlideToPerformState();
}

class _SlideToPerformState extends State<SlideToPerform>
    with TickerProviderStateMixin {
  late bool _isDragging;
  late double _thumbAlignmentFraction;
  late double _targetThumbAlignmentFraction;
  late final GlobalKey _sliderContainerKey;
  RenderBox? _sliderContainerRenderBox;
  late final AnimationController _thumbAnimationController;
  late final FrameChangeCallbackProvider _frameChangeCallbackProvider;

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _thumbAlignmentFraction = 0;
    _targetThumbAlignmentFraction = 0;
    _sliderContainerKey = GlobalKey();
    _thumbAnimationController = AnimationController(vsync: this);
    _frameChangeCallbackProvider = FrameChangeCallbackProvider(
      vsync: this,
      callback: _updateThumbMovement,
    );
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    _frameChangeCallbackProvider.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  void _updateThumbMovement(Duration delta) {
    final double lerp =
        (kThumbMovementSmoothingFactor * delta.inMilliseconds).clamp(0.0, 1.0);

    setState(
      () => _thumbAlignmentFraction = lerpDouble(
            _thumbAlignmentFraction,
            _targetThumbAlignmentFraction,
            lerp,
          ) ??
          0,
    );
  }

  bool get isDragging => _isDragging;

  Color get thumbColor => utils.lerpMultipleColors(
        colors: widget.thumbColors,
        t: _thumbAlignmentFraction,
      );

  Color get trackColor => utils.lerpMultipleColors(
        colors: widget.trackColors,
        t: _thumbAlignmentFraction,
      );

  Alignment get thumbAlignmentStart =>
      widget.rightToLeft ? Alignment.centerRight : Alignment.centerLeft;

  Alignment get thumbAlignmentEnd =>
      widget.rightToLeft ? Alignment.centerLeft : Alignment.centerRight;

  Size get thumbSize {
    double implicitHeight = widget.trackHeight - widget.thumbMargin * 2;
    return Size(widget.thumbWidth ?? implicitHeight, implicitHeight);
  }

  RenderBox? get sliderContainerRenderBox {
    _sliderContainerRenderBox = _sliderContainerRenderBox ??
        _sliderContainerKey.currentContext?.findRenderObject() as RenderBox?;
    return _sliderContainerRenderBox;
  }

  double? get trackWidth => sliderContainerRenderBox?.size.width;

  double? get trackLeftX =>
      sliderContainerRenderBox?.localToGlobal(Offset.zero).dx;

  double? get trackRightX {
    if (trackLeftX != null && trackWidth != null) {
      return trackLeftX! + trackWidth!;
    }
  }

  double? get anchorLeftX {
    if (trackLeftX != null) {
      return trackLeftX! + (widget.thumbMargin + thumbSize.width / 2.0);
    }
  }

  double? get anchorRightX {
    if (trackRightX != null) {
      return trackRightX! - (widget.thumbMargin + thumbSize.width / 2.0);
    }
  }

  double? get fillTrackWidth {
    assert(widget.fillTrack);
    final double? thumbPosition =
        lerpDouble(anchorLeftX, anchorRightX, _thumbAlignmentFraction);
    if (thumbPosition != null && trackLeftX != null) {
      return thumbPosition +
          (thumbSize.width / 2.0) -
          trackLeftX! -
          widget.thumbMargin;
    }
  }

  double? get trackWidgetOpacity {
    return lerpDouble(1, 0, (_thumbAlignmentFraction * 2).clamp(0.0, 1.0));
  }

  double get trackBorderRadius =>
      min(widget.trackHeight / 2.0, widget.roundiness);

  double get thumbBorderRadius => min(
        thumbSize.height / 2.0,
        widget.roundiness / widget.trackHeight * thumbSize.height,
      );

  void _animationToAlignmentFraction() {
    final double fraction = _thumbAnimationController.value.clamp(0.0, 1.0);
    setState(() {
      _thumbAlignmentFraction = fraction;
      _targetThumbAlignmentFraction = fraction;
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
    _thumbAnimationController.value = _thumbAlignmentFraction;
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
    _thumbAnimationController.value = _thumbAlignmentFraction;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _sliderContainerKey,
      width: double.infinity,
      height: widget.trackHeight,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(trackBorderRadius),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: trackWidgetOpacity ?? 1.0,
              child: const Center(
                child: Text("Slide to unlock"),
              ),
            ),
          ),
          if (widget.fillTrack)
            Align(
              alignment: thumbAlignmentStart,
              child: Container(
                width: fillTrackWidth,
                margin: EdgeInsets.all(
                  widget.thumbMargin,
                ),
                decoration: BoxDecoration(
                  color: thumbColor,
                  borderRadius: BorderRadius.circular(thumbBorderRadius),
                ),
              ),
            ),
          Align(
            alignment: Alignment.lerp(thumbAlignmentStart, thumbAlignmentEnd,
                    _thumbAlignmentFraction) ??
                thumbAlignmentStart,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
                _stopAnimation();
                _frameChangeCallbackProvider.start();
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);
                _frameChangeCallbackProvider.stop();
                if (_targetThumbAlignmentFraction >=
                    widget.performSnapThreshold) {
                  _animateThumbToEnd();
                } else {
                  _animateThumbToStart();
                }
              },
              onHorizontalDragCancel: () {
                setState(() => _isDragging = false);
                _frameChangeCallbackProvider.stop();
                _animateThumbToStart();
              },
              onHorizontalDragUpdate: (details) {
                if (anchorLeftX != null && anchorRightX != null) {
                  final double currentThumbPosition = details.globalPosition.dx;
                  final double fraction = utils.clampedInverseLerpDouble(
                    anchorLeftX!,
                    anchorRightX!,
                    currentThumbPosition,
                  );
                  setState(() => _targetThumbAlignmentFraction =
                      widget.rightToLeft ? 1.0 - fraction : fraction);
                }
              },
              child: Container(
                width: thumbSize.width,
                margin: EdgeInsets.all(
                  widget.thumbMargin,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    thumbSize.height,
                  ),
                  color: widget.fillTrack ? null : thumbColor,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_sharp,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

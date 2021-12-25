import 'package:flutter/material.dart';

const Duration _kSnapAnimationDuration = Duration(milliseconds: 600);
const Curve _kSnapAnimationCurve = Curves.easeOut;

class SlideToPerform extends StatefulWidget {
  const SlideToPerform({
    this.onPerform,
    this.sliderHeight = 64,
    this.thumbMargin = 4,
    this.snapAnimationDuration = _kSnapAnimationDuration,
    this.snapAnimationCurve = _kSnapAnimationCurve,
    this.performSnapThreshold = 0.85,
    this.rightToLeft = false,
    this.thumbWidth,
    Key? key,
  }) : super(key: key);

  final double sliderHeight;
  final double thumbMargin;
  final double? thumbWidth;
  final double performSnapThreshold;
  final Duration snapAnimationDuration;
  final Curve snapAnimationCurve;
  final VoidCallback? onPerform;
  final bool rightToLeft;

  @override
  _SlideToPerformState createState() => _SlideToPerformState();
}

class _SlideToPerformState extends State<SlideToPerform>
    with SingleTickerProviderStateMixin {
  late bool _isDragging;
  late double _thumbAlignmentFraction;

  late final GlobalKey _sliderContainerKey;
  RenderBox? _sliderContainerRenderBox;

  late final AnimationController _thumbAnimationController;

  @override
  void initState() {
    super.initState();
    _isDragging = false;
    _thumbAlignmentFraction = 0;
    _sliderContainerKey = GlobalKey();
    _thumbAnimationController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  bool get isDragging => _isDragging;

  Alignment get thumbAlignmentStart =>
      widget.rightToLeft ? Alignment.centerRight : Alignment.centerLeft;

  Alignment get thumbAlignmentEnd =>
      widget.rightToLeft ? Alignment.centerLeft : Alignment.centerRight;

  Size get thumbSize {
    double implicitHeight = widget.sliderHeight - widget.thumbMargin * 2;
    return Size(widget.thumbWidth ?? implicitHeight, implicitHeight);
  }

  RenderBox? get sliderContainerRenderBox {
    _sliderContainerRenderBox = _sliderContainerRenderBox ??
        _sliderContainerKey.currentContext?.findRenderObject() as RenderBox?;
    return _sliderContainerRenderBox;
  }

  double? get leftAnchorGlobalX {
    double? leftCorner =
        sliderContainerRenderBox?.localToGlobal(Offset.zero).dx;
    if (leftCorner != null) {
      return leftCorner + (widget.thumbMargin + thumbSize.width / 2.0);
    }
  }

  double? get rightAnchorGlobalX {
    double? leftCorner = leftAnchorGlobalX;
    double? width = _sliderContainerRenderBox?.size.width;
    if (leftCorner != null && width != null) {
      double rightCorner = leftCorner + width;
      return rightCorner - (widget.thumbMargin + thumbSize.width / 2.0);
    }
  }

  double _clampedInverseLerpDouble(double min, double max, double value) {
    assert(min < max);
    if (value <= min) return 0;
    if (value >= max) return 1;
    double difference = max - min;
    return (value - min) / difference;
  }

  void _animationToAlignmentFraction() {
    final double fraction = _thumbAnimationController.value.clamp(0.0, 1.0);
    setState(() => _thumbAlignmentFraction = fraction);
  }

  void _attachAnimationListener() =>
      _thumbAnimationController.addListener(_animationToAlignmentFraction);

  void _detachAnimationListener() =>
      _thumbAnimationController.removeListener(_animationToAlignmentFraction);

  void _stopAnimation() {
    if (_thumbAnimationController.isAnimating) {
      _thumbAnimationController.stop(canceled: true);
    }
  }

  void _animateThumbToStart() {
    _thumbAnimationController.value = _thumbAlignmentFraction;
    _thumbAnimationController.duration =
        widget.snapAnimationDuration * _thumbAlignmentFraction;
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
    _thumbAnimationController.duration =
        widget.snapAnimationDuration * (1 - _thumbAlignmentFraction);
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
      height: widget.sliderHeight,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(
          widget.sliderHeight / 2.0,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.lerp(thumbAlignmentStart, thumbAlignmentEnd,
                    _thumbAlignmentFraction) ??
                thumbAlignmentStart,
            child: GestureDetector(
              onHorizontalDragStart: (_) {
                setState(() => _isDragging = true);
                _stopAnimation();
              },
              onHorizontalDragEnd: (_) {
                setState(() => _isDragging = false);
                if (_thumbAlignmentFraction >= widget.performSnapThreshold) {
                  _animateThumbToEnd();
                } else {
                  _animateThumbToStart();
                }
              },
              onHorizontalDragCancel: () {
                setState(() => _isDragging = false);
                _animateThumbToStart();
              },
              onHorizontalDragUpdate: (details) {
                final double? leftAnchor = leftAnchorGlobalX;
                final double? rightAnchor = rightAnchorGlobalX;

                if (leftAnchor == null || rightAnchor == null) return;

                final double currentThumbPosition = details.globalPosition.dx
                  + (thumbSize.width / 2.0) - widget.thumbMargin;
                
                final double fraction = _clampedInverseLerpDouble(
                  leftAnchor,
                  rightAnchor,
                  currentThumbPosition,
                );
                setState(() => _thumbAlignmentFraction =
                    widget.rightToLeft ? 1.0 - fraction : fraction);
              },
              child: Container(
                width: thumbSize.width,
                margin: EdgeInsets.all(widget.thumbMargin),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(thumbSize.height),
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

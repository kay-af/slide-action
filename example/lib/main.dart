import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:slide_action/slide_action.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Example',
      debugShowCheckedModeBanner: false,
      home: SlideToPerformExample(),
    );
  }
}

class SlideToPerformExample extends StatelessWidget {
  const SlideToPerformExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Scrollbar(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            child: DefaultTextStyle(
              style: Theme.of(context).textTheme.bodyText2!,
              textAlign: TextAlign.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Simple Examples",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const Text("Below is a basic slide action widget!"),
                  SimpleExample(callback: () {}),
                  const Text("Slide action has RTL support!"),
                  SimpleExample(rightToLeft: true, callback: () {}),
                  const Text("Disabled slide action widget!"),
                  const SimpleExample(callback: null),
                  const Text("The thumb can be stretched when dragged!"),
                  SimpleExample(stretchThumb: true, callback: () {}),
                  const Text(
                    "Control the curve and duration of the animation that drives the thumb to the resting position!",
                  ),
                  SimpleExample(
                    callback: () {},
                    resetCurve: Curves.bounceOut,
                    resetDuration: const Duration(milliseconds: 3000),
                  ),
                  const Text("Control the thumb width!"),
                  SimpleExample(
                    callback: () {},
                    thumbWidth: 100,
                  ),
                  const Text("And the track height!"),
                  SimpleExample(
                    callback: () {},
                    thumbWidth: 100,
                    trackHeight: 80,
                  ),
                  const Divider(),
                  Text(
                    "Complex Examples",
                    style: Theme.of(context).textTheme.headline5,
                  ),
                  const Text("Colors based on thumb fraction!"),
                  const ColorChangingExample(),
                  const Text("The thumb is not limited to simple icons!"),
                  const IndianFlagExample(),
                  const Text("iOS4 styled slide to unlock!"),
                  const IOS4SlideToUnlockExample(),
                  const Divider(),
                  Text(
                    "And much more :)",
                    style: Theme.of(context).textTheme.headline6,
                  ),
                ]
                    .map(
                      (slideToPerformWidget) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: slideToPerformWidget,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleExample extends StatelessWidget {
  const SimpleExample({
    this.rightToLeft = false,
    this.callback,
    this.stretchThumb = false,
    this.resetCurve = Curves.easeOut,
    this.resetDuration = const Duration(milliseconds: 400),
    this.thumbWidth,
    this.trackHeight = 64,
    Key? key,
  }) : super(key: key);

  final bool rightToLeft;
  final VoidCallback? callback;
  final bool stretchThumb;
  final Curve resetCurve;
  final Duration resetDuration;
  final double? thumbWidth;
  final double trackHeight;

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      trackHeight: trackHeight,
      snapAnimationCurve: resetCurve,
      snapAnimationDuration: resetDuration,
      stretchThumb: stretchThumb,
      thumbWidth: thumbWidth,
      rightToLeft: rightToLeft,
      trackBuilder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Thumb fraction: ${state.thumbFraction.toStringAsPrecision(2)}",
            ),
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: stretchThumb ? 64 : double.infinity,
              child: Center(
                child: Icon(
                  rightToLeft ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
      onActionPerformed: callback,
    );
  }
}

Color lerpColorList(
  final List<Color> colors,
  final double t,
) {
  assert(!t.isNaN, "Must be a number");
  assert(t >= 0 && t <= 1, "Value out of range");
  assert(colors.isNotEmpty, "Color list must not be empty");

  if (colors.length == 1) return colors.first;
  if (t == 1) return colors.last;

  double scaled = t * (colors.length - 1);

  Color firstColor = colors[scaled.floor()];
  Color secondColor = colors[(scaled + 1.0).floor()];

  return Color.lerp(
    firstColor,
    secondColor,
    scaled - scaled.floor(),
  )!;
}

class ColorChangingExample extends StatelessWidget {
  const ColorChangingExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
    ];

    return SlideAction(
      stretchThumb: true,
      trackBuilder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Text(
              "❤💚💙",
            ),
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: lerpColorList(colors, state.thumbFraction),
            borderRadius: BorderRadius.circular(100),
          ),
          child: const Icon(
            Icons.color_lens_outlined,
            color: Colors.white,
          ),
        );
      },
      onActionPerformed: () {},
    );
  }
}

class AnimatedImageThumbExample extends StatelessWidget {
  const AnimatedImageThumbExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      onActionPerformed: () {},
      trackBuilder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.grey.shade100,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(4.0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: Colors.grey.shade100,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: state.thumbFraction <= 0.5
                ? Image.network(
                    "https://picsum.photos/id/1024/200/200",
                    key: const ValueKey("FirstImage"),
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    "https://picsum.photos/id/1025/200/200",
                    key: const ValueKey("SecondImage"),
                    fit: BoxFit.cover,
                  ),
          ),
        );
      },
    );
  }
}

class IndianFlagExample extends StatelessWidget {
  const IndianFlagExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      stretchThumb: true,
      trackBuilder: (contex, state) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              "Slide to hoist the flag!",
              style: Theme.of(context).textTheme.bodyText2?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.circle_outlined,
                color: Colors.blue,
              ),
              ...List<double>.generate(6, (index) => index * pi / 6).map(
                (e) => Transform.rotate(
                  angle: e,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.horizontal_rule_sharp,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.shade300,
                Colors.orange.shade500,
                Colors.white,
                Colors.white,
                Colors.green.shade700,
                Colors.green.shade800,
              ],
              stops: const [0, 0.33, 0.33, 0.67, 0.67, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
        );
      },
      onActionPerformed: () {},
    );
  }
}

class IOS4SlideToUnlockExample extends StatelessWidget {
  const IOS4SlideToUnlockExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideAction(
      stretchThumb: false,
      trackBuilder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
            gradient: LinearGradient(
              colors: [
                Colors.black,
                Colors.grey.shade800,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Opacity(
            opacity:
                lerpDouble(1, 0, (state.thumbFraction * 2).clamp(0.0, 1.0))!,
            child: Center(
              child: Text(
                "Slide To Unlock",
                style: Theme.of(context).textTheme.headline6?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        );
      },
      thumbBuilder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Colors.white,
                Colors.grey,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Icon(
              Icons.arrow_right_alt,
              color: Colors.grey.shade700,
              size: 32,
            ),
          ),
        );
      },
      thumbWidth: 80,
      onActionPerformed: () {},
    );
  }
}

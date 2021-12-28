import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:slide_to_perform/slide_to_perform.dart';

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

class SlideToPerformExample extends StatelessWidget {
  const SlideToPerformExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const AnimatedImageThumbExample(),
              const IndianFlagExample(),
              const IOS4SlideToUnlockExample(),
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
    );
  }
}

class AnimatedImageThumbExample extends StatelessWidget {
  const AnimatedImageThumbExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideToPerform(
      onPerform: () {},
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
    return SlideToPerform(
        stretchThumb: true,
        trackBuilder: (contex, state) {
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
        onPerform: () {});
  }
}

class IOS4SlideToUnlockExample extends StatelessWidget {
  const IOS4SlideToUnlockExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideToPerform(
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
            child: Align(
              alignment: const Alignment(0.35, 0),
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
      onPerform: () {},
    );
  }
}

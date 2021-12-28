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

class SlideToPerformExample extends StatelessWidget {
  const SlideToPerformExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const BasicSlideToPerform(),
              const IOS4SlideToUnlock(),
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

class BasicSlideToPerform extends StatelessWidget {
  const BasicSlideToPerform({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideToPerform(
        trackBuilder: (contex, state) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey.shade300,
            ),
          );
        },
        thumbBuilder: (context, state) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: const Icon(Icons.chevron_right),
          );
        },
        onPerform: () {});
  }
}

class IOS4SlideToUnlock extends StatelessWidget {
  const IOS4SlideToUnlock({Key? key}) : super(key: key);

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

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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SlideToPerform(
            stretchThumb: true,
            trackBuilder: (context, state) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Opacity(
                  opacity: lerpDouble(
                      1, 0, (state.thumbFraction * 2).clamp(0.0, 1.0))!,
                  child: const Center(
                    child: Text(
                      "Slide To Unlock",
                    ),
                  ),
                ),
              );
            },
            thumbBuilder: (context, state) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: const Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.chevron_right),
                  ),
                ),
              );
            },
            onPerform: () {},
          ),
        ),
      ),
    );
  }
}

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
      home: SlideToPerformExample(),
    );
  }
}

class SlideToPerformExample extends StatelessWidget {
  const SlideToPerformExample({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SlideToPerform(),
        ),
      ),
    );
  }
}
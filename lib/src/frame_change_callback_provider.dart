import 'package:flutter/scheduler.dart';

typedef FrameChangeCallback = void Function(Duration delta);

class FrameChangeCallbackProvider {
  FrameChangeCallbackProvider({
    required this.vsync,
    required this.callback,
  }) {
    _internalTicker = vsync.createTicker(_onFrame);
  }

  final TickerProvider vsync;
  final FrameChangeCallback callback;

  late final Ticker _internalTicker;
  late Duration _lastTickDuration;

  void _onFrame(Duration elapsed) {
    final Duration delta = elapsed - _lastTickDuration;
    _lastTickDuration = elapsed;
    callback(delta);
  }

  void start() {
    _lastTickDuration = Duration.zero;
    _internalTicker.start().orCancel.catchError((_) {});
  }

  void stop() {
    _internalTicker.stop();
  }

  void dispose() {
    _internalTicker.dispose();
  }
}

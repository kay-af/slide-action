import 'package:flutter/scheduler.dart';

/// `delta` is the time elapsed since last frame.
typedef FrameChangeCallback = void Function(Duration delta);

/// Provides functionality for executing a function every frame
/// in a given context.
class FrameChangeCallbackProvider {

  /// Creates a [FrameChangeCallbackProvider].
  /// 
  /// * `vsync` is the ticker provider for current context.
  /// * `callback` the callback to execute whenever a frame changes. See [FrameChangeCallback].
  /// 
  /// ## Notes:
  ///
  /// * Use `start` and `stop` methods to control when to listen for changes.
  /// An instance of this class is in a *stopped* state on creation.
  /// * `dispose` must be called when no longer in use.
  FrameChangeCallbackProvider({
    required this.vsync,
    required this.callback,
  }) {
    _internalTicker = vsync.createTicker(_onFrame);
  }

  /// The [TickerProvider] associated with the instance.
  final TickerProvider vsync;

  /// The callback to be fired every frame.
  /// The [FrameChangeCallbackProvider] instance must be started for the callback to fire.
  final FrameChangeCallback callback;

  late final Ticker _internalTicker;
  late Duration _lastTickDuration;

  void _onFrame(Duration elapsed) {
    final Duration delta = elapsed - _lastTickDuration;
    _lastTickDuration = elapsed;
    callback(delta);
  }

  /// Starts the [FrameChangeCallbackProvider] instance.
  /// Does nothing if already running.
  void start() {
    if (_internalTicker.isActive) return;

    _lastTickDuration = Duration.zero;
    _internalTicker.start().orCancel.catchError((_) {});
  }

  /// Stops the [FrameChangeCallbackProvider] instance.
  /// Does nothing if already stopped.
  void stop() {
    if (!_internalTicker.isActive) return;
    _internalTicker.stop();
  }

  /// Call to dispose the [FrameChangeCallbackProvider] instance
  /// if it is no longer in use.
  void dispose() {
    _internalTicker.dispose();
  }
}

import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';

typedef HeadingEventProvider = Stream<CompassEvent> Function();

/// Confidence level for heading/compass readings.
enum HeadingConfidence {
  /// No compass data available
  unavailable,

  /// Low confidence (large variance or uncalibrated)
  low,

  /// Medium confidence (acceptable for navigation)
  medium,

  /// High confidence (reliable heading)
  high,
}

/// Adapter for device compass/heading sensor.
/// Wraps flutter_compass behind injectable interfaces for testability.
class CompassAdapter {
  CompassAdapter({
    HeadingEventProvider? headingEventProvider,
    Duration throttleDuration = const Duration(milliseconds: 500),
  })  : _headingEventProvider =
            headingEventProvider ?? (() => FlutterCompass.events ?? Stream.empty()),
        _throttleDuration = throttleDuration;

  final HeadingEventProvider _headingEventProvider;
  final Duration _throttleDuration;
  StreamSubscription<CompassEvent>? _subscription;
  DateTime? _lastConfidenceEmissionTime;
  HeadingConfidence? _lastConfidenceEmitted;

  bool get isTracking => _subscription != null;

  /// Starts listening to compass headings.
  /// Calls [onHeading] with each heading update (in degrees 0-360).
  /// Calls [onConfidence] with the compass confidence level, throttled by default
  /// to reduce mission state thrashing on noisy devices (default 500ms throttle).
  /// Calls [onError] if the compass is unavailable or permission denied.
  /// Calls [onDone] when the stream closes.
  Future<void> startTracking({
    required void Function(double headingDegrees) onHeading,
    required void Function(HeadingConfidence confidence) onConfidence,
    void Function(Object error)? onError,
    void Function()? onDone,
  }) async {
    await stopTracking();
    _lastConfidenceEmissionTime = null;
    _lastConfidenceEmitted = null;

    try {
      _subscription = _headingEventProvider().listen(
        (CompassEvent event) {
          if (event.heading != null) {
            onHeading(event.heading!);
            // Flutter compass provides heading when available.
            // We assume medium confidence when heading is available.
            // Full confidence estimation would require device calibration state,
            // which flutter_compass does not expose.
            _emitConfidenceThrottled(
              HeadingConfidence.medium,
              onConfidence,
            );
          } else {
            _emitConfidenceThrottled(
              HeadingConfidence.unavailable,
              onConfidence,
            );
          }
        },
        onError: (Object error) {
          onError?.call(error);
          _emitConfidenceThrottled(
            HeadingConfidence.unavailable,
            onConfidence,
          );
        },
        onDone: onDone,
      );
    } catch (e) {
      onError?.call(e);
      _emitConfidenceThrottled(
        HeadingConfidence.unavailable,
        onConfidence,
      );
    }
  }

  /// Emits confidence change only if throttle period has elapsed or confidence changed.
  void _emitConfidenceThrottled(
    HeadingConfidence confidence,
    void Function(HeadingConfidence) onConfidence,
  ) {
    final now = DateTime.now();
    final lastTime = _lastConfidenceEmissionTime;
    final lastConfidence = _lastConfidenceEmitted;

    // Emit if: (1) confidence changed OR (2) throttle duration elapsed
    if (lastConfidence != confidence ||
        lastTime == null ||
        now.difference(lastTime) >= _throttleDuration) {
      _lastConfidenceEmissionTime = now;
      _lastConfidenceEmitted = confidence;
      onConfidence(confidence);
    }
  }

  /// Stops listening to compass headings.
  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
    _lastConfidenceEmissionTime = null;
    _lastConfidenceEmitted = null;
  }

}

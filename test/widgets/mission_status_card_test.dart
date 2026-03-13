import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dravik/services/mission_engine/mission_state.dart';
import 'package:dravik/widgets/mission_status_card.dart';
import 'package:dravik/widgets/mission_metric_tile.dart';

/// Wraps a widget in a minimal MaterialApp so Theme.of(context) works.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Builds a [MissionRuntimeState] in tracking status with the given context fields.
MissionRuntimeState _trackingRuntime({
  double gpsConfidence = 0.9,
  double headingConfidence = 80,
  double altitudeMeters = 1500,
  double speedMetersPerSecond = 0,
  double slopePercent = 0,
  int? batteryPercent,
}) {
  return MissionRuntimeState(
    status: MissionStatus.tracking,
    context: MissionContext(
      gpsConfidence: gpsConfidence,
      headingConfidence: headingConfidence,
      altitudeMeters: altitudeMeters,
      speedMetersPerSecond: speedMetersPerSecond,
      slopePercent: slopePercent,
      batteryPercent: batteryPercent,
    ),
    enteredAt: DateTime(2026, 3, 11),
  );
}

void main() {
  group('MissionStatusCard label formatters', () {
    test('formatSpeed converts m/s to km/h', () {
      expect(MissionStatusCard.formatSpeed(0), '--');
      expect(MissionStatusCard.formatSpeed(1.0), '3.6 km/h');
      expect(MissionStatusCard.formatSpeed(5.0), '18.0 km/h');
      expect(MissionStatusCard.formatSpeed(10.0), '36.0 km/h');
    });

    test('formatSlope renders percent with one decimal', () {
      expect(MissionStatusCard.formatSlope(0), '--');
      expect(MissionStatusCard.formatSlope(12.5), '12.5%');
      expect(MissionStatusCard.formatSlope(-8.3), '-8.3%');
      expect(MissionStatusCard.formatSlope(0.1), '0.1%');
    });

    test('formatAltitude rounds to whole meters', () {
      expect(MissionStatusCard.formatAltitude(0), '--');
      expect(MissionStatusCard.formatAltitude(-1), '--');
      expect(MissionStatusCard.formatAltitude(1523.7), '1524m');
    });

    test('formatGps converts ratio to rounded percent', () {
      expect(MissionStatusCard.formatGps(0), 'Pending');
      expect(MissionStatusCard.formatGps(0.95), '95%');
      expect(MissionStatusCard.formatGps(0.876), '88%');
    });

    test('formatBattery returns -- when null', () {
      expect(MissionStatusCard.formatBattery(null), '--');
      expect(MissionStatusCard.formatBattery(42), '42%');
    });

    test('formatHeading returns Pending when zero', () {
      expect(MissionStatusCard.formatHeading(0), 'Pending');
      expect(MissionStatusCard.formatHeading(72.4), '72%');
    });
  });

  group('MissionStatusCard widget rendering', () {
    testWidgets('Speed label and km/h value appear when speed is non-zero',
        (tester) async {
      final runtime = _trackingRuntime(speedMetersPerSecond: 5.0); // 18.0 km/h

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('18.0 km/h'), findsOneWidget);
    });

    testWidgets('Slope label and percent value appear when slope is non-zero',
        (tester) async {
      final runtime = _trackingRuntime(slopePercent: 23.7);

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      expect(find.text('Slope'), findsOneWidget);
      expect(find.text('23.7%'), findsOneWidget);
    });

    testWidgets('Altitude label and meter value appear when altitude non-zero',
        (tester) async {
      final runtime = _trackingRuntime(altitudeMeters: 1200.0);

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      expect(find.text('Altitude'), findsOneWidget);
      expect(find.text('1200m'), findsOneWidget);
    });

    testWidgets('Speed and Slope show -- when values are zero', (tester) async {
      final runtime = _trackingRuntime(
        altitudeMeters: 0,
        speedMetersPerSecond: 0,
        slopePercent: 0,
      );

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      // All three zero-value metrics render '--'
      expect(find.text('--'), findsWidgets);
      // Labels still visible even when values are zero
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Slope'), findsOneWidget);
      expect(find.text('Altitude'), findsOneWidget);
    });

    testWidgets('All three row labels present simultaneously', (tester) async {
      final runtime = _trackingRuntime(
        speedMetersPerSecond: 2.78, // ~10.0 km/h
        slopePercent: 5.0,
        altitudeMeters: 850,
      );

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      expect(find.text('GPS'), findsOneWidget);
      expect(find.text('Battery'), findsOneWidget);
      expect(find.text('Heading'), findsOneWidget);
      expect(find.text('Altitude'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Slope'), findsOneWidget);
    });

    testWidgets('statusLabel "Tracking" appears in card title', (tester) async {
      final runtime = _trackingRuntime();

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: runtime)));

      expect(find.text('Tracking'), findsOneWidget);
    });

    testWidgets('degraded status shows orange accent and Degraded label',
        (tester) async {
      final degradedRuntime = MissionRuntimeState(
        status: MissionStatus.degraded,
        context: const MissionContext(
          degradedReason: DegradedReason.lowBattery,
        ),
        enteredAt: DateTime(2026, 3, 11),
      );

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: degradedRuntime)));

      expect(find.text('Degraded'), findsOneWidget);
      expect(find.text('Low battery mode'), findsOneWidget);
    });

    testWidgets('Offline badge appears when context.isOffline is true',
        (tester) async {
      final offlineRuntime = MissionRuntimeState(
        status: MissionStatus.tracking,
        context: const MissionContext(isOffline: true, gpsConfidence: 0.7),
        enteredAt: DateTime(2026, 3, 11),
      );

      await tester.pumpWidget(_wrap(MissionStatusCard(runtime: offlineRuntime)));

      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('batteryPercent passed directly renders correctly',
        (tester) async {
      final runtime = MissionRuntimeState(
        status: MissionStatus.tracking,
        // batteryPercent NOT set in context — comes from the outer param
        context: const MissionContext(),
        enteredAt: DateTime(2026, 3, 11),
      );

      await tester.pumpWidget(
        _wrap(MissionStatusCard(runtime: runtime, batteryPercent: 78)),
      );

      expect(find.text('78%'), findsOneWidget);
    });
  });

  group('MissionMetricTile', () {
    testWidgets('renders label and value text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MissionMetricTile(
            icon: Icons.speed,
            label: 'Speed',
            value: '18.0 km/h',
          ),
        ),
      );

      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('18.0 km/h'), findsOneWidget);
    });

    testWidgets('renders icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MissionMetricTile(
            icon: Icons.terrain,
            label: 'Slope',
            value: '12.5%',
          ),
        ),
      );

      expect(find.byIcon(Icons.terrain), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:dravik/services/mission_engine/mission_state.dart';
import 'package:dravik/widgets/mission_metric_tile.dart';

/// A self-contained card that renders the current mission telemetry:
/// GPS confidence, battery, heading, altitude, speed, and slope.
///
/// All reactive concerns (Obx, visibility guard) stay in the caller.
/// This widget is a pure function of [runtime] and [batteryPercent].
class MissionStatusCard extends StatelessWidget {
  const MissionStatusCard({
    super.key,
    required this.runtime,
    this.batteryPercent,
  });

  final MissionRuntimeState runtime;
  final int? batteryPercent;

  // ── Static helpers ────────────────────────────────────────────────────────

  static Color statusColor(MissionStatus status) {
    switch (status) {
      case MissionStatus.tracking:
        return const Color(0xFF1B8A5A);
      case MissionStatus.rerouting:
        return const Color(0xFFB26A00);
      case MissionStatus.degraded:
        return const Color(0xFFC2471A);
      case MissionStatus.emergencyMode:
        return const Color(0xFFB00020);
      case MissionStatus.acquiringFix:
        return const Color(0xFF1A73E8);
      case MissionStatus.idle:
        return Colors.blueGrey;
    }
  }

  static String statusLabel(MissionStatus status) {
    switch (status) {
      case MissionStatus.idle:
        return 'Idle';
      case MissionStatus.acquiringFix:
        return 'Acquiring Fix';
      case MissionStatus.tracking:
        return 'Tracking';
      case MissionStatus.rerouting:
        return 'Rerouting';
      case MissionStatus.degraded:
        return 'Degraded';
      case MissionStatus.emergencyMode:
        return 'Emergency';
    }
  }

  static String degradedReasonLabel(DegradedReason reason) {
    switch (reason) {
      case DegradedReason.none:
        return 'All systems nominal';
      case DegradedReason.gpsTimeout:
        return 'GPS timeout';
      case DegradedReason.gpsUnavailable:
        return 'GPS weak';
      case DegradedReason.permissionDenied:
        return 'Permission denied';
      case DegradedReason.lowBattery:
        return 'Low battery mode';
      case DegradedReason.networkUnavailable:
        return 'Offline fallback';
      case DegradedReason.routeUnavailable:
        return 'Route fallback';
      case DegradedReason.sensorFault:
        return 'Sensor fault';
      case DegradedReason.manualEmergency:
        return 'Manual emergency';
    }
  }

  // ── Label formatters ─────────────────────────────────────────────────────

  static String formatGps(double confidence) =>
      confidence <= 0 ? 'Pending' : '${(confidence * 100).round()}%';

  static String formatBattery(int? percent) =>
      percent == null ? '--' : '$percent%';

  static String formatHeading(double confidence) =>
      confidence <= 0 ? 'Pending' : '${confidence.round()}%';

  static String formatAltitude(double meters) =>
      meters <= 0 ? '--' : '${meters.round()}m';

  static String formatSpeed(double mps) =>
      mps <= 0 ? '--' : '${(mps * 3.6).toStringAsFixed(1)} km/h';

  static String formatSlope(double percent) =>
      percent == 0 ? '--' : '${percent.toStringAsFixed(1)}%';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctx = runtime.context;
    final accent = statusColor(runtime.status);

    final effectiveBattery =
        ctx.batteryPercent ?? batteryPercent;

    return Material(
      elevation: 6,
      color: isDark ? Colors.grey.shade900 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.32)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isDark ? 0.24 : 0.12),
              isDark ? Colors.grey.shade900 : Colors.white,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title row ─────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusLabel(runtime.status),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (ctx.isOffline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              degradedReasonLabel(ctx.degradedReason),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
            ),
            if (ctx.lastError != null && ctx.lastError!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                ctx.lastError!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            // ── Row 1: GPS | Battery | Heading ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: MissionMetricTile(
                    icon: Icons.gps_fixed,
                    label: 'GPS',
                    value: formatGps(ctx.gpsConfidence),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MissionMetricTile(
                    icon: effectiveBattery != null && effectiveBattery <= 20
                        ? Icons.battery_alert
                        : Icons.battery_6_bar,
                    label: 'Battery',
                    value: formatBattery(effectiveBattery),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MissionMetricTile(
                    icon: Icons.explore,
                    label: 'Heading',
                    value: formatHeading(ctx.headingConfidence),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Row 2: Altitude | Speed ───────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: MissionMetricTile(
                    icon: Icons.height,
                    label: 'Altitude',
                    value: formatAltitude(ctx.altitudeMeters),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MissionMetricTile(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: formatSpeed(ctx.speedMetersPerSecond),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Row 3: Slope ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: MissionMetricTile(
                    icon: Icons.terrain,
                    label: 'Slope',
                    value: formatSlope(ctx.slopePercent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

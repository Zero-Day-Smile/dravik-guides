import 'package:flutter/material.dart';
import 'package:dravik/config/feature_flags.dart';
import 'package:dravik/widgets/platform_unavailable_screen.dart';

/// Legacy ARCore screen placeholder.
/// Use `ArTrailScannerPro` for the current AR experience.
class ArTrailScannerScreenV2 extends StatelessWidget {
  const ArTrailScannerScreenV2({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.isEnabled(AppFeature.arScanner)) {
      return const PlatformUnavailableScreen(
        title: 'AR Trail (Legacy)',
        message:
            'Legacy AR module is available only in native mobile builds.',
        icon: Icons.view_in_ar,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('AR Trail (Legacy)')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'This legacy ARCore-based screen is disabled.\n\n'
            'Please use the new AR Trail Scanner Pro for sensor-fusion AR overlays.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:dravik/config/edition_copy.dart';
import 'package:dravik/config/platform_capabilities.dart';
import 'package:dravik/widgets/edition_banner.dart';

class EditionBannerForScreen extends StatelessWidget {
  const EditionBannerForScreen({
    super.key,
    required this.screen,
  });

  final EditionScreen screen;

  @override
  Widget build(BuildContext context) {
    final copy = EditionCopy.forScreen(screen);

    if (PlatformCapabilities.isWeb) {
      return EditionBanner(
        type: EditionType.web,
        title: copy.webTitle,
        subtitle: copy.webSubtitle,
      );
    }

    if (PlatformCapabilities.isIOS) {
      return EditionBanner(
        type: EditionType.ios,
        title: copy.iosTitle,
        subtitle: copy.iosSubtitle,
      );
    }

    return EditionBanner(
      type: EditionType.mobile,
      title: copy.mobileTitle,
      subtitle: copy.mobileSubtitle,
    );
  }
}

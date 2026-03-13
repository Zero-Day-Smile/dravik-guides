class EditionText {
  const EditionText({
    required this.webTitle,
    required this.webSubtitle,
    required this.iosTitle,
    required this.iosSubtitle,
    required this.mobileTitle,
    required this.mobileSubtitle,
  });

  final String webTitle;
  final String webSubtitle;
  final String iosTitle;
  final String iosSubtitle;
  final String mobileTitle;
  final String mobileSubtitle;
}

enum EditionScreen {
  home,
  map,
  guides,
  guidesNew,
  guideDetail,
  tripPlanner,
  gear,
  gearNew,
  settings,
  countryExplorer,
  weather,
  placeGuide,
  emergencyGuides,
  analytics,
  ultimateGuide,
}

class EditionCopy {
  const EditionCopy._();

  static EditionText forScreen(EditionScreen screen) {
    switch (screen) {
      case EditionScreen.home:
        return const EditionText(
          webTitle: 'Web Discovery Hub',
          webSubtitle:
              'Explore ranked destinations and plan journeys with a desktop-first flow.',
          iosTitle: 'iOS Adventure Hub',
          iosSubtitle: 'Refined navigation and presentation designed for iOS behavior.',
          mobileTitle: 'Mobile Expedition Hub',
          mobileSubtitle:
              'Operate full trek workflows with advanced in-field capabilities.',
        );
      case EditionScreen.map:
        return const EditionText(
          webTitle: 'Web Exploration Map',
          webSubtitle:
              'Best for route discovery and pre-trip planning on a larger screen.',
          iosTitle: 'iOS Navigation Map',
          iosSubtitle: 'Smooth map gestures and battery-conscious map interactions.',
          mobileTitle: 'Mobile Field Navigation',
          mobileSubtitle:
              'Live map operations optimized for on-route decision making.',
        );
      case EditionScreen.guides:
      case EditionScreen.guidesNew:
        return const EditionText(
          webTitle: 'Web Guide Studio',
          webSubtitle: 'Research and compare guides quickly with desktop-focused flow.',
          iosTitle: 'iOS Guide Studio',
          iosSubtitle: 'Curated readability and touch flow for iOS devices.',
          mobileTitle: 'Mobile Guide Studio',
          mobileSubtitle:
              'Rapid tactical guide access for active travel and treks.',
        );
      case EditionScreen.guideDetail:
        return const EditionText(
          webTitle: 'Web Reading Experience',
          webSubtitle: 'Long-form guide reading and planning optimized for desktop.',
          iosTitle: 'iOS Reading Experience',
          iosSubtitle: 'Comfort-focused typography and pacing for iOS devices.',
          mobileTitle: 'Mobile Reading Experience',
          mobileSubtitle: 'Quick tactical reading flow for on-route decision making.',
        );
      case EditionScreen.tripPlanner:
        return const EditionText(
          webTitle: 'Web Planning Studio',
          webSubtitle:
              'Compare itineraries and shortlist journeys before heading mobile.',
          iosTitle: 'iOS Trip Experience',
          iosSubtitle: 'Smooth planning flow tuned for iOS interactions.',
          mobileTitle: 'Mobile Expedition Mode',
          mobileSubtitle:
              'Use this on the go for full tracking, safety signals, and updates.',
        );
      case EditionScreen.gear:
      case EditionScreen.gearNew:
        return const EditionText(
          webTitle: 'Web Gear Studio',
          webSubtitle: 'Compare packing strategies and refine lists from desktop.',
          iosTitle: 'iOS Gear Studio',
          iosSubtitle: 'Polished list management and interactions tuned for iOS.',
          mobileTitle: 'Mobile Gear Studio',
          mobileSubtitle:
              'Fast packing workflows for expedition-ready mobile usage.',
        );
      case EditionScreen.settings:
        return const EditionText(
          webTitle: 'Web Settings Profile',
          webSubtitle:
              'Web-first preferences for planning and account controls.',
          iosTitle: 'iOS Settings Profile',
          iosSubtitle: 'Privacy-focused defaults and iOS-optimized controls.',
          mobileTitle: 'Mobile Settings Profile',
          mobileSubtitle:
              'Full expedition controls for sensors, emergency and travel logic.',
        );
      case EditionScreen.countryExplorer:
        return const EditionText(
          webTitle: 'Web Destination Research',
          webSubtitle:
              'Compare countries, shortlist routes, and prepare logistics from desktop.',
          iosTitle: 'iOS Explorer Mode',
          iosSubtitle: 'Quick destination insights optimized for iOS reading flow.',
          mobileTitle: 'Mobile Explorer Mode',
          mobileSubtitle:
              'Carry destination intelligence directly into the field.',
        );
      case EditionScreen.weather:
        return const EditionText(
          webTitle: 'Web Weather Desk',
          webSubtitle:
              'Use desktop forecasting for pre-trip planning and risk comparison.',
          iosTitle: 'iOS Forecast Mode',
          iosSubtitle: 'Optimized for quick check-ins with iOS-friendly density.',
          mobileTitle: 'Mobile Forecast Mode',
          mobileSubtitle: 'Designed for field decisions and on-route weather updates.',
        );
      case EditionScreen.placeGuide:
        return const EditionText(
          webTitle: 'Web AI Planning Assistant',
          webSubtitle:
              'Generate destination intelligence and compare journey ideas from desktop.',
          iosTitle: 'iOS AI Guide Mode',
          iosSubtitle: 'Balanced summaries and smoother reading for iOS devices.',
          mobileTitle: 'Mobile AI Field Guide',
          mobileSubtitle:
              'Actionable advice designed for real-time travel and trek execution.',
        );
      case EditionScreen.emergencyGuides:
        return const EditionText(
          webTitle: 'Web Emergency Knowledge Base',
          webSubtitle:
              'Learn protocols on desktop and rely on mobile for live emergency actions.',
          iosTitle: 'iOS Safety Guide Mode',
          iosSubtitle: 'Fast-reference emergency knowledge tuned for iOS usage.',
          mobileTitle: 'Mobile Emergency Ready',
          mobileSubtitle:
              'Operational emergency guidance for active field scenarios.',
        );
      case EditionScreen.analytics:
        return const EditionText(
          webTitle: 'Web Insight Dashboard',
          webSubtitle:
              'Compare progress trends and plan improvements from a larger screen.',
          iosTitle: 'iOS Performance Snapshot',
          iosSubtitle: 'Focused analytics cards with iOS-optimized readability.',
          mobileTitle: 'Mobile Performance Tracker',
          mobileSubtitle: 'Track expedition outcomes alongside active journeys.',
        );
      case EditionScreen.ultimateGuide:
        return const EditionText(
          webTitle: 'Web Master Guide Library',
          webSubtitle:
              'Deep research mode with broad survival and travel references.',
          iosTitle: 'iOS Master Guide Mode',
          iosSubtitle: 'Structured long-form guidance optimized for iOS readability.',
          mobileTitle: 'Mobile Master Guide Mode',
          mobileSubtitle:
              'Practical field-grade guidance designed for expedition contexts.',
        );
    }
  }
}

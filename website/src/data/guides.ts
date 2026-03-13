import { Mountain, Compass, Thermometer, Backpack, Footprints, Sun, CloudRain, TreePine } from "lucide-react";

export type GuideItem = {
  slug: string;
  icon: typeof Mountain;
  title: string;
  description: string;
  difficulty: "Beginner" | "Moderate" | "Challenging" | "Advanced";
  tips: string[];
  markdown: string;
};

export const guides: GuideItem[] = [
  {
    slug: "high-altitude-trekking",
    icon: Mountain,
    title: "High Altitude Trekking",
    description:
      "Everything you need to know about acclimatization, altitude sickness prevention, and thriving above 4,000m.",
    tips: [
      "Ascend no more than 500m per day above 3,000m",
      "Stay hydrated and monitor symptoms daily",
      "Carry Diamox as preventive support",
      "Never ignore persistent headaches or nausea",
    ],
    difficulty: "Advanced",
    markdown: `## Overview\nHigh altitude trekking requires progressive adaptation. The objective is to maximize safety while preserving climb momentum.\n\n## Acclimatization Protocol\n- Climb high, sleep low\n- Add one rest day every 3-4 days\n- Keep a conservative ascent profile above 3000m\n\n## Warning Signs\n- Persistent headache\n- Nausea or appetite loss\n- Ataxia or unusual fatigue\n\n## Action Plan\nIf symptoms worsen at rest, descend immediately and avoid further ascent until full recovery.`,
  },
  {
    slug: "navigation-in-the-wild",
    icon: Compass,
    title: "Navigation in the Wild",
    description: "Master map reading, compass navigation, and GPS usage for backcountry adventures.",
    tips: [
      "Carry a physical map as backup",
      "Read contour lines and slope breaks",
      "Use landmarks for route validation",
      "Practice triangulation before long treks",
    ],
    difficulty: "Moderate",
    markdown: `## Overview\nNavigation skill is your fail-safe when batteries die or signal drops.\n\n## Core Stack\n- Paper topo map\n- Baseplate compass\n- GPS device or phone offline map\n\n## Field Workflow\n1. Set bearing\n2. Confirm terrain match\n3. Recheck every major landmark\n\n## Mistake Prevention\nNever rely on a single tool. Cross-check direction and distance at every route transition.`,
  },
  {
    slug: "packing-for-multi-day-treks",
    icon: Backpack,
    title: "Packing for Multi-Day Treks",
    description: "The art of packing light without sacrificing safety.",
    tips: [
      "Keep base weight under 10kg where possible",
      "Use layer systems and avoid cotton",
      "Always include rain protection",
      "Test every piece of gear pre-trip",
    ],
    difficulty: "Beginner",
    markdown: `## Overview\nGreat pack systems balance safety, comfort, and pace.\n\n## Priority Order\n- Shelter and sleep system\n- Clothing layers\n- Food and hydration\n- Navigation and emergency kit\n\n## Pack Strategy\nHeaviest items close to spine center. Frequently used gear near top access.\n\n## Final Check\nRun a full load walk before departure to spot pressure points and overpacking.`,
  },
  {
    slug: "weather-reading-and-forecasting",
    icon: Thermometer,
    title: "Weather Reading and Forecasting",
    description: "Understand cloud formations, wind patterns, and pressure shifts to predict weather changes.",
    tips: [
      "Lenticular clouds often signal instability",
      "Rapid pressure drop means worsening weather",
      "Check mountain-specific forecasts 48h ahead",
      "Start early to avoid afternoon storm windows",
    ],
    difficulty: "Moderate",
    markdown: `## Overview\nForecasting on trail is pattern recognition plus conservative decisions.\n\n## Inputs\n- Forecast trend over 48 hours\n- Cloud development speed\n- Wind shift and gust profile\n\n## Decision Rule\nIf terrain exposure is high and weather confidence is low, reduce objective and return with margin.`,
  },
  {
    slug: "leave-no-trace-principles",
    icon: TreePine,
    title: "Leave No Trace Principles",
    description: "Seven principles of outdoor ethics for long-term wilderness protection.",
    tips: [
      "Plan ahead and prepare",
      "Travel on durable surfaces",
      "Pack out all waste",
      "Leave what you find",
    ],
    difficulty: "Beginner",
    markdown: `## Overview\nResponsible travel keeps ecosystems healthy and access open for future adventurers.\n\n## Principles\n- Minimize campsite impact\n- Respect wildlife distance\n- Preserve natural and cultural features\n\n## Practical Habit\nBefore moving camp, perform a final impact sweep with your team.`,
  },
  {
    slug: "desert-and-arid-trekking",
    icon: Sun,
    title: "Desert and Arid Trekking",
    description: "Survive and thrive in heat with water discipline and movement timing.",
    tips: [
      "Carry at least 1L per hour of movement",
      "Hike dawn and dusk, rest midday",
      "Wear loose sun-protective layers",
      "Know heat exhaustion warning signs",
    ],
    difficulty: "Advanced",
    markdown: `## Overview\nHeat management is performance management. Small mistakes compound quickly in arid terrain.\n\n## Core Rules\n- Protect skin and head from direct sun\n- Hydrate before thirst appears\n- Monitor urine color and team fatigue\n\n## Emergency Trigger\nIf confusion or unstable gait appears, stop and cool immediately.`,
  },
  {
    slug: "monsoon-and-wet-season-hiking",
    icon: CloudRain,
    title: "Monsoon and Wet Season Hiking",
    description: "Hike safely during rainy seasons with river and footing risk control.",
    tips: [
      "Keep essentials in waterproof dry bags",
      "Avoid river crossings after heavy rain",
      "Use poles for muddy and unstable terrain",
      "Start early before storm build-up",
    ],
    difficulty: "Challenging",
    markdown: `## Overview\nWet-season trekking is mostly about timing and terrain conservatism.\n\n## Critical Risks\n- Flash flooding\n- Trail washouts\n- Reduced visibility\n\n## Safety Pattern\nBuild retreat options into every segment and cut objectives early when water levels rise.`,
  },
  {
    slug: "trail-running-fundamentals",
    icon: Footprints,
    title: "Trail Running Fundamentals",
    description: "Transition from road to trail with terrain-aware running mechanics.",
    tips: [
      "Shorten stride on technical sections",
      "Look 3-4 steps ahead",
      "Increase mileage gradually",
      "Use shoes matched to terrain grip needs",
    ],
    difficulty: "Moderate",
    markdown: `## Overview\nTrail speed comes from rhythm and control, not forcing pace.\n\n## Technique\n- Keep cadence stable
- Soften downhill impact
- Use arms for balance on narrow sections\n\n## Progression\nAlternate easy and technical days to build skill and reduce overuse injury risk.`,
  },
];

export const getGuideBySlug = (slug: string) => guides.find((guide) => guide.slug === slug);

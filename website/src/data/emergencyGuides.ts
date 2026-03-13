export type EmergencyGuide = {
  slug: string;
  title: string;
  category: "Medical" | "Weather" | "Navigation" | "Rescue";
  summary: string;
  steps: string[];
};

export const emergencyGuides: EmergencyGuide[] = [
  {
    slug: "altitude-sickness-response",
    title: "Altitude Sickness Response",
    category: "Medical",
    summary: "Immediate steps when AMS symptoms escalate during high-elevation treks.",
    steps: [
      "Stop ascent immediately and assess all team members.",
      "Hydrate and monitor for worsening headache, nausea, confusion, or ataxia.",
      "Descend 500-1000m if symptoms persist at rest.",
      "Administer medication per prior medical guidance and seek evacuation if severe.",
    ],
  },
  {
    slug: "storm-and-lightning-protocol",
    title: "Storm and Lightning Protocol",
    category: "Weather",
    summary: "Risk-reduction protocol for exposed terrain during thunderstorm development.",
    steps: [
      "Exit ridgelines and summits immediately when thunder is nearby.",
      "Avoid isolated trees and metal equipment clusters.",
      "Spread group members out to reduce multi-casualty risk.",
      "Resume movement only after at least 30 minutes without thunder.",
    ],
  },
  {
    slug: "lost-navigation-stop-plan",
    title: "Lost Navigation STOP Plan",
    category: "Navigation",
    summary: "Structured decision cycle for route loss or map uncertainty.",
    steps: [
      "Stop moving and prevent panic-driven drift.",
      "Think through last confirmed waypoint and elapsed travel time.",
      "Observe terrain, bearings, and weather for relocation clues.",
      "Plan conservative return or hold position with signaling if uncertain.",
    ],
  },
  {
    slug: "injury-and-evacuation-setup",
    title: "Injury and Evacuation Setup",
    category: "Rescue",
    summary: "Basic stabilization and evacuation preparation for serious trail injuries.",
    steps: [
      "Stabilize airway, bleeding, and fractures before movement.",
      "Share exact coordinates and access landmarks with rescue channels.",
      "Protect casualty from exposure and maintain hydration where safe.",
      "Assign team roles for signaling, route clearing, and documentation.",
    ],
  },
];

class Guide {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<String> tags;

  Guide({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.tags,
  });
}

// Dummy data (replace with Triposo/Wiki API later)
final List<Guide> sampleGuides = [
  Guide(
    title: "Valley of Flowers",
    subtitle: "Uttarakhand • Moderate • June–Sept",
    imageUrl: "https://images.unsplash.com/photo-1563201517-e8cfbe8a8c15",
    tags: ["Nature", "UNESCO", "Wildflowers"],
  ),
  Guide(
    title: "Sandakphu Trek",
    subtitle: "Darjeeling • Moderate • Nov–Feb",
    imageUrl: "https://images.unsplash.com/photo-1609840172570-bdb1c9b45b83",
    tags: ["Himalayas", "4 Peaks View", "Sunrise"],
  ),
];

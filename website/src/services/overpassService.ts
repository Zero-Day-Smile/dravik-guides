const ENDPOINT = "https://overpass-api.de/api/interpreter";

interface OverpassElement {
  id: number;
  type: "node" | "way" | "relation";
  tags?: Record<string, string>;
  geometry?: { lat: number; lon: number }[];
  center?: { lat: number; lon: number };
  lat?: number;
  lon?: number;
}

async function runQuery(query: string): Promise<OverpassElement[]> {
  const res = await fetch(ENDPOINT, {
    method: "POST",
    body: `data=${encodeURIComponent(query)}`,
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  if (!res.ok) return [];
  const json = await res.json() as { elements: OverpassElement[] };
  return json.elements ?? [];
}

function bbox(south: number, west: number, north: number, east: number) {
  return `${south},${west},${north},${east}`;
}

export interface TrailFeature {
  id: string;
  name: string;
  difficulty: string;
  surface: string;
  coords: [number, number][];
}

export interface PointFeature {
  id: string;
  name: string;
  lat: number;
  lon: number;
  category: string;
}

export async function fetchTrails(
  south: number, west: number, north: number, east: number,
  nameFilter?: string
): Promise<TrailFeature[]> {
  const bb = bbox(south, west, north, east);
  const nameQ = nameFilter ? `["name"~"${nameFilter}",i]` : "";
  const query = `[out:json][timeout:20];
way["highway"~"path|footway|bridleway"]${nameQ}(${bb});
out geom 200;`;

  const elements = await runQuery(query);
  return elements
    .filter((e) => Array.isArray(e.geometry) && e.geometry.length > 1)
    .map((e) => ({
      id: String(e.id),
      name: e.tags?.name ?? "Unnamed Trail",
      difficulty: e.tags?.sac_scale ?? "hiking",
      surface: e.tags?.surface ?? "unknown",
      coords: (e.geometry ?? []).map((g) => [g.lat, g.lon] as [number, number]),
    }));
}

export async function fetchShelters(
  south: number, west: number, north: number, east: number
): Promise<PointFeature[]> {
  const bb = bbox(south, west, north, east);
  const query = `[out:json][timeout:15];
(
  node["tourism"="alpine_hut"](${bb});
  node["amenity"="shelter"](${bb});
  way["tourism"="alpine_hut"](${bb});
  way["amenity"="shelter"](${bb});
);
out center 100;`;
  const elements = await runQuery(query);
  return toPoints(elements, "shelter");
}

export async function fetchWaterSources(
  south: number, west: number, north: number, east: number
): Promise<PointFeature[]> {
  const bb = bbox(south, west, north, east);
  const query = `[out:json][timeout:15];
(
  node["natural"="spring"](${bb});
  node["amenity"="drinking_water"](${bb});
);
out center 100;`;
  const elements = await runQuery(query);
  return toPoints(elements, "water");
}

export async function fetchPOIs(
  south: number, west: number, north: number, east: number,
  key: string, values: string[], label: string
): Promise<PointFeature[]> {
  const bb = bbox(south, west, north, east);
  const valRe = values.join("|");
  const query = `[out:json][timeout:15];
(
  node["${key}"~"${valRe}"](${bb});
  way["${key}"~"${valRe}"](${bb});
);
out center 100;`;
  const elements = await runQuery(query);
  return toPoints(elements, label);
}

function toPoints(elements: OverpassElement[], category: string): PointFeature[] {
  return elements
    .map((e) => {
      const center = e.type === "way" ? e.center : e;
      if (!center?.lat || !center?.lon) return null;
      return {
        id: String(e.id),
        name: e.tags?.name ?? category,
        lat: center.lat as number,
        lon: center.lon as number,
        category,
      };
    })
    .filter(Boolean) as PointFeature[];
}

export async function searchPlaces(query: string): Promise<{ name: string; lat: number; lon: number; display: string }[]> {
  const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5`;
  const res = await fetch(url, { headers: { "Accept-Language": "en" } });
  if (!res.ok) return [];
  const json = await res.json() as { name: string; display_name: string; lat: string; lon: string }[];
  return json.map((r) => ({
    name: r.name,
    display: r.display_name,
    lat: parseFloat(r.lat),
    lon: parseFloat(r.lon),
  }));
}

export async function fetchWikiSummary(placeName: string): Promise<{ title: string; summary: string } | null> {
  const slug = encodeURIComponent(placeName.replace(/ /g, "_"));
  try {
    const res = await fetch(`https://en.wikipedia.org/api/rest_v1/page/summary/${slug}`);
    if (!res.ok) return null;
    const json = await res.json();
    return { title: json.title, summary: json.extract ?? "" };
  } catch {
    return null;
  }
}

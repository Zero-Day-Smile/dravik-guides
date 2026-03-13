import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  MapPin, Navigation, Layers, Search, X, Droplets,
  Home, ShoppingBag, Utensils, HeartPulse, Fuel,
  TreePine, Bus, Hotel, Star, Landmark, Wrench,
  Mountain, ChevronDown, ChevronUp, Info,
} from "lucide-react";
import L from "leaflet";
import {
  MapContainer, Marker, Popup, TileLayer,
  Polyline, useMap, useMapEvents, CircleMarker,
} from "react-leaflet";
import "leaflet/dist/leaflet.css";
import Navbar from "@/components/Navbar";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useDestinations } from "@/hooks/useDestinations";
import {
  fetchTrails, fetchShelters, fetchWaterSources, fetchPOIs,
  searchPlaces, fetchWikiSummary,
  type TrailFeature, type PointFeature,
} from "@/services/overpassService";

// ─── Constants ────────────────────────────────────────────────────────────────
const DEFAULT_CENTER: [number, number] = [27.98785, 86.925026];
const DEFAULT_ZOOM = 7;

const TILE_LAYERS = {
  osm: {
    label: "Street",
    url: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
  },
  satellite: {
    label: "Satellite",
    url: "https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    attribution: "Tiles &copy; Esri",
  },
  topographic: {
    label: "Topo",
    url: "https://tile.opentopomap.org/{z}/{x}/{y}.png",
    attribution: '&copy; <a href="https://opentopomap.org">OpenTopoMap</a> contributors',
  },
} as const;

type LayerKey = keyof typeof TILE_LAYERS;

const DEST_ICON = new L.Icon({
  iconUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
  iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34], shadowSize: [41, 41],
});

const USER_ICON = new L.DivIcon({
  className: "",
  html: `<div style="background:#3b82f6;width:14px;height:14px;border-radius:50%;border:2px solid white;box-shadow:0 0 0 3px rgba(59,130,246,0.4)"></div>`,
  iconSize: [14, 14], iconAnchor: [7, 7],
});

const TRAIL_COLORS: Record<string, string> = {
  hiking: "#22c55e",
  mountain_hiking: "#f59e0b",
  demanding_mountain_hiking: "#ef4444",
  alpine_hiking: "#a855f7",
  demanding_alpine_hiking: "#ec4899",
  unknown: "#64748b",
};

const POI_CATEGORIES = [
  { key: "trails",    label: "Trails",    icon: TreePine,    color: "#22c55e", activeClass: "bg-[#22c55e]" },
  { key: "shelters",  label: "Shelters",  icon: Home,        color: "#f59e0b", activeClass: "bg-[#f59e0b]" },
  { key: "water",     label: "Water",     icon: Droplets,    color: "#3b82f6", activeClass: "bg-[#3b82f6]" },
  { key: "food",      label: "Food",      icon: Utensils,    color: "#f97316", activeClass: "bg-[#f97316]" },
  { key: "medical",   label: "Medical",   icon: HeartPulse,  color: "#ef4444", activeClass: "bg-[#ef4444]" },
  { key: "shops",     label: "Shops",     icon: ShoppingBag, color: "#8b5cf6", activeClass: "bg-[#8b5cf6]" },
  { key: "fuel",      label: "Fuel",      icon: Fuel,        color: "#64748b", activeClass: "bg-[#64748b]" },
  { key: "hotels",    label: "Hotels",    icon: Hotel,       color: "#d97706", activeClass: "bg-[#d97706]" },
  { key: "transport", label: "Transport", icon: Bus,         color: "#0ea5e9", activeClass: "bg-[#0ea5e9]" },
  { key: "atm",       label: "ATM",       icon: Landmark,    color: "#10b981", activeClass: "bg-[#10b981]" },
  { key: "repair",    label: "Repair",    icon: Wrench,      color: "#78716c", activeClass: "bg-[#78716c]" },
] as const;

type PoiKey = (typeof POI_CATEGORIES)[number]["key"];

// ─── Sub-components ───────────────────────────────────────────────────────────
function MapController({ center, zoom }: { center: [number, number]; zoom: number }) {
  const map = useMap();
  useEffect(() => { map.setView(center, zoom); }, [center, zoom]);  // eslint-disable-line
  return null;
}

function MapClickHandler({ onMapMoved }: { onMapMoved: (bounds: L.LatLngBounds) => void }) {
  const map = useMapEvents({
    moveend: () => onMapMoved(map.getBounds()),
    zoomend: () => onMapMoved(map.getBounds()),
  });
  useEffect(() => { onMapMoved(map.getBounds()); }, []); // eslint-disable-line
  return null;
}

// ─── Main Component ───────────────────────────────────────────────────────────
const MapPage = () => {
  // layer
  const [activeLayer, setActiveLayer] = useState<LayerKey>("topographic");
  const [showLayerPanel, setShowLayerPanel] = useState(false);

  // enabled overlays
  const [enabled, setEnabled] = useState<Set<PoiKey>>(new Set(["trails"]));

  // search
  const [placeQuery, setPlaceQuery] = useState("");
  const [placeResults, setPlaceResults] = useState<{ name: string; display: string; lat: number; lon: number }[]>([]);
  const [searchLoading, setSearchLoading] = useState(false);

  // map center + flyto
  const [mapCenter, setMapCenter] = useState<[number, number]>(DEFAULT_CENTER);
  const [mapZoom, setMapZoom] = useState(DEFAULT_ZOOM);

  // user GPS
  const [userPos, setUserPos] = useState<[number, number] | null>(null);

  // overpass data
  const [trails, setTrails] = useState<TrailFeature[]>([]);
  const [shelters, setShelters] = useState<PointFeature[]>([]);
  const [water, setWater] = useState<PointFeature[]>([]);
  const [poisMap, setPoisMap] = useState<Record<string, PointFeature[]>>({});
  const [overpassLoading, setOverpassLoading] = useState(false);

  // wiki info card
  const [wikiCard, setWikiCard] = useState<{ title: string; summary: string } | null>(null);
  const [wikiLoading, setWikiLoading] = useState(false);

  // sidebar
  const [sidebarOpen, setSidebarOpen] = useState(true);

  // Dravik destinations
  const { data: destinations } = useDestinations({ limit: 300 });
  const mappable = useMemo(
    () => (destinations || []).filter((d) => d.latitude != null && d.longitude != null),
    [destinations],
  );

  // toggle overlay category
  const toggleCategory = useCallback((key: PoiKey) => {
    setEnabled((prev) => {
      const next = new Set(prev);
      if (next.has(key)) { next.delete(key); } else { next.add(key); }
      return next;
    });
  }, []);

  // GPS locate me
  const locateMe = useCallback(() => {
    if (!navigator.geolocation) return;
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const coords: [number, number] = [pos.coords.latitude, pos.coords.longitude];
        setUserPos(coords);
        setMapCenter(coords);
        setMapZoom(13);
      },
      () => {},
      { enableHighAccuracy: true, timeout: 8000 },
    );
  }, []);

  // place search via Nominatim
  const handlePlaceSearch = useCallback(async () => {
    if (!placeQuery.trim()) return;
    setSearchLoading(true);
    const results = await searchPlaces(placeQuery);
    setPlaceResults(results);
    setSearchLoading(false);
  }, [placeQuery]);

  const flyToPlace = useCallback((lat: number, lon: number, name: string) => {
    setMapCenter([lat, lon]);
    setMapZoom(13);
    setPlaceResults([]);
    setPlaceQuery(name);
    // fetch wiki summary
    setWikiLoading(true);
    setWikiCard(null);
    fetchWikiSummary(name).then((info) => {
      setWikiCard(info);
      setWikiLoading(false);
    });
  }, []);

  // load overpass data when map moves
  const loadOverpass = useCallback(async (bounds: L.LatLngBounds) => {
    if (bounds.getNorth() - bounds.getSouth() > 3) return; // too zoomed out
    setOverpassLoading(true);
    const s = bounds.getSouth(), w = bounds.getWest(), n = bounds.getNorth(), e = bounds.getEast();
    const jobs: Promise<void>[] = [];

    if (enabled.has("trails")) {
      jobs.push(fetchTrails(s, w, n, e).then(setTrails));
    }
    if (enabled.has("shelters")) {
      jobs.push(fetchShelters(s, w, n, e).then(setShelters));
    }
    if (enabled.has("water")) {
      jobs.push(fetchWaterSources(s, w, n, e).then(setWater));
    }
    if (enabled.has("food")) {
      jobs.push(fetchPOIs(s, w, n, e, "amenity", ["restaurant", "cafe", "fast_food", "bar"], "food")
        .then((p) => setPoisMap((prev) => ({ ...prev, food: p }))));
    }
    if (enabled.has("medical")) {
      jobs.push(fetchPOIs(s, w, n, e, "amenity", ["hospital", "clinic", "pharmacy", "doctors"], "medical")
        .then((p) => setPoisMap((prev) => ({ ...prev, medical: p }))));
    }
    if (enabled.has("shops")) {
      jobs.push(fetchPOIs(s, w, n, e, "shop", ["supermarket", "convenience", "general"], "shops")
        .then((p) => setPoisMap((prev) => ({ ...prev, shops: p }))));
    }
    if (enabled.has("fuel")) {
      jobs.push(fetchPOIs(s, w, n, e, "amenity", ["fuel"], "fuel")
        .then((p) => setPoisMap((prev) => ({ ...prev, fuel: p }))));
    }
    if (enabled.has("hotels")) {
      jobs.push(fetchPOIs(s, w, n, e, "tourism", ["hotel", "hostel", "guest_house", "motel"], "hotels")
        .then((p) => setPoisMap((prev) => ({ ...prev, hotels: p }))));
    }
    if (enabled.has("transport")) {
      jobs.push(fetchPOIs(s, w, n, e, "highway", ["bus_stop"], "transport")
        .then((p) => setPoisMap((prev) => ({ ...prev, transport: p }))));
    }
    if (enabled.has("atm")) {
      jobs.push(fetchPOIs(s, w, n, e, "amenity", ["atm", "bank"], "atm")
        .then((p) => setPoisMap((prev) => ({ ...prev, atm: p }))));
    }
    if (enabled.has("repair")) {
      jobs.push(fetchPOIs(s, w, n, e, "shop", ["bicycle", "outdoor"], "repair")
        .then((p) => setPoisMap((prev) => ({ ...prev, repair: p }))));
    }

    await Promise.allSettled(jobs);
    setOverpassLoading(false);
  }, [enabled]);

  // re-load when enabled set changes (triggers new map bounds load on next render)
  const boundsRef = useRef<L.LatLngBounds | null>(null);
  const handleBoundsChanged = useCallback((bounds: L.LatLngBounds) => {
    boundsRef.current = bounds;
    loadOverpass(bounds);
  }, [loadOverpass]);

  useEffect(() => {
    if (boundsRef.current) loadOverpass(boundsRef.current);
  }, [enabled]); // eslint-disable-line

  const tileLayer = TILE_LAYERS[activeLayer];

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-20">
        <div className="flex h-[calc(100vh-80px)] relative">

          {/* ── SIDEBAR ── */}
          <AnimatePresence>
            {sidebarOpen && (
              <motion.div
                initial={{ x: -320, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                exit={{ x: -320, opacity: 0 }}
                transition={{ type: "spring", stiffness: 300, damping: 30 }}
                className="absolute left-0 top-0 bottom-0 z-[1000] w-80 bg-background/95 backdrop-blur-xl border-r border-border flex flex-col shadow-2xl"
              >
                {/* Header */}
                <div className="p-4 border-b border-border flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Mountain className="w-5 h-5 text-primary" />
                    <span className="font-display font-bold text-lg">
                      Trail <span className="text-gradient-amber">Map</span>
                    </span>
                  </div>
                  <button aria-label="Close sidebar" onClick={() => setSidebarOpen(false)} className="text-muted-foreground hover:text-foreground">
                    <X className="w-4 h-4" />
                  </button>
                </div>

                {/* Place Search */}
                <div className="p-4 border-b border-border space-y-2">
                  <div className="flex gap-2">
                    <Input
                      placeholder="Search place…"
                      value={placeQuery}
                      onChange={(e) => setPlaceQuery(e.target.value)}
                      onKeyDown={(e) => e.key === "Enter" && handlePlaceSearch()}
                      className="bg-muted border-border font-body text-sm"
                    />
                    <Button size="sm" onClick={handlePlaceSearch} disabled={searchLoading} className="px-3">
                      <Search className="w-4 h-4" />
                    </Button>
                  </div>
                  {placeResults.length > 0 && (
                    <div className="rounded-xl border border-border bg-background shadow-lg max-h-52 overflow-auto">
                      {placeResults.map((r, i) => (
                        <button
                          key={i}
                          onClick={() => flyToPlace(r.lat, r.lon, r.name)}
                          className="w-full text-left px-3 py-2 hover:bg-muted text-sm font-body border-b border-border last:border-0"
                        >
                          <p className="font-semibold text-foreground truncate">{r.name}</p>
                          <p className="text-xs text-muted-foreground truncate">{r.display}</p>
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Layer switcher */}
                <div className="p-4 border-b border-border">
                  <button
                    className="flex items-center gap-2 w-full text-sm font-body font-semibold text-foreground mb-2"
                    onClick={() => setShowLayerPanel((v) => !v)}
                  >
                    <Layers className="w-4 h-4 text-primary" /> Map Style
                    {showLayerPanel ? <ChevronUp className="w-3 h-3 ml-auto" /> : <ChevronDown className="w-3 h-3 ml-auto" />}
                  </button>
                  {showLayerPanel && (
                    <div className="grid grid-cols-3 gap-2">
                      {(Object.keys(TILE_LAYERS) as LayerKey[]).map((key) => (
                        <button
                          key={key}
                          onClick={() => setActiveLayer(key)}
                          className={`rounded-lg py-2 px-3 text-xs font-body font-semibold border transition-colors ${
                            activeLayer === key
                              ? "bg-primary text-primary-foreground border-primary"
                              : "bg-muted border-border text-foreground hover:bg-muted/70"
                          }`}
                        >
                          {TILE_LAYERS[key].label}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                {/* Overlay categories */}
                <div className="p-4 border-b border-border">
                  <p className="text-xs font-body font-semibold text-muted-foreground mb-2 uppercase tracking-wider">Overlays</p>
                  <div className="flex flex-wrap gap-2">
                    {POI_CATEGORIES.map(({ key, label, icon: Icon, activeClass }) => (
                      <button
                        key={key}
                        onClick={() => toggleCategory(key)}
                        className={`flex items-center gap-1.5 rounded-full px-3 py-1 text-xs font-body font-semibold border transition-all ${
                          enabled.has(key)
                            ? `${activeClass} border-transparent text-white`
                            : "bg-muted border-border text-muted-foreground hover:border-foreground/30"
                        }`}
                      >
                        <Icon className="w-3 h-3" /> {label}
                      </button>
                    ))}
                  </div>
                  {overpassLoading && (
                    <p className="text-xs text-muted-foreground mt-2 flex items-center gap-1">
                      <span className="w-2 h-2 rounded-full bg-primary animate-pulse inline-block" />
                      Loading overlays…
                    </p>
                  )}
                </div>

                {/* Wikipedia info card */}
                {(wikiCard || wikiLoading) && (
                  <div className="p-4 border-b border-border">
                    <div className="flex items-center gap-2 mb-1">
                      <Info className="w-4 h-4 text-primary" />
                      <p className="text-xs font-body font-semibold text-foreground">{wikiCard?.title ?? "Loading…"}</p>
                    </div>
                    {wikiLoading && <p className="text-xs text-muted-foreground">Fetching Wikipedia summary…</p>}
                    {wikiCard?.summary && (
                      <p className="text-xs text-muted-foreground leading-relaxed line-clamp-4">{wikiCard.summary}</p>
                    )}
                  </div>
                )}

                {/* Dravik destinations list */}
                <div className="flex-1 overflow-auto p-4">
                  <p className="text-xs font-body font-semibold text-muted-foreground mb-2 uppercase tracking-wider">
                    Destinations ({mappable.length})
                  </p>
                  <div className="space-y-1.5">
                    {mappable.map((dest) => (
                      <button
                        key={dest.id}
                        className="w-full text-left rounded-xl bg-muted/40 hover:bg-muted/70 p-3 transition-colors"
                        onClick={() => {
                          setMapCenter([dest.latitude as number, dest.longitude as number]);
                          setMapZoom(11);
                        }}
                      >
                        <p className="font-display text-sm text-foreground truncate">{dest.title}</p>
                        <p className="font-body text-xs text-muted-foreground truncate">
                          {dest.location}, {dest.country}
                        </p>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-xs text-muted-foreground">{dest.difficulty ?? "—"}</span>
                          {dest.avg_rating ? (
                            <span className="flex items-center gap-0.5 text-xs text-amber-500">
                              <Star className="w-3 h-3 fill-current" /> {dest.avg_rating.toFixed(1)}
                            </span>
                          ) : null}
                        </div>
                      </button>
                    ))}
                    {mappable.length === 0 && (
                      <p className="text-xs text-muted-foreground">No destinations with coordinates yet.</p>
                    )}
                  </div>
                </div>

                {/* GPS button */}
                <div className="p-4 border-t border-border">
                  <Button onClick={locateMe} variant="outline" className="w-full flex items-center gap-2 font-body text-sm">
                    <Navigation className="w-4 h-4" /> Locate Me (GPS)
                  </Button>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Sidebar toggle tab */}
          {!sidebarOpen && (
            <button
              aria-label="Open sidebar"
              onClick={() => setSidebarOpen(true)}
              className="absolute left-0 top-1/2 -translate-y-1/2 z-[1000] bg-background border border-border rounded-r-lg p-2 shadow-lg"
            >
              <Layers className="w-4 h-4 text-primary" />
            </button>
          )}

          {/* ── MAP ── */}
          <div className={`flex-1 transition-all ${sidebarOpen ? "ml-80" : "ml-0"}`}>
            <MapContainer
              center={DEFAULT_CENTER}
              zoom={DEFAULT_ZOOM}
              scrollWheelZoom
              className="h-full w-full"
              zoomControl={false}
            >
              <MapController center={mapCenter} zoom={mapZoom} />
              <MapClickHandler onMapMoved={handleBoundsChanged} />

              <TileLayer key={activeLayer} url={tileLayer.url} attribution={tileLayer.attribution} maxZoom={19} />

              {/* Hillshading overlay on topo */}
              {activeLayer === "topographic" && (
                <TileLayer
                  url="https://tiles.wmflabs.org/hillshading/{z}/{x}/{y}.png"
                  attribution=""
                  opacity={0.4}
                />
              )}

              {/* Dravik destination markers */}
              {mappable.map((dest) => (
                <Marker key={dest.id} position={[dest.latitude as number, dest.longitude as number]} icon={DEST_ICON}>
                  <Popup>
                    <div className="min-w-[180px] space-y-1">
                      <p className="font-semibold text-sm">{dest.title}</p>
                      <p className="text-xs text-gray-500">{dest.location}, {dest.country}</p>
                      <p className="text-xs">Difficulty: {dest.difficulty ?? "Unknown"}</p>
                      <p className="text-xs">Duration: {dest.duration ?? "—"}</p>
                      {dest.avg_rating ? (
                        <p className="text-xs flex items-center gap-1">
                          <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                          {dest.avg_rating.toFixed(1)}
                        </p>
                      ) : null}
                    </div>
                  </Popup>
                </Marker>
              ))}

              {/* Trails (polylines) */}
              {enabled.has("trails") && trails.map((trail) => (
                <Polyline
                  key={trail.id}
                  positions={trail.coords}
                  color={TRAIL_COLORS[trail.difficulty] ?? TRAIL_COLORS.unknown}
                  weight={3}
                  opacity={0.8}
                >
                  <Popup>
                    <p className="font-semibold text-sm">{trail.name}</p>
                    <p className="text-xs">Difficulty: {trail.difficulty}</p>
                    <p className="text-xs">Surface: {trail.surface}</p>
                  </Popup>
                </Polyline>
              ))}

              {/* Point overlays */}
              {(["shelters", "water", ...Object.keys(poisMap)] as PoiKey[]).map((catKey) => {
                const catConf = POI_CATEGORIES.find((c) => c.key === catKey);
                if (!catConf || !enabled.has(catKey)) return null;
                const points: PointFeature[] =
                  catKey === "shelters" ? shelters
                  : catKey === "water" ? water
                  : (poisMap[catKey] ?? []);
                return points.map((pt) => (
                  <CircleMarker
                    key={`${catKey}-${pt.id}`}
                    center={[pt.lat, pt.lon]}
                    radius={6}
                    color={catConf.color}
                    fillColor={catConf.color}
                    fillOpacity={0.8}
                    weight={1.5}
                  >
                    <Popup>
                      <p className="font-semibold text-sm">{pt.name}</p>
                      <p className="text-xs capitalize">{pt.category}</p>
                    </Popup>
                  </CircleMarker>
                ));
              })}

              {/* User GPS position */}
              {userPos && (
                <Marker position={userPos} icon={USER_ICON}>
                  <Popup><p className="text-sm font-semibold">Your Location</p></Popup>
                </Marker>
              )}
            </MapContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MapPage;


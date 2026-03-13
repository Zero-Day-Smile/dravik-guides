import { motion, AnimatePresence } from "framer-motion";
import { MapPin, Star, ArrowRight, X } from "lucide-react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useDestinations } from "@/hooks/useDestinations";

interface MapPin3D {
  id: string;
  x: number;
  y: number;
  title: string;
  country: string;
  slug: string;
  rating: number;
  image?: string;
}

// Approximate lat/lng to SVG position mapping
const geoToSvg = (lat: number, lng: number): { x: number; y: number } => {
  const x = ((lng + 180) / 360) * 100;
  const y = ((90 - lat) / 180) * 100;
  return { x, y };
};

const InteractiveMapSection = () => {
  const [activePin, setActivePin] = useState<string | null>(null);
  const [hoveredPin, setHoveredPin] = useState<string | null>(null);
  const navigate = useNavigate();
  const { data: destinations } = useDestinations({ featured: true, limit: 8 });

  const pins: MapPin3D[] = (destinations || [])
    .filter((d: any) => d.latitude && d.longitude)
    .map((d: any) => ({
      id: d.id,
      ...geoToSvg(d.latitude, d.longitude),
      title: d.title,
      country: d.country,
      slug: d.slug,
      rating: d.avg_rating || 0,
      image: d.image_url,
    }));

  const activeDestination = destinations?.find((d: any) => d.id === activePin);

  return (
    <section className="py-32 relative overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/3 left-1/4 w-[600px] h-[600px] rounded-full bg-accent/3 blur-[180px]" />
        <div className="absolute bottom-1/4 right-1/3 w-[400px] h-[400px] rounded-full bg-primary/3 blur-[140px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Discover
          </span>
          <h2 className="font-display font-bold text-4xl md:text-6xl mb-4">
            Explore the <span className="text-gradient-amber">world</span>
          </h2>
          <p className="text-muted-foreground font-body text-lg">
            Click a pin to discover adventures around the globe
          </p>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          className="relative max-w-5xl mx-auto"
        >
          {/* Simplified world map SVG */}
          <div className="relative aspect-[2/1] glass-card rounded-2xl p-6 overflow-hidden">
            {/* Grid lines */}
            <svg className="absolute inset-0 w-full h-full opacity-10" preserveAspectRatio="none">
              {Array.from({ length: 12 }).map((_, i) => (
                <line key={`v${i}`} x1={`${(i + 1) * 8}%`} y1="0" x2={`${(i + 1) * 8}%`} y2="100%" stroke="hsl(var(--foreground))" strokeWidth="0.5" />
              ))}
              {Array.from({ length: 6 }).map((_, i) => (
                <line key={`h${i}`} x1="0" y1={`${(i + 1) * 16}%`} x2="100%" y2={`${(i + 1) * 16}%`} stroke="hsl(var(--foreground))" strokeWidth="0.5" />
              ))}
            </svg>

            {/* Continent blobs (simplified) */}
            <svg className="absolute inset-0 w-full h-full" viewBox="0 0 100 50" preserveAspectRatio="none">
              {/* North America */}
              <ellipse cx="22" cy="16" rx="10" ry="8" fill="hsl(var(--muted))" opacity="0.3" />
              {/* South America */}
              <ellipse cx="28" cy="32" rx="5" ry="9" fill="hsl(var(--muted))" opacity="0.3" />
              {/* Europe */}
              <ellipse cx="52" cy="14" rx="6" ry="5" fill="hsl(var(--muted))" opacity="0.3" />
              {/* Africa */}
              <ellipse cx="54" cy="27" rx="6" ry="9" fill="hsl(var(--muted))" opacity="0.3" />
              {/* Asia */}
              <ellipse cx="72" cy="16" rx="12" ry="8" fill="hsl(var(--muted))" opacity="0.3" />
              {/* Australia */}
              <ellipse cx="82" cy="35" rx="5" ry="4" fill="hsl(var(--muted))" opacity="0.3" />
            </svg>

            {/* Animated connection lines between pins */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none" viewBox="0 0 100 100">
              {pins.slice(0, -1).map((pin, i) => {
                const next = pins[i + 1];
                if (!next) return null;
                return (
                  <motion.line
                    key={`line-${i}`}
                    x1={`${pin.x}%`}
                    y1={`${pin.y}%`}
                    x2={`${next.x}%`}
                    y2={`${next.y}%`}
                    stroke="hsl(var(--primary))"
                    strokeWidth="0.15"
                    strokeDasharray="2,2"
                    initial={{ pathLength: 0, opacity: 0 }}
                    whileInView={{ pathLength: 1, opacity: 0.3 }}
                    viewport={{ once: true }}
                    transition={{ delay: i * 0.3, duration: 1.5 }}
                  />
                );
              })}
            </svg>

            {/* Pins */}
            {pins.map((pin, i) => (
              <motion.button
                key={pin.id}
                initial={{ scale: 0, opacity: 0 }}
                whileInView={{ scale: 1, opacity: 1 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.15, type: "spring", stiffness: 300 }}
                whileHover={{ scale: 1.5 }}
                onClick={() => setActivePin(activePin === pin.id ? null : pin.id)}
                onMouseEnter={() => setHoveredPin(pin.id)}
                onMouseLeave={() => setHoveredPin(null)}
                className="absolute z-10 -translate-x-1/2 -translate-y-1/2 group"
                style={{ left: `${pin.x}%`, top: `${pin.y}%` }}
              >
                {/* Pulse ring */}
                <motion.div
                  animate={{ scale: [1, 2, 1], opacity: [0.5, 0, 0.5] }}
                  transition={{ repeat: Infinity, duration: 3, delay: i * 0.5 }}
                  className="absolute inset-0 rounded-full bg-primary/30"
                />
                {/* Pin dot */}
                <div className={`w-3 h-3 rounded-full transition-colors duration-300 shadow-lg ${
                  activePin === pin.id ? "bg-primary shadow-amber" : "bg-primary/70 group-hover:bg-primary"
                }`} />
                
                {/* Hover tooltip */}
                <AnimatePresence>
                  {hoveredPin === pin.id && activePin !== pin.id && (
                    <motion.div
                      initial={{ opacity: 0, y: 5, scale: 0.9 }}
                      animate={{ opacity: 1, y: 0, scale: 1 }}
                      exit={{ opacity: 0, y: 5, scale: 0.9 }}
                      className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 whitespace-nowrap glass-card rounded-lg px-3 py-1.5"
                    >
                      <p className="font-display font-semibold text-xs text-foreground">{pin.title}</p>
                      <p className="font-body text-[10px] text-muted-foreground">{pin.country}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.button>
            ))}

            {/* Active destination detail card */}
            <AnimatePresence>
              {activeDestination && (
                <motion.div
                  initial={{ opacity: 0, x: 20, scale: 0.95 }}
                  animate={{ opacity: 1, x: 0, scale: 1 }}
                  exit={{ opacity: 0, x: 20, scale: 0.95 }}
                  className="absolute right-4 top-4 bottom-4 w-64 glass-card rounded-xl overflow-hidden z-20 flex flex-col"
                >
                  <button
                    onClick={() => setActivePin(null)}
                    className="absolute top-2 right-2 z-30 w-6 h-6 rounded-full bg-muted flex items-center justify-center hover:bg-muted-foreground/20 transition-colors"
                  >
                    <X className="w-3 h-3 text-foreground" />
                  </button>
                  {activeDestination.image_url && (
                    <div className="h-32 overflow-hidden">
                      <img src={activeDestination.image_url} alt={activeDestination.title} className="w-full h-full object-cover" />
                    </div>
                  )}
                  <div className="p-4 flex-1 flex flex-col">
                    <div className="flex items-center gap-1 mb-1">
                      <Star className="w-3 h-3 text-primary fill-primary" />
                      <span className="font-body text-xs text-foreground">{activeDestination.avg_rating}</span>
                    </div>
                    <h3 className="font-display font-semibold text-foreground mb-1">{activeDestination.title}</h3>
                    <p className="font-body text-xs text-muted-foreground mb-1">{activeDestination.country}</p>
                    <p className="font-body text-xs text-muted-foreground mb-3 line-clamp-3">{activeDestination.description}</p>
                    <div className="flex gap-2 mb-4">
                      {activeDestination.difficulty && (
                        <span className="font-body text-[10px] bg-accent/30 text-accent-foreground px-2 py-0.5 rounded">{activeDestination.difficulty}</span>
                      )}
                      {activeDestination.duration && (
                        <span className="font-body text-[10px] bg-muted text-muted-foreground px-2 py-0.5 rounded">{activeDestination.duration}</span>
                      )}
                    </div>
                    <button
                      onClick={() => navigate(`/destination/${activeDestination.slug}`)}
                      className="mt-auto flex items-center gap-2 bg-gradient-amber text-primary-foreground font-display font-semibold text-sm px-4 py-2 rounded-lg hover:opacity-90 transition-opacity"
                    >
                      Explore <ArrowRight className="w-3 h-3" />
                    </button>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default InteractiveMapSection;

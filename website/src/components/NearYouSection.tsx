import { motion } from "framer-motion";
import { MapPin, Compass, ArrowRight } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useDestinations } from "@/hooks/useDestinations";

const NearYouSection = () => {
  const [cityName, setCityName] = useState("your area");
  const navigate = useNavigate();
  const { data: destinations, isLoading } = useDestinations({ limit: 6 });

  useEffect(() => {
    // Try to get user's city from browser geolocation + reverse geocode
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        async (pos) => {
          try {
            const res = await fetch(
              `https://nominatim.openstreetmap.org/reverse?lat=${pos.coords.latitude}&lon=${pos.coords.longitude}&format=json&accept-language=en`
            );
            const data = await res.json();
            const city = data.address?.city || data.address?.town || data.address?.state || "your area";
            setCityName(city);
          } catch {
            setCityName("your area");
          }
        },
        () => setCityName("your area"),
        { timeout: 5000 }
      );
    }
  }, []);

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute top-1/3 left-0 w-[400px] h-[400px] rounded-full bg-secondary/10 blur-[150px] pointer-events-none" />

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-12"
        >
          <div className="flex items-center gap-2 mb-4">
            <Compass className="w-5 h-5 text-primary animate-spin" style={{ animationDuration: '8s' }} />
            <span className="text-primary font-body text-sm tracking-widest uppercase">Near You</span>
          </div>
          <h2 className="font-display font-bold text-3xl md:text-5xl mb-3">
            Explore experiences near{" "}
            <span className="text-gradient-amber">{cityName}</span>
          </h2>
          <p className="font-body text-muted-foreground max-w-xl">
            Can't-miss picks near you — find adventures waiting just around the corner.
          </p>
        </motion.div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-2xl h-48 animate-pulse bg-muted" />
            ))}
          </div>
        ) : (
          <motion.div
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "-50px" }}
            variants={{ hidden: {}, show: { transition: { staggerChildren: 0.08 } } }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5"
          >
            {destinations?.map((dest: any) => (
              <motion.div
                key={dest.id}
                variants={{ hidden: { opacity: 0, x: -20 }, show: { opacity: 1, x: 0, transition: { duration: 0.5 } } }}
                onClick={() => navigate(`/destination/${dest.slug}`)}
                className="glass-card rounded-xl p-4 flex gap-4 cursor-pointer group hover:border-primary/30 transition-colors"
              >
                <div className="w-24 h-24 rounded-lg overflow-hidden flex-shrink-0">
                  {dest.image_url ? (
                    <img src={dest.image_url} alt={dest.title} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" loading="lazy" />
                  ) : (
                    <div className="w-full h-full bg-gradient-forest rounded-lg" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <h3 className="font-display font-semibold text-foreground mb-1 group-hover:text-primary transition-colors truncate">
                    {dest.title}
                  </h3>
                  <div className="flex items-center gap-1 mb-2">
                    <MapPin className="w-3 h-3 text-muted-foreground" />
                    <span className="font-body text-xs text-muted-foreground truncate">{dest.location}, {dest.country}</span>
                  </div>
                  <div className="flex gap-2">
                    <span className="font-body text-xs bg-accent/30 text-accent-foreground px-2 py-0.5 rounded">{dest.difficulty}</span>
                    <span className="font-body text-xs bg-muted text-muted-foreground px-2 py-0.5 rounded">{dest.duration}</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}

        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="mt-8 text-center"
        >
          <button
            onClick={() => navigate("/explore")}
            className="inline-flex items-center gap-2 font-body text-primary hover:text-foreground transition-colors font-medium"
          >
            Explore all destinations <ArrowRight className="w-4 h-4" />
          </button>
        </motion.div>
      </div>
    </section>
  );
};

export default NearYouSection;

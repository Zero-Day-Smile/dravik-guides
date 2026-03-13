import { motion } from "framer-motion";
import { Search, Mountain, Compass, Tent, Waves, MapPin } from "lucide-react";
import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useDestinations } from "@/hooks/useDestinations";

const tabs = [
  { icon: Search, label: "Search All" },
  { icon: Mountain, label: "Trails" },
  { icon: Compass, label: "Expeditions" },
  { icon: Tent, label: "Camping" },
  { icon: Waves, label: "Water" },
];

const ExploreSearchSection = () => {
  const [activeTab, setActiveTab] = useState(0);
  const [query, setQuery] = useState("");
  const [isFocused, setIsFocused] = useState(false);
  const navigate = useNavigate();
  const { data: suggestions } = useDestinations({ limit: 6 });

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    navigate(`/explore${query ? `?q=${encodeURIComponent(query)}` : ""}`);
  };

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[400px] rounded-full bg-primary/3 blur-[150px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <h2 className="font-display font-bold text-5xl md:text-7xl lg:text-8xl mb-4">
            Where will you <span className="text-gradient-amber">explore</span>?
          </h2>
          <p className="text-muted-foreground font-body text-lg">
            Search trails, plan expeditions, and discover the wild
          </p>
        </motion.div>

        {/* Tabs */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ delay: 0.1 }}
          className="flex items-center justify-center gap-2 mb-6"
        >
          {tabs.map((tab, i) => (
            <button
              key={tab.label}
              onClick={() => setActiveTab(i)}
              className={`flex items-center gap-2 px-4 py-2 rounded-full font-body text-sm transition-all duration-300 ${
                activeTab === i
                  ? "bg-primary text-primary-foreground shadow-amber"
                  : "text-muted-foreground hover:text-foreground hover:bg-muted"
              }`}
            >
              <tab.icon className="w-4 h-4" />
              <span className="hidden sm:inline">{tab.label}</span>
            </button>
          ))}
        </motion.div>

        {/* Search Bar */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          whileInView={{ opacity: 1, scale: 1 }}
          viewport={{ once: true }}
          transition={{ delay: 0.2 }}
          className="max-w-3xl mx-auto relative"
        >
          <form onSubmit={handleSearch}>
            <div
              className={`glass-card rounded-2xl p-2 flex items-center gap-3 transition-all duration-300 ${
                isFocused ? "border-primary/40 shadow-amber" : ""
              }`}
            >
              <div className="pl-4">
                <MapPin className="w-5 h-5 text-primary" />
              </div>
              <input
                type="text"
                placeholder="Search trails, mountains, destinations..."
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onFocus={() => setIsFocused(true)}
                onBlur={() => setTimeout(() => setIsFocused(false), 200)}
                className="flex-1 bg-transparent font-body text-foreground placeholder:text-muted-foreground outline-none py-3 text-lg"
              />
              <button type="submit" className="bg-gradient-amber text-primary-foreground font-display font-semibold px-6 py-3 rounded-xl hover:opacity-90 transition-opacity">
                Explore
              </button>
            </div>
          </form>

          {/* Suggestions dropdown */}
          {isFocused && suggestions && suggestions.length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="absolute top-full left-0 right-0 mt-2 glass-card rounded-xl overflow-hidden z-20"
            >
              <div className="p-2">
                <p className="px-3 py-2 font-body text-xs text-muted-foreground uppercase tracking-widest">
                  Popular Explorations
                </p>
                {suggestions.map((s: any) => (
                  <button
                    key={s.id}
                    onMouseDown={() => navigate(`/destination/${s.slug}`)}
                    className="w-full text-left px-3 py-2.5 rounded-lg font-body text-sm text-foreground hover:bg-muted transition-colors flex items-center gap-3"
                  >
                    <MapPin className="w-4 h-4 text-primary shrink-0" />
                    <span>{s.title}</span>
                    <span className="text-xs text-muted-foreground ml-auto">{s.country}</span>
                  </button>
                ))}
              </div>
            </motion.div>
          )}
        </motion.div>
      </div>
    </section>
  );
};

export default ExploreSearchSection;

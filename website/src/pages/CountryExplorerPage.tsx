import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Globe2, Mountain, Star, Route } from "lucide-react";
import Navbar from "@/components/Navbar";
import { Input } from "@/components/ui/input";
import { useDestinations } from "@/hooks/useDestinations";

type CountrySummary = {
  country: string;
  continent: string;
  destinationCount: number;
  averageRating: number;
  topDestinations: string[];
};

const CountryExplorerPage = () => {
  const [search, setSearch] = useState("");
  const [continentFilter, setContinentFilter] = useState("all");
  const { data: destinations, isLoading } = useDestinations({ limit: 500 });

  const summaries = useMemo(() => {
    const map = new Map<string, CountrySummary>();

    (destinations || []).forEach((dest) => {
      if (!dest.country) return;

      const key = dest.country;
      const existing = map.get(key);
      const rating = dest.avg_rating || 0;

      if (!existing) {
        map.set(key, {
          country: dest.country,
          continent: dest.continent || "Unknown",
          destinationCount: 1,
          averageRating: rating,
          topDestinations: [dest.title],
        });
        return;
      }

      const nextCount = existing.destinationCount + 1;
      const nextAvg = (existing.averageRating * existing.destinationCount + rating) / nextCount;

      existing.destinationCount = nextCount;
      existing.averageRating = nextAvg;
      if (existing.topDestinations.length < 3) {
        existing.topDestinations.push(dest.title);
      }
    });

    return Array.from(map.values()).sort((a, b) => b.destinationCount - a.destinationCount);
  }, [destinations]);

  const continents = useMemo(() => {
    const unique = new Set(summaries.map((s) => s.continent));
    return ["all", ...Array.from(unique).sort((a, b) => a.localeCompare(b))];
  }, [summaries]);

  const filtered = useMemo(() => {
    return summaries.filter((item) => {
      const matchesContinent = continentFilter === "all" || item.continent === continentFilter;
      const term = search.trim().toLowerCase();
      const matchesSearch = !term || item.country.toLowerCase().includes(term);
      return matchesContinent && matchesSearch;
    });
  }, [summaries, continentFilter, search]);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Country <span className="text-gradient-amber">Explorer</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Discover country-level adventure insights from your destination catalog.
          </p>

          <div className="glass-card rounded-2xl p-6 mb-8 grid grid-cols-1 md:grid-cols-2 gap-4">
            <Input
              placeholder="Search country..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-muted border-border font-body"
            />
            <select
              value={continentFilter}
              onChange={(e) => setContinentFilter(e.target.value)}
              className="h-10 rounded-md border border-border bg-muted px-3 font-body text-sm"
              aria-label="Continent filter"
            >
              {continents.map((c) => (
                <option key={c} value={c}>
                  {c === "all" ? "All continents" : c}
                </option>
              ))}
            </select>
          </div>

          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="glass-card rounded-2xl h-56 animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {filtered.map((item) => (
                <div key={item.country} className="glass-card rounded-2xl p-5">
                  <div className="flex items-center justify-between mb-4">
                    <p className="font-display font-semibold text-foreground text-xl">{item.country}</p>
                    <Globe2 className="w-5 h-5 text-primary" />
                  </div>

                  <p className="font-body text-xs text-muted-foreground uppercase tracking-wider mb-4">{item.continent}</p>

                  <div className="space-y-2 mb-4">
                    <p className="font-body text-sm text-foreground flex items-center gap-2">
                      <Route className="w-4 h-4 text-primary" /> {item.destinationCount} destinations
                    </p>
                    <p className="font-body text-sm text-foreground flex items-center gap-2">
                      <Star className="w-4 h-4 text-primary" /> {item.averageRating.toFixed(1)} avg rating
                    </p>
                    <p className="font-body text-sm text-foreground flex items-center gap-2">
                      <Mountain className="w-4 h-4 text-primary" /> Top picks: {item.topDestinations.join(", ")}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          )}

          {!isLoading && filtered.length === 0 && (
            <div className="glass-card rounded-2xl p-8 text-center">
              <p className="font-body text-muted-foreground">No countries match your filters.</p>
            </div>
          )}
        </motion.div>
      </div>
    </div>
  );
};

export default CountryExplorerPage;

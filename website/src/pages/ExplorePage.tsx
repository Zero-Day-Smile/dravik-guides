import { useState } from "react";
import { useDestinations, useCategories } from "@/hooks/useDestinations";
import { motion } from "framer-motion";
import IconicPlacesSection from "@/components/IconicPlacesSection";
import WildAwardsSection from "@/components/WildAwardsSection";
import NearYouSection from "@/components/NearYouSection";
import InterestPicksSection from "@/components/InterestPicksSection";
import { Search, MapPin, Star, Filter, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useNavigate } from "react-router-dom";
import Navbar from "@/components/Navbar";
import TiltCard from "@/components/TiltCard";

const ExplorePage = () => {
  const [search, setSearch] = useState("");
  const [selectedCategory, setSelectedCategory] = useState<string | undefined>();
  const [selectedDifficulty, setSelectedDifficulty] = useState<string | undefined>();
  const navigate = useNavigate();

  const { data: categories } = useCategories();
  const { data: destinations, isLoading } = useDestinations({
    search: search || undefined,
    category: selectedCategory,
    difficulty: selectedDifficulty,
  });

  const difficulties = ["Easy", "Moderate", "Challenging", "Advanced", "Expert"];

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Explore <span className="text-gradient-amber">destinations</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Discover trails, peaks, and adventures worldwide
          </p>

          {/* Search & Filters */}
          <div className="flex flex-col md:flex-row gap-4 mb-8">
            <div className="flex-1 relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
              <Input
                placeholder="Search destinations..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="pl-10 bg-muted border-border font-body h-12"
              />
            </div>
          </div>

          {/* Category pills */}
          <div className="flex flex-wrap gap-2 mb-4">
            <button
              onClick={() => setSelectedCategory(undefined)}
              className={`px-4 py-2 rounded-full font-body text-sm transition-all ${
                !selectedCategory ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:text-foreground"
              }`}
            >
              All
            </button>
            {categories?.map((cat: any) => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(selectedCategory === cat.id ? undefined : cat.id)}
                className={`px-4 py-2 rounded-full font-body text-sm transition-all ${
                  selectedCategory === cat.id ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground hover:text-foreground"
                }`}
              >
                {cat.name}
              </button>
            ))}
          </div>

          {/* Difficulty pills */}
          <div className="flex flex-wrap gap-2 mb-8">
            {difficulties.map((d) => (
              <button
                key={d}
                onClick={() => setSelectedDifficulty(selectedDifficulty === d ? undefined : d)}
                className={`px-3 py-1 rounded-full font-body text-xs transition-all ${
                  selectedDifficulty === d ? "bg-accent text-accent-foreground" : "bg-muted/50 text-muted-foreground hover:text-foreground"
                }`}
              >
                {d}
              </button>
            ))}
            {(selectedCategory || selectedDifficulty) && (
              <button
                onClick={() => { setSelectedCategory(undefined); setSelectedDifficulty(undefined); }}
                className="px-3 py-1 rounded-full font-body text-xs text-destructive hover:bg-destructive/10 flex items-center gap-1"
              >
                <X className="w-3 h-3" /> Clear filters
              </button>
            )}
          </div>

          {/* Results */}
          {isLoading ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="glass-card rounded-2xl h-80 animate-pulse" />
              ))}
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {destinations?.map((dest: any) => (
                <motion.div
                  key={dest.id}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  onClick={() => navigate(`/destination/${dest.slug}`)}
                >
                  <TiltCard className="glass-card rounded-2xl overflow-hidden cursor-pointer group h-full">
                    <div className="relative h-48 overflow-hidden bg-gradient-forest">
                      {dest.image_url && (
                        <img src={dest.image_url} alt={dest.title} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" loading="lazy" />
                      )}
                      {dest.is_trending && (
                        <span className="absolute top-3 left-3 bg-primary text-primary-foreground font-body text-xs font-semibold px-3 py-1 rounded-full">
                          Trending
                        </span>
                      )}
                      <div className="absolute top-3 right-3 glass-card rounded-full px-2 py-1 flex items-center gap-1">
                        <Star className="w-3 h-3 text-primary fill-primary" />
                        <span className="font-body text-xs text-foreground">{dest.avg_rating}</span>
                      </div>
                    </div>
                    <div className="p-5">
                      <span className="font-body text-xs text-primary uppercase tracking-wider">{dest.categories?.name}</span>
                      <h3 className="font-display font-semibold text-lg text-foreground mt-1 group-hover:text-primary transition-colors">
                        {dest.title}
                      </h3>
                      <div className="flex items-center gap-1 mt-2">
                        <MapPin className="w-3 h-3 text-muted-foreground" />
                        <span className="font-body text-sm text-muted-foreground">{dest.country}</span>
                      </div>
                      <div className="flex items-center gap-3 mt-3">
                        <span className="font-body text-xs bg-accent/30 text-accent-foreground px-2 py-1 rounded">{dest.difficulty}</span>
                        <span className="font-body text-xs text-muted-foreground">{dest.duration}</span>
                      </div>
                    </div>
                  </TiltCard>
                </motion.div>
              ))}
            </div>
          )}

          {destinations?.length === 0 && !isLoading && (
            <div className="text-center py-20">
              <p className="font-display text-2xl text-foreground mb-2">No destinations found</p>
              <p className="font-body text-muted-foreground">Try adjusting your filters or search terms</p>
            </div>
          )}
        </motion.div>
      </div>

      <IconicPlacesSection />
      <WildAwardsSection />
      <NearYouSection />
      <InterestPicksSection />
    </div>
  );
};

export default ExplorePage;

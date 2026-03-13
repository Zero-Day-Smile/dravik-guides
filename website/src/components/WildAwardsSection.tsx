import { motion } from "framer-motion";
import { Award, Star, MapPin, Trophy } from "lucide-react";
import { useDestinations } from "@/hooks/useDestinations";
import { useNavigate } from "react-router-dom";

const WildAwardsSection = () => {
  const { data: destinations, isLoading } = useDestinations({ limit: 8 });
  const navigate = useNavigate();

  // Pick top-rated as "award winners"
  const winners = destinations
    ?.sort((a: any, b: any) => (b.avg_rating || 0) - (a.avg_rating || 0))
    .slice(0, 4);

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute bottom-0 right-0 w-[500px] h-[500px] rounded-full bg-accent/5 blur-[180px] pointer-events-none" />

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-14"
        >
          <div className="inline-flex items-center gap-2 bg-primary/10 border border-primary/20 rounded-full px-5 py-2 mb-6">
            <Trophy className="w-4 h-4 text-primary" />
            <span className="font-body text-sm text-primary font-semibold">Wild Choice Awards 2026</span>
          </div>
          <h2 className="font-display font-bold text-3xl md:text-5xl mb-3">
            Best of the <span className="text-gradient-amber">Wild</span>
          </h2>
          <p className="font-body text-muted-foreground max-w-lg mx-auto">
            The most loved destinations by the Dravik community — voted by thousands of adventurers worldwide.
          </p>
        </motion.div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {Array.from({ length: 4 }).map((_, i) => (
              <div key={i} className="rounded-2xl h-96 animate-pulse bg-muted" />
            ))}
          </div>
        ) : (
          <motion.div
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "-50px" }}
            variants={{ hidden: {}, show: { transition: { staggerChildren: 0.12 } } }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6"
          >
            {winners?.map((dest: any, i: number) => (
              <motion.div
                key={dest.id}
                variants={{ hidden: { opacity: 0, scale: 0.95 }, show: { opacity: 1, scale: 1, transition: { duration: 0.5 } } }}
                onClick={() => navigate(`/destination/${dest.slug}`)}
                className="glass-card rounded-2xl overflow-hidden cursor-pointer group relative"
              >
                <div className="relative h-56 overflow-hidden">
                  {dest.image_url ? (
                    <img src={dest.image_url} alt={dest.title} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-700" loading="lazy" />
                  ) : (
                    <div className="w-full h-full bg-gradient-forest" />
                  )}
                  <div className="absolute inset-0 bg-gradient-to-t from-card to-transparent" />
                  <div className="absolute top-3 left-3 bg-background/80 backdrop-blur-sm rounded-full px-3 py-1 flex items-center gap-1.5 border border-primary/30">
                    <Award className="w-3.5 h-3.5 text-primary" />
                    <span className="font-body text-xs text-primary font-semibold">#{i + 1} Wild Pick</span>
                  </div>
                </div>
                <div className="p-5">
                  <h3 className="font-display font-semibold text-lg text-foreground mb-2 group-hover:text-primary transition-colors">
                    {dest.title}
                  </h3>
                  <div className="flex items-center gap-1 mb-2">
                    <MapPin className="w-3 h-3 text-muted-foreground" />
                    <span className="font-body text-sm text-muted-foreground">{dest.location}, {dest.country}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="flex">
                      {Array.from({ length: 5 }).map((_, si) => (
                        <Star key={si} className={`w-3.5 h-3.5 ${si < Math.round(dest.avg_rating || 0) ? 'text-primary fill-primary' : 'text-muted-foreground/30'}`} />
                      ))}
                    </div>
                    <span className="font-body text-xs text-muted-foreground">{dest.review_count?.toLocaleString()} reviews</span>
                  </div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>
    </section>
  );
};

export default WildAwardsSection;

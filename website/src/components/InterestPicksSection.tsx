import { motion } from "framer-motion";
import { Flame, Mountain, Waves, Tent, Bike, ArrowRight } from "lucide-react";
import { useCategories } from "@/hooks/useDestinations";
import { useNavigate } from "react-router-dom";

const iconMap: Record<string, React.ReactNode> = {
  trekking: <Mountain className="w-6 h-6" />,
  mountaineering: <Mountain className="w-6 h-6" />,
  camping: <Tent className="w-6 h-6" />,
  "water-sports": <Waves className="w-6 h-6" />,
  "rock-climbing": <Flame className="w-6 h-6" />,
  "mountain-biking": <Bike className="w-6 h-6" />,
};

const InterestPicksSection = () => {
  const { data: categories, isLoading } = useCategories();
  const navigate = useNavigate();

  return (
    <section className="py-24 relative">
      <div className="container mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-14"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Find Your Thing
          </span>
          <h2 className="font-display font-bold text-3xl md:text-5xl mb-3">
            Find things to do by <span className="text-gradient-amber">interest</span>
          </h2>
          <p className="font-body text-muted-foreground max-w-lg mx-auto">
            Whether you crave altitude or solitude, pick your passion and we'll show you the way.
          </p>
        </motion.div>

        {isLoading ? (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-2xl h-40 animate-pulse bg-muted" />
            ))}
          </div>
        ) : (
          <motion.div
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "-50px" }}
            variants={{ hidden: {}, show: { transition: { staggerChildren: 0.08 } } }}
            className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4"
          >
            {categories?.map((cat: any) => (
              <motion.div
                key={cat.id}
                variants={{ hidden: { opacity: 0, y: 20 }, show: { opacity: 1, y: 0, transition: { duration: 0.4 } } }}
                onClick={() => navigate("/explore")}
                className="glass-card rounded-2xl p-6 flex flex-col items-center gap-3 cursor-pointer group hover:border-primary/40 transition-all hover:bg-primary/5"
              >
                <div className="w-14 h-14 rounded-full bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300">
                  {iconMap[cat.slug] || <Mountain className="w-6 h-6" />}
                </div>
                <h3 className="font-display font-semibold text-sm text-foreground text-center">{cat.name}</h3>
                <span className="font-body text-xs text-muted-foreground">{cat.item_count?.toLocaleString()}+ trails</span>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>
    </section>
  );
};

export default InterestPicksSection;

import { motion, useScroll, useTransform } from "framer-motion";
import TiltCard from "@/components/TiltCard";
import { useCategories } from "@/hooks/useDestinations";
import { useNavigate } from "react-router-dom";
import { useRef } from "react";
import catTrekking from "@/assets/cat-trekking.jpg";
import catMountaineering from "@/assets/cat-mountaineering.jpg";
import catCamping from "@/assets/cat-camping.jpg";
import catWater from "@/assets/cat-water.jpg";
import catClimbing from "@/assets/cat-climbing.jpg";
import catCycling from "@/assets/cat-cycling.jpg";

const categoryImages: Record<string, string> = {
  trekking: catTrekking,
  mountaineering: catMountaineering,
  camping: catCamping,
  "water-sports": catWater,
  "rock-climbing": catClimbing,
  "mountain-biking": catCycling,
};

const CategoriesSection = () => {
  const { data: categories, isLoading } = useCategories();
  const navigate = useNavigate();
  const sectionRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"],
  });
  const xLeft = useTransform(scrollYProgress, [0, 1], [-50, 50]);
  const xRight = useTransform(scrollYProgress, [0, 1], [50, -50]);

  return (
    <section ref={sectionRef} className="py-24 relative overflow-hidden">
      <div className="container mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-12"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Explore by Interest
          </span>
          <h2 className="font-display font-bold text-3xl md:text-5xl">
            Whatever you're into, <span className="text-gradient-amber">we've got it</span>
          </h2>
        </motion.div>

        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {(isLoading ? Array.from({ length: 6 }) : categories)?.map((cat: any, i: number) =>
            isLoading ? (
              <div key={i} className="rounded-2xl h-64 animate-pulse bg-muted" />
            ) : (
              <motion.div
                key={cat.id}
                style={{ x: i % 2 === 0 ? xLeft : xRight }}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08, duration: 0.5 }}
              >
                <TiltCard
                  className="rounded-2xl overflow-hidden cursor-pointer group h-64 relative"
                >
                  <div onClick={() => navigate("/explore")} className="h-full">
                    <img
                      src={cat.image_url || categoryImages[cat.slug] || catTrekking}
                      alt={cat.name}
                      className="absolute inset-0 w-full h-full object-cover group-hover:scale-110 transition-transform duration-700"
                      loading="lazy"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-background via-background/20 to-transparent" />
                    {/* Reveal overlay on hover */}
                    <motion.div
                      initial={false}
                      className="absolute inset-0 bg-primary/0 group-hover:bg-primary/10 transition-colors duration-500"
                    />
                    <div className="absolute bottom-0 left-0 right-0 p-4">
                      <h3 className="font-display font-semibold text-foreground text-lg group-hover:text-primary transition-colors duration-300">{cat.name}</h3>
                      <motion.p
                        initial={{ opacity: 0, y: 10 }}
                        whileInView={{ opacity: 1, y: 0 }}
                        className="font-body text-xs text-primary"
                      >
                        {cat.item_count?.toLocaleString()}+ trails
                      </motion.p>
                    </div>
                  </div>
                </TiltCard>
              </motion.div>
            )
          )}
        </div>
      </div>
    </section>
  );
};

export default CategoriesSection;

import { motion } from "framer-motion";
import { Star, MapPin, ArrowRight, Crown } from "lucide-react";
import { useDestinations } from "@/hooks/useDestinations";
import { useNavigate } from "react-router-dom";

const IconicPlacesSection = () => {
  const { data: destinations, isLoading } = useDestinations({ featured: true, limit: 6 });
  const navigate = useNavigate();

  return (
    <section className="py-24 relative overflow-hidden">
      <div className="absolute top-0 left-0 w-[600px] h-[600px] rounded-full bg-primary/5 blur-[200px] pointer-events-none" />

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mb-12"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Bucket List
          </span>
          <h2 className="font-display font-bold text-3xl md:text-5xl mb-3">
            Iconic places you <span className="text-gradient-amber">need to see</span>
          </h2>
          <p className="font-body text-muted-foreground max-w-xl">
            The world's most breathtaking trails and wild destinations, handpicked for true adventurers.
          </p>
        </motion.div>

        {isLoading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="rounded-2xl h-72 animate-pulse bg-muted" />
            ))}
          </div>
        ) : (
          <motion.div
            initial="hidden"
            whileInView="show"
            viewport={{ once: true, margin: "-50px" }}
            variants={{ hidden: {}, show: { transition: { staggerChildren: 0.1 } } }}
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"
          >
            {destinations?.map((dest: any, i: number) => (
              <motion.div
                key={dest.id}
                variants={{ hidden: { opacity: 0, y: 30 }, show: { opacity: 1, y: 0, transition: { duration: 0.5 } } }}
                onClick={() => navigate(`/destination/${dest.slug}`)}
                className={`relative rounded-2xl overflow-hidden cursor-pointer group ${i === 0 ? 'md:col-span-2 md:row-span-2 h-[28rem]' : 'h-72'}`}
              >
                {dest.image_url ? (
                  <img src={dest.image_url} alt={dest.title} className="absolute inset-0 w-full h-full object-cover group-hover:scale-105 transition-transform duration-700" loading="lazy" />
                ) : (
                  <div className="absolute inset-0 bg-gradient-forest" />
                )}
                <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
                <div className="absolute top-4 left-4">
                  <span className="bg-primary/90 text-primary-foreground font-body text-xs font-semibold px-3 py-1.5 rounded-full flex items-center gap-1.5">
                    <Crown className="w-3 h-3" /> Must Visit
                  </span>
                </div>
                <div className="absolute bottom-0 left-0 right-0 p-6">
                  <h3 className="font-display font-bold text-xl md:text-2xl text-foreground mb-1 group-hover:text-primary transition-colors">
                    {dest.title}
                  </h3>
                  <div className="flex items-center gap-3 mb-2">
                    <span className="flex items-center gap-1 font-body text-sm text-muted-foreground">
                      <MapPin className="w-3.5 h-3.5" /> {dest.country}
                    </span>
                    <span className="flex items-center gap-1 font-body text-sm text-primary">
                      <Star className="w-3.5 h-3.5 fill-primary" /> {dest.avg_rating}
                    </span>
                  </div>
                  <p className="font-body text-sm text-muted-foreground line-clamp-2">{dest.description}</p>
                </div>
              </motion.div>
            ))}
          </motion.div>
        )}
      </div>
    </section>
  );
};

export default IconicPlacesSection;

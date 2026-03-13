import { motion, useScroll, useTransform } from "framer-motion";
import { Map, Compass, CloudSun, Backpack, BookOpen, Shield, Users, Route, Globe } from "lucide-react";
import TiltCard from "@/components/TiltCard";
import { useRef, useState } from "react";

const features = [
  {
    icon: Map,
    title: "Offline Maps",
    description: "Download regions and navigate without signal. Full topographic detail when you need it most.",
    color: "from-primary/20 to-accent/10",
  },
  {
    icon: Compass,
    title: "AR Trail Scanner",
    description: "Point your camera at the trail ahead. AR overlays show waypoints, elevation, and hazards in real-time.",
    color: "from-accent/20 to-primary/10",
  },
  {
    icon: CloudSun,
    title: "Weather Intelligence",
    description: "Hyper-local forecasts with storm alerts. Cached offline so you're never caught off guard.",
    color: "from-secondary/30 to-primary/10",
  },
  {
    icon: Backpack,
    title: "Gear Management",
    description: "Track your equipment, get weight estimates, and receive smart packing suggestions per trip.",
    color: "from-primary/15 to-secondary/15",
  },
  {
    icon: BookOpen,
    title: "50+ Trail Guides",
    description: "Comprehensive guides covering terrain types, survival tips, and local flora & fauna.",
    color: "from-accent/15 to-primary/15",
  },
  {
    icon: Shield,
    title: "Safety & Emergency",
    description: "One-tap SOS with GPS coordinates. Emergency contacts and safety protocols always accessible.",
    color: "from-destructive/10 to-primary/10",
  },
  {
    icon: Users,
    title: "Group Sync",
    description: "Real-time location sharing with your crew. Stay connected even in remote areas.",
    color: "from-secondary/20 to-accent/10",
  },
  {
    icon: Route,
    title: "Trip Planner",
    description: "AI-powered safety analysis, route optimization, and itinerary management for every expedition.",
    color: "from-primary/20 to-secondary/10",
  },
  {
    icon: Globe,
    title: "Country Explorer",
    description: "Discover outdoor destinations worldwide with terrain data, regulations, and local insights.",
    color: "from-accent/20 to-secondary/10",
  },
];

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.08 },
  },
};

const FeatureCard = ({ feature, index }: { feature: typeof features[0]; index: number }) => {
  const [isFlipped, setIsFlipped] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay: index * 0.08, duration: 0.5 }}
      className="perspective-[1000px] h-64"
      onMouseEnter={() => setIsFlipped(true)}
      onMouseLeave={() => setIsFlipped(false)}
    >
      <motion.div
        animate={{ rotateY: isFlipped ? 180 : 0 }}
        transition={{ duration: 0.6, type: "spring", stiffness: 100 }}
        className="relative w-full h-full"
        style={{ transformStyle: "preserve-3d" }}
      >
        {/* Front */}
        <div className="absolute inset-0 glass-card rounded-xl p-8 flex flex-col backface-hidden" style={{ backfaceVisibility: "hidden" }}>
          <div className={`w-12 h-12 rounded-lg bg-gradient-to-br ${feature.color} flex items-center justify-center mb-5`}>
            <feature.icon className="w-6 h-6 text-primary" />
          </div>
          <h3 className="font-display font-semibold text-xl text-foreground mb-3">
            {feature.title}
          </h3>
          <p className="font-body text-muted-foreground leading-relaxed text-sm">
            {feature.description.split('.')[0]}.
          </p>
        </div>

        {/* Back */}
        <div
          className="absolute inset-0 glass-card rounded-xl p-8 flex flex-col items-center justify-center text-center border-primary/30"
          style={{ backfaceVisibility: "hidden", transform: "rotateY(180deg)" }}
        >
          <div className={`w-16 h-16 rounded-2xl bg-gradient-to-br ${feature.color} flex items-center justify-center mb-4`}>
            <feature.icon className="w-8 h-8 text-primary" />
          </div>
          <h3 className="font-display font-semibold text-lg text-primary mb-2">
            {feature.title}
          </h3>
          <p className="font-body text-foreground text-sm leading-relaxed">
            {feature.description}
          </p>
        </div>
      </motion.div>
    </motion.div>
  );
};

const FeaturesSection = () => {
  const sectionRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start end", "end start"],
  });
  const bgY = useTransform(scrollYProgress, [0, 1], [100, -100]);

  return (
    <section ref={sectionRef} className="py-32 relative overflow-hidden" id="features">
      {/* Parallax ambient glow */}
      <motion.div style={{ y: bgY }} className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/2 left-1/4 -translate-y-1/2 w-[500px] h-[500px] rounded-full bg-accent/5 blur-[150px]" />
        <div className="absolute top-1/3 right-1/4 w-[400px] h-[400px] rounded-full bg-primary/5 blur-[120px]" />
      </motion.div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Features
          </span>
          <h2 className="font-display font-bold text-4xl md:text-5xl lg:text-6xl mb-6">
            Built for the <span className="text-gradient-amber">wild</span>
          </h2>
          <p className="text-muted-foreground font-body text-lg max-w-xl mx-auto">
            Hover over a card to flip it and discover more details
          </p>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features.map((feature, i) => (
            <FeatureCard key={feature.title} feature={feature} index={i} />
          ))}
        </div>
      </div>
    </section>
  );
};

export default FeaturesSection;

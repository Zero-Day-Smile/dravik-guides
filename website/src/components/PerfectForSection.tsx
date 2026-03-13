import { motion } from "framer-motion";
import { User, Users, Flag } from "lucide-react";
import TiltCard from "@/components/TiltCard";

const personas = [
  {
    icon: User,
    title: "Solo Trekkers",
    description: "Navigate challenging trails with confidence using offline maps and AR guidance",
    gradient: "from-primary/20 to-accent/10",
  },
  {
    icon: Flag,
    title: "Tour Operators",
    description: "Manage group expeditions with real-time collaboration and safety monitoring",
    gradient: "from-accent/20 to-primary/10",
  },
  {
    icon: Users,
    title: "Adventure Clubs",
    description: "Organize club activities with comprehensive trip planning and shared guides",
    gradient: "from-secondary/30 to-primary/10",
  },
];

const badges = [
  { label: "∞", sub: "Offline Availability" },
  { label: "AR", sub: "Trail Technology" },
  { label: "AI", sub: "Safety Analysis" },
  { label: "100%", sub: "Privacy Focused" },
];

const container = {
  hidden: {},
  show: { transition: { staggerChildren: 0.12 } },
};

const item = {
  hidden: { opacity: 0, y: 24 },
  show: { opacity: 1, y: 0, transition: { duration: 0.5 } },
};

const PerfectForSection = () => {
  return (
    <section className="py-32 relative overflow-hidden">
      {/* Ambient effects */}
      <div className="absolute bottom-0 left-0 right-0 h-px bg-gradient-to-r from-transparent via-primary/20 to-transparent" />
      <div className="absolute top-1/2 right-0 -translate-y-1/2 w-[400px] h-[400px] rounded-full bg-primary/3 blur-[120px] pointer-events-none" />

      <div className="container mx-auto px-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-20"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Perfect For
          </span>
          <h2 className="font-display font-bold text-4xl md:text-5xl lg:text-6xl mb-6">
            Built for <span className="text-gradient-amber">every</span> adventurer
          </h2>
          <p className="text-muted-foreground font-body text-lg max-w-xl mx-auto">
            Dravik serves adventurers of all types and skill levels
          </p>
        </motion.div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: "-100px" }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-20"
        >
          {personas.map((persona) => (
            <motion.div key={persona.title} variants={item}>
              <TiltCard className="glass-card rounded-xl p-10 text-center h-full hover:border-primary/30 transition-all duration-300 cursor-pointer group">
                <div className={`w-20 h-20 rounded-2xl bg-gradient-to-br ${persona.gradient} flex items-center justify-center mx-auto mb-6 group-hover:scale-110 group-hover:rotate-3 transition-all duration-300`}>
                  <persona.icon className="w-8 h-8 text-primary" />
                </div>
                <h3 className="font-display font-semibold text-2xl text-foreground mb-3 group-hover:text-primary transition-colors">
                  {persona.title}
                </h3>
                <p className="font-body text-muted-foreground leading-relaxed">
                  {persona.description}
                </p>
              </TiltCard>
            </motion.div>
          ))}
        </motion.div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true }}
          className="grid grid-cols-2 md:grid-cols-4 gap-6"
        >
          {badges.map((badge) => (
            <motion.div key={badge.sub} variants={item}>
              <motion.div
                whileHover={{ scale: 1.05, y: -4 }}
                transition={{ type: "spring", stiffness: 300 }}
                className="glass-card rounded-xl p-6 text-center cursor-default hover:border-primary/20 transition-colors"
              >
                <span className="font-display font-bold text-3xl text-gradient-amber block mb-2">
                  {badge.label}
                </span>
                <span className="font-body text-sm text-muted-foreground">
                  {badge.sub}
                </span>
              </motion.div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
};

export default PerfectForSection;

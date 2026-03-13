import { motion } from "framer-motion";
import { Star, Quote } from "lucide-react";
import { Smartphone, Scan, MapPin, CloudSun, Shield } from "lucide-react";

const testimonials = [
  {
    name: "Sarah Mitchell",
    role: "Solo Trekker • Colorado",
    text: "Dravik saved my life. Literally. The offline SOS feature got mountain rescue to me in under 2 hours when I broke my ankle on a remote trail.",
    rating: 5,
    avatar: "SM",
  },
  {
    name: "Marco Rossi",
    role: "Tour Operator • Dolomites",
    text: "Managing 20+ person expedition groups used to be chaos. Group Sync changed everything — real-time positions, safety alerts, and trip planning in one place.",
    rating: 5,
    avatar: "MR",
  },
  {
    name: "Yuki Tanaka",
    role: "Adventure Photographer • Japan",
    text: "The AR trail scanner is absolutely mind-blowing. It's like having a local guide overlaid on reality. I've discovered hidden trails I never would have found.",
    rating: 5,
    avatar: "YT",
  },
];

const appFeatures = [
  { icon: Scan, label: "AR Scanner", desc: "See trails in augmented reality" },
  { icon: MapPin, label: "Offline Maps", desc: "Navigate without signal" },
  { icon: CloudSun, label: "Weather AI", desc: "Hyper-local forecasts" },
  { icon: Shield, label: "SOS Alert", desc: "One-tap emergency help" },
];

const AppShowcaseSection = () => {
  return (
    <section className="py-32 relative overflow-hidden">
      {/* Background effects */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-0 w-[500px] h-[500px] rounded-full bg-primary/3 blur-[150px]" />
        <div className="absolute bottom-1/4 right-0 w-[400px] h-[400px] rounded-full bg-accent/5 blur-[120px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        {/* App Showcase */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center mb-32">
          <motion.div
            initial={{ opacity: 0, x: -40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
          >
            <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
              The App
            </span>
            <h2 className="font-display font-bold text-4xl md:text-5xl mb-6">
              Your pocket <span className="text-gradient-amber">expedition HQ</span>
            </h2>
            <p className="font-body text-muted-foreground text-lg mb-10 leading-relaxed">
              Every feature you need in the wild — AR navigation, offline intelligence, 
              group tracking, and emergency tools. All working without a cell signal.
            </p>

            <div className="grid grid-cols-2 gap-4">
              {appFeatures.map((f, i) => (
                <motion.div
                  key={f.label}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                  whileHover={{ scale: 1.05, x: 5 }}
                  className="glass-card rounded-xl p-4 flex items-center gap-3 cursor-default group"
                >
                  <div className="w-10 h-10 rounded-lg bg-gradient-forest flex items-center justify-center shrink-0 group-hover:scale-110 transition-transform">
                    <f.icon className="w-5 h-5 text-primary" />
                  </div>
                  <div>
                    <h4 className="font-display font-semibold text-sm text-foreground">{f.label}</h4>
                    <p className="font-body text-xs text-muted-foreground">{f.desc}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.div>

          {/* Phone Mockup */}
          <motion.div
            initial={{ opacity: 0, x: 40 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            className="flex justify-center"
          >
            <motion.div
              whileHover={{ rotateY: 5, rotateX: -5 }}
              transition={{ type: "spring", stiffness: 100 }}
              style={{ perspective: 1000, transformStyle: "preserve-3d" }}
              className="relative"
            >
              {/* Phone frame */}
              <div className="w-[280px] h-[560px] rounded-[3rem] border-[6px] border-muted bg-card shadow-2xl shadow-background/50 overflow-hidden relative">
                {/* Status bar */}
                <div className="h-12 bg-card flex items-center justify-center">
                  <div className="w-20 h-5 rounded-full bg-muted" />
                </div>
                {/* App content mockup */}
                <div className="p-4 space-y-4">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-display font-bold text-foreground text-sm">Good morning</p>
                      <p className="font-body text-xs text-muted-foreground">Ready to explore?</p>
                    </div>
                    <div className="w-8 h-8 rounded-full bg-gradient-amber" />
                  </div>
                  {/* Search */}
                  <div className="rounded-xl bg-muted p-3 flex items-center gap-2">
                    <MapPin className="w-4 h-4 text-primary" />
                    <span className="font-body text-xs text-muted-foreground">Search trails...</span>
                  </div>
                  {/* AR Scanner card */}
                  <div className="rounded-xl bg-gradient-forest p-4">
                    <div className="flex items-center gap-2 mb-2">
                      <Scan className="w-4 h-4 text-primary" />
                      <span className="font-display font-semibold text-xs text-foreground">AR Scanner</span>
                    </div>
                    <p className="font-body text-[10px] text-muted-foreground">Tap to scan your trail</p>
                    <div className="mt-3 h-24 rounded-lg bg-background/30 flex items-center justify-center">
                      <Smartphone className="w-8 h-8 text-primary/50" />
                    </div>
                  </div>
                  {/* Weather widget */}
                  <div className="rounded-xl glass-card p-3 flex items-center justify-between">
                    <div>
                      <p className="font-body text-xs text-foreground">Partly Cloudy</p>
                      <p className="font-body text-[10px] text-muted-foreground">Wind: 12 km/h</p>
                    </div>
                    <div className="flex items-center gap-1">
                      <CloudSun className="w-5 h-5 text-primary" />
                      <span className="font-display font-bold text-foreground">18°</span>
                    </div>
                  </div>
                  {/* Quick actions */}
                  <div className="flex gap-2">
                    {["Maps", "Gear", "SOS"].map((a) => (
                      <div key={a} className="flex-1 rounded-lg bg-muted p-2 text-center">
                        <span className="font-body text-[10px] text-muted-foreground">{a}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
              {/* Glow behind phone */}
              <div className="absolute -inset-8 rounded-[4rem] bg-primary/5 blur-3xl -z-10" />
            </motion.div>
          </motion.div>
        </div>

        {/* Testimonials */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-12"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Trusted by Explorers
          </span>
          <h2 className="font-display font-bold text-3xl md:text-5xl">
            Stories from the <span className="text-gradient-amber">trail</span>
          </h2>
        </motion.div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {testimonials.map((t, i) => (
            <motion.div
              key={t.name}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              whileHover={{ y: -5 }}
              className="glass-card rounded-xl p-6 relative group cursor-default"
            >
              <Quote className="w-8 h-8 text-primary/20 absolute top-4 right-4 group-hover:text-primary/40 transition-colors" />
              <div className="flex items-center gap-3 mb-4">
                <div className="w-10 h-10 rounded-full bg-gradient-amber flex items-center justify-center font-display font-bold text-sm text-primary-foreground">
                  {t.avatar}
                </div>
                <div>
                  <p className="font-display font-semibold text-sm text-foreground">{t.name}</p>
                  <p className="font-body text-xs text-muted-foreground">{t.role}</p>
                </div>
              </div>
              <div className="flex gap-0.5 mb-3">
                {Array.from({ length: t.rating }).map((_, j) => (
                  <Star key={j} className="w-3.5 h-3.5 text-primary fill-primary" />
                ))}
              </div>
              <p className="font-body text-sm text-muted-foreground leading-relaxed">
                "{t.text}"
              </p>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default AppShowcaseSection;

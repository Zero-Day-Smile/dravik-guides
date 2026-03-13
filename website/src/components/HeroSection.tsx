import { motion, useScroll, useTransform } from "framer-motion";
import { MapPin, Download } from "lucide-react";
import { Button } from "@/components/ui/button";
import MountainScene from "@/components/MountainScene";
import { useRef } from "react";

const HeroSection = () => {
  const sectionRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start start", "end start"],
  });
  const y = useTransform(scrollYProgress, [0, 1], [0, 200]);
  const opacity = useTransform(scrollYProgress, [0, 0.8], [1, 0]);
  const scale = useTransform(scrollYProgress, [0, 1], [1, 0.9]);

  return (
    <section ref={sectionRef} className="relative min-h-screen flex items-center justify-center overflow-hidden">
      {/* 3D Background */}
      <MountainScene />

      {/* Gradient overlays */}
      <div className="absolute inset-0 z-[1] bg-gradient-to-t from-background via-background/60 to-transparent" />
      <div className="absolute inset-0 z-[1] bg-gradient-to-b from-background/80 via-transparent to-transparent" />

      {/* Content */}
      <motion.div style={{ y, opacity, scale }} className="relative z-10 container mx-auto px-6 text-center">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.8, ease: "easeOut" }}
          className="max-w-4xl mx-auto"
        >
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2, duration: 0.6 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass-card mb-8"
          >
            <MapPin className="w-4 h-4 text-primary" />
            <span className="text-sm font-body text-muted-foreground">Your expedition companion</span>
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3, duration: 1, ease: "easeOut" }}
            className="font-display font-900 text-7xl md:text-9xl lg:text-[12rem] tracking-tighter leading-[0.85] mb-6"
          >
            <span className="text-foreground">DRA</span>
            <span className="text-gradient-amber">VIK</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.6, duration: 0.8 }}
            className="font-body text-lg md:text-xl text-mist max-w-2xl mx-auto mb-10 leading-relaxed"
          >
            Navigate the unknown with confidence. Offline maps, AR trail scanning,
            real-time weather, and group sync — all in one rugged platform.
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8, duration: 0.6 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4"
          >
            <Button
              size="lg"
              className="group bg-gradient-amber text-primary-foreground font-display font-semibold text-lg px-8 py-6 shadow-amber hover:opacity-90 transition-all hover:scale-105 active:scale-95"
            >
              <Download className="w-5 h-5 mr-2 group-hover:animate-bounce" />
              Start Exploring
            </Button>
            <Button
              variant="outline"
              size="lg"
              className="border-border text-foreground font-display font-medium text-lg px-8 py-6 hover:bg-muted transition-all hover:scale-105 active:scale-95"
            >
              View Features
            </Button>
          </motion.div>
        </motion.div>

        {/* Scroll indicator */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 1.5 }}
          className="absolute bottom-10 left-1/2 -translate-x-1/2"
        >
          <motion.div
            animate={{ y: [0, 8, 0] }}
            transition={{ repeat: Infinity, duration: 2 }}
            className="w-6 h-10 rounded-full border-2 border-muted-foreground/30 flex items-start justify-center p-1.5"
          >
            <div className="w-1.5 h-1.5 rounded-full bg-primary" />
          </motion.div>
        </motion.div>
      </motion.div>
    </section>
  );
};

export default HeroSection;

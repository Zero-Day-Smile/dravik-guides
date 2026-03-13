import { motion, useMotionValue, useSpring, useInView } from "framer-motion";
import { useEffect, useRef, useState } from "react";

const stats = [
  { target: 50, suffix: "+", label: "Trail Guides", duration: 2000 },
  { target: 100, suffix: "%", label: "Offline Ready", duration: 2500 },
  { target: 24, suffix: "/7", label: "Weather Alerts", duration: 1800 },
  { target: 360, suffix: "°", label: "AR Scanning", duration: 3000 },
];

const useCountUp = (target: number, duration: number, shouldStart: boolean) => {
  const [count, setCount] = useState(0);
  
  useEffect(() => {
    if (!shouldStart) return;
    let start = 0;
    const startTime = performance.now();
    
    const animate = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      // Ease out cubic
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = Math.round(eased * target);
      
      setCount(current);
      if (progress < 1) requestAnimationFrame(animate);
    };
    
    requestAnimationFrame(animate);
  }, [target, duration, shouldStart]);
  
  return count;
};

const AnimatedCounter = ({ target, suffix, label, duration, delay }: { target: number; suffix: string; label: string; duration: number; delay: number }) => {
  const ref = useRef<HTMLDivElement>(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });
  const [shouldStart, setShouldStart] = useState(false);
  const count = useCountUp(target, duration, shouldStart);

  useEffect(() => {
    if (isInView) {
      const timer = setTimeout(() => setShouldStart(true), delay);
      return () => clearTimeout(timer);
    }
  }, [isInView, delay]);

  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, scale: 0.5, rotateX: 45 }}
      whileInView={{ opacity: 1, scale: 1, rotateX: 0 }}
      viewport={{ once: true }}
      whileHover={{ scale: 1.15, y: -8 }}
      transition={{ type: "spring", stiffness: 200, damping: 15 }}
      className="text-center cursor-default group relative"
    >
      {/* Glow ring on hover */}
      <div className="absolute inset-0 rounded-2xl bg-primary/0 group-hover:bg-primary/5 blur-xl transition-all duration-500" />
      <div className="relative">
        <div className="font-display font-bold text-5xl md:text-7xl text-gradient-amber mb-2 group-hover:drop-shadow-[0_0_30px_hsla(38,65%,58%,0.6)] transition-all duration-500 tabular-nums">
          {count}{suffix}
        </div>
        <div className="font-body text-muted-foreground text-sm tracking-wide uppercase group-hover:text-foreground transition-colors duration-300">
          {label}
        </div>
        {/* Animated underline */}
        <motion.div 
          className="h-0.5 bg-gradient-amber mx-auto mt-3 rounded-full"
          initial={{ width: 0 }}
          whileInView={{ width: "60%" }}
          viewport={{ once: true }}
          transition={{ delay: delay / 1000 + 0.5, duration: 0.8 }}
        />
      </div>
    </motion.div>
  );
};

const MouseTracker = () => {
  const ref = useRef<HTMLDivElement>(null);
  const mouseX = useMotionValue(0);
  const mouseY = useMotionValue(0);
  const x = useSpring(mouseX, { stiffness: 50, damping: 20 });
  const y = useSpring(mouseY, { stiffness: 50, damping: 20 });

  useEffect(() => {
    const handleMouse = (e: MouseEvent) => {
      if (!ref.current) return;
      const rect = ref.current.getBoundingClientRect();
      mouseX.set(e.clientX - rect.left - 150);
      mouseY.set(e.clientY - rect.top - 150);
    };
    const el = ref.current;
    el?.addEventListener("mousemove", handleMouse);
    return () => el?.removeEventListener("mousemove", handleMouse);
  }, [mouseX, mouseY]);

  return (
    <div ref={ref} className="absolute inset-0 overflow-hidden pointer-events-none">
      <motion.div
        style={{ x, y }}
        className="w-[300px] h-[300px] rounded-full bg-primary/5 blur-[80px] pointer-events-none"
      />
    </div>
  );
};

const StatsSection = () => {
  return (
    <section className="py-24 border-y border-border relative overflow-hidden">
      <MouseTracker />
      <div className="container mx-auto px-6 relative z-10">
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          {stats.map((stat, i) => (
            <AnimatedCounter
              key={stat.label}
              target={stat.target}
              suffix={stat.suffix}
              label={stat.label}
              duration={stat.duration}
              delay={i * 200}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

export default StatsSection;

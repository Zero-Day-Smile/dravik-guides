import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { useRef, useState, useEffect } from "react";
import { Compass, Wind, Thermometer, Droplets, Mountain } from "lucide-react";

const wildFacts = [
  { direction: "N", text: "The Himalayas grow ~1cm taller every year", icon: Mountain },
  { direction: "E", text: "90% of volcanic activity occurs in the Ring of Fire", icon: Wind },
  { direction: "S", text: "Patagonian winds can reach 150 km/h", icon: Droplets },
  { direction: "W", text: "The Pacific Crest Trail is 4,265 km long", icon: Thermometer },
];

const WildCompassSection = () => {
  const sectionRef = useRef<HTMLDivElement>(null);
  const [mouseAngle, setMouseAngle] = useState(0);
  const [activeFact, setActiveFact] = useState(0);
  const springAngle = useSpring(mouseAngle, { stiffness: 60, damping: 20 });

  useEffect(() => {
    const handleMouse = (e: MouseEvent) => {
      if (!sectionRef.current) return;
      const rect = sectionRef.current.getBoundingClientRect();
      const centerX = rect.left + rect.width / 2;
      const centerY = rect.top + rect.height / 2;
      const angle = Math.atan2(e.clientY - centerY, e.clientX - centerX) * (180 / Math.PI);
      setMouseAngle(angle + 90);
      
      // Determine which quadrant
      const normalizedAngle = ((angle + 180) % 360);
      if (normalizedAngle < 90) setActiveFact(0);
      else if (normalizedAngle < 180) setActiveFact(1);
      else if (normalizedAngle < 270) setActiveFact(2);
      else setActiveFact(3);
    };
    
    window.addEventListener("mousemove", handleMouse);
    return () => window.removeEventListener("mousemove", handleMouse);
  }, []);

  return (
    <section ref={sectionRef} className="py-32 relative overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] rounded-full bg-primary/2 blur-[200px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Wild Facts
          </span>
          <h2 className="font-display font-bold text-4xl md:text-6xl mb-4">
            Move your cursor, <span className="text-gradient-amber">explore</span> the wild
          </h2>
          <p className="text-muted-foreground font-body text-lg">
            Your mouse controls the compass — discover facts in every direction
          </p>
        </motion.div>

        <div className="flex flex-col lg:flex-row items-center gap-16 justify-center">
          {/* Interactive Compass */}
          <motion.div
            initial={{ opacity: 0, scale: 0.8 }}
            whileInView={{ opacity: 1, scale: 1 }}
            viewport={{ once: true }}
            className="relative w-72 h-72 md:w-96 md:h-96"
          >
            {/* Outer ring */}
            <div className="absolute inset-0 rounded-full border-2 border-border" />
            <div className="absolute inset-3 rounded-full border border-border/50" />
            
            {/* Direction markers */}
            {["N", "E", "S", "W"].map((dir, i) => (
              <div
                key={dir}
                className={`absolute font-display font-bold text-lg transition-colors duration-300 ${
                  activeFact === i ? "text-primary" : "text-muted-foreground"
                }`}
                style={{
                  top: i === 0 ? "4%" : i === 2 ? "auto" : "50%",
                  bottom: i === 2 ? "4%" : "auto",
                  left: i === 3 ? "4%" : i === 1 ? "auto" : "50%",
                  right: i === 1 ? "4%" : "auto",
                  transform: (i === 0 || i === 2) ? "translateX(-50%)" : "translateY(-50%)",
                }}
              >
                {dir}
              </div>
            ))}

            {/* Tick marks */}
            {Array.from({ length: 36 }).map((_, i) => (
              <div
                key={i}
                className="absolute top-0 left-1/2 origin-bottom h-1/2"
                style={{ transform: `rotate(${i * 10}deg)` }}
              >
                <div className={`w-px ${i % 9 === 0 ? "h-4 bg-primary/60" : "h-2 bg-border"}`} />
              </div>
            ))}

            {/* Spinning needle */}
            <motion.div
              style={{ rotate: springAngle }}
              className="absolute inset-8 flex items-center justify-center"
            >
              <div className="relative w-full h-full">
                {/* North needle */}
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[6px] border-r-[6px] border-b-[calc(50%-8px)] border-l-transparent border-r-transparent border-b-primary drop-shadow-[0_0_10px_hsla(38,65%,58%,0.5)]" />
                {/* South needle */}
                <div className="absolute bottom-0 left-1/2 -translate-x-1/2 w-0 h-0 border-l-[4px] border-r-[4px] border-t-[calc(50%-8px)] border-l-transparent border-r-transparent border-t-muted-foreground/40" />
                {/* Center dot */}
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 rounded-full bg-primary shadow-amber" />
              </div>
            </motion.div>

            {/* Compass icon center */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
              <Compass className="w-6 h-6 text-primary/20" />
            </div>
          </motion.div>

          {/* Fact cards */}
          <div className="flex flex-col gap-4 max-w-sm w-full">
            {wildFacts.map((fact, i) => {
              const FactIcon = fact.icon;
              return (
                <motion.div
                  key={fact.direction}
                  initial={{ opacity: 0, x: 30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.1 }}
                  animate={{
                    scale: activeFact === i ? 1.05 : 1,
                    borderColor: activeFact === i ? "hsl(var(--primary))" : "transparent",
                  }}
                  className="glass-card rounded-xl p-5 flex items-start gap-4 transition-all duration-300 border"
                >
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center shrink-0 transition-all duration-300 ${
                    activeFact === i ? "bg-gradient-amber" : "bg-muted"
                  }`}>
                    <FactIcon className={`w-5 h-5 transition-colors duration-300 ${
                      activeFact === i ? "text-primary-foreground" : "text-muted-foreground"
                    }`} />
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <span className={`font-display font-bold text-sm transition-colors duration-300 ${
                        activeFact === i ? "text-primary" : "text-muted-foreground"
                      }`}>
                        {fact.direction}
                      </span>
                      {activeFact === i && (
                        <motion.div
                          layoutId="compass-indicator"
                          className="w-1.5 h-1.5 rounded-full bg-primary"
                        />
                      )}
                    </div>
                    <p className={`font-body text-sm leading-relaxed transition-colors duration-300 ${
                      activeFact === i ? "text-foreground" : "text-muted-foreground"
                    }`}>
                      {fact.text}
                    </p>
                  </div>
                </motion.div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
};

export default WildCompassSection;

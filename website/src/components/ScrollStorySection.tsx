import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";

const stages = [
  {
    title: "Dawn at Base Camp",
    description: "The journey begins at 2,400m. First light paints the glacier gold.",
    skyFrom: "hsl(220, 30%, 12%)",
    skyTo: "hsl(30, 60%, 30%)",
    groundColor: "hsl(150, 25%, 15%)",
    peakColor: "hsl(150, 20%, 20%)",
    snowColor: "hsl(40, 15%, 85%)",
    sunY: 85,
    sunOpacity: 0.3,
    particles: 5,
  },
  {
    title: "The Alpine Meadow",
    description: "Wildflowers carpet the valleys at 3,200m. Eagles circle above.",
    skyFrom: "hsl(200, 50%, 60%)",
    skyTo: "hsl(40, 80%, 70%)",
    groundColor: "hsl(120, 30%, 25%)",
    peakColor: "hsl(150, 15%, 30%)",
    snowColor: "hsl(0, 0%, 95%)",
    sunY: 50,
    sunOpacity: 0.7,
    particles: 10,
  },
  {
    title: "The Glacier Crossing",
    description: "Ice and rock at 4,800m. The air thins, the world expands.",
    skyFrom: "hsl(210, 40%, 70%)",
    skyTo: "hsl(210, 30%, 85%)",
    groundColor: "hsl(200, 10%, 60%)",
    peakColor: "hsl(200, 8%, 45%)",
    snowColor: "hsl(200, 20%, 95%)",
    sunY: 30,
    sunOpacity: 0.9,
    particles: 15,
  },
  {
    title: "The Summit",
    description: "6,190m. Above the clouds. The world below disappears.",
    skyFrom: "hsl(230, 40%, 15%)",
    skyTo: "hsl(260, 30%, 25%)",
    groundColor: "hsl(0, 0%, 30%)",
    peakColor: "hsl(0, 0%, 40%)",
    snowColor: "hsl(0, 0%, 98%)",
    sunY: 15,
    sunOpacity: 1,
    particles: 25,
  },
];

const ScrollStorySection = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  const stageIndex = useTransform(scrollYProgress, [0, 1], [0, stages.length - 1]);
  const sunY = useTransform(scrollYProgress, [0, 0.33, 0.66, 1], [85, 50, 30, 15]);
  const sunScale = useTransform(scrollYProgress, [0, 1], [0.8, 1.5]);
  const sunOpacity = useTransform(scrollYProgress, [0, 0.5, 1], [0.3, 0.9, 1]);
  const mountainScale = useTransform(scrollYProgress, [0, 1], [1, 1.3]);
  const elevation = useTransform(scrollYProgress, [0, 1], [2400, 6190]);
  const textOpacity1 = useTransform(scrollYProgress, [0, 0.1, 0.2, 0.25], [0, 1, 1, 0]);
  const textOpacity2 = useTransform(scrollYProgress, [0.25, 0.35, 0.45, 0.5], [0, 1, 1, 0]);
  const textOpacity3 = useTransform(scrollYProgress, [0.5, 0.6, 0.7, 0.75], [0, 1, 1, 0]);
  const textOpacity4 = useTransform(scrollYProgress, [0.75, 0.85, 0.95, 1], [0, 1, 1, 1]);
  const stageOpacities = [textOpacity1, textOpacity2, textOpacity3, textOpacity4];

  return (
    <div ref={containerRef} className="relative" style={{ height: "400vh" }}>
      <div className="sticky top-0 h-screen overflow-hidden">
        {/* Dynamic sky */}
        <motion.div
          className="absolute inset-0 transition-colors duration-1000"
          style={{
            background: useTransform(
              scrollYProgress,
              [0, 0.33, 0.66, 1],
              [
                `linear-gradient(to top, ${stages[0].skyTo}, ${stages[0].skyFrom})`,
                `linear-gradient(to top, ${stages[1].skyTo}, ${stages[1].skyFrom})`,
                `linear-gradient(to top, ${stages[2].skyTo}, ${stages[2].skyFrom})`,
                `linear-gradient(to top, ${stages[3].skyTo}, ${stages[3].skyFrom})`,
              ]
            ),
          }}
        />

        {/* Sun */}
        <motion.div
          className="absolute left-1/2 -translate-x-1/2 rounded-full"
          style={{
            width: 80,
            height: 80,
            top: useTransform(sunY, (v) => `${v}%`),
            scale: sunScale,
            opacity: sunOpacity,
            background: "radial-gradient(circle, hsla(38, 80%, 70%, 1), hsla(38, 80%, 50%, 0.5), transparent 70%)",
            boxShadow: "0 0 80px 40px hsla(38, 80%, 60%, 0.3)",
          }}
        />

        {/* Stars (visible at dawn and summit) */}
        {Array.from({ length: 40 }).map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-[2px] h-[2px] rounded-full bg-foreground"
            style={{
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 40}%`,
              opacity: useTransform(scrollYProgress, [0, 0.2, 0.7, 1], [0.5, 0, 0, 0.4]),
            }}
          />
        ))}

        {/* Mountain layers with parallax */}
        <svg className="absolute bottom-0 left-0 right-0 w-full h-[60%]" viewBox="0 0 1440 400" preserveAspectRatio="none">
          {/* Far mountains */}
          <motion.path
            d="M0,400 L0,250 L120,180 L240,220 L400,130 L560,200 L720,110 L880,180 L1040,100 L1200,170 L1320,120 L1440,190 L1440,400 Z"
            style={{
              fill: useTransform(scrollYProgress, [0, 0.33, 0.66, 1],
                stages.map(s => s.peakColor)),
              scale: mountainScale,
              transformOrigin: "bottom center",
            }}
          />
          {/* Near mountains */}
          <motion.path
            d="M0,400 L0,300 L180,220 L350,270 L500,180 L680,250 L850,190 L1020,260 L1200,200 L1350,270 L1440,240 L1440,400 Z"
            style={{
              fill: useTransform(scrollYProgress, [0, 0.33, 0.66, 1],
                stages.map(s => s.groundColor)),
            }}
          />
          {/* Snow caps */}
          <motion.path
            d="M395,130 L400,120 L405,130 M715,110 L720,100 L725,110 M1035,100 L1040,88 L1045,100"
            fill="none"
            strokeWidth="3"
            style={{
              stroke: useTransform(scrollYProgress, [0, 0.33, 0.66, 1],
                stages.map(s => s.snowColor)),
              opacity: useTransform(scrollYProgress, [0, 0.5, 1], [0.3, 0.7, 1]),
            }}
          />
        </svg>

        {/* Floating particles (snow/dust) */}
        {Array.from({ length: 20 }).map((_, i) => (
          <motion.div
            key={`snow-${i}`}
            className="absolute w-1 h-1 rounded-full bg-foreground/30"
            style={{
              left: `${10 + Math.random() * 80}%`,
              top: `${20 + Math.random() * 60}%`,
              opacity: useTransform(scrollYProgress, [0, 1], [0.1, 0.6]),
            }}
            animate={{
              y: [0, 40, 0],
              x: [0, (Math.random() - 0.5) * 30, 0],
              opacity: [0.1, 0.5, 0.1],
            }}
            transition={{
              repeat: Infinity,
              duration: 4 + Math.random() * 6,
              delay: Math.random() * 5,
            }}
          />
        ))}

        {/* Content overlay */}
        <div className="absolute inset-0 flex items-center justify-center z-10">
          <div className="container mx-auto px-6">
            <div className="max-w-2xl">
              {stages.map((stage, i) => (
                <motion.div
                  key={i}
                  className="absolute"
                  style={{ opacity: stageOpacities[i] }}
                >
                  <motion.div className="glass-card rounded-2xl p-8 backdrop-blur-xl">
                    <p className="font-body text-primary text-sm tracking-widest uppercase mb-2">
                      Stage {i + 1} of 4
                    </p>
                    <h2 className="font-display font-bold text-4xl md:text-5xl text-foreground mb-3">
                      {stage.title}
                    </h2>
                    <p className="font-body text-muted-foreground text-lg mb-4">
                      {stage.description}
                    </p>
                    <div className="flex items-center gap-4">
                      <div className="flex items-center gap-2">
                        <div className="w-2 h-2 rounded-full bg-primary animate-pulse" />
                        <span className="font-display font-bold text-primary text-2xl">
                          {stages[i].sunY === 85 ? "2,400" : stages[i].sunY === 50 ? "3,200" : stages[i].sunY === 30 ? "4,800" : "6,190"}m
                        </span>
                      </div>
                      <div className="h-4 w-px bg-border" />
                      <span className="font-body text-sm text-muted-foreground">
                        {i === 0 ? "Base Camp" : i === 1 ? "Alpine Zone" : i === 2 ? "Glacier" : "Summit"}
                      </span>
                    </div>
                  </motion.div>
                </motion.div>
              ))}
            </div>
          </div>
        </div>

        {/* Elevation indicator */}
        <div className="absolute right-8 top-1/2 -translate-y-1/2 z-10 hidden md:flex flex-col items-center gap-2">
          <div className="h-40 w-1 rounded-full bg-border relative overflow-hidden">
            <motion.div
              className="absolute bottom-0 left-0 right-0 bg-gradient-amber rounded-full"
              style={{ height: useTransform(scrollYProgress, (v) => `${v * 100}%`) }}
            />
          </div>
          <motion.span className="font-display font-bold text-primary text-sm">
            <motion.span>{useTransform(elevation, (v) => `${Math.round(v).toLocaleString()}m`)}</motion.span>
          </motion.span>
        </div>

        {/* Scroll hint */}
        <motion.div
          className="absolute bottom-8 left-1/2 -translate-x-1/2 z-10"
          style={{ opacity: useTransform(scrollYProgress, [0, 0.1], [1, 0]) }}
        >
          <motion.div
            animate={{ y: [0, 8, 0] }}
            transition={{ repeat: Infinity, duration: 2 }}
            className="flex flex-col items-center gap-2"
          >
            <span className="font-body text-xs text-muted-foreground">Scroll to climb</span>
            <div className="w-5 h-8 rounded-full border border-muted-foreground/30 flex items-start justify-center p-1">
              <div className="w-1 h-1.5 rounded-full bg-primary" />
            </div>
          </motion.div>
        </motion.div>
      </div>
    </div>
  );
};

export default ScrollStorySection;

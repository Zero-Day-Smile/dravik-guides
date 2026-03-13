import { motion } from "framer-motion";

const MountainScene = () => {
  return (
    <div className="absolute inset-0 z-0 overflow-hidden">
      {/* Animated gradient sky */}
      <div className="absolute inset-0 bg-gradient-to-b from-[hsl(220,15%,12%)] via-[hsl(40,20%,6%)] to-[hsl(40,20%,6%)]" />

      {/* Stars */}
      {Array.from({ length: 80 }).map((_, i) => (
        <motion.div
          key={i}
          className="absolute w-[2px] h-[2px] rounded-full bg-foreground/40"
          style={{
            left: `${Math.random() * 100}%`,
            top: `${Math.random() * 50}%`,
          }}
          animate={{ opacity: [0.2, 0.8, 0.2] }}
          transition={{
            repeat: Infinity,
            duration: 2 + Math.random() * 3,
            delay: Math.random() * 2,
          }}
        />
      ))}

      {/* Mountain silhouettes */}
      <svg
        className="absolute bottom-0 left-0 right-0 w-full"
        viewBox="0 0 1440 400"
        preserveAspectRatio="none"
        style={{ height: "60%" }}
      >
        {/* Back mountain range */}
        <motion.path
          d="M0,400 L0,280 L120,200 L240,240 L360,160 L480,220 L600,140 L720,180 L840,120 L960,190 L1080,130 L1200,200 L1320,150 L1440,210 L1440,400 Z"
          fill="hsl(150, 30%, 10%)"
          initial={{ opacity: 0, y: 50 }}
          animate={{ opacity: 0.6, y: 0 }}
          transition={{ duration: 2 }}
        />
        {/* Mid mountain range */}
        <motion.path
          d="M0,400 L0,300 L100,250 L200,280 L350,190 L500,260 L650,180 L800,240 L950,170 L1100,230 L1250,190 L1350,250 L1440,220 L1440,400 Z"
          fill="hsl(150, 25%, 12%)"
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 0.8, y: 0 }}
          transition={{ duration: 1.5, delay: 0.3 }}
        />
        {/* Front mountain range */}
        <motion.path
          d="M0,400 L0,320 L180,260 L300,300 L450,230 L580,290 L720,220 L900,280 L1050,240 L1200,290 L1350,260 L1440,300 L1440,400 Z"
          fill="hsl(150, 20%, 8%)"
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 1, delay: 0.6 }}
        />
        {/* Snow caps */}
        <motion.path
          d="M350,190 L360,185 L370,190"
          fill="none"
          stroke="hsl(40,15%,80%)"
          strokeWidth="2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ delay: 1.5 }}
        />
        <motion.path
          d="M645,180 L655,173 L665,180"
          fill="none"
          stroke="hsl(40,15%,80%)"
          strokeWidth="2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ delay: 1.7 }}
        />
        <motion.path
          d="M945,170 L957,162 L968,170"
          fill="none"
          stroke="hsl(40,15%,80%)"
          strokeWidth="2"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ delay: 1.9 }}
        />
      </svg>

      {/* Floating compass element */}
      <motion.div
        className="absolute top-[25%] right-[15%] w-12 h-12 rounded-full border border-primary/30"
        animate={{ y: [0, -10, 0], rotate: [0, 360] }}
        transition={{ y: { repeat: Infinity, duration: 4 }, rotate: { repeat: Infinity, duration: 20, ease: "linear" } }}
      >
        <div className="absolute top-1 left-1/2 -translate-x-1/2 w-0.5 h-3 bg-primary/50 rounded-full" />
        <div className="absolute bottom-1 left-1/2 -translate-x-1/2 w-0.5 h-3 bg-muted-foreground/30 rounded-full" />
      </motion.div>

      {/* Floating particles */}
      {Array.from({ length: 15 }).map((_, i) => (
        <motion.div
          key={`p-${i}`}
          className="absolute w-1 h-1 rounded-full bg-primary/30"
          style={{
            left: `${20 + Math.random() * 60}%`,
            top: `${30 + Math.random() * 40}%`,
          }}
          animate={{
            y: [0, -30, 0],
            opacity: [0.2, 0.6, 0.2],
          }}
          transition={{
            repeat: Infinity,
            duration: 4 + Math.random() * 4,
            delay: Math.random() * 3,
          }}
        />
      ))}

      {/* Fog layer */}
      <div className="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-background to-transparent" />
    </div>
  );
};

export default MountainScene;

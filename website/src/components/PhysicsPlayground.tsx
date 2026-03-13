import { motion, useMotionValue, useSpring, useTransform } from "framer-motion";
import { useRef, useState, useEffect } from "react";
import { Mountain, Compass, Tent, Flame, Snowflake, Wind, TreePine, Sun } from "lucide-react";

const floatingItems = [
  { icon: Mountain, label: "Peak", size: 56, x: 15, y: 25, mass: 1.5 },
  { icon: Compass, label: "Navigate", size: 48, x: 75, y: 20, mass: 1.2 },
  { icon: Tent, label: "Camp", size: 52, x: 30, y: 65, mass: 1.8 },
  { icon: Flame, label: "Fire", size: 44, x: 60, y: 70, mass: 1.0 },
  { icon: Snowflake, label: "Snow", size: 40, x: 85, y: 45, mass: 0.8 },
  { icon: Wind, label: "Wind", size: 42, x: 45, y: 35, mass: 0.6 },
  { icon: TreePine, label: "Forest", size: 50, x: 20, y: 50, mass: 1.4 },
  { icon: Sun, label: "Sun", size: 54, x: 70, y: 30, mass: 1.1 },
];

const PhysicsItem = ({
  item,
  mouseX,
  mouseY,
  containerRef,
}: {
  item: typeof floatingItems[0];
  mouseX: number;
  mouseY: number;
  containerRef: React.RefObject<HTMLDivElement>;
}) => {
  const x = useMotionValue(0);
  const y = useMotionValue(0);
  const springX = useSpring(x, { stiffness: 50, damping: 10, mass: item.mass });
  const springY = useSpring(y, { stiffness: 50, damping: 10, mass: item.mass });
  const rotate = useTransform(springX, [-100, 100], [-15, 15]);
  const [isHovered, setIsHovered] = useState(false);

  useEffect(() => {
    if (!containerRef.current) return;
    const rect = containerRef.current.getBoundingClientRect();
    const itemCenterX = rect.left + (item.x / 100) * rect.width;
    const itemCenterY = rect.top + (item.y / 100) * rect.height;

    const dx = mouseX - itemCenterX;
    const dy = mouseY - itemCenterY;
    const distance = Math.sqrt(dx * dx + dy * dy);
    const maxForce = 120;
    const radius = 250;

    if (distance < radius && distance > 0) {
      const force = (1 - distance / radius) * maxForce;
      const pushX = -(dx / distance) * force;
      const pushY = -(dy / distance) * force;
      x.set(pushX);
      y.set(pushY);
    } else {
      x.set(0);
      y.set(0);
    }
  }, [mouseX, mouseY, item.x, item.y, containerRef, x, y]);

  return (
    <motion.div
      className="absolute cursor-grab active:cursor-grabbing"
      style={{
        left: `${item.x}%`,
        top: `${item.y}%`,
        x: springX,
        y: springY,
        rotate,
      }}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      whileTap={{ scale: 0.9 }}
    >
      <motion.div
        animate={{
          y: [0, -8, 0],
          scale: isHovered ? 1.3 : 1,
        }}
        transition={{
          y: { repeat: Infinity, duration: 3 + Math.random() * 2, delay: Math.random() * 2 },
          scale: { duration: 0.3 },
        }}
        className="flex flex-col items-center gap-2"
      >
        <div
          className={`rounded-2xl flex items-center justify-center transition-all duration-300 ${
            isHovered
              ? "glass-card border-primary/40 shadow-amber"
              : "glass-card"
          }`}
          style={{ width: item.size, height: item.size }}
        >
          <item.icon
            className={`transition-all duration-300 ${
              isHovered ? "text-primary" : "text-muted-foreground"
            }`}
            style={{ width: item.size * 0.45, height: item.size * 0.45 }}
          />
        </div>
        <motion.span
          initial={{ opacity: 0, y: 5 }}
          animate={{ opacity: isHovered ? 1 : 0, y: isHovered ? 0 : 5 }}
          className="font-body text-xs text-primary font-semibold whitespace-nowrap"
        >
          {item.label}
        </motion.span>
      </motion.div>
    </motion.div>
  );
};

const PhysicsPlayground = () => {
  const containerRef = useRef<HTMLDivElement>(null);
  const [mouse, setMouse] = useState({ x: -1000, y: -1000 });

  const handleMouseMove = (e: React.MouseEvent) => {
    setMouse({ x: e.clientX, y: e.clientY });
  };

  return (
    <section className="py-32 relative overflow-hidden">
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/3 left-1/4 w-[500px] h-[500px] rounded-full bg-primary/3 blur-[150px]" />
        <div className="absolute bottom-1/4 right-1/3 w-[400px] h-[400px] rounded-full bg-accent/3 blur-[120px]" />
      </div>

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-8"
        >
          <span className="text-primary font-body text-sm tracking-widest uppercase mb-4 block">
            Interactive
          </span>
          <h2 className="font-display font-bold text-4xl md:text-6xl mb-4">
            Push the <span className="text-gradient-amber">elements</span>
          </h2>
          <p className="text-muted-foreground font-body text-lg max-w-lg mx-auto">
            Move your mouse to interact — elements float away from your cursor with physics
          </p>
        </motion.div>

        <motion.div
          ref={containerRef}
          onMouseMove={handleMouseMove}
          onMouseLeave={() => setMouse({ x: -1000, y: -1000 })}
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          viewport={{ once: true }}
          className="relative h-[500px] glass-card rounded-3xl overflow-hidden cursor-none"
        >
          {/* Grid background */}
          <svg className="absolute inset-0 w-full h-full opacity-5">
            {Array.from({ length: 20 }).map((_, i) => (
              <line key={`v${i}`} x1={`${(i + 1) * 5}%`} y1="0" x2={`${(i + 1) * 5}%`} y2="100%" stroke="hsl(var(--foreground))" strokeWidth="0.5" />
            ))}
            {Array.from({ length: 10 }).map((_, i) => (
              <line key={`h${i}`} x1="0" y1={`${(i + 1) * 10}%`} x2="100%" y2={`${(i + 1) * 10}%`} stroke="hsl(var(--foreground))" strokeWidth="0.5" />
            ))}
          </svg>

          {/* Custom cursor glow */}
          {containerRef.current && mouse.x > 0 && (
            <motion.div
              className="absolute w-32 h-32 rounded-full pointer-events-none"
              style={{
                left: mouse.x - (containerRef.current?.getBoundingClientRect().left || 0) - 64,
                top: mouse.y - (containerRef.current?.getBoundingClientRect().top || 0) - 64,
                background: "radial-gradient(circle, hsla(38, 65%, 58%, 0.15), transparent 70%)",
              }}
            />
          )}

          {/* Physics items */}
          {floatingItems.map((item, i) => (
            <PhysicsItem
              key={item.label}
              item={item}
              mouseX={mouse.x}
              mouseY={mouse.y}
              containerRef={containerRef}
            />
          ))}

          {/* Center text */}
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center pointer-events-none">
            <p className="font-display text-muted-foreground/20 text-6xl md:text-8xl font-bold select-none">
              WILD
            </p>
          </div>
        </motion.div>
      </div>
    </section>
  );
};

export default PhysicsPlayground;

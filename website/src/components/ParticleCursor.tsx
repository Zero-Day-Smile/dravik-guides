import { useEffect, useRef } from "react";

interface Particle {
  x: number;
  y: number;
  vx: number;
  vy: number;
  life: number;
  maxLife: number;
  size: number;
  hue: number;
}

const ParticleCursor = () => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const particles = useRef<Particle[]>([]);
  const mouse = useRef({ x: -100, y: -100, prevX: -100, prevY: -100 });
  const animationRef = useRef<number>();

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const resize = () => {
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
    };
    resize();
    window.addEventListener("resize", resize);

    const handleMouse = (e: MouseEvent) => {
      mouse.current.prevX = mouse.current.x;
      mouse.current.prevY = mouse.current.y;
      mouse.current.x = e.clientX;
      mouse.current.y = e.clientY;

      const speed = Math.hypot(
        e.clientX - mouse.current.prevX,
        e.clientY - mouse.current.prevY
      );
      const count = Math.min(Math.floor(speed / 3) + 1, 8);

      for (let i = 0; i < count; i++) {
        const angle = Math.random() * Math.PI * 2;
        const velocity = 0.5 + Math.random() * 2;
        particles.current.push({
          x: e.clientX + (Math.random() - 0.5) * 4,
          y: e.clientY + (Math.random() - 0.5) * 4,
          vx: Math.cos(angle) * velocity,
          vy: Math.sin(angle) * velocity - 1.5,
          life: 0,
          maxLife: 25 + Math.random() * 35,
          size: 1.5 + Math.random() * 4,
          hue: 30 + Math.random() * 20, // amber to orange range
        });
      }

      if (particles.current.length > 150) {
        particles.current = particles.current.slice(-120);
      }
    };

    window.addEventListener("mousemove", handleMouse);

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      particles.current = particles.current.filter((p) => {
        p.life++;
        p.x += p.vx;
        p.y += p.vy;
        p.vy -= 0.03;
        p.vx *= 0.99;

        const progress = p.life / p.maxLife;
        const alpha = (1 - progress) * 0.8;
        const size = p.size * (1 - progress * 0.6);

        // Fire glow
        const gradient = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, size * 2);
        gradient.addColorStop(0, `hsla(${p.hue}, 80%, 65%, ${alpha})`);
        gradient.addColorStop(0.4, `hsla(${p.hue - 10}, 70%, 50%, ${alpha * 0.6})`);
        gradient.addColorStop(1, `hsla(${p.hue - 20}, 60%, 30%, 0)`);

        ctx.beginPath();
        ctx.arc(p.x, p.y, size * 2, 0, Math.PI * 2);
        ctx.fillStyle = gradient;
        ctx.fill();

        // Bright core
        ctx.beginPath();
        ctx.arc(p.x, p.y, size * 0.5, 0, Math.PI * 2);
        ctx.fillStyle = `hsla(${p.hue + 10}, 90%, 80%, ${alpha})`;
        ctx.fill();

        return p.life < p.maxLife;
      });

      animationRef.current = requestAnimationFrame(animate);
    };
    animate();

    return () => {
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", handleMouse);
      if (animationRef.current) cancelAnimationFrame(animationRef.current);
    };
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="fixed inset-0 pointer-events-none z-50"
      style={{ mixBlendMode: "screen" }}
    />
  );
};

export default ParticleCursor;

import { motion } from "framer-motion";
import { ArrowRight, Mountain } from "lucide-react";
import { Button } from "@/components/ui/button";

const CTASection = () => {
  return (
    <section className="py-32 relative overflow-hidden">
      {/* Animated background glows */}
      <motion.div
        animate={{ scale: [1, 1.2, 1], opacity: [0.3, 0.5, 0.3] }}
        transition={{ repeat: Infinity, duration: 6, ease: "easeInOut" }}
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full bg-primary/5 blur-[120px] pointer-events-none"
      />
      <motion.div
        animate={{ scale: [1.2, 1, 1.2], opacity: [0.2, 0.4, 0.2] }}
        transition={{ repeat: Infinity, duration: 8, ease: "easeInOut" }}
        className="absolute top-1/3 right-1/4 w-[400px] h-[400px] rounded-full bg-accent/5 blur-[100px] pointer-events-none"
      />

      <div className="container mx-auto px-6 relative z-10">
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="max-w-3xl mx-auto text-center"
        >
          <motion.div
            whileHover={{ rotate: 360, scale: 1.2 }}
            transition={{ duration: 0.8, ease: "easeInOut" }}
            className="inline-block"
          >
            <Mountain className="w-12 h-12 text-primary mx-auto mb-8 animate-float" />
          </motion.div>
          <h2 className="font-display font-bold text-4xl md:text-6xl mb-6">
            Your next summit<br />
            <span className="text-gradient-amber">starts here</span>
          </h2>
          <p className="font-body text-muted-foreground text-lg mb-10 max-w-lg mx-auto">
            Join thousands of adventurers who trust Dravik as their essential expedition companion.
          </p>
          <Button
            size="lg"
            className="group bg-gradient-amber text-primary-foreground font-display font-semibold text-lg px-10 py-6 shadow-amber hover:opacity-90 transition-all hover:scale-105 active:scale-95"
          >
            Get Dravik
            <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
          </Button>
        </motion.div>
      </div>
    </section>
  );
};

export default CTASection;

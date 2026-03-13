import { motion } from "framer-motion";
import { BookOpen } from "lucide-react";
import { useNavigate } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { guides } from "@/data/guides";

const difficultyColor: Record<string, string> = {
  Beginner: "bg-accent/30 text-accent-foreground",
  Moderate: "bg-primary/20 text-primary",
  Challenging: "bg-destructive/20 text-destructive",
  Advanced: "bg-destructive/30 text-destructive",
};

const GuidesPage = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <div className="flex items-center gap-3 mb-2">
            <BookOpen className="w-8 h-8 text-primary" />
            <h1 className="font-display font-bold text-4xl md:text-6xl">
              Trail <span className="text-gradient-amber">Guides</span>
            </h1>
          </div>
          <p className="font-body text-muted-foreground text-lg mb-12 max-w-2xl">
            Expert knowledge to keep you prepared, confident, and safe on every adventure. From beginner basics to advanced survival techniques.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {guides.map((guide, i) => (
              <motion.div
                key={guide.title}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.08 }}
                onClick={() => navigate(`/guides/${guide.slug}`)}
                className="glass-card rounded-2xl p-6 group hover:border-primary/30 transition-all cursor-pointer"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-primary-foreground transition-all duration-300">
                    <guide.icon className="w-6 h-6" />
                  </div>
                  <span className={`font-body text-xs font-semibold px-3 py-1 rounded-full ${difficultyColor[guide.difficulty]}`}>
                    {guide.difficulty}
                  </span>
                </div>
                <h3 className="font-display font-semibold text-xl text-foreground mb-2 group-hover:text-primary transition-colors">
                  {guide.title}
                </h3>
                <p className="font-body text-sm text-muted-foreground mb-4 leading-relaxed">
                  {guide.description}
                </p>
                <div className="space-y-2">
                  <span className="font-body text-xs text-primary font-semibold uppercase tracking-wider">Key Tips</span>
                  <ul className="space-y-1.5">
                    {guide.tips.map((tip) => (
                      <li key={tip} className="font-body text-sm text-muted-foreground flex items-start gap-2">
                        <span className="w-1.5 h-1.5 rounded-full bg-primary mt-1.5 flex-shrink-0" />
                        {tip}
                      </li>
                    ))}
                  </ul>
                </div>
              </motion.div>
            ))}
          </div>
        </motion.div>
      </div>
      <Footer />
    </div>
  );
};

export default GuidesPage;

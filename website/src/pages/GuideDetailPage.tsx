import { motion } from "framer-motion";
import { ArrowLeft, BookOpen } from "lucide-react";
import { useMemo } from "react";
import { useNavigate, useParams } from "react-router-dom";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import { getGuideBySlug } from "@/data/guides";

type MarkdownLine =
  | { type: "h2"; text: string }
  | { type: "li"; text: string }
  | { type: "p"; text: string }
  | { type: "spacer" };

const parseMarkdown = (input: string): MarkdownLine[] => {
  return input.split("\n").map((line) => {
    const trimmed = line.trim();
    if (!trimmed) return { type: "spacer" };
    if (trimmed.startsWith("## ")) return { type: "h2", text: trimmed.replace("## ", "") };
    if (trimmed.startsWith("- ")) return { type: "li", text: trimmed.replace("- ", "") };
    return { type: "p", text: trimmed };
  });
};

const difficultyColor: Record<string, string> = {
  Beginner: "bg-accent/30 text-accent-foreground",
  Moderate: "bg-primary/20 text-primary",
  Challenging: "bg-destructive/20 text-destructive",
  Advanced: "bg-destructive/30 text-destructive",
};

const GuideDetailPage = () => {
  const navigate = useNavigate();
  const { slug = "" } = useParams<{ slug: string }>();
  const guide = getGuideBySlug(slug);

  const lines = useMemo(() => (guide ? parseMarkdown(guide.markdown) : []), [guide]);

  if (!guide) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <div className="pt-28 container mx-auto px-6">
          <div className="glass-card rounded-2xl p-8 text-center">
            <p className="font-display text-2xl text-foreground mb-2">Guide not found</p>
            <p className="font-body text-muted-foreground mb-6">The requested guide does not exist.</p>
            <button
              onClick={() => navigate("/guides")}
              className="font-body text-sm text-primary hover:underline"
            >
              Back to guides
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-12 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <button
            onClick={() => navigate("/guides")}
            className="flex items-center gap-2 text-muted-foreground hover:text-foreground mb-6 font-body text-sm"
          >
            <ArrowLeft className="w-4 h-4" /> Back to guides
          </button>

          <div className="glass-card rounded-2xl p-6 md:p-8">
            <div className="flex items-start justify-between gap-4 mb-5">
              <div>
                <h1 className="font-display font-bold text-3xl md:text-5xl text-foreground">{guide.title}</h1>
                <p className="font-body text-muted-foreground mt-2">{guide.description}</p>
              </div>
              <span className={`font-body text-xs font-semibold px-3 py-1 rounded-full ${difficultyColor[guide.difficulty]}`}>
                {guide.difficulty}
              </span>
            </div>

            <div className="flex items-center gap-2 mb-6 text-primary">
              <BookOpen className="w-5 h-5" />
              <span className="font-body text-sm">Detailed Guide</span>
            </div>

            <div className="space-y-2">
              {lines.map((line, idx) => {
                if (line.type === "spacer") return <div key={idx} className="h-2" />;
                if (line.type === "h2") {
                  return (
                    <h2 key={idx} className="font-display font-semibold text-2xl text-foreground pt-2">
                      {line.text}
                    </h2>
                  );
                }
                if (line.type === "li") {
                  return (
                    <p key={idx} className="font-body text-sm text-muted-foreground flex items-start gap-2">
                      <span className="w-1.5 h-1.5 rounded-full bg-primary mt-2 flex-shrink-0" />
                      {line.text}
                    </p>
                  );
                }
                return (
                  <p key={idx} className="font-body text-base text-muted-foreground leading-relaxed">
                    {line.text}
                  </p>
                );
              })}
            </div>
          </div>
        </motion.div>
      </div>
      <Footer />
    </div>
  );
};

export default GuideDetailPage;

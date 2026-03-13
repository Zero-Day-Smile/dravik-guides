import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Search, ShieldAlert } from "lucide-react";
import Navbar from "@/components/Navbar";
import { Input } from "@/components/ui/input";
import { emergencyGuides } from "@/data/emergencyGuides";

const EmergencyGuidesPage = () => {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState<string>("all");

  const filtered = useMemo(() => {
    return emergencyGuides.filter((guide) => {
      const byCategory = category === "all" || guide.category === category;
      const q = query.trim().toLowerCase();
      const byQuery =
        !q ||
        guide.title.toLowerCase().includes(q) ||
        guide.summary.toLowerCase().includes(q) ||
        guide.steps.some((step) => step.toLowerCase().includes(q));
      return byCategory && byQuery;
    });
  }, [query, category]);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Emergency <span className="text-gradient-amber">Guides</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Quick-response playbooks for high-risk trail situations.
          </p>

          <div className="glass-card rounded-2xl p-5 mb-8 grid grid-cols-1 md:grid-cols-3 gap-3">
            <div className="relative md:col-span-2">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                className="pl-10 bg-muted border-border font-body"
                placeholder="Search emergency procedures"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
            </div>
            <select
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="h-10 rounded-md border border-border bg-muted px-3 font-body text-sm"
              aria-label="Emergency category"
            >
              <option value="all">All categories</option>
              <option value="Medical">Medical</option>
              <option value="Weather">Weather</option>
              <option value="Navigation">Navigation</option>
              <option value="Rescue">Rescue</option>
            </select>
          </div>

          <div className="space-y-4">
            {filtered.map((guide) => (
              <details key={guide.slug} className="glass-card rounded-2xl p-5 group">
                <summary className="cursor-pointer list-none flex items-center justify-between gap-3">
                  <div>
                    <p className="font-display font-semibold text-xl text-foreground">{guide.title}</p>
                    <p className="font-body text-xs text-primary uppercase tracking-wider mt-1">{guide.category}</p>
                    <p className="font-body text-sm text-muted-foreground mt-2">{guide.summary}</p>
                  </div>
                  <ShieldAlert className="w-5 h-5 text-primary group-open:text-destructive" />
                </summary>

                <div className="mt-4 space-y-2">
                  {guide.steps.map((step, idx) => (
                    <p key={step} className="font-body text-sm text-muted-foreground flex items-start gap-2">
                      <span className="font-display text-primary">{idx + 1}.</span>
                      {step}
                    </p>
                  ))}
                </div>
              </details>
            ))}

            {filtered.length === 0 && (
              <div className="glass-card rounded-2xl p-8 text-center font-body text-muted-foreground">
                No emergency guide matched your filters.
              </div>
            )}
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default EmergencyGuidesPage;

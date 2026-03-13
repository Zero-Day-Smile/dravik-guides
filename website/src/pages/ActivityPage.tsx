import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Activity, Play, Square, Trash2 } from "lucide-react";
import Navbar from "@/components/Navbar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useActivityTracker } from "@/hooks/useActivityTracker";
import { useToast } from "@/hooks/use-toast";

const ActivityPage = () => {
  const { toast } = useToast();
  const { sessions, activeSession, stats, startSession, stopSession, clearHistory } = useActivityTracker();
  const [mode, setMode] = useState<"hiking" | "running" | "cycling">("hiking");
  const [notes, setNotes] = useState("Morning terrain training");

  const completed = useMemo(() => sessions.filter((s) => s.endedAt !== null), [sessions]);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Activity <span className="text-gradient-amber">Tracker</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Web baseline for session logging, streaks, and estimated distance.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground">Completed Sessions</p>
              <p className="font-display text-3xl text-foreground">{stats.totalSessions}</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground">Distance</p>
              <p className="font-display text-3xl text-foreground">{stats.totalDistanceKm} km</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground">Active Streak</p>
              <p className="font-display text-3xl text-foreground">{stats.streakDays} days</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground">Live Session</p>
              <p className="font-display text-lg text-foreground">{activeSession ? activeSession.mode : "None"}</p>
            </div>
          </div>

          <div className="glass-card rounded-2xl p-6 mb-8">
            <h2 className="font-display font-semibold text-xl text-foreground mb-4">Session Control</h2>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-3">
              <select
                value={mode}
                onChange={(e) => setMode(e.target.value as "hiking" | "running" | "cycling")}
                className="h-10 rounded-md border border-border bg-muted px-3 font-body text-sm"
                aria-label="Activity mode"
              >
                <option value="hiking">Hiking</option>
                <option value="running">Running</option>
                <option value="cycling">Cycling</option>
              </select>
              <Input
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="bg-muted border-border font-body md:col-span-2"
                placeholder="Session notes"
              />
            </div>

            <div className="flex flex-wrap gap-2">
              <Button
                disabled={!!activeSession}
                onClick={() => {
                  startSession(mode, notes.trim());
                  toast({ title: "Session started", description: `Mode: ${mode}` });
                }}
                className="font-body"
              >
                <Play className="w-4 h-4 mr-1" /> Start
              </Button>

              <Button
                variant="outline"
                disabled={!activeSession}
                onClick={() => {
                  stopSession();
                  toast({ title: "Session stopped", description: "Distance estimate saved." });
                }}
                className="font-body"
              >
                <Square className="w-4 h-4 mr-1" /> Stop
              </Button>

              <Button
                variant="ghost"
                onClick={() => {
                  clearHistory();
                  toast({ title: "History cleared" });
                }}
                className="font-body text-destructive"
              >
                <Trash2 className="w-4 h-4 mr-1" /> Clear
              </Button>
            </div>
          </div>

          <div className="glass-card rounded-2xl p-6">
            <h2 className="font-display font-semibold text-xl text-foreground mb-4 flex items-center gap-2">
              <Activity className="w-5 h-5 text-primary" /> Activity Log
            </h2>

            <div className="space-y-2">
              {completed.map((session) => (
                <div key={session.id} className="rounded-lg bg-muted/40 p-3">
                  <p className="font-body text-sm text-foreground capitalize">{session.mode}</p>
                  <p className="font-body text-xs text-muted-foreground">
                    {new Date(session.startedAt).toLocaleString()} - {session.endedAt ? new Date(session.endedAt).toLocaleString() : "Active"}
                  </p>
                  <p className="font-body text-xs text-muted-foreground">
                    {session.estimatedDistanceKm} km • {session.notes || "No notes"}
                  </p>
                </div>
              ))}
              {completed.length === 0 && <p className="font-body text-muted-foreground">No completed sessions yet.</p>}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default ActivityPage;

import { motion } from "framer-motion";
import { useMemo } from "react";
import { BarChart3, Trophy, Route, Heart, Star } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { BarChart, Bar, CartesianGrid, XAxis, Tooltip, PieChart, Pie, Cell, ResponsiveContainer } from "recharts";
import Navbar from "@/components/Navbar";
import { useAuth, useSavedDestinations, useUserTrips } from "@/hooks/useAuth";
import { useDestinations } from "@/hooks/useDestinations";

const colors = ["#f59e0b", "#10b981", "#3b82f6", "#ef4444", "#8b5cf6"];

const AnalyticsPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { data: trips } = useUserTrips(user?.id);
  const { data: saved } = useSavedDestinations(user?.id);
  const { data: destinations } = useDestinations({ limit: 500 });

  const statusData = useMemo(() => {
    const counts = new Map<string, number>();
    (trips || []).forEach((trip) => {
      const key = trip.status || "planning";
      counts.set(key, (counts.get(key) || 0) + 1);
    });
    return Array.from(counts.entries()).map(([name, value]) => ({ name, value }));
  }, [trips]);

  const difficultyData = useMemo(() => {
    const counts = new Map<string, number>();
    (saved || []).forEach((entry) => {
      const difficulty = entry.destinations?.difficulty || "Unknown";
      counts.set(difficulty, (counts.get(difficulty) || 0) + 1);
    });
    return Array.from(counts.entries()).map(([name, count]) => ({ name, count }));
  }, [saved]);

  const topCountries = useMemo(() => {
    const counts = new Map<string, number>();
    (destinations || []).forEach((dest) => {
      if (!dest.country) return;
      counts.set(dest.country, (counts.get(dest.country) || 0) + 1);
    });
    return Array.from(counts.entries())
      .map(([country, count]) => ({ country, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 5);
  }, [destinations]);

  const completedTrips = (trips || []).filter((t) => t.status === "completed").length;
  const activeTrips = (trips || []).filter((t) => t.status === "active").length;
  const avgSavedRating =
    (saved || []).length > 0
      ? (saved || []).reduce((acc, item) => acc + (item.destinations?.avg_rating || 0), 0) / (saved || []).length
      : 0;

  const missionCards = useMemo(() => {
    const totalTrips = trips?.length || 0;
    const totalSaved = saved?.length || 0;

    return [
      {
        id: "first-expedition",
        title: "First Expedition",
        progress: Math.min(totalTrips, 1),
        target: 1,
        description: "Create your first trip plan.",
      },
      {
        id: "summit-series",
        title: "Summit Series",
        progress: completedTrips,
        target: 5,
        description: "Complete 5 trek missions.",
      },
      {
        id: "cartographer",
        title: "Cartographer",
        progress: totalSaved,
        target: 10,
        description: "Save 10 destinations for future routes.",
      },
    ];
  }, [trips, completedTrips, saved]);

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Adventure <span className="text-gradient-amber">Analytics</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Your activity, planning, and discovery metrics in one place.
          </p>
          <button className="font-body text-sm text-primary hover:underline mb-6" onClick={() => navigate("/activity")}>Open Activity Tracker</button>

          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground flex items-center gap-1"><Route className="w-3.5 h-3.5" /> Total Trips</p>
              <p className="font-display text-3xl text-foreground">{trips?.length || 0}</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground flex items-center gap-1"><Trophy className="w-3.5 h-3.5" /> Completed</p>
              <p className="font-display text-3xl text-foreground">{completedTrips}</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground flex items-center gap-1"><Heart className="w-3.5 h-3.5" /> Saved</p>
              <p className="font-display text-3xl text-foreground">{saved?.length || 0}</p>
            </div>
            <div className="glass-card rounded-2xl p-4">
              <p className="font-body text-xs text-muted-foreground flex items-center gap-1"><Star className="w-3.5 h-3.5" /> Avg Saved Rating</p>
              <p className="font-display text-3xl text-foreground">{avgSavedRating.toFixed(1)}</p>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <div className="glass-card rounded-2xl p-5">
              <h2 className="font-display font-semibold text-xl text-foreground mb-4 flex items-center gap-2">
                <BarChart3 className="w-5 h-5 text-primary" /> Trip Status Distribution
              </h2>
              <div className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={statusData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <Tooltip />
                    <Bar dataKey="value" fill="#f59e0b" radius={[6, 6, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>

            <div className="glass-card rounded-2xl p-5">
              <h2 className="font-display font-semibold text-xl text-foreground mb-4">Saved Destinations by Difficulty</h2>
              <div className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={difficultyData} dataKey="count" nameKey="name" cx="50%" cy="50%" outerRadius={100} label>
                      {difficultyData.map((entry, idx) => (
                        <Cell key={entry.name} fill={colors[idx % colors.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          <div className="glass-card rounded-2xl p-5">
            <h2 className="font-display font-semibold text-xl text-foreground mb-4">Top Destination Countries</h2>
            <div className="space-y-2">
              {topCountries.map((country, idx) => (
                <div key={country.country} className="flex items-center justify-between rounded-lg bg-muted/40 p-3">
                  <p className="font-body text-sm text-foreground">#{idx + 1} {country.country}</p>
                  <p className="font-body text-sm text-muted-foreground">{country.count} destinations</p>
                </div>
              ))}
              {topCountries.length === 0 && <p className="font-body text-muted-foreground">No destination data available yet.</p>}
            </div>
            <p className="font-body text-xs text-muted-foreground mt-4">
              Active trips: {activeTrips}. Keep progressing your plans to improve completion streaks.
            </p>
          </div>

          <div className="glass-card rounded-2xl p-5 mt-8">
            <h2 className="font-display font-semibold text-xl text-foreground mb-4">Missions & Achievements</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {missionCards.map((mission) => {
                const percent = Math.min(100, Math.round((mission.progress / mission.target) * 100));
                const completed = mission.progress >= mission.target;

                return (
                  <div key={mission.id} className="rounded-xl bg-muted/40 p-4">
                    <div className="flex items-center justify-between mb-2">
                      <p className="font-display text-lg text-foreground">{mission.title}</p>
                      <span className={`font-body text-xs px-2 py-1 rounded-full ${completed ? "bg-accent/30 text-accent-foreground" : "bg-primary/20 text-primary"}`}>
                        {completed ? "Unlocked" : "In Progress"}
                      </span>
                    </div>

                    <p className="font-body text-sm text-muted-foreground mb-3">{mission.description}</p>

                    <progress
                      className="w-full h-2 mb-2 [&::-webkit-progress-bar]:bg-background [&::-webkit-progress-value]:bg-amber-500 [&::-moz-progress-bar]:bg-amber-500 rounded-full overflow-hidden"
                      max={mission.target}
                      value={Math.min(mission.progress, mission.target)}
                    />

                    <p className="font-body text-xs text-muted-foreground">
                      {mission.progress}/{mission.target} ({percent}%)
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default AnalyticsPage;

import { useAuth, useProfile, useSavedDestinations, useUserTrips } from "@/hooks/useAuth";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { User, Heart, Map, LogOut, Star, MapPin, Smartphone, BarChart3, Upload } from "lucide-react";
import { Button } from "@/components/ui/button";
import Navbar from "@/components/Navbar";
import { useEffect } from "react";

const DashboardPage = () => {
  const { user, loading, signOut } = useAuth();
  const navigate = useNavigate();
  const { data: profile } = useProfile(user?.id);
  const { data: saved } = useSavedDestinations(user?.id);
  const { data: trips } = useUserTrips(user?.id);
  const adminEmails = String(import.meta.env.VITE_ADMIN_EMAILS ?? "")
    .split(",")
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);
  const isAdmin = !!user && (
    String(user.app_metadata?.role ?? user.user_metadata?.role ?? "").toLowerCase() === "admin" ||
    adminEmails.includes(user.email?.toLowerCase() ?? "")
  );

  useEffect(() => {
    if (!loading && !user) navigate("/auth");
  }, [user, loading, navigate]);

  if (loading) return <div className="min-h-screen bg-background flex items-center justify-center"><div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" /></div>;

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Profile Sidebar */}
          <motion.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} className="lg:col-span-1">
            <div className="glass-card rounded-2xl p-6 sticky top-24">
              <div className="w-16 h-16 rounded-full bg-gradient-amber flex items-center justify-center mx-auto mb-4">
                <span className="font-display font-bold text-2xl text-primary-foreground">
                  {profile?.display_name?.[0]?.toUpperCase() || "?"}
                </span>
              </div>
              <h2 className="font-display font-bold text-xl text-foreground text-center">{profile?.display_name}</h2>
              <p className="font-body text-sm text-muted-foreground text-center mb-4">{user?.email}</p>
              <div className="space-y-2">
                <div className="flex justify-between font-body text-sm">
                  <span className="text-muted-foreground">Saved</span>
                  <span className="text-foreground">{saved?.length || 0}</span>
                </div>
                <div className="flex justify-between font-body text-sm">
                  <span className="text-muted-foreground">Trips</span>
                  <span className="text-foreground">{trips?.length || 0}</span>
                </div>
              </div>
              <Button variant="ghost" className="w-full mt-4 text-muted-foreground font-body" onClick={async () => { await signOut(); navigate("/"); }}>
                <LogOut className="w-4 h-4 mr-2" /> Sign out
              </Button>

              {/* App CTA */}
              <div className="mt-6 p-4 rounded-xl bg-gradient-forest">
                <div className="flex items-center gap-2 mb-2">
                  <Smartphone className="w-5 h-5 text-primary" />
                  <span className="font-display font-semibold text-sm text-foreground">Mobile App</span>
                </div>
                <p className="font-body text-xs text-muted-foreground mb-3">
                  AR scanning, offline maps, group sync & more
                </p>
                <Button size="sm" className="w-full bg-gradient-amber text-primary-foreground font-display text-xs">
                  Download App
                </Button>
              </div>
            </div>
          </motion.div>

          {/* Main Content */}
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="lg:col-span-3 space-y-8">
            <div>
              <h1 className="font-display font-bold text-3xl text-foreground mb-1">
                Welcome, <span className="text-gradient-amber">{profile?.display_name}</span>
              </h1>
              <p className="font-body text-muted-foreground">Your adventure dashboard</p>
              <Button variant="outline" className="mt-3 font-body" onClick={() => navigate("/analytics")}>
                <BarChart3 className="w-4 h-4 mr-2" /> Open Analytics
              </Button>
              {isAdmin && (
                <Button variant="outline" className="mt-3 ml-2 font-body" onClick={() => navigate("/admin/import")}>
                  <Upload className="w-4 h-4 mr-2" /> Open Import Tool
                </Button>
              )}
            </div>

            {/* Saved Destinations */}
            <div>
              <h2 className="font-display font-semibold text-xl text-foreground mb-4 flex items-center gap-2">
                <Heart className="w-5 h-5 text-primary" /> Saved Destinations
              </h2>
              {saved && saved.length > 0 ? (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {saved.map((s: any) => (
                    <div
                      key={s.id}
                      onClick={() => navigate(`/destination/${s.destinations?.slug}`)}
                      className="glass-card rounded-xl p-4 flex items-center gap-4 cursor-pointer hover:border-primary/20 transition-all"
                    >
                      <div className="w-16 h-16 rounded-lg bg-gradient-forest shrink-0 overflow-hidden">
                        {s.destinations?.image_url && (
                          <img
                            src={s.destinations.image_url}
                            alt={s.destinations?.title || "Saved destination"}
                            className="w-full h-full object-cover"
                          />
                        )}
                      </div>
                      <div>
                        <p className="font-display font-semibold text-foreground">{s.destinations?.title}</p>
                        <p className="font-body text-xs text-muted-foreground">{s.destinations?.categories?.name}</p>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="glass-card rounded-xl p-8 text-center">
                  <Heart className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
                  <p className="font-body text-muted-foreground mb-3">No saved destinations yet</p>
                  <Button variant="outline" onClick={() => navigate("/explore")}>
                    Explore Destinations
                  </Button>
                </div>
              )}
            </div>

            {/* Trips */}
            <div>
              <h2 className="font-display font-semibold text-xl text-foreground mb-4 flex items-center gap-2">
                <Map className="w-5 h-5 text-primary" /> Your Trips
              </h2>
              {trips && trips.length > 0 ? (
                <div className="space-y-3">
                  {trips.map((trip: any) => (
                    <div key={trip.id} className="glass-card rounded-xl p-4 flex items-center justify-between">
                      <div>
                        <p className="font-display font-semibold text-foreground">{trip.title}</p>
                        <p className="font-body text-xs text-muted-foreground">
                          {trip.status} {trip.start_date && `• ${trip.start_date}`}
                        </p>
                      </div>
                      <span className={`font-body text-xs px-3 py-1 rounded-full ${
                        trip.status === 'completed' ? 'bg-accent/30 text-accent-foreground' :
                        trip.status === 'active' ? 'bg-primary/20 text-primary' :
                        'bg-muted text-muted-foreground'
                      }`}>
                        {trip.status}
                      </span>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="glass-card rounded-xl p-8 text-center">
                  <Map className="w-8 h-8 text-muted-foreground mx-auto mb-3" />
                  <p className="font-body text-muted-foreground mb-3">No trips planned yet</p>
                  <Button variant="outline" onClick={() => navigate("/trips")}>
                    Plan a Trip
                  </Button>
                </div>
              )}
            </div>
          </motion.div>
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;

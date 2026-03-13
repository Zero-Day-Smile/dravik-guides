import { useParams, useNavigate } from "react-router-dom";
import { useDestination, useDestinationReviews } from "@/hooks/useDestinations";
import { useAuth, useToggleSave, useSavedDestinations } from "@/hooks/useAuth";
import { motion } from "framer-motion";
import { ArrowLeft, MapPin, Clock, Mountain, Star, Heart, Smartphone, Share2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import Navbar from "@/components/Navbar";
import { useToast } from "@/hooks/use-toast";

const DestinationPage = () => {
  const { slug } = useParams<{ slug: string }>();
  const navigate = useNavigate();
  const { data: destination, isLoading } = useDestination(slug || "");
  const { data: reviews } = useDestinationReviews(destination?.id || "");
  const { user } = useAuth();
  const { data: saved } = useSavedDestinations(user?.id);
  const toggleSave = useToggleSave();
  const { toast } = useToast();

  const isSaved = saved?.some((s: any) => s.destination_id === destination?.id) || false;

  const handleSave = () => {
    if (!user) {
      navigate("/auth");
      return;
    }
    toggleSave.mutate({ userId: user.id, destinationId: destination!.id, isSaved });
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!destination) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="text-muted-foreground font-body">Destination not found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-16">
        {/* Hero */}
        <div className="relative h-[50vh] overflow-hidden">
          {destination.image_url ? (
            <img src={destination.image_url} alt={destination.title} className="w-full h-full object-cover" />
          ) : (
            <div className="w-full h-full bg-gradient-forest" />
          )}
          <div className="absolute inset-0 bg-gradient-to-t from-background via-background/40 to-transparent" />
          <div className="absolute bottom-0 left-0 right-0 p-6 container mx-auto">
            <button onClick={() => navigate(-1)} className="flex items-center gap-2 text-foreground/80 hover:text-foreground mb-4 font-body text-sm">
              <ArrowLeft className="w-4 h-4" /> Back
            </button>
            <div className="flex items-start justify-between">
              <div>
                <span className="text-primary font-body text-xs uppercase tracking-widest">{(destination as any).categories?.name}</span>
                <h1 className="font-display font-bold text-4xl md:text-6xl text-foreground mt-1">{destination.title}</h1>
                <div className="flex items-center gap-4 mt-3">
                  <span className="flex items-center gap-1 font-body text-sm text-muted-foreground">
                    <MapPin className="w-4 h-4" /> {destination.location}, {destination.country}
                  </span>
                  <span className="flex items-center gap-1 font-body text-sm text-primary">
                    <Star className="w-4 h-4 fill-primary" /> {destination.avg_rating} ({destination.review_count} reviews)
                  </span>
                </div>
              </div>
              <div className="flex gap-2">
                <Button variant="outline" size="icon" onClick={handleSave} className={isSaved ? "text-red-500 border-red-500/30" : ""}>
                  <Heart className={`w-5 h-5 ${isSaved ? "fill-current" : ""}`} />
                </Button>
                <Button variant="outline" size="icon">
                  <Share2 className="w-5 h-5" />
                </Button>
              </div>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="container mx-auto px-6 py-12">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2 space-y-8">
              <div>
                <h2 className="font-display font-semibold text-2xl text-foreground mb-4">About this trail</h2>
                <p className="font-body text-muted-foreground leading-relaxed">{destination.description}</p>
              </div>

              {/* Quick Info */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                  { label: "Difficulty", value: destination.difficulty, icon: Mountain },
                  { label: "Duration", value: destination.duration, icon: Clock },
                  { label: "Distance", value: destination.distance_km ? `${destination.distance_km} km` : "N/A", icon: MapPin },
                  { label: "Elevation", value: destination.elevation_m ? `${destination.elevation_m}m` : "N/A", icon: Mountain },
                ].map((item) => (
                  <div key={item.label} className="glass-card rounded-xl p-4">
                    <item.icon className="w-5 h-5 text-primary mb-2" />
                    <p className="font-body text-xs text-muted-foreground">{item.label}</p>
                    <p className="font-display font-semibold text-foreground">{item.value}</p>
                  </div>
                ))}
              </div>

              {/* Tags */}
              {destination.tags && destination.tags.length > 0 && (
                <div className="flex flex-wrap gap-2">
                  {destination.tags.map((tag: string) => (
                    <span key={tag} className="font-body text-xs bg-muted text-muted-foreground px-3 py-1 rounded-full">
                      #{tag}
                    </span>
                  ))}
                </div>
              )}

              {/* Reviews */}
              <div>
                <h2 className="font-display font-semibold text-2xl text-foreground mb-4">
                  Reviews ({destination.review_count})
                </h2>
                {reviews && reviews.length > 0 ? (
                  <div className="space-y-4">
                    {reviews.map((review: any) => (
                      <div key={review.id} className="glass-card rounded-xl p-5">
                        <div className="flex items-center gap-3 mb-3">
                          <div className="w-8 h-8 rounded-full bg-gradient-amber flex items-center justify-center font-display font-bold text-xs text-primary-foreground">
                            {review.profiles?.display_name?.[0]?.toUpperCase() || "?"}
                          </div>
                          <div>
                            <p className="font-display font-semibold text-sm text-foreground">{review.profiles?.display_name}</p>
                            <div className="flex gap-0.5">
                              {Array.from({ length: review.rating }).map((_, i) => (
                                <Star key={i} className="w-3 h-3 text-primary fill-primary" />
                              ))}
                            </div>
                          </div>
                        </div>
                        {review.title && <p className="font-display font-semibold text-foreground mb-1">{review.title}</p>}
                        <p className="font-body text-sm text-muted-foreground">{review.content}</p>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="font-body text-muted-foreground">No reviews yet. Be the first to share your experience!</p>
                )}
              </div>
            </div>

            {/* Sidebar */}
            <div className="space-y-6">
              <div className="glass-card rounded-xl p-6 sticky top-24">
                <h3 className="font-display font-semibold text-lg text-foreground mb-4">Plan your trip</h3>
                <p className="font-body text-sm text-muted-foreground mb-4">
                  Best season: <span className="text-foreground">{destination.best_season || "Year-round"}</span>
                </p>
                <Button
                  className="w-full bg-gradient-amber text-primary-foreground font-display font-semibold shadow-amber mb-3"
                  onClick={() => user ? navigate(`/trips?destination=${destination.id}`) : navigate("/auth")}
                >
                  Start Planning
                </Button>
                <Button variant="outline" className="w-full font-display" onClick={handleSave}>
                  <Heart className={`w-4 h-4 mr-2 ${isSaved ? "fill-red-500 text-red-500" : ""}`} />
                  {isSaved ? "Saved" : "Save for Later"}
                </Button>

                {/* App CTA */}
                <div className="mt-6 p-4 rounded-xl bg-gradient-forest">
                  <div className="flex items-center gap-2 mb-2">
                    <Smartphone className="w-5 h-5 text-primary" />
                    <span className="font-display font-semibold text-sm text-foreground">Get the App</span>
                  </div>
                  <p className="font-body text-xs text-muted-foreground mb-3">
                    Use AR trail scanning, offline maps & group sync on the trail
                  </p>
                  <Button size="sm" className="w-full bg-gradient-amber text-primary-foreground font-display text-xs">
                    Download Dravik App
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DestinationPage;

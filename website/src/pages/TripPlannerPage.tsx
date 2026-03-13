import { useEffect, useMemo, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { motion } from "framer-motion";
import { CalendarPlus, Trash2, Route, CalendarDays, ShieldAlert } from "lucide-react";
import Navbar from "@/components/Navbar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useToast } from "@/hooks/use-toast";
import { Tables } from "@/integrations/supabase/types";
import {
  useAuth,
  useCreateTrip,
  useDeleteTrip,
  useUpdateTripStatus,
  useUserTrips,
} from "@/hooks/useAuth";
import { useDestinations } from "@/hooks/useDestinations";
import { useTripSafetyAnalyzer } from "@/hooks/useTripSafety";

const tripStatuses = ["planning", "upcoming", "active", "completed", "cancelled"];

type DestinationRow = Tables<"destinations">;
type TripRow = Tables<"trips"> & {
  destinations?: {
    title: string;
    slug: string;
    image_url: string | null;
    difficulty: string | null;
    elevation_m: number | null;
    best_season: string | null;
    country: string | null;
    location: string | null;
  } | null;
};

const getErrorMessage = (err: unknown) => {
  if (err instanceof Error) return err.message;
  return "Something went wrong.";
};

const TripPlannerPage = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const { toast } = useToast();
  const { user, loading } = useAuth();

  const preselectedDestination = searchParams.get("destination") || "";

  const { data: destinations } = useDestinations({ limit: 100 });
  const { data: trips } = useUserTrips(user?.id);
  const createTrip = useCreateTrip();
  const updateTripStatus = useUpdateTripStatus();
  const deleteTrip = useDeleteTrip();

  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [destinationId, setDestinationId] = useState(preselectedDestination);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [notes, setNotes] = useState("");

  useEffect(() => {
    if (!loading && !user) navigate("/auth");
  }, [user, loading, navigate]);

  useEffect(() => {
    if (preselectedDestination) {
      setDestinationId(preselectedDestination);
    }
  }, [preselectedDestination]);

  const destinationOptions = useMemo(() => destinations || [], [destinations]);
  const safetySummary = useTripSafetyAnalyzer((trips as TripRow[]) || []);

  const handleCreateTrip = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!user) return;
    if (!title.trim()) {
      toast({ title: "Trip title required", description: "Please add a title.", variant: "destructive" });
      return;
    }

    try {
      await createTrip.mutateAsync({
        userId: user.id,
        title: title.trim(),
        description: description.trim() || undefined,
        destinationId: destinationId || undefined,
        startDate: startDate || undefined,
        endDate: endDate || undefined,
        status: "planning",
        notes: notes.trim() || undefined,
      });

      setTitle("");
      setDescription("");
      setDestinationId("");
      setStartDate("");
      setEndDate("");
      setNotes("");

      toast({ title: "Trip created", description: "Your plan has been saved." });
    } catch (err: unknown) {
      toast({
        title: "Could not create trip",
        description: getErrorMessage(err),
        variant: "destructive",
      });
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Trip <span className="text-gradient-amber">Planner</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            Build trek plans, manage status, and keep all itinerary notes in one place.
          </p>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
            <form onSubmit={handleCreateTrip} className="glass-card rounded-2xl p-6 space-y-4">
              <h2 className="font-display font-semibold text-xl text-foreground flex items-center gap-2">
                <CalendarPlus className="w-5 h-5 text-primary" /> Create a New Trip
              </h2>

              <Input
                placeholder="Trip title"
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                className="bg-muted border-border font-body"
                required
              />

              <Input
                placeholder="Short description"
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                className="bg-muted border-border font-body"
              />

              <select
                value={destinationId}
                onChange={(e) => setDestinationId(e.target.value)}
                className="w-full h-10 rounded-md border border-border bg-muted px-3 font-body text-sm"
                aria-label="Destination selection"
                title="Destination selection"
              >
                <option value="">Select destination (optional)</option>
                {destinationOptions.map((dest: DestinationRow) => (
                  <option key={dest.id} value={dest.id}>
                    {dest.title} ({dest.country})
                  </option>
                ))}
              </select>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                <Input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} className="bg-muted border-border font-body" />
                <Input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} className="bg-muted border-border font-body" />
              </div>

              <textarea
                placeholder="Route notes, checklist, waypoints..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="w-full min-h-24 rounded-md border border-border bg-muted p-3 font-body text-sm"
              />

              <Button
                type="submit"
                className="w-full bg-gradient-amber text-primary-foreground font-display"
                disabled={createTrip.isPending}
              >
                {createTrip.isPending ? "Saving..." : "Create Trip"}
              </Button>
            </form>

            <div className="glass-card rounded-2xl p-6">
              <h2 className="font-display font-semibold text-xl text-foreground flex items-center gap-2 mb-4">
                <Route className="w-5 h-5 text-primary" /> Your Trips
              </h2>

              <div className="rounded-xl bg-muted/40 p-4 mb-4">
                <p className="font-body text-xs text-muted-foreground uppercase tracking-wider mb-1">Safety Overview</p>
                <p className="font-display text-sm text-foreground">
                  {safetySummary.highRiskCount} high risk • {safetySummary.moderateRiskCount} moderate risk
                </p>
              </div>

              {trips && trips.length > 0 ? (
                <div className="space-y-3">
                  {(trips as TripRow[]).map((trip: TripRow) => (
                    <div key={trip.id} className="rounded-xl border border-border/60 p-4 bg-muted/30">
                      <div className="flex items-start justify-between gap-3">
                        <div>
                          <p className="font-display font-semibold text-foreground">{trip.title}</p>
                          <p className="font-body text-xs text-muted-foreground mt-0.5">
                            {trip.destinations?.title || "No destination selected"}
                          </p>
                        </div>
                        <button
                          onClick={async () => {
                            try {
                              await deleteTrip.mutateAsync(trip.id);
                              toast({ title: "Trip deleted" });
                            } catch (err: unknown) {
                              toast({ title: "Delete failed", description: getErrorMessage(err), variant: "destructive" });
                            }
                          }}
                          className="text-destructive hover:opacity-80"
                          aria-label="Delete trip"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>

                      <div className="flex flex-wrap items-center gap-3 mt-3">
                        <span className="font-body text-xs text-muted-foreground flex items-center gap-1">
                          <CalendarDays className="w-3.5 h-3.5" />
                          {trip.start_date || "No start"} - {trip.end_date || "No end"}
                        </span>

                        <select
                          value={trip.status || "planning"}
                          onChange={async (e) => {
                            try {
                              await updateTripStatus.mutateAsync({ tripId: trip.id, status: e.target.value });
                            } catch (err: unknown) {
                              toast({ title: "Status update failed", description: getErrorMessage(err), variant: "destructive" });
                            }
                          }}
                          className="h-8 rounded-md border border-border bg-background px-2 font-body text-xs"
                          aria-label="Trip status"
                          title="Trip status"
                        >
                          {tripStatuses.map((status) => (
                            <option key={status} value={status}>
                              {status}
                            </option>
                          ))}
                        </select>

                        {safetySummary.byTripId.get(trip.id) && (
                          <span className={`font-body text-xs px-2 py-1 rounded-full flex items-center gap-1 ${
                            safetySummary.byTripId.get(trip.id)?.level === "High"
                              ? "bg-destructive/20 text-destructive"
                              : safetySummary.byTripId.get(trip.id)?.level === "Moderate"
                                ? "bg-primary/20 text-primary"
                                : "bg-accent/30 text-accent-foreground"
                          }`}>
                            <ShieldAlert className="w-3.5 h-3.5" />
                            {safetySummary.byTripId.get(trip.id)?.level} risk ({safetySummary.byTripId.get(trip.id)?.score})
                          </span>
                        )}
                      </div>

                      {(trip.description || trip.notes) && (
                        <p className="font-body text-xs text-muted-foreground mt-3 leading-relaxed">
                          {trip.description || trip.notes}
                        </p>
                      )}

                      {safetySummary.byTripId.get(trip.id) && (
                        <div className="mt-3 rounded-lg bg-background/70 p-3">
                          <p className="font-body text-xs text-muted-foreground mb-1">Safety Recommendation</p>
                          <p className="font-body text-xs text-foreground mb-2">
                            {safetySummary.byTripId.get(trip.id)?.recommendation}
                          </p>
                          <p className="font-body text-xs text-muted-foreground">
                            Factors: {(safetySummary.byTripId.get(trip.id)?.factors || []).join(" • ") || "No major risk factors"}
                          </p>
                        </div>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <div className="rounded-xl border border-dashed border-border p-6 text-center">
                  <p className="font-body text-muted-foreground">No trips yet. Create your first itinerary.</p>
                </div>
              )}
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default TripPlannerPage;

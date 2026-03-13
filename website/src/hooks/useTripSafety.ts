import { useMemo } from "react";
import { Tables } from "@/integrations/supabase/types";

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

export type TripRiskResult = {
  tripId: string;
  score: number;
  level: "Low" | "Moderate" | "High";
  factors: string[];
  recommendation: string;
};

const difficultyRisk = (difficulty?: string | null) => {
  switch (difficulty) {
    case "Expert":
      return 4;
    case "Advanced":
      return 3;
    case "Challenging":
      return 2;
    case "Moderate":
      return 1;
    default:
      return 0;
  }
};

const dateDistanceRisk = (startDate?: string | null) => {
  if (!startDate) return 2;
  const ms = new Date(startDate).getTime() - Date.now();
  const days = ms / (1000 * 60 * 60 * 24);
  if (days < 2) return 3;
  if (days < 7) return 2;
  if (days < 14) return 1;
  return 0;
};

const elevationRisk = (elevation?: number | null) => {
  if (!elevation) return 0;
  if (elevation >= 4500) return 4;
  if (elevation >= 3500) return 3;
  if (elevation >= 2500) return 2;
  if (elevation >= 1500) return 1;
  return 0;
};

export const useTripSafetyAnalyzer = (trips?: TripRow[] | null) => {
  return useMemo(() => {
    const items = (trips || []).map<TripRiskResult>((trip) => {
      const factors: string[] = [];
      let score = 0;

      const diffRisk = difficultyRisk(trip.destinations?.difficulty);
      if (diffRisk > 0) {
        score += diffRisk;
        factors.push(`Difficulty: ${trip.destinations?.difficulty}`);
      }

      const elevRisk = elevationRisk(trip.destinations?.elevation_m);
      if (elevRisk > 0) {
        score += elevRisk;
        factors.push(`Elevation: ${trip.destinations?.elevation_m}m`);
      }

      const timingRisk = dateDistanceRisk(trip.start_date);
      if (timingRisk > 0) {
        score += timingRisk;
        factors.push("Trip starts soon");
      }

      if (!trip.notes || trip.notes.trim().length < 12) {
        score += 1;
        factors.push("Limited contingency notes");
      }

      if (!trip.destinations) {
        score += 2;
        factors.push("No destination profile linked");
      }

      const level: TripRiskResult["level"] = score >= 8 ? "High" : score >= 4 ? "Moderate" : "Low";

      const recommendation =
        level === "High"
          ? "Add fallback route, confirm weather window, and plan emergency contacts before departure."
          : level === "Moderate"
            ? "Review weather and route checkpoints, then finalize backup transport and gear checklist."
            : "Trip risk profile is stable. Keep a lightweight emergency plan and check conditions 24h before start.";

      return {
        tripId: trip.id,
        score,
        level,
        factors,
        recommendation,
      };
    });

    return {
      byTripId: new Map(items.map((item) => [item.tripId, item])),
      highRiskCount: items.filter((item) => item.level === "High").length,
      moderateRiskCount: items.filter((item) => item.level === "Moderate").length,
      items,
    };
  }, [trips]);
};

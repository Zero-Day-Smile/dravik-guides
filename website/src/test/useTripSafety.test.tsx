import { renderHook } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import { useTripSafetyAnalyzer } from "@/hooks/useTripSafety";
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

const buildTrip = (overrides: Partial<TripRow>): TripRow => ({
  id: "trip-1",
  user_id: "user-1",
  title: "Test Trip",
  description: null,
  destination_id: null,
  start_date: null,
  end_date: null,
  status: "planning",
  gear_checklist: null,
  notes: "Standard contingency notes available.",
  is_public: false,
  created_at: new Date().toISOString(),
  updated_at: new Date().toISOString(),
  destinations: null,
  ...overrides,
});

describe("useTripSafetyAnalyzer", () => {
  it("flags high-risk trips with severe factors", () => {
    const soon = new Date(Date.now() + 1000 * 60 * 60 * 24).toISOString().slice(0, 10);

    const trip = buildTrip({
      id: "high-1",
      start_date: soon,
      notes: "short",
      destinations: {
        title: "Steep Summit",
        slug: "steep-summit",
        image_url: null,
        difficulty: "Expert",
        elevation_m: 5200,
        best_season: null,
        country: "Nepal",
        location: "Khumbu",
      },
    });

    const { result } = renderHook(() => useTripSafetyAnalyzer([trip]));
    const risk = result.current.byTripId.get("high-1");

    expect(risk).toBeDefined();
    expect(risk?.level).toBe("High");
    expect(risk?.score).toBeGreaterThanOrEqual(8);
    expect(result.current.highRiskCount).toBe(1);
  });

  it("keeps low-risk trips in low bucket", () => {
    const later = new Date(Date.now() + 1000 * 60 * 60 * 24 * 30).toISOString().slice(0, 10);

    const trip = buildTrip({
      id: "low-1",
      start_date: later,
      notes: "Detailed route with fallback shelter, contact plans, and weather checks.",
      destinations: {
        title: "Valley Walk",
        slug: "valley-walk",
        image_url: null,
        difficulty: "Easy",
        elevation_m: 900,
        best_season: null,
        country: "India",
        location: "Himachal",
      },
    });

    const { result } = renderHook(() => useTripSafetyAnalyzer([trip]));
    const risk = result.current.byTripId.get("low-1");

    expect(risk).toBeDefined();
    expect(risk?.level).toBe("Low");
    expect(result.current.highRiskCount).toBe(0);
    expect(result.current.moderateRiskCount).toBe(0);
  });
});

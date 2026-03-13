import { act, renderHook } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useActivityTracker } from "@/hooks/useActivityTracker";

const oneHour = 1000 * 60 * 60;
const trackerStorageKey = "dravik.website.activity.sessions";

const resetActivityStorage = () => {
  const storage = window.localStorage as unknown as {
    clear?: () => void;
    removeItem?: (key: string) => void;
  };

  if (typeof storage.clear === "function") {
    storage.clear();
    return;
  }

  if (typeof storage.removeItem === "function") {
    storage.removeItem(trackerStorageKey);
  }
};

describe("useActivityTracker", () => {
  beforeEach(() => {
    resetActivityStorage();
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2026-01-01T00:00:00.000Z"));

    vi.spyOn(crypto, "randomUUID").mockReturnValue("session-1");
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it("starts and stops a session with estimated distance", () => {
    const { result } = renderHook(() => useActivityTracker());
    expect(result.current.sessions.length).toBe(0);

    act(() => {
      result.current.startSession("hiking", "Morning ridge run");
    });

    expect(result.current.activeSession).not.toBeNull();
    expect(result.current.sessions[0].mode).toBe("hiking");

    vi.setSystemTime(new Date(Date.now() + oneHour * 2));

    act(() => {
      result.current.stopSession();
    });

    expect(result.current.activeSession).toBeNull();
    expect(result.current.sessions[0].estimatedDistanceKm).toBeCloseTo(8, 2);
    expect(result.current.stats.totalSessions).toBe(1);
    expect(result.current.stats.totalDistanceKm).toBeCloseTo(8, 2);
  });

  it("prevents starting a second active session", () => {
    const { result } = renderHook(() => useActivityTracker());
    expect(result.current.sessions.length).toBe(0);

    act(() => {
      result.current.startSession("running", "Session A");
      result.current.startSession("cycling", "Session B");
    });

    expect(result.current.sessions.length).toBe(1);
    expect(result.current.activeSession?.mode).toBe("running");
  });
});

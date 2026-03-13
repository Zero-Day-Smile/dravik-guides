import { useEffect, useMemo, useState } from "react";

export type ActivitySession = {
  id: string;
  startedAt: string;
  endedAt: string | null;
  mode: "hiking" | "running" | "cycling";
  notes: string;
  estimatedDistanceKm: number;
};

const STORAGE_KEY = "dravik.website.activity.sessions";

const paceByMode: Record<ActivitySession["mode"], number> = {
  hiking: 4,
  running: 8,
  cycling: 15,
};

const readSessions = (): ActivitySession[] => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? (JSON.parse(raw) as ActivitySession[]) : [];
  } catch {
    return [];
  }
};

const writeSessions = (sessions: ActivitySession[]) => {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(sessions));
};

export const useActivityTracker = () => {
  const [sessions, setSessions] = useState<ActivitySession[]>([]);

  useEffect(() => {
    setSessions(readSessions());
  }, []);

  useEffect(() => {
    writeSessions(sessions);
  }, [sessions]);

  const activeSession = useMemo(() => sessions.find((s) => s.endedAt === null) || null, [sessions]);

  const startSession = (mode: ActivitySession["mode"], notes: string) => {
    setSessions((prev) => {
      const hasActive = prev.some((session) => session.endedAt === null);
      if (hasActive) return prev;

      const session: ActivitySession = {
        id: crypto.randomUUID(),
        startedAt: new Date().toISOString(),
        endedAt: null,
        mode,
        notes,
        estimatedDistanceKm: 0,
      };

      return [session, ...prev];
    });
  };

  const stopSession = () => {
    if (!activeSession) return;

    const now = new Date();
    const started = new Date(activeSession.startedAt);
    const hours = Math.max(0, (now.getTime() - started.getTime()) / (1000 * 60 * 60));
    const distance = Number((hours * paceByMode[activeSession.mode]).toFixed(2));

    setSessions((prev) =>
      prev.map((session) =>
        session.id === activeSession.id
          ? { ...session, endedAt: now.toISOString(), estimatedDistanceKm: distance }
          : session,
      ),
    );
  };

  const clearHistory = () => {
    setSessions([]);
  };

  const stats = useMemo(() => {
    const completed = sessions.filter((s) => s.endedAt !== null);
    const totalDistance = completed.reduce((acc, s) => acc + s.estimatedDistanceKm, 0);
    const totalSessions = completed.length;

    const uniqueDays = new Set(
      completed.map((s) => new Date(s.startedAt).toISOString().slice(0, 10)),
    );

    return {
      totalDistanceKm: Number(totalDistance.toFixed(2)),
      totalSessions,
      streakDays: uniqueDays.size,
    };
  }, [sessions]);

  return {
    sessions,
    activeSession,
    stats,
    startSession,
    stopSession,
    clearHistory,
  };
};

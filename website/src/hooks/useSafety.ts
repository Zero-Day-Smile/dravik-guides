import { useEffect, useMemo, useState } from "react";

export type EmergencyContact = {
  region: string;
  number: string;
  note: string;
};

export type SafetyCheckIn = {
  id: string;
  message: string;
  location: string;
  createdAt: string;
};

export type SosEvent = {
  id: string;
  reason: string;
  location: string;
  createdAt: string;
};

const CONTACTS_KEY = "dravik.website.safety.contacts";
const CHECKINS_KEY = "dravik.website.safety.checkins";
const SOS_KEY = "dravik.website.safety.sos";

const readJson = <T,>(key: string, fallback: T): T => {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
};

const writeJson = <T,>(key: string, value: T) => {
  localStorage.setItem(key, JSON.stringify(value));
};

export const useSafetyState = (defaultContacts: EmergencyContact[]) => {
  const [contacts, setContacts] = useState<EmergencyContact[]>([]);
  const [checkIns, setCheckIns] = useState<SafetyCheckIn[]>([]);
  const [sosEvents, setSosEvents] = useState<SosEvent[]>([]);

  useEffect(() => {
    setContacts(readJson<EmergencyContact[]>(CONTACTS_KEY, defaultContacts));
    setCheckIns(readJson<SafetyCheckIn[]>(CHECKINS_KEY, []));
    setSosEvents(readJson<SosEvent[]>(SOS_KEY, []));
  }, [defaultContacts]);

  useEffect(() => {
    if (contacts.length > 0) writeJson(CONTACTS_KEY, contacts);
  }, [contacts]);

  useEffect(() => {
    writeJson(CHECKINS_KEY, checkIns);
  }, [checkIns]);

  useEffect(() => {
    writeJson(SOS_KEY, sosEvents);
  }, [sosEvents]);

  const createCheckIn = (message: string, location: string) => {
    const item: SafetyCheckIn = {
      id: crypto.randomUUID(),
      message,
      location,
      createdAt: new Date().toISOString(),
    };
    setCheckIns((prev) => [item, ...prev].slice(0, 25));
    return item;
  };

  const triggerSos = (reason: string, location: string) => {
    const item: SosEvent = {
      id: crypto.randomUUID(),
      reason,
      location,
      createdAt: new Date().toISOString(),
    };
    setSosEvents((prev) => [item, ...prev].slice(0, 25));
    return item;
  };

  const addEmergencyContact = (contact: EmergencyContact) => {
    setContacts((prev) => [contact, ...prev]);
  };

  const removeEmergencyContact = (region: string, number: string) => {
    setContacts((prev) => prev.filter((c) => !(c.region === region && c.number === number)));
  };

  const metrics = useMemo(
    () => ({
      checkInCount: checkIns.length,
      sosCount: sosEvents.length,
      contactCount: contacts.length,
      latestCheckInAt: checkIns[0]?.createdAt || null,
    }),
    [checkIns, sosEvents, contacts],
  );

  return {
    contacts,
    checkIns,
    sosEvents,
    metrics,
    createCheckIn,
    triggerSos,
    addEmergencyContact,
    removeEmergencyContact,
  };
};

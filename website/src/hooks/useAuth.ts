import { supabase } from "@/integrations/supabase/client";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import type { User } from "@supabase/supabase-js";

export const useAuth = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string, displayName: string) => {
    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: { display_name: displayName },
        emailRedirectTo: window.location.origin,
      },
    });
    return { data, error };
  };

  const signIn = async (email: string, password: string) => {
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    return { data, error };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  const resetPassword = async (email: string) => {
    const { data, error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth`,
    });
    return { data, error };
  };

  return { user, loading, signUp, signIn, signOut, resetPassword };
};

export const useProfile = (userId?: string) => {
  return useQuery({
    queryKey: ["profile", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .eq("user_id", userId!)
        .single();
      if (error) throw error;
      return data;
    },
    enabled: !!userId,
  });
};

export const useSavedDestinations = (userId?: string) => {
  return useQuery({
    queryKey: ["saved_destinations", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("saved_destinations")
        .select("*, destinations(*, categories(name))")
        .eq("user_id", userId!);
      if (error) throw error;
      return data;
    },
    enabled: !!userId,
  });
};

export const useToggleSave = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async ({ userId, destinationId, isSaved }: { userId: string; destinationId: string; isSaved: boolean }) => {
      if (isSaved) {
        const { error } = await supabase.from("saved_destinations").delete().eq("user_id", userId).eq("destination_id", destinationId);
        if (error) throw error;
      } else {
        const { error } = await supabase.from("saved_destinations").insert({ user_id: userId, destination_id: destinationId });
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["saved_destinations"] });
    },
  });
};

export const useUserTrips = (userId?: string) => {
  return useQuery({
    queryKey: ["trips", userId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("trips")
        .select("*, destinations(title, slug, image_url, difficulty, elevation_m, best_season, country, location)")
        .eq("user_id", userId!)
        .order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
    enabled: !!userId,
  });
};

export const useCreateTrip = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (payload: {
      userId: string;
      title: string;
      description?: string;
      destinationId?: string;
      startDate?: string;
      endDate?: string;
      status?: string;
      notes?: string;
      isPublic?: boolean;
    }) => {
      const { error } = await supabase.from("trips").insert({
        user_id: payload.userId,
        title: payload.title,
        description: payload.description || null,
        destination_id: payload.destinationId || null,
        start_date: payload.startDate || null,
        end_date: payload.endDate || null,
        status: payload.status || "planning",
        notes: payload.notes || null,
        is_public: payload.isPublic || false,
      });

      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trips"] });
    },
  });
};

export const useUpdateTripStatus = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async ({ tripId, status }: { tripId: string; status: string }) => {
      const { error } = await supabase.from("trips").update({ status }).eq("id", tripId);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trips"] });
    },
  });
};

export const useDeleteTrip = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (tripId: string) => {
      const { error } = await supabase.from("trips").delete().eq("id", tripId);
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["trips"] });
    },
  });
};

import { supabase } from "@/integrations/supabase/client";
import { useQuery } from "@tanstack/react-query";

export const useCategories = () => {
  return useQuery({
    queryKey: ["categories"],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("categories")
        .select("*")
        .order("name");
      if (error) throw error;
      return data;
    },
  });
};

export const useDestinations = (filters?: {
  category?: string;
  difficulty?: string;
  country?: string;
  search?: string;
  featured?: boolean;
  trending?: boolean;
  limit?: number;
}) => {
  return useQuery({
    queryKey: ["destinations", filters],
    queryFn: async () => {
      let query = supabase.from("destinations").select("*, categories(name, slug)");

      if (filters?.category) query = query.eq("category_id", filters.category);
      if (filters?.difficulty) query = query.eq("difficulty", filters.difficulty);
      if (filters?.country) query = query.eq("country", filters.country);
      if (filters?.featured) query = query.eq("is_featured", true);
      if (filters?.trending) query = query.eq("is_trending", true);
      if (filters?.search) query = query.ilike("title", `%${filters.search}%`);
      if (filters?.limit) query = query.limit(filters.limit);

      query = query.order("review_count", { ascending: false });

      const { data, error } = await query;
      if (error) throw error;
      return data;
    },
  });
};

export const useDestination = (slug: string) => {
  return useQuery({
    queryKey: ["destination", slug],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("destinations")
        .select("*, categories(name, slug)")
        .eq("slug", slug)
        .single();
      if (error) throw error;
      return data;
    },
    enabled: !!slug,
  });
};

export const useDestinationReviews = (destinationId: string) => {
  return useQuery({
    queryKey: ["reviews", destinationId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("reviews")
        .select("*, profiles(display_name, avatar_url)")
        .eq("destination_id", destinationId)
        .order("created_at", { ascending: false });
      if (error) throw error;
      return data;
    },
    enabled: !!destinationId,
  });
};

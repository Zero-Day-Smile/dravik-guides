import { supabase } from "@/integrations/supabase/client";
import type { TablesInsert } from "@/integrations/supabase/types";

export type ImportFormat = "json" | "csv";

type RawRecord = Record<string, string>;

export type NormalizedImportRow = Omit<TablesInsert<"destinations">, "category_id"> & {
  categorySlug: string;
  categoryName: string;
};

export type ParseImportResult = {
  rows: NormalizedImportRow[];
  warnings: string[];
};

export type ImportExecutionResult = {
  destinationsProcessed: number;
  categoriesCreated: number;
  destinationsCreated: number;
  destinationsUpdated: number;
  auditLogged: boolean;
};

export type DryRunResult = {
  totalRows: number;
  distinctCategoriesInFile: number;
  categoriesThatWillBeCreated: string[];
  destinationSlugsNew: string[];
  destinationSlugsExisting: string[];
};

export type ImportRunRow = {
  id: string;
  created_at: string;
  status: string;
  source_format: string;
  actor_email: string | null;
  total_rows: number;
  warnings_count: number;
  categories_created: number;
  destinations_processed: number;
  destinations_created: number;
  destinations_updated: number;
  error_message: string | null;
};

type ImportAuditContext = {
  actorUserId?: string;
  actorEmail?: string;
  sourceFormat?: ImportFormat;
  warningsCount?: number;
};

const DIFFICULTIES = new Set(["Easy", "Moderate", "Challenging", "Advanced", "Expert"]);

const normalizeKey = (key: string) => key.trim().toLowerCase().replace(/[\s-]+/g, "_");

const toSlug = (input: string) =>
  input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");

const toTitleCase = (value: string) =>
  value
    .replace(/[_-]+/g, " ")
    .split(" ")
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");

const parseNumber = (value: string | undefined): number | null => {
  if (!value) return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
};

const parseBoolean = (value: string | undefined): boolean => {
  if (!value) return false;
  return ["1", "true", "yes", "y"].includes(value.trim().toLowerCase());
};

const parseTextList = (value: string | undefined): string[] => {
  if (!value) return [];
  return value
    .split(/[|,;]/g)
    .map((part) => part.trim())
    .filter(Boolean);
};

const parseCsv = (input: string): RawRecord[] => {
  const rows: string[][] = [];
  let currentCell = "";
  let currentRow: string[] = [];
  let inQuotes = false;

  const pushCell = () => {
    currentRow.push(currentCell);
    currentCell = "";
  };

  const pushRow = () => {
    if (currentRow.length === 1 && currentRow[0].trim() === "") {
      currentRow = [];
      return;
    }
    rows.push(currentRow);
    currentRow = [];
  };

  for (let i = 0; i < input.length; i += 1) {
    const char = input[i];
    const nextChar = input[i + 1];

    if (char === '"') {
      if (inQuotes && nextChar === '"') {
        currentCell += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === "," && !inQuotes) {
      pushCell();
      continue;
    }

    if ((char === "\n" || char === "\r") && !inQuotes) {
      if (char === "\r" && nextChar === "\n") i += 1;
      pushCell();
      pushRow();
      continue;
    }

    currentCell += char;
  }

  if (currentCell.length > 0 || currentRow.length > 0) {
    pushCell();
    pushRow();
  }

  if (rows.length === 0) return [];

  const headers = rows[0].map((header) => normalizeKey(header));
  const records: RawRecord[] = [];

  for (let index = 1; index < rows.length; index += 1) {
    const sourceRow = rows[index];
    const record: RawRecord = {};
    headers.forEach((header, headerIndex) => {
      record[header] = (sourceRow[headerIndex] ?? "").trim();
    });
    records.push(record);
  }

  return records;
};

const parseJson = (input: string): RawRecord[] => {
  const parsed = JSON.parse(input) as unknown;

  const records = Array.isArray(parsed)
    ? parsed
    : typeof parsed === "object" && parsed !== null && Array.isArray((parsed as { destinations?: unknown }).destinations)
      ? ((parsed as { destinations: unknown[] }).destinations as unknown[])
      : null;

  if (!records) {
    throw new Error("JSON must be an array or an object with a destinations array.");
  }

  return records.map((value) => {
    if (typeof value !== "object" || value === null) {
      throw new Error("Each JSON item must be an object.");
    }

    const obj = value as Record<string, unknown>;
    const normalized: RawRecord = {};
    Object.entries(obj).forEach(([key, raw]) => {
      normalized[normalizeKey(key)] = raw == null ? "" : String(raw);
    });
    return normalized;
  });
};

const normalizeRawRecord = (record: RawRecord, rowNumber: number, warnings: string[]): NormalizedImportRow | null => {
  const title = record.title?.trim();
  if (!title) {
    warnings.push(`Row ${rowNumber}: skipped because title is missing.`);
    return null;
  }

  const categorySlugInput = record.category_slug?.trim() || record.category?.trim() || "";
  const categoryNameInput = record.category_name?.trim() || categorySlugInput;

  if (!categorySlugInput && !categoryNameInput) {
    warnings.push(`Row ${rowNumber}: skipped because category_slug/category_name is missing.`);
    return null;
  }

  const slug = record.slug?.trim() ? toSlug(record.slug) : toSlug(title);
  const difficultyRaw = record.difficulty?.trim();
  const difficulty = difficultyRaw && DIFFICULTIES.has(difficultyRaw) ? difficultyRaw : null;

  if (difficultyRaw && !difficulty) {
    warnings.push(`Row ${rowNumber}: difficulty '${difficultyRaw}' is invalid. Allowed: Easy, Moderate, Challenging, Advanced, Expert.`);
  }

  return {
    title,
    slug,
    description: record.description || null,
    location: record.location || null,
    country: record.country || null,
    continent: record.continent || null,
    latitude: parseNumber(record.latitude),
    longitude: parseNumber(record.longitude),
    difficulty,
    duration: record.duration || null,
    distance_km: parseNumber(record.distance_km),
    elevation_m: parseNumber(record.elevation_m),
    best_season: record.best_season || null,
    image_url: record.image_url || null,
    gallery: parseTextList(record.gallery),
    tags: parseTextList(record.tags),
    avg_rating: parseNumber(record.avg_rating) ?? 0,
    review_count: parseNumber(record.review_count) ?? 0,
    is_featured: parseBoolean(record.is_featured),
    is_trending: parseBoolean(record.is_trending),
    source_url: record.source_url || null,
    categorySlug: toSlug(categorySlugInput || categoryNameInput),
    categoryName: categoryNameInput ? toTitleCase(categoryNameInput) : toTitleCase(categorySlugInput),
  };
};

export const parseImportPayload = (input: string, format: ImportFormat): ParseImportResult => {
  const trimmed = input.trim();
  if (!trimmed) {
    throw new Error("Import payload is empty.");
  }

  const rawRecords = format === "json" ? parseJson(trimmed) : parseCsv(trimmed);
  const warnings: string[] = [];
  const rows: NormalizedImportRow[] = [];

  rawRecords.forEach((record, index) => {
    const normalized = normalizeRawRecord(record, index + 2, warnings);
    if (normalized) rows.push(normalized);
  });

  if (rows.length === 0) {
    throw new Error("No valid rows found. Check required fields: title + category_slug/category_name.");
  }

  return { rows, warnings };
};

export const detectImportFormat = (input: string): ImportFormat => {
  const trimmed = input.trim();
  if (trimmed.startsWith("[") || trimmed.startsWith("{")) return "json";
  return "csv";
};

const explainSupabaseError = (message: string) => {
  const lower = message.toLowerCase();
  if (lower.includes("row-level security") || lower.includes("permission denied")) {
    return "Import blocked by RLS. Ensure admin policies are applied and your user has role=admin in Supabase JWT app_metadata.";
  }
  return message;
};

const tryInsertImportAudit = async (payload: TablesInsert<"import_runs">): Promise<boolean> => {
  const { error } = await supabase.from("import_runs").insert(payload);
  return !error;
};

export const executeDestinationImport = async (
  rows: NormalizedImportRow[],
  context: ImportAuditContext = {},
): Promise<ImportExecutionResult> => {
  const categoryMap = new Map<string, { id: string; name: string }>();
  const categorySlugs = [...new Set(rows.map((row) => row.categorySlug))];
  const destinationSlugs = [...new Set(rows.map((row) => row.slug))];

  const { data: existingDestinations, error: existingDestinationsError } = await supabase
    .from("destinations")
    .select("slug")
    .in("slug", destinationSlugs);

  if (existingDestinationsError) {
    throw new Error(explainSupabaseError(existingDestinationsError.message));
  }

  const existingDestinationSet = new Set((existingDestinations ?? []).map((item) => item.slug));

  const { data: existingCategories, error: existingError } = await supabase
    .from("categories")
    .select("id, slug, name")
    .in("slug", categorySlugs);

  if (existingError) {
    throw new Error(explainSupabaseError(existingError.message));
  }

  (existingCategories ?? []).forEach((category) => {
    categoryMap.set(category.slug, { id: category.id, name: category.name });
  });

  const missingCategoryRows = categorySlugs
    .filter((slug) => !categoryMap.has(slug))
    .map((slug) => {
      const row = rows.find((item) => item.categorySlug === slug);
      return {
        slug,
        name: row?.categoryName ?? toTitleCase(slug),
      };
    });

  if (missingCategoryRows.length > 0) {
    const { error: createCategoriesError } = await supabase.from("categories").upsert(missingCategoryRows, { onConflict: "slug" });
    if (createCategoriesError) {
      const message = explainSupabaseError(createCategoriesError.message);
      await tryInsertImportAudit({
        actor_user_id: context.actorUserId ?? null,
        actor_email: context.actorEmail ?? null,
        source_format: context.sourceFormat ?? "csv",
        status: "failed",
        total_rows: rows.length,
        warnings_count: context.warningsCount ?? 0,
        error_message: message,
        metadata: {
          stage: "category-upsert",
        },
      });
      throw new Error(message);
    }

    const { data: refreshedCategories, error: refreshError } = await supabase
      .from("categories")
      .select("id, slug, name")
      .in("slug", categorySlugs);

    if (refreshError) {
      const message = explainSupabaseError(refreshError.message);
      await tryInsertImportAudit({
        actor_user_id: context.actorUserId ?? null,
        actor_email: context.actorEmail ?? null,
        source_format: context.sourceFormat ?? "csv",
        status: "failed",
        total_rows: rows.length,
        warnings_count: context.warningsCount ?? 0,
        error_message: message,
        metadata: {
          stage: "category-refresh",
        },
      });
      throw new Error(message);
    }

    (refreshedCategories ?? []).forEach((category) => {
      categoryMap.set(category.slug, { id: category.id, name: category.name });
    });
  }

  const destinationPayload: TablesInsert<"destinations">[] = rows.map((row) => {
    const category = categoryMap.get(row.categorySlug);
    if (!category) {
      throw new Error(`Missing category mapping for slug '${row.categorySlug}'.`);
    }

    return {
      title: row.title,
      slug: row.slug,
      description: row.description,
      location: row.location,
      country: row.country,
      continent: row.continent,
      latitude: row.latitude,
      longitude: row.longitude,
      difficulty: row.difficulty,
      duration: row.duration,
      distance_km: row.distance_km,
      elevation_m: row.elevation_m,
      best_season: row.best_season,
      image_url: row.image_url,
      gallery: row.gallery,
      tags: row.tags,
      category_id: category.id,
      avg_rating: row.avg_rating,
      review_count: row.review_count,
      is_featured: row.is_featured,
      is_trending: row.is_trending,
      source_url: row.source_url,
    };
  });

  const { error: importError } = await supabase.from("destinations").upsert(destinationPayload, { onConflict: "slug" });

  if (importError) {
    const message = explainSupabaseError(importError.message);
    await tryInsertImportAudit({
      actor_user_id: context.actorUserId ?? null,
      actor_email: context.actorEmail ?? null,
      source_format: context.sourceFormat ?? "csv",
      status: "failed",
      total_rows: rows.length,
      categories_created: missingCategoryRows.length,
      warnings_count: context.warningsCount ?? 0,
      error_message: message,
      metadata: {
        stage: "destination-upsert",
      },
    });
    throw new Error(message);
  }

  const destinationsUpdated = destinationPayload.filter((item) => existingDestinationSet.has(item.slug)).length;
  const destinationsCreated = destinationPayload.length - destinationsUpdated;

  const auditLogged = await tryInsertImportAudit({
    actor_user_id: context.actorUserId ?? null,
    actor_email: context.actorEmail ?? null,
    source_format: context.sourceFormat ?? "csv",
    status: "success",
    total_rows: rows.length,
    categories_created: missingCategoryRows.length,
    destinations_processed: destinationPayload.length,
    destinations_created: destinationsCreated,
    destinations_updated: destinationsUpdated,
    warnings_count: context.warningsCount ?? 0,
    metadata: {
      category_slugs: categorySlugs,
    },
  });

  return {
    destinationsProcessed: destinationPayload.length,
    categoriesCreated: missingCategoryRows.length,
    destinationsCreated,
    destinationsUpdated,
    auditLogged,
  };
};

export const analyzeDestinationImport = async (rows: NormalizedImportRow[]): Promise<DryRunResult> => {
  const categorySlugs = [...new Set(rows.map((row) => row.categorySlug))];
  const destinationSlugs = [...new Set(rows.map((row) => row.slug))];

  const { data: existingCategories, error: categoriesError } = await supabase
    .from("categories")
    .select("slug")
    .in("slug", categorySlugs);

  if (categoriesError) {
    throw new Error(explainSupabaseError(categoriesError.message));
  }

  const { data: existingDestinations, error: destinationsError } = await supabase
    .from("destinations")
    .select("slug")
    .in("slug", destinationSlugs);

  if (destinationsError) {
    throw new Error(explainSupabaseError(destinationsError.message));
  }

  const existingCategorySet = new Set((existingCategories ?? []).map((item) => item.slug));
  const existingDestinationSet = new Set((existingDestinations ?? []).map((item) => item.slug));

  const categoriesThatWillBeCreated = categorySlugs.filter((slug) => !existingCategorySet.has(slug));
  const destinationSlugsNew = destinationSlugs.filter((slug) => !existingDestinationSet.has(slug));
  const destinationSlugsExisting = destinationSlugs.filter((slug) => existingDestinationSet.has(slug));

  return {
    totalRows: rows.length,
    distinctCategoriesInFile: categorySlugs.length,
    categoriesThatWillBeCreated,
    destinationSlugsNew,
    destinationSlugsExisting,
  };
};

export const listRecentImportRuns = async (limit = 20): Promise<ImportRunRow[]> => {
  const { data, error } = await supabase
    .from("import_runs")
    .select(
      "id, created_at, status, source_format, actor_email, total_rows, warnings_count, categories_created, destinations_processed, destinations_created, destinations_updated, error_message",
    )
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) {
    throw new Error(explainSupabaseError(error.message));
  }

  return data ?? [];
};

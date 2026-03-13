import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Upload, ShieldAlert, Database, FileText, FlaskConical, ArrowUpDown, Download, ArrowUp, ArrowDown } from "lucide-react";
import Navbar from "@/components/Navbar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/hooks/useAuth";
import {
  analyzeDestinationImport,
  detectImportFormat,
  executeDestinationImport,
  type DryRunResult,
  type ImportRunRow,
  listRecentImportRuns,
  type NormalizedImportRow,
  parseImportPayload,
  type ImportFormat,
} from "@/services/adminImportService";

const templateCsv = `title,slug,category_slug,category_name,country,location,difficulty,duration,distance_km,elevation_m,latitude,longitude,best_season,tags,is_featured,is_trending,source_url\nEverest Base Camp Trek,everest-base-camp-trek,trekking,Trekking,Nepal,Khumbu Region,Challenging,12-14 days,130,5364,28.0043,86.8571,March-May|October-November,himalaya|altitude|base-camp,true,true,https://en.wikipedia.org/wiki/Everest_Base_Camp`;

const AdminImportPage = () => {
  const { user, loading } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();

  const [payload, setPayload] = useState(templateCsv);
  const [format, setFormat] = useState<ImportFormat>("csv");
  const [warnings, setWarnings] = useState<string[]>([]);
  const [parsedRows, setParsedRows] = useState<NormalizedImportRow[]>([]);
  const [isImporting, setIsImporting] = useState(false);
  const [isDraggingFile, setIsDraggingFile] = useState(false);
  const [isDryRunning, setIsDryRunning] = useState(false);
  const [dryRunResult, setDryRunResult] = useState<DryRunResult | null>(null);
  const [importRuns, setImportRuns] = useState<ImportRunRow[]>([]);
  const [isHistoryLoading, setIsHistoryLoading] = useState(false);
  const [statusFilter, setStatusFilter] = useState<"all" | "success" | "failed">("all");
  const [actorFilter, setActorFilter] = useState("");
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [sortBy, setSortBy] = useState<"created_at" | "status" | "actor_email" | "source_format" | "total_rows" | "destinations_created" | "destinations_updated">("created_at");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("desc");

  const loadImportHistory = useCallback(async () => {
    setIsHistoryLoading(true);
    try {
      const rows = await listRecentImportRuns(20);
      setImportRuns(rows);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to load import history.";
      toast({ title: "History load failed", description: message, variant: "destructive" });
    } finally {
      setIsHistoryLoading(false);
    }
  }, [toast]);

  const loadFile = async (file: File) => {
    const text = await file.text();
    setPayload(text);

    const extension = file.name.split(".").pop()?.toLowerCase();
    if (extension === "json") setFormat("json");
    if (extension === "csv") setFormat("csv");

    toast({ title: "File loaded", description: `${file.name} is ready to parse.` });
  };

  const isAdmin = useMemo(() => {
    if (!user) return false;

    const role = String(user.app_metadata?.role ?? user.user_metadata?.role ?? "").toLowerCase();
    if (role === "admin") return true;

    const adminEmails = String(import.meta.env.VITE_ADMIN_EMAILS ?? "")
      .split(",")
      .map((item) => item.trim().toLowerCase())
      .filter(Boolean);

    const email = user.email?.toLowerCase() ?? "";
    return adminEmails.includes(email);
  }, [user]);

  const filteredImportRuns = useMemo(() => {
    const filtered = importRuns.filter((run) => {
      if (statusFilter !== "all" && run.status !== statusFilter) return false;

      if (actorFilter.trim()) {
        const actor = (run.actor_email ?? "").toLowerCase();
        if (!actor.includes(actorFilter.trim().toLowerCase())) return false;
      }

      const runDate = new Date(run.created_at);
      if (fromDate) {
        const from = new Date(`${fromDate}T00:00:00`);
        if (runDate < from) return false;
      }

      if (toDate) {
        const to = new Date(`${toDate}T23:59:59`);
        if (runDate > to) return false;
      }

      return true;
    });

    const sorted = [...filtered].sort((a, b) => {
      const direction = sortDir === "asc" ? 1 : -1;

      if (sortBy === "created_at") {
        return (new Date(a.created_at).getTime() - new Date(b.created_at).getTime()) * direction;
      }

      if (sortBy === "total_rows" || sortBy === "destinations_created" || sortBy === "destinations_updated") {
        return ((a[sortBy] as number) - (b[sortBy] as number)) * direction;
      }

      const av = String(a[sortBy] ?? "").toLowerCase();
      const bv = String(b[sortBy] ?? "").toLowerCase();
      if (av < bv) return -1 * direction;
      if (av > bv) return 1 * direction;
      return 0;
    });

    return sorted;
  }, [importRuns, statusFilter, actorFilter, fromDate, toDate, sortBy, sortDir]);

  const setSort = (column: typeof sortBy) => {
    if (sortBy === column) {
      setSortDir((prev) => (prev === "asc" ? "desc" : "asc"));
      return;
    }
    setSortBy(column);
    setSortDir("desc");
  };

  const renderSortIcon = (column: typeof sortBy) => {
    if (sortBy !== column) return <ArrowUpDown className="w-3 h-3" />;
    return sortDir === "asc" ? <ArrowUp className="w-3 h-3" /> : <ArrowDown className="w-3 h-3" />;
  };

  const exportHistoryCsv = () => {
    if (filteredImportRuns.length === 0) {
      toast({ title: "No data", description: "No filtered history rows to export.", variant: "destructive" });
      return;
    }

    const headers = [
      "created_at",
      "status",
      "actor_email",
      "source_format",
      "total_rows",
      "warnings_count",
      "categories_created",
      "destinations_processed",
      "destinations_created",
      "destinations_updated",
      "error_message",
    ];

    const escapeCsv = (value: string | number | null) => {
      const text = value == null ? "" : String(value);
      return `"${text.replace(/"/g, '""')}"`;
    };

    const lines = [
      headers.join(","),
      ...filteredImportRuns.map((row) =>
        [
          row.created_at,
          row.status,
          row.actor_email,
          row.source_format,
          row.total_rows,
          row.warnings_count,
          row.categories_created,
          row.destinations_processed,
          row.destinations_created,
          row.destinations_updated,
          row.error_message,
        ]
          .map(escapeCsv)
          .join(","),
      ),
    ];

    const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
    const url = window.URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `import-history-${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.URL.revokeObjectURL(url);
    toast({ title: "Export complete", description: `${filteredImportRuns.length} history row(s) exported.` });
  };

  useEffect(() => {
    if (!loading && !user) navigate("/auth");
  }, [loading, navigate, user]);

  useEffect(() => {
    if (!loading && user && isAdmin) {
      void loadImportHistory();
    }
    // isAdmin must be a dependency so history loads once role checks settle.
  }, [loading, user, isAdmin, loadImportHistory]);

  const parsePayload = () => {
    try {
      const inferred = detectImportFormat(payload);
      const parsed = parseImportPayload(payload, inferred);
      setFormat(inferred);
      setParsedRows(parsed.rows);
      setWarnings(parsed.warnings);
      setDryRunResult(null);
      toast({
        title: "Import parsed",
        description: `${parsed.rows.length} row(s) ready as ${inferred.toUpperCase()}.`,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Failed to parse import payload.";
      setParsedRows([]);
      setWarnings([]);
      toast({ title: "Parse failed", description: message, variant: "destructive" });
    }
  };

  const onFileSelected = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;
    await loadFile(file);
  };

  const runDryCheck = async () => {
    if (parsedRows.length === 0) {
      toast({ title: "Nothing to check", description: "Parse data first.", variant: "destructive" });
      return;
    }

    setIsDryRunning(true);
    try {
      const result = await analyzeDestinationImport(parsedRows);
      setDryRunResult(result);
      toast({
        title: "Dry check complete",
        description: `${result.destinationSlugsNew.length} new and ${result.destinationSlugsExisting.length} existing destination slug(s).`,
      });
    } catch (error) {
      const message = error instanceof Error ? error.message : "Dry check failed.";
      toast({ title: "Dry check failed", description: message, variant: "destructive" });
    } finally {
      setIsDryRunning(false);
    }
  };

  const runImport = async () => {
    if (parsedRows.length === 0) {
      toast({ title: "Nothing to import", description: "Parse data first.", variant: "destructive" });
      return;
    }

    setIsImporting(true);
    try {
      const result = await executeDestinationImport(parsedRows, {
        actorUserId: user?.id,
        actorEmail: user?.email,
        sourceFormat: format,
        warningsCount: warnings.length,
      });
      setDryRunResult(null);
      toast({
        title: "Import complete",
        description: `${result.destinationsProcessed} processed (${result.destinationsCreated} created, ${result.destinationsUpdated} updated). ${result.categoriesCreated} category(ies) created.${result.auditLogged ? "" : " Import succeeded but audit log write failed."}`,
      });
      await loadImportHistory();
    } catch (error) {
      const message = error instanceof Error ? error.message : "Import failed.";
      toast({ title: "Import failed", description: message, variant: "destructive" });
    } finally {
      setIsImporting(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <div className="w-8 h-8 border-2 border-primary border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-background">
        <Navbar />
        <div className="pt-24 pb-16 container mx-auto px-6 max-w-3xl">
          <Card className="glass-card border border-border/50">
            <CardHeader>
              <CardTitle className="font-display text-2xl flex items-center gap-2">
                <ShieldAlert className="w-6 h-6 text-destructive" />
                Admin Access Required
              </CardTitle>
              <CardDescription>
                Add `role: admin` to your Supabase user app metadata, or include your email in `VITE_ADMIN_EMAILS`.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <Button variant="outline" onClick={() => navigate("/dashboard")}>Go back</Button>
            </CardContent>
          </Card>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6 space-y-6">
        <Card className="glass-card border border-border/50">
          <CardHeader>
            <CardTitle className="font-display text-2xl flex items-center gap-2">
              <Database className="w-6 h-6 text-primary" />
              Admin Destination Import
            </CardTitle>
            <CardDescription>
              Upload CSV/JSON, preview rows, then upsert categories and destinations by slug.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="import-file">Upload file</Label>
              <Input id="import-file" type="file" accept=".csv,.json,application/json,text/csv" onChange={onFileSelected} />
              <div
                className={`rounded-xl border border-dashed p-4 text-sm transition-colors ${isDraggingFile ? "border-primary bg-primary/5" : "border-border/60"}`}
                onDragOver={(event) => {
                  event.preventDefault();
                  setIsDraggingFile(true);
                }}
                onDragLeave={() => setIsDraggingFile(false)}
                onDrop={async (event) => {
                  event.preventDefault();
                  setIsDraggingFile(false);
                  const file = event.dataTransfer.files?.[0];
                  if (file) await loadFile(file);
                }}
              >
                Drag and drop a CSV/JSON file here.
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="import-payload">Payload ({format.toUpperCase()})</Label>
              <Textarea
                id="import-payload"
                className="min-h-[260px] font-mono text-xs"
                value={payload}
                onChange={(event) => setPayload(event.target.value)}
              />
            </div>

            <div className="flex flex-wrap gap-2">
              <Button onClick={parsePayload}>
                <FileText className="w-4 h-4 mr-2" />
                Parse Payload
              </Button>
              <Button variant="outline" onClick={() => setPayload(templateCsv)}>
                Load CSV Template
              </Button>
              <Button variant="outline" onClick={runDryCheck} disabled={isDryRunning || parsedRows.length === 0}>
                <FlaskConical className="w-4 h-4 mr-2" />
                {isDryRunning ? "Checking..." : "Run Dry Check"}
              </Button>
              <Button variant="secondary" onClick={runImport} disabled={isImporting || parsedRows.length === 0}>
                <Upload className="w-4 h-4 mr-2" />
                {isImporting ? "Importing..." : "Run Import"}
              </Button>
            </div>
          </CardContent>
        </Card>

        {dryRunResult && (
          <Card className="glass-card border border-primary/30">
            <CardHeader>
              <CardTitle className="font-display text-lg">Dry Check Summary</CardTitle>
              <CardDescription>No database writes were performed.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-1 text-sm text-muted-foreground">
              <p>Total parsed rows: {dryRunResult.totalRows}</p>
              <p>Distinct categories in file: {dryRunResult.distinctCategoriesInFile}</p>
              <p>Categories to create: {dryRunResult.categoriesThatWillBeCreated.length}</p>
              <p>New destination slugs: {dryRunResult.destinationSlugsNew.length}</p>
              <p>Existing destination slugs (will update): {dryRunResult.destinationSlugsExisting.length}</p>
            </CardContent>
          </Card>
        )}

        {warnings.length > 0 && (
          <Card className="glass-card border border-amber-500/30">
            <CardHeader>
              <CardTitle className="font-display text-lg">Parse Warnings</CardTitle>
            </CardHeader>
            <CardContent className="space-y-1 text-sm text-muted-foreground">
              {warnings.slice(0, 20).map((warning) => (
                <p key={warning}>- {warning}</p>
              ))}
              {warnings.length > 20 && <p>...and {warnings.length - 20} more</p>}
            </CardContent>
          </Card>
        )}

        {parsedRows.length > 0 && (
          <Card className="glass-card border border-border/50">
            <CardHeader>
              <CardTitle className="font-display text-lg">Preview ({parsedRows.length} rows)</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="overflow-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Title</TableHead>
                      <TableHead>Slug</TableHead>
                      <TableHead>Category</TableHead>
                      <TableHead>Country</TableHead>
                      <TableHead>Difficulty</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {parsedRows.slice(0, 10).map((row) => (
                      <TableRow key={row.slug}>
                        <TableCell>{row.title}</TableCell>
                        <TableCell>{row.slug}</TableCell>
                        <TableCell>{row.categorySlug}</TableCell>
                        <TableCell>{row.country ?? "-"}</TableCell>
                        <TableCell>{row.difficulty ?? "-"}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </CardContent>
          </Card>
        )}

        <Card className="glass-card border border-border/50">
          <CardHeader className="flex flex-row items-center justify-between">
            <div>
              <CardTitle className="font-display text-lg">Import History</CardTitle>
              <CardDescription>Latest 20 import runs from `import_runs`.</CardDescription>
            </div>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" onClick={exportHistoryCsv}>
                <Download className="w-4 h-4 mr-2" />
                Export CSV
              </Button>
              <Button variant="outline" size="sm" onClick={() => void loadImportHistory()} disabled={isHistoryLoading}>
                {isHistoryLoading ? "Refreshing..." : "Refresh"}
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-3 mb-4">
              <div className="space-y-1">
                <Label htmlFor="history-status">Status</Label>
                <select
                  id="history-status"
                  title="Filter import history by status"
                  aria-label="Filter import history by status"
                  value={statusFilter}
                  onChange={(event) => setStatusFilter(event.target.value as "all" | "success" | "failed")}
                  className="w-full h-10 rounded-md border border-input bg-background px-3 text-sm"
                >
                  <option value="all">All</option>
                  <option value="success">Success</option>
                  <option value="failed">Failed</option>
                </select>
              </div>

              <div className="space-y-1">
                <Label htmlFor="history-actor">Actor email</Label>
                <Input
                  id="history-actor"
                  placeholder="admin@dravik.com"
                  value={actorFilter}
                  onChange={(event) => setActorFilter(event.target.value)}
                />
              </div>

              <div className="space-y-1">
                <Label htmlFor="history-from">From</Label>
                <Input id="history-from" type="date" value={fromDate} onChange={(event) => setFromDate(event.target.value)} />
              </div>

              <div className="space-y-1">
                <Label htmlFor="history-to">To</Label>
                <Input id="history-to" type="date" value={toDate} onChange={(event) => setToDate(event.target.value)} />
              </div>
            </div>

            <div className="mb-3 text-xs text-muted-foreground">
              Showing {filteredImportRuns.length} of {importRuns.length} runs
            </div>

            {filteredImportRuns.length === 0 ? (
              <p className="text-sm text-muted-foreground">No import runs yet.</p>
            ) : (
              <div className="overflow-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("created_at")}>
                          Time {renderSortIcon("created_at")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("status")}>
                          Status {renderSortIcon("status")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("actor_email")}>
                          Actor {renderSortIcon("actor_email")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("source_format")}>
                          Format {renderSortIcon("source_format")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("total_rows")}>
                          Rows {renderSortIcon("total_rows")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("destinations_created")}>
                          Created {renderSortIcon("destinations_created")}
                        </button>
                      </TableHead>
                      <TableHead>
                        <button className="inline-flex items-center gap-1" onClick={() => setSort("destinations_updated")}>
                          Updated {renderSortIcon("destinations_updated")}
                        </button>
                      </TableHead>
                      <TableHead>Error</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {filteredImportRuns.map((run) => (
                      <TableRow key={run.id}>
                        <TableCell>{new Date(run.created_at).toLocaleString()}</TableCell>
                        <TableCell>{run.status}</TableCell>
                        <TableCell>{run.actor_email ?? "-"}</TableCell>
                        <TableCell>{run.source_format.toUpperCase()}</TableCell>
                        <TableCell>{run.total_rows}</TableCell>
                        <TableCell>{run.destinations_created}</TableCell>
                        <TableCell>{run.destinations_updated}</TableCell>
                        <TableCell className="max-w-[320px] truncate">{run.error_message ?? "-"}</TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

export default AdminImportPage;

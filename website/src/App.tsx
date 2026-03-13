import { lazy, Suspense } from "react";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";

const Index = lazy(() => import("./pages/Index"));
const AuthPage = lazy(() => import("./pages/AuthPage"));
const ExplorePage = lazy(() => import("./pages/ExplorePage"));
const DestinationPage = lazy(() => import("./pages/DestinationPage"));
const DashboardPage = lazy(() => import("./pages/DashboardPage"));
const AdminImportPage = lazy(() => import("./pages/AdminImportPage"));
const GuidesPage = lazy(() => import("./pages/GuidesPage"));
const SafetyPage = lazy(() => import("./pages/SafetyPage"));
const TripPlannerPage = lazy(() => import("./pages/TripPlannerPage"));
const WeatherPage = lazy(() => import("./pages/WeatherPage"));
const CountryExplorerPage = lazy(() => import("./pages/CountryExplorerPage"));
const NotFound = lazy(() => import("./pages/NotFound"));
const GuideDetailPage = lazy(() => import("./pages/GuideDetailPage"));
const AnalyticsPage = lazy(() => import("./pages/AnalyticsPage"));
const EmergencyGuidesPage = lazy(() => import("./pages/EmergencyGuidesPage"));
const ActivityPage = lazy(() => import("./pages/ActivityPage"));
const MapPage = lazy(() => import("./pages/MapPage"));

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,
      gcTime: 10 * 60 * 1000,
      retry: 1,
    },
  },
});

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Suspense fallback={<div className="min-h-screen bg-background" />}>
          <Routes>
            <Route path="/" element={<Index />} />
            <Route path="/auth" element={<AuthPage />} />
            <Route path="/explore" element={<ExplorePage />} />
            <Route path="/map" element={<MapPage />} />
            <Route path="/destination/:slug" element={<DestinationPage />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/admin/import" element={<AdminImportPage />} />
            <Route path="/trips" element={<TripPlannerPage />} />
            <Route path="/weather" element={<WeatherPage />} />
            <Route path="/countries" element={<CountryExplorerPage />} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/emergency-guides" element={<EmergencyGuidesPage />} />
            <Route path="/activity" element={<ActivityPage />} />
            <Route path="/guides" element={<GuidesPage />} />
            <Route path="/guides/:slug" element={<GuideDetailPage />} />
            <Route path="/safety" element={<SafetyPage />} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </Suspense>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;

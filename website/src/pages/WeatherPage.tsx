import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { CloudSun, Droplets, Wind, ThermometerSun } from "lucide-react";
import Navbar from "@/components/Navbar";
import { useDestinations } from "@/hooks/useDestinations";
import { useWeatherForecast, weatherCodeLabel } from "@/hooks/useWeather";

const formatDate = (dateIso: string) =>
  new Date(dateIso).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric" });

const WeatherPage = () => {
  const { data: destinations, isLoading: destinationsLoading } = useDestinations({ limit: 100 });

  const availableDestinations = useMemo(
    () =>
      (destinations || []).filter(
        (d) => d.latitude !== null && d.latitude !== undefined && d.longitude !== null && d.longitude !== undefined,
      ),
    [destinations],
  );

  const [selectedDestinationId, setSelectedDestinationId] = useState<string>("");

  const selectedDestination = useMemo(() => {
    if (selectedDestinationId) {
      return availableDestinations.find((d) => d.id === selectedDestinationId) || null;
    }
    return availableDestinations[0] || null;
  }, [availableDestinations, selectedDestinationId]);

  const { data: forecast, isLoading: forecastLoading, error } = useWeatherForecast(
    selectedDestination?.latitude,
    selectedDestination?.longitude,
  );

  return (
    <div className="min-h-screen bg-background">
      <Navbar />
      <div className="pt-24 pb-16 container mx-auto px-6">
        <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }}>
          <h1 className="font-display font-bold text-4xl md:text-6xl mb-2">
            Weather <span className="text-gradient-amber">Forecast</span>
          </h1>
          <p className="font-body text-muted-foreground text-lg mb-8">
            7-day trail weather outlook powered by live forecast data.
          </p>

          <div className="glass-card rounded-2xl p-6 mb-8">
            <label htmlFor="forecast-destination" className="block font-body text-sm text-muted-foreground mb-2">
              Select destination
            </label>
            <select
              id="forecast-destination"
              value={selectedDestination?.id || ""}
              onChange={(e) => setSelectedDestinationId(e.target.value)}
              className="w-full h-10 rounded-md border border-border bg-muted px-3 font-body text-sm"
              aria-label="Forecast destination"
            >
              {availableDestinations.map((dest) => (
                <option key={dest.id} value={dest.id}>
                  {dest.title} ({dest.country})
                </option>
              ))}
            </select>
          </div>

          {destinationsLoading && (
            <div className="glass-card rounded-2xl p-8 text-center font-body text-muted-foreground">Loading destinations...</div>
          )}

          {!destinationsLoading && availableDestinations.length === 0 && (
            <div className="glass-card rounded-2xl p-8 text-center font-body text-muted-foreground">
              No destinations with coordinates are available yet.
            </div>
          )}

          {error && (
            <div className="glass-card rounded-2xl p-8 text-center font-body text-destructive">
              Could not load forecast right now.
            </div>
          )}

          {forecastLoading && selectedDestination && (
            <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
              {Array.from({ length: 4 }).map((_, idx) => (
                <div key={idx} className="glass-card rounded-2xl h-40 animate-pulse" />
              ))}
            </div>
          )}

          {forecast && selectedDestination && (
            <>
              <div className="glass-card rounded-2xl p-6 mb-6">
                <p className="font-display font-semibold text-xl text-foreground">{selectedDestination.title}</p>
                <p className="font-body text-sm text-muted-foreground">
                  {selectedDestination.location}, {selectedDestination.country} • {forecast.timezone}
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
                {forecast.days.map((day) => (
                  <div key={day.date} className="glass-card rounded-2xl p-5">
                    <div className="flex items-center justify-between mb-4">
                      <p className="font-display font-semibold text-foreground">{formatDate(day.date)}</p>
                      <CloudSun className="w-5 h-5 text-primary" />
                    </div>

                    <p className="font-body text-sm text-muted-foreground mb-4">{weatherCodeLabel(day.weatherCode)}</p>

                    <div className="space-y-2">
                      <p className="font-body text-sm text-foreground flex items-center gap-2">
                        <ThermometerSun className="w-4 h-4 text-primary" />
                        {Math.round(day.tempMin)}°C - {Math.round(day.tempMax)}°C
                      </p>
                      <p className="font-body text-sm text-foreground flex items-center gap-2">
                        <Droplets className="w-4 h-4 text-primary" />
                        {day.precipitation.toFixed(1)} mm rain
                      </p>
                      <p className="font-body text-sm text-foreground flex items-center gap-2">
                        <Wind className="w-4 h-4 text-primary" />
                        {Math.round(day.windMax)} km/h wind
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </motion.div>
      </div>
    </div>
  );
};

export default WeatherPage;

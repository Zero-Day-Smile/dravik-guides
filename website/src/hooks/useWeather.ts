import { useQuery } from "@tanstack/react-query";

export type DailyForecast = {
  date: string;
  weatherCode: number;
  tempMax: number;
  tempMin: number;
  precipitation: number;
  windMax: number;
};

type WeatherApiResponse = {
  timezone: string;
  daily: {
    time: string[];
    weathercode: number[];
    temperature_2m_max: number[];
    temperature_2m_min: number[];
    precipitation_sum: number[];
    windspeed_10m_max: number[];
  };
};

const toForecastRows = (payload: WeatherApiResponse): DailyForecast[] => {
  const rows: DailyForecast[] = [];

  for (let i = 0; i < payload.daily.time.length; i += 1) {
    rows.push({
      date: payload.daily.time[i],
      weatherCode: payload.daily.weathercode[i],
      tempMax: payload.daily.temperature_2m_max[i],
      tempMin: payload.daily.temperature_2m_min[i],
      precipitation: payload.daily.precipitation_sum[i],
      windMax: payload.daily.windspeed_10m_max[i],
    });
  }

  return rows;
};

export const weatherCodeLabel = (code: number) => {
  if (code === 0) return "Clear sky";
  if ([1, 2, 3].includes(code)) return "Partly cloudy";
  if ([45, 48].includes(code)) return "Fog";
  if ([51, 53, 55, 56, 57].includes(code)) return "Drizzle";
  if ([61, 63, 65, 66, 67, 80, 81, 82].includes(code)) return "Rain";
  if ([71, 73, 75, 77, 85, 86].includes(code)) return "Snow";
  if ([95, 96, 99].includes(code)) return "Thunderstorm";
  return "Variable";
};

export const useWeatherForecast = (latitude?: number | null, longitude?: number | null) => {
  return useQuery({
    queryKey: ["weather-forecast", latitude, longitude],
    queryFn: async () => {
      if (latitude == null || longitude == null) {
        throw new Error("Missing coordinates for forecast");
      }

      const params = new URLSearchParams({
        latitude: latitude.toString(),
        longitude: longitude.toString(),
        daily:
          "weathercode,temperature_2m_max,temperature_2m_min,precipitation_sum,windspeed_10m_max",
        forecast_days: "7",
        timezone: "auto",
      });

      const response = await fetch(`https://api.open-meteo.com/v1/forecast?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`Weather API failed (${response.status})`);
      }

      const payload = (await response.json()) as WeatherApiResponse;
      return {
        timezone: payload.timezone,
        days: toForecastRows(payload),
      };
    },
    enabled: latitude != null && longitude != null,
    staleTime: 1000 * 60 * 15,
  });
};

import 'package:flutter/material.dart';
import 'package:dravik/services/offline_weather_service.dart';
import 'package:dravik/models/trip.dart';

class TripSafetyAnalyzer {
  final _weatherService = OfflineWeatherService();

  Future<TripSafetyScore> analyzeTripSafety(Trip trip) async {
    final forecasts =
        await _weatherService.getForecast(trip.latitude, trip.longitude);
    if (forecasts.isEmpty) {
      return TripSafetyScore(
        safetyRating: 'unknown',
        riskScore: 50,
        warnings: ['Weather data not available'],
        recommendations: [],
      );
    }

    final warnings = <String>[];
    final recommendations = <String>[];
    int riskScore = 0;

    // Check date overlap
    final tripStart = trip.startDate;
    final tripEnd = trip.endDate;
    final overlappingForecasts = forecasts.where((f) {
      final fDate = DateTime(
          f.forecastDate.year, f.forecastDate.month, f.forecastDate.day);
      final start = DateTime(tripStart.year, tripStart.month, tripStart.day);
      final end = DateTime(tripEnd.year, tripEnd.month, tripEnd.day);
      return fDate.isAfter(start.subtract(const Duration(days: 1))) &&
          fDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    if (overlappingForecasts.isEmpty) {
      recommendations.add('✅ No severe weather during trip dates');
    } else {
      // Analyze severe weather
      final severe =
          overlappingForecasts.where((f) => f.hasSevereWeather()).toList();
      if (severe.isNotEmpty) {
        warnings.add(
            '⚠️ Severe weather on ${severe.map((f) => f.forecastDate.toString().split(' ')[0]).join(', ')}');
        riskScore += 30;
      }

      // Check extreme temperatures
      final coldForecasts =
          overlappingForecasts.where((f) => f.tempC < 0).toList();
      if (coldForecasts.isNotEmpty) {
        warnings.add('❄️ Freezing temperatures expected');
        recommendations.add('Pack winter gear and insulators');
        riskScore += 15;
      }

      // Check high wind
      final windyForecasts =
          overlappingForecasts.where((f) => f.windKmh > 40).toList();
      if (windyForecasts.isNotEmpty) {
        warnings.add(
            '💨 High winds (>${windyForecasts.map((f) => f.windKmh.toInt()).reduce((a, b) => a > b ? a : b)} km/h)');
        recommendations.add('Secure all loose gear; avoid exposed ridges');
        riskScore += 20;
      }

      // Check precipitation
      final wetForecasts =
          overlappingForecasts.where((f) => f.precipitationMm > 20).toList();
      if (wetForecasts.isNotEmpty) {
        warnings.add(
            '🌧️ Heavy rain (>${wetForecasts.map((f) => f.precipitationMm).reduce((a, b) => a > b ? a : b)} mm)');
        recommendations.add('Prepare for muddy trails; bring waterproof gear');
        riskScore += 15;
      }

      // Day length check
      final sunrises = overlappingForecasts.map((f) => f.sunrise).toList();
      final sunsets = overlappingForecasts.map((f) => f.sunset).toList();
      if (sunrises.isNotEmpty && sunsets.isNotEmpty) {
        final minDaylength = sunsets.first.difference(sunrises.first).inHours;
        if (minDaylength < 9) {
          warnings.add('🌙 Short days ($minDaylength hrs). Plan accordingly.');
          recommendations.add('Start hikes early; carry headlamp');
          riskScore += 10;
        }
      }
    }

    String rating;
    if (riskScore >= 60) {
      rating = 'HIGH_RISK';
    } else if (riskScore >= 30) {
      rating = 'MODERATE_RISK';
    } else if (riskScore >= 10) {
      rating = 'LOW_RISK';
    } else {
      rating = 'SAFE';
    }

    if (recommendations.isEmpty && warnings.isEmpty) {
      recommendations.add('✅ Excellent conditions for your trip');
    }

    return TripSafetyScore(
      safetyRating: rating,
      riskScore: riskScore,
      warnings: warnings,
      recommendations: recommendations,
    );
  }
}

class TripSafetyScore {
  final String
      safetyRating; // 'SAFE', 'LOW_RISK', 'MODERATE_RISK', 'HIGH_RISK', 'unknown'
  final int riskScore; // 0-100
  final List<String> warnings;
  final List<String> recommendations;

  TripSafetyScore({
    required this.safetyRating,
    required this.riskScore,
    required this.warnings,
    required this.recommendations,
  });

  Color getRatingColor() {
    switch (safetyRating) {
      case 'SAFE':
        return Colors.green;
      case 'LOW_RISK':
        return Colors.blue;
      case 'MODERATE_RISK':
        return Colors.orange;
      case 'HIGH_RISK':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getEmoji() {
    switch (safetyRating) {
      case 'SAFE':
        return '✅';
      case 'LOW_RISK':
        return '🟢';
      case 'MODERATE_RISK':
        return '🟡';
      case 'HIGH_RISK':
        return '🔴';
      default:
        return '❓';
    }
  }
}

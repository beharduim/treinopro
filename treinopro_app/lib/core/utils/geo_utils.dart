import 'dart:math' as math;

/// Utilitários de geolocalização
class GeoUtils {
  /// Calcula a distância em quilômetros entre dois pontos (Haversine)
  static double distanceInKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _deg2rad(lat2 - lat1);
    final double dLon = _deg2rad(lng2 - lng1);
    final double a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
            (math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2));
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Verifica se um ponto está dentro de um raio (km) a partir de um centro
  static bool isWithinRadiusKm({
    required double centerLat,
    required double centerLng,
    required double targetLat,
    required double targetLng,
    required double radiusKm,
  }) {
    final distanceKm = distanceInKm(
      lat1: centerLat,
      lng1: centerLng,
      lat2: targetLat,
      lng2: targetLng,
    );
    return distanceKm <= radiusKm;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}



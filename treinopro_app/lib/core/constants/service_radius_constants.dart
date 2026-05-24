/// Raio de atendimento do personal — espelha SSOT do backend NestJS.
class ServiceRadiusConstants {
  static const double defaultKm = 15;
  static const double minKm = 0;
  static const double maxKm = 50;

  static double clamp(double value) {
    if (value.isNaN) return defaultKm;
    return value.clamp(minKm, maxKm);
  }
}

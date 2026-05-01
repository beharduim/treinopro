import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/training_location.dart';

/// Serviço para gerenciar locais populares/favoritos do usuário
class PopularLocationsService {
  static const String _popularLocationsKey = 'popular_locations';
  static const String _locationUsageKey = 'location_usage';
  static const int _maxPopularLocations = 10;

  /// Adicionar um local aos populares quando selecionado
  static Future<void> addLocationUsage(TrainingLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obter uso atual dos locais
      final usageJson = prefs.getString(_locationUsageKey) ?? '{}';
      final Map<String, dynamic> usage = json.decode(usageJson);

      // Incrementar contador de uso
      final locationId = location.id;
      final currentCount = usage[locationId] ?? 0;
      usage[locationId] = currentCount + 1;

      // Salvar uso atualizado
      await prefs.setString(_locationUsageKey, json.encode(usage));

      // Atualizar lista de populares
      await _updatePopularLocations(usage);
    } catch (e) {
      print('Erro ao adicionar uso do local: $e');
    }
  }

  /// Obter locais populares ordenados por uso
  static Future<List<TrainingLocation>> getPopularLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final popularJson = prefs.getString(_popularLocationsKey);

      if (popularJson == null) {
        return _getDefaultPopularLocations();
      }

      final List<dynamic> popularData = json.decode(popularJson);
      final locations = popularData
          .map((data) => TrainingLocation.fromJson(data))
          .toList();

      // Filtrar "casa_cliente" caso ainda esteja no cache
      final filteredLocations = locations
          .where((location) => location.id != 'casa_cliente')
          .toList();

      // Se removemos algum local, atualizar o cache
      if (filteredLocations.length != locations.length) {
        final filteredData = filteredLocations.map((l) => l.toJson()).toList();
        await prefs.setString(_popularLocationsKey, json.encode(filteredData));
      }

      return filteredLocations;
    } catch (e) {
      print('Erro ao obter locais populares: $e');
      return _getDefaultPopularLocations();
    }
  }

  /// Atualizar lista de locais populares baseado no uso
  static Future<void> _updatePopularLocations(
    Map<String, dynamic> usage,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converter uso em lista ordenada
      final sortedUsage = usage.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));

      // Obter locais correspondentes
      final List<TrainingLocation> popularLocations = [];

      for (final entry in sortedUsage.take(_maxPopularLocations)) {
        final locationId = entry.key;
        final location = _getLocationById(locationId);
        if (location != null) {
          popularLocations.add(location);
        }
      }

      // Se não há locais populares suficientes, adicionar padrões
      if (popularLocations.length < 5) {
        final defaultLocations = _getDefaultPopularLocations();
        for (final location in defaultLocations) {
          if (!popularLocations.any((l) => l.id == location.id)) {
            popularLocations.add(location);
          }
        }
      }

      // Salvar locais populares atualizados
      final popularData = popularLocations.map((l) => l.toJson()).toList();
      await prefs.setString(_popularLocationsKey, json.encode(popularData));
    } catch (e) {
      print('Erro ao atualizar locais populares: $e');
    }
  }

  /// Obter local por ID (busca nos locais conhecidos)
  static TrainingLocation? _getLocationById(String id) {
    // Lista de locais conhecidos que podem ser populares
    final knownLocations = [
      TrainingLocation(
        id: 'smartfit_01',
        name: 'Smart Fit - Shopping Vila Olímpia',
        address: 'R. Olimpíadas, 360 - Vila Olímpia, São Paulo',
        description: 'Academia completa com equipamentos modernos',
        availableModalities: ['musculacao', 'cardio', 'funcional'],
      ),
      TrainingLocation(
        id: 'bio_ritmo_01',
        name: 'Bio Ritmo - Moema',
        address: 'Av. Moema, 170 - Moema, São Paulo',
        description: 'Academia premium com piscina e sauna',
        availableModalities: ['musculacao', 'cardio', 'funcional'],
      ),
      TrainingLocation(
        id: 'parque_ibirapuera',
        name: 'Parque Ibirapuera',
        address: 'Av. Paulista, 1578 - Bela Vista, São Paulo',
        description: 'Treino ao ar livre no maior parque da cidade',
        availableModalities: ['cardio', 'funcional'],
      ),
      TrainingLocation(
        id: 'academia_formula',
        name: 'Fórmula Academia',
        address: 'R. Augusta, 2690 - Jardim Paulista, São Paulo',
        description: 'Academia boutique com personal trainers especializados',
        availableModalities: ['musculacao', 'hiit', 'funcional'],
      ),
    ];

    try {
      return knownLocations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obter locais padrão populares (para novos usuários)
  static List<TrainingLocation> _getDefaultPopularLocations() {
    return [
      TrainingLocation(
        id: 'smartfit_01',
        name: 'Smart Fit - Shopping Vila Olímpia',
        address: 'R. Olimpíadas, 360 - Vila Olímpia, São Paulo',
        description: 'Academia completa com equipamentos modernos',
        availableModalities: ['musculacao', 'cardio', 'funcional'],
      ),
      TrainingLocation(
        id: 'bio_ritmo_01',
        name: 'Bio Ritmo - Moema',
        address: 'Av. Moema, 170 - Moema, São Paulo',
        description: 'Academia premium com piscina e sauna',
        availableModalities: ['musculacao', 'cardio', 'funcional'],
      ),
      TrainingLocation(
        id: 'parque_ibirapuera',
        name: 'Parque Ibirapuera',
        address: 'Av. Paulista, 1578 - Bela Vista, São Paulo',
        description: 'Treino ao ar livre no maior parque da cidade',
        availableModalities: ['cardio', 'funcional'],
      ),
    ];
  }

  /// Limpar histórico de locais e forçar atualização (para remover locais removidos)
  static Future<void> clearLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_popularLocationsKey);
      await prefs.remove(_locationUsageKey);

      // Forçar atualização imediata com locais padrão limpos
      await _updatePopularLocations({});
    } catch (e) {
      print('Erro ao limpar histórico de locais: $e');
    }
  }

  /// Remover local específico do histórico (para remover locais que não devem mais aparecer)
  static Future<void> removeLocationFromHistory(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Remover do uso
      final usageJson = prefs.getString(_locationUsageKey) ?? '{}';
      final Map<String, dynamic> usage = json.decode(usageJson);
      usage.remove(locationId);
      await prefs.setString(_locationUsageKey, json.encode(usage));

      // Remover dos populares
      final popularJson = prefs.getString(_popularLocationsKey);
      if (popularJson != null) {
        final List<dynamic> popularData = json.decode(popularJson);
        popularData.removeWhere((data) => data['id'] == locationId);
        await prefs.setString(_popularLocationsKey, json.encode(popularData));
      }

      // Atualizar lista
      await _updatePopularLocations(usage);
    } catch (e) {
      print('Erro ao remover local do histórico: $e');
    }
  }

  /// Obter estatísticas de uso dos locais
  static Future<Map<String, int>> getLocationUsageStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageJson = prefs.getString(_locationUsageKey) ?? '{}';
      final Map<String, dynamic> usage = json.decode(usageJson);

      return usage.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      print('Erro ao obter estatísticas de uso: $e');
      return {};
    }
  }
}

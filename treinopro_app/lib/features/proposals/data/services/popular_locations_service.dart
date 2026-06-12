import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/training_location.dart';

/// Serviço para gerenciar locais populares/favoritos do usuário
class PopularLocationsService {
  static const String _popularLocationsKey = 'popular_locations';
  static const String _locationUsageKey = 'location_usage';
  // Objeto completo de cada local usado (inclui locais reais vindos da API).
  static const String _locationObjectsKey = 'location_objects';
  // Ordem de recência: ids do mais recente para o mais antigo.
  static const String _locationRecencyKey = 'location_recency';
  static const int _maxPopularLocations = 10;

  /// Persiste local a partir dos campos de uma proposta (ex.: após envio).
  static Future<void> rememberFromProposalFields({
    String? locationId,
    String? locationName,
    String? locationAddress,
    double? locationLat,
    double? locationLng,
  }) async {
    final name = locationName?.trim() ?? '';
    if (name.isEmpty) return;

    final id = (locationId?.trim().isNotEmpty == true)
        ? locationId!.trim()
        : _stableLocationId(
            name: name,
            address: locationAddress ?? '',
            lat: locationLat,
            lng: locationLng,
          );

    await addLocationUsage(
      TrainingLocation(
        id: id,
        name: name,
        address: locationAddress ?? '',
        latitude: locationLat,
        longitude: locationLng,
      ),
    );
  }

  static String _stableLocationId({
    required String name,
    required String address,
    double? lat,
    double? lng,
  }) {
    if (lat != null && lng != null) {
      return 'geo_${lat.toStringAsFixed(5)}_${lng.toStringAsFixed(5)}';
    }
    final normalized = '${name.toLowerCase()}|${address.toLowerCase()}';
    return 'loc_${normalized.hashCode.abs()}';
  }

  /// Adicionar um local aos populares quando selecionado
  static Future<void> addLocationUsage(TrainingLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationId = location.id.isNotEmpty
          ? location.id
          : _stableLocationId(
              name: location.name,
              address: location.address,
              lat: location.latitude,
              lng: location.longitude,
            );

      // Incrementar contador de uso (mantido para estatísticas)
      final usageJson = prefs.getString(_locationUsageKey) ?? '{}';
      final Map<String, dynamic> usage = json.decode(usageJson);
      usage[locationId] = (usage[locationId] ?? 0) + 1;
      await prefs.setString(_locationUsageKey, json.encode(usage));

      // Persistir o objeto completo do local (assim locais reais da API
      // também voltam a aparecer na próxima proposta).
      final objectsJson = prefs.getString(_locationObjectsKey) ?? '{}';
      final Map<String, dynamic> objects = json.decode(objectsJson);
      objects[locationId] = location.copyWith(id: locationId).toJson();
      await prefs.setString(_locationObjectsKey, json.encode(objects));

      // Atualizar ordem de recência: o último selecionado vai para o topo.
      final recencyJson = prefs.getString(_locationRecencyKey) ?? '[]';
      final List<dynamic> recency = json.decode(recencyJson);
      recency.removeWhere((id) => id == locationId);
      recency.insert(0, locationId);
      await prefs.setString(_locationRecencyKey, json.encode(recency));

      // Reconstruir lista de populares (último usado primeiro)
      await _rebuildPopularLocations();
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

  /// Reconstruir a lista de locais populares priorizando a recência:
  /// o último local selecionado fica em primeiro.
  static Future<void> _rebuildPopularLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final recencyJson = prefs.getString(_locationRecencyKey) ?? '[]';
      final List<String> recency = (json.decode(recencyJson) as List)
          .map((e) => e as String)
          .toList();

      final objectsJson = prefs.getString(_locationObjectsKey) ?? '{}';
      final Map<String, dynamic> objects = json.decode(objectsJson);

      final List<TrainingLocation> popularLocations = [];
      final Set<String> addedIds = {};

      // 1) Locais já usados, na ordem do mais recente para o mais antigo
      for (final id in recency) {
        if (id == 'casa_cliente') continue;

        TrainingLocation? location;
        final stored = objects[id];
        if (stored != null) {
          location = TrainingLocation.fromJson(
            Map<String, dynamic>.from(stored as Map),
          );
        } else {
          location = _getLocationById(id);
        }

        if (location != null && addedIds.add(location.id)) {
          popularLocations.add(location);
        }
        if (popularLocations.length >= _maxPopularLocations) break;
      }

      // 2) Completar com padrões se ainda houver poucos locais
      if (popularLocations.length < 5) {
        for (final location in _getDefaultPopularLocations()) {
          if (addedIds.add(location.id)) {
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
      await prefs.remove(_locationObjectsKey);
      await prefs.remove(_locationRecencyKey);

      // Forçar atualização imediata com locais padrão limpos
      await _rebuildPopularLocations();
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

      // Remover do objeto persistido
      final objectsJson = prefs.getString(_locationObjectsKey) ?? '{}';
      final Map<String, dynamic> objects = json.decode(objectsJson);
      objects.remove(locationId);
      await prefs.setString(_locationObjectsKey, json.encode(objects));

      // Remover da ordem de recência
      final recencyJson = prefs.getString(_locationRecencyKey) ?? '[]';
      final List<dynamic> recency = json.decode(recencyJson);
      recency.removeWhere((id) => id == locationId);
      await prefs.setString(_locationRecencyKey, json.encode(recency));

      // Remover dos populares
      final popularJson = prefs.getString(_popularLocationsKey);
      if (popularJson != null) {
        final List<dynamic> popularData = json.decode(popularJson);
        popularData.removeWhere((data) => data['id'] == locationId);
        await prefs.setString(_popularLocationsKey, json.encode(popularData));
      }

      // Atualizar lista
      await _rebuildPopularLocations();
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

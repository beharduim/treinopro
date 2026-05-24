import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/training_location.dart';

/// Serviço para consumir APIs de locais
class LocationsService {
  final http.Client _client;
  final String _baseUrl;

  LocationsService({required http.Client client, String? baseUrl})
    : _client = client,
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// Busca locais com sugestões inteligentes
  Future<List<TrainingLocation>> searchLocations(
    String query, {
    double? userLat,
    double? userLng,
    int? radius,
    String? type,
    int? limit,
    String? token,
    bool useCurrentLocation = true,
    BuildContext? locationContext,
  }) async {
    print('🔍 DEBUG: Buscando locais com query: "$query"');

    // Obter localização atual se não fornecida e useCurrentLocation for true
    double? finalUserLat = userLat;
    double? finalUserLng = userLng;

    if (useCurrentLocation && (userLat == null || userLng == null)) {
      try {
        final location = await LocationService.instance
            .getLocationWithFallback(context: locationContext);
        if (location != null) {
          finalUserLat = location.latitude;
          finalUserLng = location.longitude;
          print(
            '📍 DEBUG: Usando localização atual: $finalUserLat, $finalUserLng',
          );
        } else {
          print(
            '📍 DEBUG: Localização não disponível - buscando sem coordenadas',
          );
        }
      } catch (e) {
        print(
          '⚠️ DEBUG: Erro ao obter localização, buscando sem coordenadas: $e',
        );
      }
    }

    // Construir parâmetros da query
    final queryParams = <String, String>{'query': query};

    if (finalUserLat != null) queryParams['userLat'] = finalUserLat.toString();
    if (finalUserLng != null) queryParams['userLng'] = finalUserLng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    if (type != null) queryParams['type'] = type;
    if (limit != null) queryParams['limit'] = limit.toString();

    final uri = Uri.parse(
      '$_baseUrl${ApiConstants.locationsSearch}',
    ).replace(queryParameters: queryParams);

    print('🔍 DEBUG: URL da busca: $uri');

    final response = await _client.get(
      uri,
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('🔍 DEBUG: Status da resposta: ${response.statusCode}');
    print('🔍 DEBUG: Corpo da resposta: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final locationsData = data['locations'] as List<dynamic>? ?? [];

      final locations = locationsData.map((locationJson) {
        return TrainingLocation.fromJson(locationJson);
      }).toList();

      print('🔍 DEBUG: ${locations.length} locais encontrados');
      return locations;
    } else {
      print(
        '🔍 DEBUG: Erro na busca de locais: ${response.statusCode} - ${response.body}',
      );
      throw Exception('Falha ao buscar locais: ${response.statusCode}');
    }
  }

  /// Adiciona local aos favoritos
  Future<bool> addToFavorites(
    String locationId, {
    String? customName,
    String? token,
  }) async {
    if (token == null) {
      throw Exception('Token de autenticação necessário');
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl${ApiConstants.locationsFavorites}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'locationId': locationId,
        if (customName != null) 'customName': customName,
      }),
    );

    return response.statusCode == 201;
  }

  /// Lista locais favoritos
  Future<List<TrainingLocation>> getFavorites({String? token}) async {
    if (token == null) {
      throw Exception('Token de autenticação necessário');
    }

    final response = await _client.get(
      Uri.parse('$_baseUrl${ApiConstants.locationsFavorites}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final locationsData = data['locations'] as List<dynamic>? ?? [];

      return locationsData.map((locationJson) {
        return TrainingLocation.fromJson(locationJson);
      }).toList();
    } else {
      throw Exception('Falha ao carregar favoritos: ${response.statusCode}');
    }
  }
}

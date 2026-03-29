import 'dart:async';
import 'dart:async' as async;
import 'package:geolocator/geolocator.dart';

/// Serviço para gerenciar geolocalização do usuário
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  
  LocationService._();
  
  // Flag para desabilitar localização se Google Play Services não estiver disponível
  bool _isLocationDisabled = false;
  bool get isLocationDisabled => _isLocationDisabled;
  
  /// Verifica se a localização está habilitada
  Future<bool> isLocationEnabled() async {
    // Se localização foi desabilitada por erro anterior, retornar false imediatamente
    if (_isLocationDisabled) {
      print('📍 [LOCATION] Localização desabilitada devido a erro anterior');
      return false;
    }
    
    // ✅ CORREÇÃO CRÍTICA: Usar runZonedGuarded para capturar TODAS as exceções não tratadas,
    // incluindo RuntimeExecutionException que pode escapar do catchError normal
    final completer = Completer<bool>();
    
    async.runZonedGuarded(() async {
      try {
        final bool enabled = await Geolocator.isLocationServiceEnabled()
            .timeout(const Duration(seconds: 5))
            .catchError((error, stackTrace) {
          // Captura qualquer erro do geolocator (incluindo RuntimeExecutionException)
          print('⚠️ [LOCATION] Erro ao verificar se localização está habilitada: $error');
          print('📍 [LOCATION] Stack trace: $stackTrace');
          
          // Desabilitar localização permanentemente se Google Play Services não está disponível
          final errorStr = error.toString();
          if (errorStr.contains('API_UNAVAILABLE') || 
              errorStr.contains('Google Play Services') ||
              errorStr.contains('RuntimeExecutionException') ||
              errorStr.contains('ApiException') ||
              errorStr.contains('ConnectionResult') ||
              errorStr.contains('statusCode=API_UNAVAILABLE')) {
            _isLocationDisabled = true;
            print('🚫 [LOCATION] Google Play Services indisponível - localização desabilitada permanentemente');
          }
          completer.complete(false);
          return false; // Retornar false para o catchError
        });
        
        if (!completer.isCompleted) {
          completer.complete(enabled);
        }
      } catch (e, stackTrace) {
        // Captura exceções que podem escapar do catchError
        print('⚠️ [LOCATION] Exceção capturada ao verificar localização: $e');
        print('📍 [LOCATION] Stack trace: $stackTrace');
        
        final errorStr = e.toString();
        if (errorStr.contains('API_UNAVAILABLE') || 
            errorStr.contains('Google Play Services') ||
            errorStr.contains('RuntimeExecutionException') ||
            errorStr.contains('ApiException') ||
            errorStr.contains('ConnectionResult') ||
            errorStr.contains('statusCode=API_UNAVAILABLE')) {
          _isLocationDisabled = true;
          print('🚫 [LOCATION] Google Play Services indisponível - localização desabilitada permanentemente');
        }
        
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    }, (error, stackTrace) {
      // ✅ CORREÇÃO CRÍTICA: runZonedGuarded captura TODAS as exceções não tratadas,
      // incluindo RuntimeExecutionException que pode escapar de try-catch normais
      print('❌ [LOCATION] Erro fatal capturado por runZonedGuarded: $error');
      print('📍 [LOCATION] Stack trace: $stackTrace');
      
      final errorStr = error.toString();
      if (errorStr.contains('API_UNAVAILABLE') || 
          errorStr.contains('Google Play Services') ||
          errorStr.contains('RuntimeExecutionException') ||
          errorStr.contains('ApiException') ||
          errorStr.contains('ConnectionResult') ||
          errorStr.contains('statusCode=API_UNAVAILABLE')) {
        _isLocationDisabled = true;
        print('🚫 [LOCATION] Google Play Services indisponível - localização desabilitada permanentemente');
      }
      
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    
    return completer.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        print('⏰ [LOCATION] Timeout ao verificar localização');
        _isLocationDisabled = true;
        return false;
      },
    );
  }
  
  /// Solicita permissão de localização
  Future<bool> requestLocationPermission() async {
    try {
      // Verificar se já tem permissão
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5))
          .catchError((error) {
        print('⚠️ [LOCATION] Erro ao verificar permissão: $error');
        return LocationPermission.denied;
      });
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 5))
            .catchError((error) {
          print('⚠️ [LOCATION] Erro ao solicitar permissão: $error');
          return LocationPermission.denied;
        });
        
        if (permission == LocationPermission.denied) {
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
      
      return true;
    } catch (e, stackTrace) {
      // Captura TODAS as exceções, incluindo RuntimeExecutionException
      print('⚠️ [LOCATION] Google Play Services indisponível: $e');
      print('📍 [LOCATION] Stack trace: $stackTrace');
      print('📍 [LOCATION] Usando modo fallback (permissão negada)');
      return false;
    }
  }
  
  /// Obtém a localização atual do usuário
  Future<LocationData?> getCurrentLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      )
          .timeout(const Duration(seconds: 10))
          .catchError((error) {
        // Captura RuntimeExecutionException e outros erros do geolocator
        print('⚠️ [LOCATION] Erro ao obter posição: $error');
        throw error; // Re-throw para ser capturado pelo catch externo
      });
      
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e, stackTrace) {
      // Captura TODAS as exceções, incluindo RuntimeExecutionException
      print('⚠️ [LOCATION] Google Play Services indisponível ou erro: $e');
      print('📍 [LOCATION] Stack trace: $stackTrace');
      print('📍 [LOCATION] Usando localização padrão');
      return null;
    }
  }
  
  /// Obtém localização atual do usuário (sem fallback para localização padrão)
  /// Retorna null se não conseguir obter a localização
  Future<LocationData?> getLocationWithFallback() async {
    // Retornar null imediatamente se desabilitada
    if (_isLocationDisabled) {
      print('📍 [LOCATION] Localização desabilitada - retornando null');
      return null;
    }
    
    try {
      // Verificar se localização está habilitada (com timeout e tratamento de erro)
      final isEnabled = await isLocationEnabled()
          .timeout(const Duration(seconds: 5))
          .catchError((error) {
        print('⚠️ [LOCATION] Erro ao verificar localização habilitada: $error');
        _isLocationDisabled = true; // Desabilitar permanentemente
        return false;
      });
      
      if (!isEnabled) {
        print('📍 Localização desabilitada - retornando null');
        return null;
      }
      
      // Solicitar permissão (com timeout)
      final hasPermission = await requestLocationPermission()
          .timeout(const Duration(seconds: 5))
          .catchError((error) {
        print('⚠️ [LOCATION] Erro ao solicitar permissão: $error');
        return false;
      });
      
      if (!hasPermission) {
        print('📍 Permissão negada - retornando null');
        return null;
      }
      
      // Tentar obter localização atual (com timeout)
      final location = await getCurrentLocation()
          .timeout(const Duration(seconds: 10))
          .catchError((error) {
        print('⚠️ [LOCATION] Erro ao obter localização atual: $error');
        return null;
      });
      
      if (location != null) {
        print('📍 Localização obtida: ${location.latitude}, ${location.longitude}');
        return location;
      }
      
      print('📍 Não foi possível obter localização - retornando null');
      return null;
    } catch (e, stackTrace) {
      // Captura TODAS as exceções para garantir que nunca crasha
      print('❌ [LOCATION] Erro fatal ao obter localização: $e');
      print('📍 [LOCATION] Stack trace: $stackTrace');
      print('📍 Retornando null devido a erro crítico');
      return null;
    }
  }
}

/// Dados de localização do usuário
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
  
  
  @override
  String toString() {
    return 'LocationData(lat: $latitude, lng: $longitude, accuracy: $accuracy)';
  }
}

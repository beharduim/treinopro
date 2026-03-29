import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar a otimização de bateria
/// Solicita automaticamente a desabilitação da otimização de bateria na primeira inicialização
class BatteryOptimizationService {
  static const String _keyBatteryOptimizationRequested = 'battery_optimization_requested';
  
  /// Verifica se a otimização de bateria está desabilitada
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      return true; // iOS não tem otimização de bateria da mesma forma
    }
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      print('❌ [BATTERY] Erro ao verificar status: $e');
      return false;
    }
  }
  
  /// Solicita automaticamente a desabilitação da otimização de bateria
  /// Similar ao Facebook: solicita automaticamente na primeira inicialização
  static Future<void> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) {
      return; // iOS não precisa
    }
    
    try {
      // Verificar status atual
      final status = await Permission.ignoreBatteryOptimizations.status;
      
      if (status.isGranted) {
        print('✅ [BATTERY] Otimização de bateria já está desabilitada');
        return;
      }
      
      if (status.isPermanentlyDenied) {
        print('⚠️ [BATTERY] Permissão permanentemente negada - usuário precisa habilitar manualmente');
        return;
      }
      
      // Solicitar permissão automaticamente (sem mostrar diálogo explicativo)
      // Isso abre a tela de configurações do sistema onde o usuário pode aceitar
      print('📱 [BATTERY] Solicitando desabilitação de otimização de bateria...');
      
      final result = await Permission.ignoreBatteryOptimizations.request();
      
      // Salvar que já foi solicitado (para referência futura)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBatteryOptimizationRequested, true);
      
      if (result.isGranted) {
        print('✅ [BATTERY] Otimização de bateria desabilitada com sucesso');
      } else if (result.isDenied) {
        print('⚠️ [BATTERY] Usuário negou a permissão de otimização de bateria');
      } else if (result.isPermanentlyDenied) {
        print('⚠️ [BATTERY] Permissão permanentemente negada');
      }
    } catch (e) {
      print('❌ [BATTERY] Erro ao solicitar desabilitação de otimização: $e');
    }
  }
  
  /// Abre as configurações de bateria do sistema para o usuário habilitar manualmente
  static Future<void> openBatterySettings() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ [BATTERY] Erro ao abrir configurações: $e');
    }
  }
  
  /// Verifica e solicita automaticamente se necessário (chamado na inicialização)
  static Future<void> ensureBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) {
      return;
    }
    
    final isDisabled = await isBatteryOptimizationDisabled();
    
    if (!isDisabled) {
      print('📱 [BATTERY] Otimização de bateria está habilitada - solicitando desabilitação...');
      await requestIgnoreBatteryOptimization();
    } else {
      print('✅ [BATTERY] Otimização de bateria já está desabilitada');
    }
  }
}


import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

/// Configuração de notificação de proposta
enum ProposalNotificationMode {
  /// Simples: 1 som + notificação
  simple,
  
  /// Moderado: 3 sons + notificação com timer
  moderate,
  
  /// Agressivo: Som em loop + notificação full-screen (estilo Uber)
  aggressive,
}

/// Serviço especializado para notificações de propostas
/// Oferece diferentes modos de notificação
class ProposalNotificationService {
  static ProposalNotificationService? _instance;
  static ProposalNotificationService get instance => _instance ??= ProposalNotificationService._();
  
  ProposalNotificationService._();
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _soundTimer;
  Timer? _notificationTimer;
  ProposalNotificationMode _mode = ProposalNotificationMode.moderate;
  
  /// Define o modo de notificação
  void setMode(ProposalNotificationMode mode) {
    _mode = mode;
    if (kDebugMode) {
      print('🔔 Modo de notificação alterado para: $_mode');
    }
  }
  
  /// Obtém o modo atual
  ProposalNotificationMode get mode => _mode;
  
  /// Mostra notificação de proposta baseado no modo configurado
  Future<void> showProposalNotification({
    required String proposalId,
    required String studentName,
    required String location,
    int expiresInSeconds = 30,
  }) async {
    // Cancelar notificações anteriores
    await cancelNotification();
    
    switch (_mode) {
      case ProposalNotificationMode.simple:
        await _showSimpleNotification(proposalId, studentName, location);
        break;
      case ProposalNotificationMode.moderate:
        await _showModerateNotification(proposalId, studentName, location, expiresInSeconds);
        break;
      case ProposalNotificationMode.aggressive:
        await _showAggressiveNotification(proposalId, studentName, location, expiresInSeconds);
        break;
    }
  }
  
  /// Modo Simples: 1 som + 1 notificação
  Future<void> _showSimpleNotification(
    String proposalId,
    String studentName,
    String location,
  ) async {
    try {
      // Tocar som uma vez
      await _audioPlayer.play(AssetSource('sounds/alert_proposal.mp3'));
      
      // Mostrar notificação
      // TODO: Implementar notificação quando necessário
      // await NotificationService().showMessageNotification(
      //   title: '🎯 Nova Proposta de Treino!',
      //   body: '$studentName em $location',
      //   payload: 'proposal:$proposalId',
      // );
      
      if (kDebugMode) {
        print('🔔 Notificação simples enviada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na notificação simples: $e');
      }
    }
  }
  
  /// Modo Moderado: 3 sons + notificação com timer (RECOMENDADO)
  Future<void> _showModerateNotification(
    String proposalId,
    String studentName,
    String location,
    int expiresInSeconds,
  ) async {
    try {
      // Tocar som 3 vezes com intervalo
      int soundCount = 0;
      _soundTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        if (soundCount >= 3) {
          timer.cancel();
          return;
        }
        
        await _audioPlayer.play(AssetSource('sounds/alert_proposal.mp3'));
        soundCount++;
        
        if (kDebugMode) {
          print('🔊 Som tocado ($soundCount/3)');
        }
      });
      
      // Primeira notificação imediata
      // TODO: Implementar notificação quando necessário
      // await NotificationService().showMessageNotification(
      //   title: '🎯 Nova Proposta de Treino!',
      //   body: '$studentName em $location\nExpira em $expiresInSeconds segundos',
      //   payload: 'proposal:$proposalId',
      // );
      
      // Atualizar notificação a cada 10 segundos
      int remainingTime = expiresInSeconds;
      _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        remainingTime -= 10;
        
        if (remainingTime <= 0) {
          timer.cancel();
          return;
        }
        
        // TODO: Implementar notificação quando necessário
        // await NotificationService().showMessageNotification(
        //   title: '⏰ Proposta Expirando!',
        //   body: '$studentName em $location\n$remainingTime segundos restantes',
        //   payload: 'proposal:$proposalId',
        // );
      });
      
      if (kDebugMode) {
        print('🔔 Notificação moderada enviada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na notificação moderada: $e');
      }
    }
  }
  
  /// Modo Agressivo: Som em loop + notificações frequentes (estilo Uber)
  Future<void> _showAggressiveNotification(
    String proposalId,
    String studentName,
    String location,
    int expiresInSeconds,
  ) async {
    try {
      // Tocar som em loop
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/alert_proposal.mp3'));
      
      // Parar som após tempo expirar
      _soundTimer = Timer(Duration(seconds: expiresInSeconds), () {
        _audioPlayer.stop();
      });
      
      // Primeira notificação
      // TODO: Implementar notificação quando necessário
      // await NotificationService().showMessageNotification(
      //   title: '🚨 NOVA PROPOSTA URGENTE!',
      //   body: '$studentName em $location\nACEITE AGORA!',
      //   payload: 'proposal:$proposalId',
      // );
      
      // Atualizar notificação a cada 5 segundos
      int remainingTime = expiresInSeconds;
      _notificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        remainingTime -= 5;
        
        if (remainingTime <= 0) {
          timer.cancel();
          await _audioPlayer.stop();
          return;
        }
        
        // TODO: Implementar notificação quando necessário
        // await NotificationService().showMessageNotification(
        //   title: '⏰ EXPIRA EM $remainingTime SEGUNDOS!',
        //   body: '$studentName em $location\nTOQUE PARA ACEITAR!',
        //   payload: 'proposal:$proposalId',
        // );
      });
      
      if (kDebugMode) {
        print('🔔 Notificação agressiva enviada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro na notificação agressiva: $e');
      }
    }
  }
  
  /// Cancela notificação e sons em andamento
  Future<void> cancelNotification() async {
    _soundTimer?.cancel();
    _notificationTimer?.cancel();
    await _audioPlayer.stop();
    
    if (kDebugMode) {
      print('🔕 Notificação cancelada');
    }
  }
  
  /// Limpa recursos
  void dispose() {
    _soundTimer?.cancel();
    _notificationTimer?.cancel();
    _audioPlayer.dispose();
  }
}

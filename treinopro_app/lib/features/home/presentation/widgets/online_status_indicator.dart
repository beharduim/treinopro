import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/di/dependency_injection.dart' as di;

/// Widget que mostra o status online do personal
class OnlineStatusIndicator extends StatefulWidget {
  const OnlineStatusIndicator({super.key});

  @override
  State<OnlineStatusIndicator> createState() => _OnlineStatusIndicatorState();
}

class _OnlineStatusIndicatorState extends State<OnlineStatusIndicator> {
  bool _isOnline = false;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    final wsService = di.sl<WebSocketService>();
    
    // Verificar status inicial
    _checkStatus();
    
    // Escutar mudanças no status da conexão WebSocket
    _connectionSubscription = wsService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isOnline = connected;
        });
      }
    });
  }

  void _checkStatus() {
    final wsService = di.sl<WebSocketService>();
    setState(() {
      _isOnline = wsService.isConnected;
    });
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOnline ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _isOnline ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget expandido com mais informações e controle
class OnlineStatusCard extends StatefulWidget {
  final VoidCallback? onToggle;
  
  const OnlineStatusCard({
    super.key,
    this.onToggle,
  });

  @override
  State<OnlineStatusCard> createState() => _OnlineStatusCardState();
}

class _OnlineStatusCardState extends State<OnlineStatusCard> {
  bool _isOnline = false;
  bool _isLoading = false;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListener();
  }

  void _setupWebSocketListener() {
    final wsService = di.sl<WebSocketService>();
    
    // Verificar status inicial
    _checkStatus();
    
    // Escutar mudanças no status da conexão WebSocket
    _connectionSubscription = wsService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isOnline = connected;
        });
      }
    });
  }

  void _checkStatus() {
    final wsService = di.sl<WebSocketService>();
    setState(() {
      _isOnline = wsService.isConnected;
    });
  }

  Future<void> _toggleStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final wsService = di.sl<WebSocketService>();
      
      if (_isOnline) {
        // Desconectar WebSocket (manual)
        await wsService.disconnect(manual: true);
      } else {
        // Reconectar WebSocket
        await wsService.connect();
      }
      
      _checkStatus();
      widget.onToggle?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isOnline ? 'Você está online' : 'Você está offline',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isOnline
                            ? 'Recebendo propostas de treino'
                            : 'Ative para receber propostas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch(
                    value: _isOnline,
                    onChanged: (_) => _toggleStatus(),
                    activeColor: Colors.green,
                  ),
              ],
            ),
            if (_isOnline) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sua localização está sendo compartilhada',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

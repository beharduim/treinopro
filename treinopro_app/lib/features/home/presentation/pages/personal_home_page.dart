import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/widgets/custom_top_bar.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/service_radius_constants.dart';
import '../../widgets/personal_bottom_navigation.dart';
import '../../widgets/proposal_modal.dart';
import '../../../classes/presentation/pages/classes_page.dart';
import '../../../classes/presentation/pages/personal_class_tracking_page.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../classes/presentation/bloc/classes_event.dart';
import '../../../classes/presentation/bloc/classes_state.dart';
import '../../../classes/presentation/widgets/class_timer_widget.dart';
import '../../../classes/data/models/class_response_dto.dart';
import '../../../profile/data/services/profile_api_service.dart';
import '../../data/services/personal_financial_api_service.dart';
import '../../data/models/personal_financial_stats_model.dart';
import '../../../proposals/domain/entities/training_location.dart';
import '../../../proposals/presentation/widgets/location_search_field.dart';
import '../../../proposals/presentation/pages/proposals_page.dart';
import '../../../proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../../profile/presentation/pages/personal_profile_page.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../proposals/data/services/personal_proposals_api_service.dart';
import '../../../users/data/services/users_api_service.dart';
import '../../../chat/presentation/pages/chat_page.dart';
import '../../../classes/data/services/classes_api_service.dart';
import '../../../classes/data/models/get_classes_dto.dart';
// (sem fetch) não precisamos destes imports para o fluxo via WebSocket
import '../../../proposals/data/services/locations_service.dart';
import '../../data/services/auth_service.dart';
import '../../../gamification/presentation/bloc/gamification_bloc.dart';
import '../../../gamification/presentation/bloc/gamification_event.dart';
import '../../../gamification/presentation/bloc/gamification_state.dart';
import '../../../gamification/presentation/services/gamification_dev_notice_coordinator.dart';
import '../../../notifications/notifications.dart';
import '../widgets/personal_weekly_mission_card.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_state.dart';
import '../bloc/home_event.dart';
import '../../../proposals/presentation/bloc/proposals_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/services/wakelock_service.dart';
import '../../../balance/presentation/bloc/balance_bloc.dart';
import '../../../balance/presentation/bloc/balance_state.dart';
import '../../../balance/presentation/bloc/balance_event.dart';
import '../../../payouts/presentation/widgets/add_payout_method_bottom_sheet.dart';

/// Página principal da home do personal trainer
class PersonalHomePage extends StatefulWidget {
  final int? initialTabIndex;
  const PersonalHomePage({super.key, this.initialTabIndex});

  @override
  State<PersonalHomePage> createState() => _PersonalHomePageState();
}

class _PersonalHomePageState extends State<PersonalHomePage>
    with WidgetsBindingObserver, NotificationsMixin {
  int _currentBottomNavIndex = 0;
  double _raioAtendimento = ServiceRadiusConstants.defaultKm;
  bool _isOnline = false; // Estado inicial offline
  late RealtimeDataService _realtimeDataService; // Serviço centralizado
  StreamSubscription<dynamic>?
  _newProposalSub; // assinatura leve para new_proposal
  StreamSubscription<bool>? _connectionSub; // listener de conexão do WebSocket
  static const String _onlinePrefKey = 'personal_online_status';

  // Dados reais do personal
  String _personalName = 'Carregando...';
  String _balance = 'R\$ 0,00';
  bool _isLoadingPersonalData = true;
  String? statsDataCacheXp;
  String? _profileImageUrl;

  // Campo de localização
  TrainingLocation? _selectedLocation;
  List<TrainingLocation> _locationSuggestions = [];
  bool _isLoadingLocations = false;

  // Estado do fluxo de propostas/match
  final Set<String> _handledProposalIds =
      <String>{}; // dedupe de proposals já exibidas/aceitas
  final Set<String> _acceptingProposalIds =
      <String>{}; // dedupe de aceitação em andamento
  String? _iAcceptedProposalId; // proposta que este personal aceitou
  String? _visibleProposalId; // proposal atualmente visível no modal
  // ✅ NOVO: Key para acessar o estado do modal e transicionar para matched
  GlobalKey<State<ProposalModal>>? _currentProposalModalKey;
  // Cache: proposalId -> dados da aula criada (para abrir chat sem fetch)
  final Map<String, Map<String, String>> _classByProposalId =
      <String, Map<String, String>>{};
  // Esperadores por proposalId quando usuário clica antes de chegar class_created
  final Map<String, Completer<Map<String, String>>> _classWaiterByProposalId =
      <String, Completer<Map<String, String>>>{};
  final Set<String> _processedFinancialClassIds = <String>{};

  /// Payload enviado ao backend via personal_online (SSOT de raio/local).
  Map<String, dynamic> _buildPersonalOnlinePayload() {
    final centerLat = _selectedLocation?.latitude;
    final centerLng = _selectedLocation?.longitude;
    return {
      'action': 'set_radius',
      'radiusKm': _raioAtendimento,
      if (centerLat != null && centerLng != null)
        'center': {'lat': centerLat, 'lng': centerLng},
    };
  }

  void _syncPersonalOnlineStatus({required String reason}) {
    final ws = sl<WebSocketService>();
    if (_isOnline) {
      print('📤 [PERSONAL_HOME] SSOT online ($reason)');
      ws.configurePersonalOnline(
        active: true,
        payload: _buildPersonalOnlinePayload(),
      );
    } else {
      print('📴 [PERSONAL_HOME] SSOT offline ($reason)');
      ws.configurePersonalOnline(active: false);
    }
  }

  // ===== Helpers de geolocalização/raio =====
  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  double _haversineKm({
    required double lat1,
    required double lng1,
    required double lat2,
    required double lng2,
  }) {
    const double earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lng2 - lng1);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  ({double? lat, double? lng}) _extractProposalLatLng(
    Map<String, dynamic> proposal,
  ) {
    double? lat;
    double? lng;
    lat = double.tryParse(
      (proposal['locationLat'] ?? proposal['lat'] ?? '').toString(),
    );
    lng = double.tryParse(
      (proposal['locationLng'] ?? proposal['lng'] ?? '').toString(),
    );
    final loc = proposal['location'] as Map<String, dynamic>?;
    if ((lat == null || lng == null) && loc != null) {
      lat = double.tryParse((loc['latitude'] ?? loc['lat'] ?? '').toString());
      lng = double.tryParse((loc['longitude'] ?? loc['lng'] ?? '').toString());
    }
    return (lat: lat, lng: lng);
  }

  String _extractCityFromAddress(String address) {
    final cleaned = address.trim();
    if (cleaned.isEmpty) return '';

    // Padrão comum: "Rua, Bairro - Cidade - UF"
    final dashParts = cleaned.split('-').map((s) => s.trim()).toList();
    if (dashParts.length >= 2) {
      final last = dashParts.last;
      // Se o último token é UF (2 letras), cidade é o penúltimo (pode conter vírgula)
      if (RegExp(r'^[A-Z]{2}$').hasMatch(last)) {
        final penultimate = dashParts[dashParts.length - 2];
        final penComma = penultimate.split(',');
        return penComma.last.trim();
      }
      // Caso contrário, usar último segmento após vírgula
      final lastComma = last.split(',');
      return lastComma.last.trim();
    }

    // Fallback: parte após a última vírgula
    final commaParts = cleaned.split(',').map((s) => s.trim()).toList();
    if (commaParts.isNotEmpty) {
      return commaParts.last;
    }
    return cleaned;
  }

  bool _isProposalWithinRadius(Map<String, dynamic> proposal) {
    // 1) Centro do raio: local escolhido ou persistido
    double? centerLat = _selectedLocation?.latitude;
    double? centerLng = _selectedLocation?.longitude;
    try {
      final prefs = sl<SharedPreferences>();
      centerLat = centerLat ?? prefs.getDouble('personal_location_lat');
      centerLng = centerLng ?? prefs.getDouble('personal_location_lng');
    } catch (_) {}

    // 2) Se temos coordenadas do centro e da proposta → Haversine
    final coords = _extractProposalLatLng(proposal);
    final lat = coords.lat;
    final lng = coords.lng;
    if (centerLat != null && centerLng != null && lat != null && lng != null) {
      final distanceKm = _haversineKm(
        lat1: centerLat,
        lng1: centerLng,
        lat2: lat,
        lng2: lng,
      );
      debugPrint(
        '📏[PROPOSAL_RT] Distância até proposta: ${distanceKm.toStringAsFixed(2)}km (raio=${_raioAtendimento.toStringAsFixed(1)}km)',
      );
      return distanceKm <= _raioAtendimento;
    }

    // 3) Fallback por cidade quando faltam coordenadas na proposta
    String preferredCity = '';
    try {
      final prefs = sl<SharedPreferences>();
      final savedAddress =
          prefs.getString('personal_location_address') ??
          _selectedLocation?.address ??
          '';
      preferredCity = _extractCityFromAddress(savedAddress);
    } catch (_) {}
    if (preferredCity.isNotEmpty) {
      final locAddress = (proposal['locationAddress'] ?? '').toString();
      final locName = (proposal['locationName'] ?? '').toString();
      final cityLower = preferredCity.toLowerCase();
      final matches =
          locAddress.toLowerCase().contains(cityLower) ||
          locName.toLowerCase().contains(cityLower);
      debugPrint(
        '🏙️[PROPOSAL_RT] Fallback cidade="$preferredCity" → match=$matches',
      );
      return matches;
    }

    // 4) Sem centro/cidade → bloquear por segurança
    debugPrint(
      '⚠️[PROPOSAL_RT] Sem centro ou cidade para filtrar — bloqueando',
    );
    return false;
  }

  DateTime? _extractProposalNotificationTimestamp(
    Map<String, dynamic> proposal, {
    Map<String, dynamic>? wrapper,
  }) {
    final updatedAt = DateTime.tryParse(
      (proposal['updatedAt'] ?? '').toString(),
    );
    final createdAt = DateTime.tryParse(
      (proposal['createdAt'] ?? wrapper?['timestamp'] ?? '').toString(),
    );

    if (updatedAt != null && createdAt != null) {
      return updatedAt.isAfter(createdAt) ? updatedAt : createdAt;
    }
    return updatedAt ?? createdAt;
  }

  bool _isProposalFreshForNotification(
    Map<String, dynamic> proposal, {
    Map<String, dynamic>? wrapper,
  }) {
    final timestamp = _extractProposalNotificationTimestamp(
      proposal,
      wrapper: wrapper,
    );
    if (timestamp == null) {
      return false;
    }

    // 30 minutos — alinhado com expiração da proposta no backend.
    // Usa updatedAt quando pagamento demora (createdAt ficaria "velho" cedo demais).
    return DateTime.now().difference(timestamp).inMinutes < 30;
  }

  @override
  void initState() {
    super.initState();

    // Aplicar aba inicial, se fornecida via navegação
    if (widget.initialTabIndex != null) {
      _currentBottomNavIndex = widget.initialTabIndex!.clamp(0, 3);
    }

    // Remove timer simulado; agora usamos eventos reais do WS
    WidgetsBinding.instance.addObserver(this);

    // Inicializar RealtimeDataService centralizado
    _realtimeDataService = sl<RealtimeDataService>();

    // ✅ Restaurar estado local imediatamente (antes do postFrame)
    try {
      final prefs = sl<SharedPreferences>();
      // Restaurar raio (km)
      final savedRadius = prefs.getDouble('personal_radius_km');
      if (savedRadius != null) {
        _raioAtendimento = ServiceRadiusConstants.clamp(savedRadius);
      }
      // Restaurar online/offline
      final savedOnline = prefs.getBool(_onlinePrefKey);
      if (savedOnline != null) {
        _isOnline = savedOnline;
        // Se estava online antes de fechar, manter tela ativa imediatamente
        if (_isOnline) {
          WakelockService.instance.enable();
        }
      }

      // Restaurar localização selecionada
      final savedLocName = prefs.getString('personal_location_name');
      final savedLocAddress = prefs.getString('personal_location_address');
      final savedLat = prefs.getDouble('personal_location_lat');
      final savedLng = prefs.getDouble('personal_location_lng');
      if (savedLocName != null) {
        // ✅ Restaurar mesmo sem lat/lng para pré-preencher o campo visual
        _selectedLocation = TrainingLocation(
          id: 'saved_location',
          name: savedLocName,
          address: savedLocAddress ?? '',
          latitude: savedLat,
          longitude: savedLng,
        );
      }
    } catch (_) {}

    // Carrega dados reais do personal
    _loadPersonalData();

    // Inicializar RealtimeDataService com os BLoCs necessários
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Inicializa gamificação
      final uid = sl<AuthService>().currentUserId;
      final gamificationBloc = context.read<GamificationBloc>();
      if (uid != null && uid.isNotEmpty) {
        gamificationBloc.add(InitializeGamification(userId: uid));
      }

      // Conectar WebSocket agora que o usuário está autenticado
      final classesBloc = context.read<ClassesBloc>();
      if (!classesBloc.isClosed) {
        classesBloc.add(const ClassesConnectWebSocket());
      }

      _realtimeDataService.initialize(
        homeBloc: context.read<HomeBloc>(),
        classesBloc: classesBloc,
        proposalsBloc: context.read<ProposalsBloc>(),
        gamificationBloc: gamificationBloc,
        proposalSearchBloc: context.read<ProposalSearchBloc>(),
        onClassCreated: (classData) => _onClassCreated(classData),
      );
      print('🔌 [PERSONAL_HOME] RealtimeDataService inicializado');

      // ✅ CRÍTICO: decidir deep link x gamificação apenas após hidratar pending persistido
      unawaited(_coordinatePendingDeepLinkAndGamification());

      // Restaurar disponibilidade online (persistido) e reemitir status
      try {
        final prefs = sl<SharedPreferences>();
        final savedOnline = prefs.getBool(_onlinePrefKey);
        if (savedOnline != null && savedOnline != _isOnline) {
          setState(() => _isOnline = savedOnline);
        }
        if (_isOnline) {
          _syncPersonalOnlineStatus(reason: 'init');
          _attemptForegroundRecovery();
        }
      } catch (e) {
        print('⚠️ [PERSONAL_HOME] Falha ao restaurar online status: $e');
      }
    });

    // Assinatura leve: ouvir apenas new_proposal e acionar recovery → abre modal
    _setupProposalListener();

    // ✅ CORREÇÃO CRÍTICA: Escutar conexão do WebSocket para recriar listener após reconexão
    _setupConnectionListener();
  }

  /// Configura listener de conexão do WebSocket para recriar listener de propostas após reconexão
  void _setupConnectionListener() {
    // Cancelar listener antigo se existir
    _connectionSub?.cancel();

    // Escutar mudanças de conexão
    _connectionSub = sl<WebSocketService>().connectionStream.listen((
      connected,
    ) {
      if (connected) {
        print(
          '✅ [PERSONAL_HOME] WebSocket conectado - recriando listener de propostas...',
        );
        // Recriar listener de propostas quando WebSocket reconecta
        _setupProposalListener();

        // ✅ CORREÇÃO CRÍTICA: Reemitir personal_online ou personal_offline quando WebSocket reconecta
        // Isso garante que o backend saiba o status atual do personal
        if (_isOnline) {
          print(
            '📤 [PERSONAL_HOME] Personal está online - reemitindo após reconexão WS...',
          );
          _syncPersonalOnlineStatus(reason: 'ws_reconnect');
        } else {
          print(
            '📴 [PERSONAL_HOME] Personal está offline - confirmando após reconexão WS...',
          );
          _syncPersonalOnlineStatus(reason: 'ws_reconnect_offline');
        }
      } else {
        print('⚠️ [PERSONAL_HOME] WebSocket desconectado');
      }
    });
  }

  @override
  void dispose() {
    // Garantir que wakelock seja liberado ao fechar a página
    WakelockService.instance.disable();
    _realtimeDataService.dispose();
    _newProposalSub?.cancel();
    _connectionSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Notificar o mixin de notificações sobre mudança de lifecycle
    onAppLifecycleStateChanged(state);

    // Gerenciar wakelock com base no ciclo de vida do app
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App foi para background: liberar wakelock (inutilizado sem UI visível)
      WakelockService.instance.disable();
    }

    if (state == AppLifecycleState.resumed) {
      // App voltou ao foreground: reativar wakelock se personal ainda está online
      if (_isOnline) {
        WakelockService.instance.enable();
      }
      // ✅ CORREÇÃO CRÍTICA: Recriar listener de propostas quando app volta ao foreground
      // O listener pode ter sido perdido quando o WebSocket desconectou no background
      _recreateProposalListener();

      _attemptForegroundRecovery();

      // ✅ CORREÇÃO CRÍTICA: Reinicializar HomeBloc se estiver em HomeInitial
      // Quando o app volta do background, o HomeBloc pode estar em HomeInitial
      // e eventos de propostas são ignorados. Precisamos garantir que ele esteja em HomeLoaded
      final homeBloc = context.read<HomeBloc>();
      if (!homeBloc.isClosed) {
        if (homeBloc.state is HomeInitial) {
          print(
            '🔄 [PERSONAL_HOME] HomeBloc está em HomeInitial - reinicializando...',
          );
          homeBloc.add(const InitializeHome());
        }
      }

      // ✅ CORREÇÃO CRÍTICA: Reenviar status online/offline quando app volta ao foreground
      // Isso garante que o backend saiba o estado correto mesmo após desconexão no background
      // O estado do toggle é persistido localmente e deve ser restaurado no backend
      final wsService = sl<WebSocketService>();
      if (wsService.isConnected) {
        // Aguardar um pouco para garantir que WebSocket está totalmente reconectado
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;

          _syncPersonalOnlineStatus(reason: 'foreground_resume');
          print(
            '✅ [PERSONAL_HOME] Status online/offline reenviado após voltar do background',
          );
        });
      } else {
        print(
          '⚠️ [PERSONAL_HOME] WebSocket não conectado - status será reenviado quando conectar',
        );
      }

      // ✅ CORREÇÃO: Sincronizar aulas ativas quando app volta ao foreground
      // Isso garante que eventos perdidos durante sleep sejam recuperados
      final classesBloc = context.read<ClassesBloc>();
      if (!classesBloc.isClosed) {
        // Se WebSocket não está conectado, tentar reconectar
        if (classesBloc.state is ClassesLoaded) {
          final loadedState = classesBloc.state as ClassesLoaded;
          if (!loadedState.isWebSocketConnected) {
            print(
              '🔄 [PERSONAL_HOME] WebSocket desconectado - reconectando...',
            );
            classesBloc.add(const ClassesConnectWebSocket());
          } else {
            // WebSocket está conectado, mas pode ter perdido eventos durante sleep
            // Fazer refresh para sincronizar
            print(
              '🔄 [PERSONAL_HOME] App voltou ao foreground - sincronizando aulas ativas...',
            );
            classesBloc.add(const ClassesRefresh());
          }
        }
      }
    }
  }

  /// Recria o listener de propostas quando o app volta ao foreground
  /// Isso garante que propostas sejam recebidas mesmo após reconexão do WebSocket
  void _recreateProposalListener() {
    print('🔄 [PERSONAL_HOME] Recriando listener de propostas...');

    // O listener de conexão já cuida de recriar o listener quando o WebSocket reconecta
    // Mas vamos garantir que está configurado agora
    _setupProposalListener();

    // Se WebSocket já está conectado, o listener já foi criado acima
    // Se não está conectado, o listener de conexão vai criar quando conectar
    final wsService = sl<WebSocketService>();
    if (wsService.isConnected) {
      print('✅ [PERSONAL_HOME] WebSocket já conectado - listener recriado');
    } else {
      print(
        '⏳ [PERSONAL_HOME] WebSocket não conectado - listener será criado quando conectar',
      );
    }
  }

  /// Configura o listener de propostas
  /// Baseado no commit ee34dde que funcionava corretamente
  void _setupProposalListener() {
    if (!mounted) return;

    // Cancelar listener antigo se existir
    _newProposalSub?.cancel();

    // ✅ HOMOLOGAÇÃO: Usar código simples do commit antigo que funcionava
    // O backend já envia new_proposal com estrutura: { action: 'proposal_created', proposal: {...}, student: {...}, timestamp: ... }
    // Então message['data'] já tem a estrutura correta e podemos passar diretamente para _maybeShowIncomingProposal
    _newProposalSub = sl<WebSocketService>().messageStream.listen((message) {
      final type = message['type'] as String?;
      print('📥 [PERSONAL_HOME] Mensagem WebSocket recebida - tipo: $type');

      if (type == 'new_proposal' || type == 'proposal_created') {
        print('📨 [PERSONAL_HOME] Nova proposta recebida via WebSocket');
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          print('📨 [PERSONAL_HOME] Dados da proposta: ${data.keys}');
          _maybeShowIncomingProposal(data);
        } else {
          print('⚠️ [PERSONAL_HOME] Dados da proposta são null');
        }
      } else if (type == 'proposal_update') {
        // ✅ NOVO: Escutar atualizações de propostas para fechar modal quando cancelada ou aceita
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final action = data['action'] as String?;
          final proposal = data['proposal'] as Map<String, dynamic>?;
          final proposalId =
              proposal?['id']?.toString() ?? data['proposalId']?.toString();

          if (proposalId != null && _visibleProposalId == proposalId) {
            if (action == 'proposal_cancelled') {
              print(
                '❌ [PERSONAL_HOME] Proposta cancelada - fechando modal: $proposalId',
              );
              _closeProposalModal();
            } else if (action == 'proposal_accepted') {
              // Verificar se não foi este personal que aceitou
              // Verificar tanto _iAcceptedProposalId quanto _acceptingProposalIds para evitar race condition
              final isMyAcceptance =
                  _iAcceptedProposalId == proposalId ||
                  _acceptingProposalIds.contains(proposalId);
              if (!isMyAcceptance) {
                print(
                  '✅ [PERSONAL_HOME] Proposta aceita por outro personal - fechando modal: $proposalId',
                );
                _closeProposalModal();
              } else {
                print(
                  '✅ [PERSONAL_HOME] Proposta aceita por este personal - transicionando modal para matched: $proposalId',
                );
                // ✅ NOVO: Transicionar modal para estado matched
                _transitionModalToMatched();
              }
            }
          }
        }
      } else if (type == 'match_confirmed') {
        // ✅ NOVO: Escutar evento match_confirmed para transicionar modal
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final proposal = data['proposal'] as Map<String, dynamic>?;
          final eventProposalId =
              proposal?['id']?.toString() ?? data['proposalId']?.toString();

          if (eventProposalId != null &&
              _visibleProposalId == eventProposalId) {
            final isMyAcceptance =
                _iAcceptedProposalId == eventProposalId ||
                _acceptingProposalIds.contains(eventProposalId);
            if (isMyAcceptance) {
              print(
                '✅ [PERSONAL_HOME] Match confirmado - transicionando modal para matched: $eventProposalId',
              );
              _transitionModalToMatched();
            }
          }
        }
      } else if (type == 'financial_update') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          _handleFinancialUpdate(data);
        }
      }
    });

    print('✅ [PERSONAL_HOME] Listener de propostas configurado com sucesso');
  }

  /// ✅ NOVO: Transicionar modal para estado matched
  void _transitionModalToMatched() {
    if (_currentProposalModalKey?.currentState != null) {
      print(
        '🔄 [PERSONAL_HOME] Transicionando modal para matched via GlobalKey',
      );
      (_currentProposalModalKey!.currentState as dynamic).transitionToMatch();
    } else {
      print('⚠️ [PERSONAL_HOME] Modal key não disponível para transição');
    }
  }

  /// Fecha o modal de proposta se estiver aberto
  void _closeProposalModal() {
    if (_visibleProposalId == null) return;
    _currentProposalModalKey = null; // ✅ Limpar key ao fechar

    print('🚪 [PERSONAL_HOME] Fechando modal de proposta: $_visibleProposalId');

    // Limpar estado
    _visibleProposalId = null;

    // Fechar modal se estiver montado
    if (mounted) {
      try {
        Navigator.of(context).pop();
        print('✅ [PERSONAL_HOME] Modal fechado com sucesso');
      } catch (e) {
        print(
          '⚠️ [PERSONAL_HOME] Erro ao fechar modal (pode não estar aberto): $e',
        );
      }
    }
  }

  /// Carrega dados reais do personal trainer
  Future<void> _loadPersonalData() async {
    try {
      setState(() {
        _isLoadingPersonalData = true;
      });

      // Carregar perfil primeiro (obrigatório)
      Map<String, dynamic> profileData = {};
      Map<String, dynamic> statsData = {};
      Map<String, dynamic> financialData = {};

      try {
        profileData = await sl<ProfileApiService>().getUserProfile();
        print('✅ [PERSONAL HOME] Perfil carregado: $profileData');
        print(
          '🔍 [PERSONAL HOME] Chaves do perfil: ${profileData.keys.toList()}',
        );
      } catch (e) {
        print('⚠️ [PERSONAL HOME] Erro ao carregar perfil: $e');
      }

      try {
        statsData = await sl<ProfileApiService>().getUserStats();
        print('✅ [PERSONAL HOME] Stats carregados: $statsData');
      } catch (e) {
        print('⚠️ [PERSONAL HOME] Erro ao carregar stats: $e');
      }

      try {
        financialData = await sl<PersonalFinancialApiService>()
            .getPersonalFinancialStats();
        print('✅ [PERSONAL HOME] Dados financeiros carregados: $financialData');
      } catch (e) {
        print('⚠️ [PERSONAL HOME] Erro ao carregar dados financeiros: $e');
        // Fallback: usar dados mockados temporariamente até a API ser corrigida
        financialData = {
          'availableBalance': 0.0,
          'pendingBalance': 0.0,
          'totalEarned': 0.0,
          'totalWithdrawn': 0.0,
        };
      }

      // Processar dados do perfil
      final firstName = profileData['firstName'] ?? '';
      final lastName = profileData['lastName'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      final profileImageUrl =
          (profileData['profileImageUrl'] ??
                  profileData['imageUrl'] ??
                  profileData['avatarUrl'] ??
                  profileData['profileImage'] ??
                  '')
              .toString();

      print('🔍 [PERSONAL HOME] firstName: "$firstName"');
      print('🔍 [PERSONAL HOME] lastName: "$lastName"');
      print('🔍 [PERSONAL HOME] fullName: "$fullName"');

      // Processar dados financeiros (com fallback)
      double balance = 0.0;
      if (financialData.isNotEmpty) {
        try {
          final financialStats = PersonalFinancialStatsModel.fromJson(
            financialData,
          );
          balance = financialStats.availableBalance;
        } catch (e) {
          print('⚠️ [PERSONAL HOME] Erro ao processar dados financeiros: $e');
        }
      }

      // Extrair XP das stats (se disponível)
      int totalXp = 0;
      if (statsData.isNotEmpty) {
        totalXp = statsData['totalXP'] ?? statsData['totalXp'] ?? 0;
      }

      if (mounted) {
        final apiRadius = profileData['serviceRadiusKm'];
        if (apiRadius != null) {
          final parsed = double.tryParse(apiRadius.toString());
          if (parsed != null) {
            _raioAtendimento = ServiceRadiusConstants.clamp(parsed);
            try {
              sl<SharedPreferences>().setDouble(
                'personal_radius_km',
                _raioAtendimento,
              );
            } catch (_) {}
          }
        }

        setState(() {
          _personalName = fullName.isNotEmpty ? fullName : 'Personal Trainer';
          _balance = 'R\$ ${balance.toStringAsFixed(2).replaceAll('.', ',')}';
          statsDataCacheXp = totalXp.toString();
          _profileImageUrl = profileImageUrl.isNotEmpty
              ? profileImageUrl
              : null;
          _isLoadingPersonalData = false;
        });
      }
    } catch (e) {
      print('❌ [PERSONAL HOME] Erro geral ao carregar dados do personal: $e');

      if (mounted) {
        setState(() {
          _personalName = 'Personal Trainer';
          _balance = 'R\$ 0,00';
          statsDataCacheXp = '0';
          _profileImageUrl = null;
          _isLoadingPersonalData = false;
        });
      }
    }
  }

  /// Busca locais baseado na query (Google Places via API backend)
  Future<void> _onLocationSearchChanged(String query) async {
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final token = await sl<AuthService>().getValidToken();
      final results = await sl<LocationsService>().searchLocations(
        query,
        token: token,
        useCurrentLocation: true,
        limit: 8,
        locationContext: context,
      );
      if (!mounted) return;
      setState(() {
        _locationSuggestions = results;
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationSuggestions = [];
        _isLoadingLocations = false;
      });
      debugPrint('❌ [PERSONAL_HOME] Erro ao buscar locais: $e');
    }
  }

  /// Seleciona um local
  void _onLocationSelected(TrainingLocation location) {
    setState(() {
      _selectedLocation = location;
    });
    print('📍 [PERSONAL HOME] Local selecionado: ${location.name}');
    // ✅ Persistir local selecionado
    try {
      final prefs = sl<SharedPreferences>();
      prefs.setString('personal_location_name', location.name ?? '');
      prefs.setString('personal_location_address', location.address);
      if (location.latitude != null) {
        prefs.setDouble('personal_location_lat', location.latitude!);
      }
      if (location.longitude != null) {
        prefs.setDouble('personal_location_lng', location.longitude!);
      }
    } catch (_) {}

    // ✅ Se estiver online, atualizar no backend também
    if (_isOnline) {
      _syncPersonalOnlineStatus(reason: 'location_change');
      final centerLat = location.latitude;
      final centerLng = location.longitude;
      if (centerLat != null && centerLng != null) {
        final wsService = sl<WebSocketService>();
        if (!wsService.isConnected) {
          _updateServiceLocationViaRest(centerLat, centerLng, _raioAtendimento);
        }
      }
    }
  }

  // Removido timer e modal fake. Agora usamos eventos reais via WebSocket em _subscribeWebSocket.

  /// Atualiza localização de atendimento via endpoint REST
  Future<void> _updateServiceLocationViaRest(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    try {
      print(
        '📍 [PERSONAL_HOME] Atualizando localização via REST: lat=$lat, lng=$lng, radius=$radiusKm',
      );
      final profileApiService = sl<ProfileApiService>();

      // ✅ Usar o método específico para atualizar localização de atendimento
      await profileApiService.updateServiceLocation(
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
      );

      print('✅ [PERSONAL_HOME] Localização atualizada via REST com sucesso');

      // Se WebSocket conectar depois, ele vai reenviar via WebSocket também
      // mas o importante é que já está salvo no banco
    } catch (e) {
      print('❌ [PERSONAL_HOME] Erro ao atualizar localização via REST: $e');
      // Não bloquear o fluxo - o WebSocket pode tentar depois
    }
  }

  Future<void> _persistRadiusViaRestIfPossible() async {
    try {
      final prefs = sl<SharedPreferences>();
      final lat = prefs.getDouble('personal_location_lat');
      final lng = prefs.getDouble('personal_location_lng');
      if (lat == null || lng == null) return;
      await _updateServiceLocationViaRest(lat, lng, _raioAtendimento);
    } catch (_) {}
  }

  void _showTimeoutMessage(String studentName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ Tempo esgotado! Proposta de $studentName expirou.'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    print('⏰ Proposta de $studentName expirou por timeout');
  }

  /// Verifica se já existe uma aula agendada no mesmo horário
  Future<bool> _checkScheduleConflict(DateTime date, String time) async {
    try {
      final classesApi = sl<ClassesApiService>();
      final response = await classesApi.getClasses(
        GetClassesDto(
          page: 1,
          limit: 100,
          date:
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        ),
      );

      final List<dynamic> classesData = response['classes'] ?? [];

      for (final classJson in classesData) {
        final classTime = classJson['time'] as String?;
        final classStatus = classJson['status'] as String?;

        if (classTime == time &&
            (classStatus == 'SCHEDULED' ||
                classStatus == 'PENDING_CONFIRMATION' ||
                classStatus == 'ACTIVE')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Erro ao verificar conflito de horário: $e');
      return false;
    }
  }

  void _onBottomNavTap(int index) {
    print('🔍 Navegando para página $index');
    setState(() {
      _currentBottomNavIndex = index;
    });
    // Refresh leve ao voltar para Home, sem polling e sem flicker
    if (index == 0) {
      _refreshIfHomeTab();
    } else if (index == 3) {
      // Perfil: recarregar dados do perfil de forma leve
      _refreshProfileIfNeeded();
    }
  }

  Future<void> _refreshProfileIfNeeded() async {
    try {
      final prevName = _personalName;
      Map<String, dynamic> profileData = {};
      try {
        profileData = await sl<ProfileApiService>().getUserProfile();
      } catch (_) {}
      final firstName = profileData['firstName'] ?? '';
      final lastName = profileData['lastName'] ?? '';
      final fullName = '$firstName $lastName'.trim();
      final profileImageUrl =
          (profileData['profileImageUrl'] ??
                  profileData['imageUrl'] ??
                  profileData['avatarUrl'] ??
                  profileData['profileImage'] ??
                  '')
              .toString();
      if (mounted && fullName.isNotEmpty && fullName != prevName) {
        setState(() {
          _personalName = fullName;
          _profileImageUrl = profileImageUrl.isNotEmpty
              ? profileImageUrl
              : null;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false, // Páginas normais têm fundo claro
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFDFE), // Background do Figma
        appBar: _currentBottomNavIndex == 0
            ? CustomTopBar(
                unreadNotificationsCount: unreadCount,
                onNotificationTap: showNotificationsModal,
              )
            : null,
        body: SafeArea(
          top: _currentBottomNavIndex == 0 ? false : true,
          bottom: true,
          child: IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              _buildHomeView(),
              const ClassesPage(),
              const ProposalsPage(),
              const PersonalProfilePage(),
            ],
          ),
        ),
        bottomNavigationBar: PersonalBottomNavigation(
          currentIndex: _currentBottomNavIndex,
          onTap: _onBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    return BlocBuilder<ClassesBloc, ClassesState>(
      builder: (context, state) {
        return RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () async {
            await _loadPersonalData();
            if (mounted) {
              context.read<BalanceBloc>().add(RefreshBalance());
            }
            final uid = sl<AuthService>().currentUserId;
            if (uid != null && uid.isNotEmpty) {
              sl<GamificationBloc>().add(RefreshGamificationData(userId: uid));
            }
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStripeOnboardingBanner(),
                if (latestUnreadCancellationNotification != null) ...[
                  PersistentNoticeCard(
                    title: latestUnreadCancellationNotification!.title,
                    message: latestUnreadCancellationNotification!.message,
                    onTap: () async {
                      await markAsRead(
                        latestUnreadCancellationNotification!.id,
                      );
                      if (!mounted) return;
                      _onBottomNavTap(1);
                    },
                    onDismiss: () {
                      markAsRead(latestUnreadCancellationNotification!.id);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Card principal escuro
                _buildMainCard(state),

                const SizedBox(height: 20),
                // Missão da semana (gamificação em tempo real)
                const PersonalWeeklyMissionCard(),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(ClassesState state) {
    // Usar dados reais do personal trainer
    final personalName = _personalName;
    final balance = _balance;
    // xp removido do layout

    // Contar aulas do dia
    int todayClasses = 0;
    int activeClasses = 0;
    String? activeClassId;

    if (state is ClassesLoaded) {
      final today = DateTime.now();
      todayClasses = state.classes.where((classData) {
        final classDate = classData.date;
        final isToday =
            classDate.year == today.year &&
            classDate.month == today.month &&
            classDate.day == today.day;
        // Contar apenas aulas não finalizadas/canceladas
        final isCountable = !classData.isCompleted && !classData.isCancelled;
        return isToday && isCountable;
      }).length;

      // Encontrar aula ativa (apenas se houver aulas)
      if (state.classes.isNotEmpty) {
        try {
          final activeClass = state.classes.firstWhere(
            (classData) => classData.status == 'ACTIVE',
          );

          if (activeClass.status == 'ACTIVE') {
            activeClasses = 1;
            activeClassId = activeClass.id;
          }
        } catch (e) {
          // Nenhuma aula ativa encontrada, continuar normalmente
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo (XP/nível removidos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoChip(
                icon: Icons.monetization_on,
                label: 'Saldo:',
                value: _isLoadingPersonalData ? '...' : balance,
                valueColor: AppColors.primaryOrange,
              ),
              _buildInfoChip(
                icon: Icons.emoji_events,
                label: 'XP:',
                value: _isLoadingPersonalData
                    ? '...'
                    : (statsDataCacheXp ?? '0'),
                valueColor: AppColors.primaryOrange,
              ),
            ],
          ),

          const SizedBox(height: 20), // Reduzido de 24 para 20
          // Perfil e saudação
          Row(
            children: [
              GestureDetector(
                onTap: () => _onBottomNavTap(3),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryOrange,
                      width: 3,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child:
                        (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty)
                        ? Image.network(
                            _profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.person,
                                  color: Color(0xFF666666),
                                  size: 40,
                                ),
                          )
                        : const Icon(
                            Icons.person,
                            color: Color(0xFF666666),
                            size: 40,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      personalName,
                      style: const TextStyle(
                        fontSize: 24, // Padrão do título principal
                        fontWeight: FontWeight.w600, // semibold
                        color: Color(0xFFF9F9F9),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      todayClasses == 0
                          ? 'Nenhuma aula hoje'
                          : todayClasses == 1
                          ? 'Você tem 1 aula hoje!'
                          : 'Você tem $todayClasses aulas hoje!',
                      style: const TextStyle(
                        fontSize: 14, // Padrão do texto descritivo
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFF3F3F3),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20), // Reduzido de 24 para 20
          // Divider
          Container(height: 1, color: const Color(0xFFF3F3F3)),

          const SizedBox(height: 20), // Reduzido de 24 para 20
          // Aula ativa (se houver)
          if (activeClasses > 0 && activeClassId != null) ...[
            _buildActiveClassCard(activeClassId),
            const SizedBox(height: 20),
          ],

          // Disponibilidade
          const Text(
            'Você está disponível hoje?',
            style: TextStyle(
              fontSize: 18, // Padrão do título de seção
              fontWeight: FontWeight.w700, // bold
              color: Color(0xFFF9F9F9),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20), // Reduzido de 24 para 20
          // Toggle offline/online funcional
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Offline',
                style: TextStyle(
                  fontSize: 12, // Padrão do texto pequeno
                  color: _isOnline
                      ? const Color(0xFFF3F3F3)
                      : AppColors.primaryOrange,
                  height: 1.3,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final wasOnline = _isOnline;
                  setState(() {
                    _isOnline = !_isOnline;
                  });

                  print(
                    '🔄 [PERSONAL_HOME] Toggle online: $wasOnline → $_isOnline',
                  );

                  // Persistir status
                  try {
                    sl<SharedPreferences>().setBool(_onlinePrefKey, _isOnline);
                    print('💾 [PERSONAL_HOME] Status online salvo: $_isOnline');
                  } catch (e) {
                    print('❌ [PERSONAL_HOME] Erro ao salvar status online: $e');
                  }

                  // Wakelock: manter tela ativa enquanto online para proposta aparecer imediatamente
                  if (_isOnline) {
                    WakelockService.instance.enable();
                  } else {
                    WakelockService.instance.disable();
                  }

                  if (_isOnline) {
                    debugPrint(
                      '🔁[PROPOSAL_RT] Toggle online → tentativa de recovery imediata',
                    );
                    final wsService = sl<WebSocketService>();
                    if (!wsService.isConnected) {
                      wsService.connect().catchError((e) {
                        print(
                          '❌ [PERSONAL_HOME] Falha ao conectar WebSocket: $e',
                        );
                      });
                    }
                    _syncPersonalOnlineStatus(reason: 'toggle_online');
                    _attemptForegroundRecovery();
                  } else {
                    print('📴 [PERSONAL_HOME] Personal foi para offline');
                    _syncPersonalOnlineStatus(reason: 'toggle_offline');
                  }
                },
                child: Container(
                  width: 88,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(21),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        alignment: _isOnline
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Online',
                style: TextStyle(
                  fontSize: 12, // Padrão do texto pequeno
                  color: _isOnline
                      ? const Color(0xFFFF6A00)
                      : const Color(0xFFF3F3F3),
                  height: 1.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Container(height: 1, color: const Color(0xFFF3F3F3)),

          const SizedBox(height: 20),

          // Raio de atendimento
          const Text(
            'Área de atendimento',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, // Padrão do título de seção
              fontWeight: FontWeight.w700, // bold
              color: Color(0xFFF9F9F9),
              height: 1.2,
            ),
          ),

          const SizedBox(height: 20),

          // Campo de localização
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFF3F3F3).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ponto  inicial',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF9F9F9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LocationSearchField(
                  initialValue: _selectedLocation?.name,
                  suggestions: _locationSuggestions,
                  isLoading: _isLoadingLocations,
                  placeholder: 'Escolher local de partida',
                  onSearchChanged: _onLocationSearchChanged,
                  onLocationSelected: _onLocationSelected,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Slider do raio funcional
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Slider customizado ocupando largura total
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.primaryOrange,
                  inactiveTrackColor: const Color(0xFFF3F3F3),
                  trackHeight: 8.0,
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12.0,
                    elevation: 4.0,
                  ),
                  overlayColor: AppColors.primaryOrange.withOpacity(0.2),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20.0,
                  ),
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: Slider(
                  value: _raioAtendimento,
                  min: ServiceRadiusConstants.minKm,
                  max: ServiceRadiusConstants.maxKm,
                  divisions: ServiceRadiusConstants.maxKmInt,
                  onChanged: (double value) {
                    setState(() {
                      _raioAtendimento = ServiceRadiusConstants.clamp(value);
                    });
                    // ✅ Persistir raio selecionado
                    try {
                      sl<SharedPreferences>().setDouble(
                        'personal_radius_km',
                        _raioAtendimento,
                      );
                    } catch (_) {}
                    // SSOT: re-sincroniza personal_online via WebSocketService
                    if (_isOnline) {
                      _syncPersonalOnlineStatus(reason: 'radius_change');
                      final wsService = sl<WebSocketService>();
                      if (!wsService.isConnected) {
                        _persistRadiusViaRestIfPossible();
                      }
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Labels 0 km, valor atual e 80 km alinhados
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0 km',
                style: TextStyle(
                  fontSize: 12, // Padrão do texto pequeno
                  color: Color(0xFFF3F3F3),
                  height: 1.3,
                ),
              ),
              // Texto com valor atual centralizado
              Text(
                '${_raioAtendimento.round()} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                  height: 1.2,
                ),
              ),
              const Text(
                '${ServiceRadiusConstants.maxKmInt} km',
                style: TextStyle(
                  fontSize: 12, // Padrão do texto pequeno
                  color: Color(0xFFF3F3F3),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveClassCard(String classId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primaryOrange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aula em andamento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 16,
                      color: AppColors.primaryOrange,
                    ),
                    const SizedBox(width: 4),
                    ClassTimerWidget(
                      classId: classId,
                      showSeconds: false,
                      suffix: 'm restantes',
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFF3F3F3), width: 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14, // Padrão do texto descritivo
                fontWeight: FontWeight.w700, // bold
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: label,
                  style: const TextStyle(color: Color(0xFFF9F9F9)),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: value,
                  style: TextStyle(color: valueColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tenta recuperação leve pós-build
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _attemptForegroundRecovery(),
    );
  }

  Future<void> _attemptForegroundRecovery() async {
    if (!mounted) return;
    if (!_isOnline) {
      debugPrint('🔁[PROPOSAL_RT] Recovery abortado (offline)');
      return;
    }
    try {
      final resp = await sl<PersonalProposalsApiService>().getProposals(
        limit: 10,
        status: 'pending',
      );
      final List list =
          (resp['items'] ?? resp['data'] ?? resp['results'] ?? []) as List;
      final now = DateTime.now();
      for (final raw in list) {
        final p = Map<String, dynamic>.from(raw as Map);
        final id = p['id']?.toString();
        if (id == null || _handledProposalIds.contains(id)) continue;
        if (!_isProposalFreshForNotification(p)) continue;
        // Filtro por raio a partir do local selecionado
        if (!_isProposalWithinRadius(p)) continue;
        final ts = _extractProposalNotificationTimestamp(p);
        debugPrint(
          '🔁[PROPOSAL_RT] Foreground recovery exibindo id=$id age=${ts != null ? now.difference(ts).inSeconds : '?'}s',
        );
        _handledProposalIds.add(id);
        final student = p['student'] as Map<String, dynamic>? ?? {};
        final studentName = (student['name'] ?? 'Aluno') as String;
        final locationName = (p['locationName'] ?? '') as String;
        final modality = (p['modalityName'] ?? '-') as String;
        final time = (p['trainingTime'] ?? '-') as String;
        final trainingDateIso = (p['trainingDate'] ?? '') as String;
        String? formattedDate;
        try {
          if (trainingDateIso.isNotEmpty) {
            final dt = DateTime.parse(trainingDateIso);
            // Usar UTC para evitar problemas de fuso horário
            final utcDt = dt.isUtc
                ? dt
                : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute);
            formattedDate =
                '${utcDt.day.toString().padLeft(2, '0')}/${utcDt.month.toString().padLeft(2, '0')}';
            print('🔍 [RECOVERY] Data original: $trainingDateIso');
            print('🔍 [RECOVERY] Data parseada: ${dt.toIso8601String()}');
            print('🔍 [RECOVERY] Data UTC: ${utcDt.toIso8601String()}');
            print('🔍 [RECOVERY] Data formatada: $formattedDate');
          }
        } catch (e) {
          print('❌ [RECOVERY] Erro ao parsear data: $e');
        }
        final priceNum = (p['price'] as num?)?.round() ?? 0;
        if (!mounted) return;
        _visibleProposalId = id;
        _visibleProposalId = id;
        // PRIMEIRA CHAMADA REMOVIDA - usando apenas a segunda com dados enriquecidos
        /*
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          builder: (context) => Stack(
            children: [
              // Blur background
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // Modal content
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  child: ProposalModal(
                    studentName: studentName,
                    location: locationName,
                    price: priceNum.toString(),
                    time: time,
                    date: formattedDate,
                    modality: modality,
                    countdownSeconds: 15,
                    studentRating: null,
                    studentExperience: null,
                    studentImageUrl: null,
                    proposalId: id,
                    onAccept: () async {
                      if (_acceptingProposalIds.contains(id)) return;
                      _acceptingProposalIds.add(id);
                      try {
                        debugPrint('🤝[PROPOSAL_RT] (Recovery) Aceitando proposalId=$id ...');
                        
                        // Verificar conflito de horário
                        try {
                          final dt = DateTime.parse(trainingDateIso);
                          final hasConflict = await _checkScheduleConflict(dt, time);
                          if (hasConflict) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Você já tem uma aula agendada para esse horário'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                        } catch (e) {
                          debugPrint('⚠️ Erro ao verificar conflito: $e');
                        }
                        
                        _iAcceptedProposalId = id;
                        await sl<PersonalProposalsApiService>().acceptProposal(id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Proposta aceita! Aguardando confirmação.')),
                        );
                        debugPrint('✅[PROPOSAL_RT] (Recovery) Aceita proposalId=$id');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao aceitar: $e')),
                        );
                        debugPrint('❌[PROPOSAL_RT] (Recovery) Falha ao aceitar proposalId=$id err=$e');
                      } finally {
                        _acceptingProposalIds.remove(id);
                      }
                    },
                    onIgnore: () {
                      _visibleProposalId = null;
                      Navigator.of(context).pop();
                    },
                    onTimeout: () {
                      Navigator.of(context).pop();
                      _showTimeoutMessage(studentName);
                      debugPrint('⏰[PROPOSAL_RT] (Recovery) Timeout proposalId=$id');
                      _visibleProposalId = null;
                    },
                  ),
                ),
              ),
            ],
          ),
        );
        */
        break; // Exibe apenas a mais recente elegível
      }
    } catch (_) {}
  }

  /// ✅ CRÍTICO: Verificar e processar deep links pendentes (FCM de estado TERMINATED)
  /// Chamado quando PersonalHomePage é montada, como fallback do splash
  Future<void> _coordinatePendingDeepLinkAndGamification() async {
    try {
      await DeepLinkService.hydratePendingDeepLinkFromStorage();
      if (!mounted) return;

      if (DeepLinkService.hasPendingDeepLink) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _checkAndProcessPendingDeepLink();
        });
        return;
      }

      // Exibe aviso de gamificação apenas se não houver deep link pendente
      sl<GamificationDevNoticeCoordinator>().maybeShow(context);
    } catch (e) {
      print('⚠️ [PERSONAL_HOME] Erro ao coordenar deep link/gamificação: $e');
      if (!mounted) return;
      sl<GamificationDevNoticeCoordinator>().maybeShow(context);
    }
  }

  /// ✅ CRÍTICO: Verificar e processar deep links pendentes (FCM de estado TERMINATED)
  /// Chamado quando PersonalHomePage é montada, como fallback do splash
  Future<void> _checkAndProcessPendingDeepLink() async {
    try {
      // Fallback extra: garantir carga do pending salvo em SharedPreferences
      await DeepLinkService.hydratePendingDeepLinkFromStorage();

      if (!DeepLinkService.hasPendingDeepLink) {
        print('ℹ️ [PERSONAL_HOME] Nenhum deep link pendente');
        return;
      }

      print('🔗 [PERSONAL_HOME] ===== DEEP LINK PENDENTE DETECTADO =====');
      print(
        '🔗 [PERSONAL_HOME] proposalId: ${DeepLinkService.pendingProposalId}',
      );

      // ✅ CORREÇÃO: Aumentar delay para garantir que UI está totalmente pronta
      // e que todos os listeners estão configurados
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      print('🔗 [PERSONAL_HOME] Processando deep link pendente...');
      print(
        '🔗 [PERSONAL_HOME] hasPendingDeepLink: ${DeepLinkService.hasPendingDeepLink}',
      );
      print(
        '🔗 [PERSONAL_HOME] pendingProposalId: ${DeepLinkService.pendingProposalId}',
      );

      // Processar o deep link
      await DeepLinkService.processPendingDeepLink();

      print('✅ [PERSONAL_HOME] Deep link processado');
    } catch (e) {
      print('❌ [PERSONAL_HOME] Erro ao processar deep link pendente: $e');
    }
  }

  /// Callback chamado quando há atualização financeira (saldo da carteira)
  void _handleFinancialUpdate(Map<String, dynamic> data) {
    try {
      final action = data['action'] as String?;
      final userId = data['userId'] as String?;
      final financial = data['financial'] as Map<String, dynamic>?;

      print('💰 [FINANCIAL_UPDATE] Evento recebido: $action');
      print('💰 [FINANCIAL_UPDATE] UserId: $userId');
      print('💰 [FINANCIAL_UPDATE] Financial data: $financial');

      // Verificar se é para o usuário atual
      final currentUserId = sl<AuthService>().currentUserId;
      if (userId != currentUserId) {
        print(
          '💰 [FINANCIAL_UPDATE] Evento não é para o usuário atual, ignorando',
        );
        return;
      }

      if (action == 'payment_released' && financial != null) {
        final amount = financial['amount'] as num?;
        final classId = financial['classId']?.toString();
        final amountValue = amount?.toDouble() ?? 0.0;

        if (amountValue <= 0) {
          print(
            '💰 [FINANCIAL_UPDATE] Ignorando pagamento com valor <= 0 (classId=$classId, amount=$amountValue)',
          );
          return;
        }

        if (classId != null && classId.isNotEmpty) {
          if (_processedFinancialClassIds.contains(classId)) {
            print(
              '💰 [FINANCIAL_UPDATE] Evento financeiro duplicado ignorado para classId=$classId',
            );
            return;
          }
          _processedFinancialClassIds.add(classId);
        }

        if (amount != null) {
          print('💰 [FINANCIAL_UPDATE] Pagamento liberado: R\$ $amount');

          // Atualizar saldo em tempo real
          if (mounted) {
            setState(() {
              // Atualizar saldo atual
              final currentBalance = _balance
                  .replaceAll('R\$ ', '')
                  .replaceAll(',', '.');
              final currentBalanceNum = double.tryParse(currentBalance) ?? 0.0;
              final newBalance = currentBalanceNum + amount.toDouble();
              _balance =
                  'R\$ ${newBalance.toStringAsFixed(2).replaceAll('.', ',')}';
            });

            // Mostrar notificação de ganho
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '💰 Ganho de R\$ ${amount.toStringAsFixed(2).replaceAll('.', ',')} adicionado ao seu saldo!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print(
        '❌ [FINANCIAL_UPDATE] Erro ao processar atualização financeira: $e',
      );
    }
  }

  /// Callback chamado quando uma nova aula é criada (para cache do chat)
  void _onClassCreated(Map<String, dynamic> classData) {
    try {
      final proposalId = classData['proposalId'] as String?;
      if (proposalId == null) return;

      // Preencher cache para o chat
      final classId = classData['id'] as String?;
      final studentId = classData['studentId'] as String?;
      final location = classData['location'] as String?;
      final date = classData['date'] as String?;
      final time = classData['time'] as String?;
      final duration = classData['duration'] as String?;

      if (classId != null && studentId != null) {
        _classByProposalId[proposalId] = {
          'classId': classId,
          'studentId': studentId,
          'location': location ?? '',
          'date': date ?? '',
          'time': time ?? '',
          'duration': duration ?? '',
        };

        debugPrint(
          '💾 [PERSONAL_HOME] Cache do chat atualizado para proposalId=$proposalId',
        );

        // Resolver qualquer Completer pendente
        final completer = _classWaiterByProposalId[proposalId];
        if (completer != null && !completer.isCompleted) {
          completer.complete(_classByProposalId[proposalId]!);
          _classWaiterByProposalId.remove(proposalId);
          debugPrint(
            '✅ [PERSONAL_HOME] Completer resolvido para proposalId=$proposalId',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [PERSONAL_HOME] Erro ao processar class_created: $e');
    }
  }

  void _maybeShowIncomingProposal(Map<String, dynamic> data) async {
    try {
      final action = data['action'] as String?;
      if (action != null && action != 'proposal_created') {
        print(
          '⚠️ [PERSONAL_HOME] Action não é proposal_created, ignorando. Action: $action',
        );
        return;
      }

      if (!_isOnline) {
        print(
          '⚠️ [PERSONAL_HOME] Personal não está online, ignorando proposta',
        );
        return;
      }

      print('✅ [PERSONAL_HOME] Personal está online, processando proposta...');

      final proposal = data['proposal'] as Map<String, dynamic>?;
      if (proposal == null) {
        print('⚠️ [PERSONAL_HOME] Proposal é null, ignorando');
        return;
      }

      print('✅ [PERSONAL_HOME] Proposal encontrado: ${proposal['id']}');

      final createdAtIso = (proposal['createdAt'] ?? data['timestamp'])
          ?.toString();
      if (createdAtIso == null) {
        print('⚠️ [PERSONAL_HOME] createdAtIso é null, ignorando');
        return;
      }

      if (!_isProposalFreshForNotification(proposal, wrapper: data)) {
        final ts = _extractProposalNotificationTimestamp(
          proposal,
          wrapper: data,
        );
        final ageMin = ts != null
            ? DateTime.now().difference(ts).inMinutes
            : null;
        print(
          '⚠️ [PERSONAL_HOME] Proposta expirada para exibição imediata (${ageMin ?? '?'}min >= 30min), ignorando',
        );
        return;
      }

      // Filtro por raio
      print(
        '📏 [PERSONAL_HOME] Verificando se proposta está dentro do raio...',
      );
      final isWithinRadius = _isProposalWithinRadius(proposal);
      print('📏 [PERSONAL_HOME] Proposta dentro do raio: $isWithinRadius');
      if (!isWithinRadius) {
        print('⚠️ [PERSONAL_HOME] Proposta fora do raio, ignorando');
        return;
      }

      print(
        '✅ [PERSONAL_HOME] Proposta passou em todos os filtros, exibindo modal...',
      );

      final proposalId = proposal['id']?.toString();
      if (proposalId == null) return;
      if (_handledProposalIds.contains(proposalId)) return;
      _handledProposalIds.add(proposalId);
      _visibleProposalId = proposalId;

      final locationName = (proposal['locationName'] ?? '') as String;
      final modality = (proposal['modalityName'] ?? '-') as String;
      final time = (proposal['trainingTime'] ?? '-') as String;
      final trainingDateIso = (proposal['trainingDate'] ?? '') as String;
      String? formattedDate;
      try {
        if (trainingDateIso.isNotEmpty) {
          final dt = DateTime.parse(trainingDateIso);
          final utcDt = dt.isUtc
              ? dt
              : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute);
          formattedDate =
              '${utcDt.day.toString().padLeft(2, '0')}/${utcDt.month.toString().padLeft(2, '0')}';
        }
      } catch (_) {}
      final priceNum = (proposal['price'] ?? 0).toString();

      // Enriquecimento opcional do aluno
      String studentName = (proposal['student']?['name'] ?? 'Aluno') as String;
      String? ratingStr;
      String? experienceStr;
      String? imageUrl;
      try {
        final studentId =
            (proposal['student']?['id'] ??
                    proposal['studentId'] ??
                    proposal['student_id'])
                ?.toString();
        if (studentId != null && studentId.isNotEmpty) {
          final basic = await sl<UsersApiService>().getUserBasicInfo(studentId);
          final firstName = (basic['firstName'] ?? '').toString();
          final lastName = (basic['lastName'] ?? '').toString();
          final full = ('$firstName $lastName').trim();
          if (full.isNotEmpty) studentName = full;
          final rating = (basic['rating'] ?? '0.0').toString();
          ratingStr = rating.replaceAll('.', ',');
          experienceStr = sl<UsersApiService>().calculateTimeOnPlatform(
            basic['createdAt'] as String?,
          );
          imageUrl = (basic['profileImageUrl'] ?? '').toString();
        }
      } catch (_) {}

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (context) => Stack(
          children: [
            // Blur background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
            // Modal content
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: ProposalModal(
                  key: _currentProposalModalKey =
                      GlobalKey<
                        State<ProposalModal>
                      >(), // ✅ NOVO: Key para transicionar para matched quando WebSocket notificar
                  studentName: studentName,
                  location: locationName,
                  price: (double.tryParse(priceNum)?.round() ?? 0).toString(),
                  time: time,
                  date: formattedDate,
                  modality: modality,
                  countdownSeconds: 15,
                  studentRating: ratingStr,
                  studentExperience: experienceStr,
                  studentImageUrl: imageUrl,
                  proposalId: proposalId,
                  onAccept: () async {
                    try {
                      if (_acceptingProposalIds.contains(proposalId)) return;
                      _acceptingProposalIds.add(proposalId);

                      // ✅ CORREÇÃO: Definir _iAcceptedProposalId ANTES de chamar a API
                      // Isso garante que o listener não feche o modal quando o evento WebSocket chegar
                      _iAcceptedProposalId = proposalId;

                      // Verificar conflito de horário
                      try {
                        final dt = DateTime.parse(trainingDateIso);
                        final hasConflict = await _checkScheduleConflict(
                          dt,
                          time,
                        );
                        if (hasConflict) {
                          // Limpar estado se houver conflito
                          _iAcceptedProposalId = null;
                          _acceptingProposalIds.remove(proposalId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Você já tem uma aula agendada para esse horário',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          return;
                        }
                      } catch (e) {
                        debugPrint('⚠️ Erro ao verificar conflito: $e');
                      }

                      await sl<PersonalProposalsApiService>().acceptProposal(
                        proposalId,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Proposta aceita! Aguardando confirmação.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao aceitar: $e')),
                        );
                      }
                    } finally {
                      _acceptingProposalIds.remove(proposalId);
                    }
                  },
                  onIgnore: () {
                    _visibleProposalId = null;
                    _currentProposalModalKey = null; // ✅ Limpar key ao ignorar
                    Navigator.of(context).pop();
                  },
                  onTimeout: () {
                    Navigator.of(context).pop();
                    _showTimeoutMessage(studentName);
                    _visibleProposalId = null;
                    _currentProposalModalKey = null; // ✅ Limpar key ao timeout
                  },
                  // ✅ NOVO: Callback onMatched não é necessário aqui porque
                  // o listener do WebSocket já chama _transitionModalToMatched() diretamente
                  onChatPressed: () async {
                    print('💬 [PERSONAL_HOME] Botão Chat pressionado');
                    try {
                      final pid = proposalId;
                      print('💬 [PERSONAL_HOME] ProposalId: $pid');

                      // Se já está no cache, abrir direto
                      final cached = _classByProposalId[pid];
                      print('💬 [PERSONAL_HOME] Cache encontrado: $cached');

                      if (cached != null) {
                        if (!mounted) return;
                        print(
                          '💬 [PERSONAL_HOME] Navegando para ChatPage com dados do cache...',
                        );

                        // Fechar modal em background e navegar imediatamente
                        Navigator.of(context).pop();
                        await Future.microtask(() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                classId: cached['classId'] ?? '',
                                receiverId: cached['studentId'] ?? '',
                                receiverName: studentName,
                                location: cached['location'] ?? '',
                                date: cached['date'] ?? '',
                                time: cached['time'] ?? '',
                                duration:
                                    ((cached['duration'] ?? '')).isNotEmpty
                                    ? '${cached['duration']} min'
                                    : '',
                                currentUserIsStudent: false,
                              ),
                            ),
                          );
                        });
                        print('✅ [PERSONAL_HOME] ChatPage aberta com sucesso');
                        return;
                      }
                      // Ainda não chegou o class_created: aguardar via WS (sem fetch)
                      print(
                        '💬 [PERSONAL_HOME] Aguardando dados da aula via WebSocket...',
                      );
                      final completer = Completer<Map<String, String>>();
                      _classWaiterByProposalId[pid] = completer;
                      Map<String, String> cls;
                      try {
                        cls = await completer.future.timeout(
                          const Duration(seconds: 12),
                        );
                        print(
                          '💬 [PERSONAL_HOME] Dados recebidos via WebSocket: $cls',
                        );
                      } catch (_) {
                        print(
                          '❌ [PERSONAL_HOME] Timeout aguardando dados da aula',
                        );
                        _classWaiterByProposalId.remove(pid);
                        return;
                      }
                      if (!mounted) return;
                      print(
                        '💬 [PERSONAL_HOME] Navegando para ChatPage com dados do WebSocket...',
                      );

                      // Fechar modal em background e navegar imediatamente
                      Navigator.of(context).pop();
                      await Future.microtask(() {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              classId: cls['classId'] ?? '',
                              receiverId: cls['studentId'] ?? '',
                              receiverName: studentName,
                              location: cls['location'] ?? '',
                              date: cls['date'] ?? '',
                              time: cls['time'] ?? '',
                              duration: ((cls['duration'] ?? '')).isNotEmpty
                                  ? '${cls['duration']} min'
                                  : '',
                              currentUserIsStudent: false,
                            ),
                          ),
                        );
                      });
                      print('✅ [PERSONAL_HOME] ChatPage aberta com sucesso');
                    } catch (e) {
                      print('❌ [PERSONAL_HOME] Erro ao abrir ChatPage: $e');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      );
    } catch (_) {}
  }

  /// Navega para tracking quando aluno confirma aula (chamado do BlocListener)
  void _navigateToTrackingFromHome(ClassResponseDto classData) {
    if (!mounted) return;

    print(
      '🚀 [PERSONAL_HOME] ClassesStartSuccess recebido - navegando para tracking',
    );
    print('🚀 [PERSONAL_HOME] ClassId: ${classData.id}');

    // Obter a mesma instância do ClassesBloc conectada ao WebSocket
    final classesBloc = context.read<ClassesBloc>();

    // Validar que o BLoC está conectado ao WebSocket
    if (classesBloc.state is ClassesLoaded) {
      final state = classesBloc.state as ClassesLoaded;
      if (!state.isWebSocketConnected) {
        print('⚠️ [PERSONAL_HOME] WebSocket não conectado, reconectando...');
        classesBloc.add(const ClassesConnectWebSocket());
      }
    }

    // Formatar data para o formato esperado pela página
    String _formatDate(DateTime date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final classDay = DateTime(date.year, date.month, date.day);

      if (classDay == today) {
        return 'Hoje';
      } else if (classDay == today.add(const Duration(days: 1))) {
        return 'Amanhã';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: classesBloc,
          child: PersonalClassTrackingPage(
            aula: {
              'id': classData.id,
              'studentName': classData.studentName,
              'personalName': classData.personalName,
              'location': classData.location,
              'date': _formatDate(classData.date),
              'time': classData.time,
              'duration': '${classData.duration}min',
              'durationMinutes': classData.duration,
              if (classData.proposalPrice != null)
                'proposalPrice': classData.proposalPrice,
            },
          ),
        ),
      ),
    );
  }

  Future<void> _refreshIfHomeTab() async {
    if (!mounted) return;
    // Apenas recarrega se estiver na aba Home (0)
    if (_currentBottomNavIndex == 0) {
      // Carrega dados, mas aplica setState apenas se houver diferença para evitar "piscada"
      final prevName = _personalName;
      final prevBalance = _balance;
      final prevXp = statsDataCacheXp;
      await _loadPersonalData();
      if (mounted &&
          (prevName == _personalName &&
              prevBalance == _balance &&
              prevXp == statsDataCacheXp)) {
        // Nenhuma mudança → nada de rebuild pesado
        return;
      }
    }
  }
  Widget _buildStripeOnboardingBanner() {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        if (state is BalanceLoaded && state.profile.requiresStripeOnboarding) {
          final stripe = state.profile.stripeAccount;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryOrange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: AppColors.primaryOrange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Configuração Financeira Pendente",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        stripe?.statusDescription ?? "Complete seu cadastro para liberar seus recebimentos.",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AddPayoutMethodBottomSheet(
                        onSaved: () {
                          context.read<BalanceBloc>().add(const LoadBalance());
                        },
                      ),
                    );
                  },
                  child: const Text(
                    "CONFIGURAR",
                    style: TextStyle(color: AppColors.primaryOrange, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

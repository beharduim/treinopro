import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/proposals/data/services/proposals_api_service.dart';
import '../../features/proposals/data/models/proposal_response_dto.dart';
import '../../features/home/widgets/proposal_modal.dart';
import '../../core/navigation/app_navigator.dart';
import '../../features/home/data/services/auth_service.dart';
import '../../features/proposals/data/services/personal_proposals_api_service.dart';
import '../../features/users/data/services/users_api_service.dart';
import '../services/websocket_service.dart';
import '../services/live_activity_service.dart';

/// Resultado da validação de proposta
enum ProposalUnavailableReason {
  alreadyAccepted, // Outro personal aceitou
  completed, // Já foi concluída
  cancelled, // Foi cancelada
  invalidStatus, // Status inválido
  expired, // Expirada
  notFound, // Não encontrada
}

/// Resultado da validação
class ProposalValidationResult {
  final bool isValid;
  final ProposalResponseDto? proposal;
  final ProposalUnavailableReason? reason;
  final String message;

  ProposalValidationResult({
    required this.isValid,
    this.proposal,
    this.reason,
    required this.message,
  });
}

/// Serviço para gerenciar deep links e exibição de modais de proposta
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const String _pendingProposalIdKey = 'pending_proposal_id';
  static const String _pendingProposalTimestampKey =
      'pending_proposal_timestamp';
  static const Duration _maxPendingAge = Duration(minutes: 15);

  static String? _pendingProposalId;
  bool _isProcessing = false;
  StreamSubscription<Map<String, dynamic>>? _websocketSubscription;
  String? _currentProposalId; // ID da proposta sendo exibida no modal
  BuildContext? _currentModalContext; // Contexto do modal aberto
  VoidCallback?
  _onProposalMatched; // ✅ NOVO: Callback para atualizar modal quando match acontecer

  /// Processar deep link pendente (quando app inicia de estado terminado)
  /// ✅ CRÍTICO: Este método deve ser chamado DEPOIS que a home estiver montada
  static Future<void> processPendingDeepLink() async {
    print('🔗 [DEEP_LINK] ===== INICIANDO PROCESSAMENTO DE DEEP LINK =====');

    // Garantir hidratação do pending vindo do background isolate (SharedPreferences)
    await hydratePendingDeepLinkFromStorage();
    print('🔗 [DEEP_LINK] _pendingProposalId: $_pendingProposalId');

    if (_pendingProposalId == null) {
      print('ℹ️ [DEEP_LINK] Nenhum deep link pendente');
      return;
    }

    final proposalId = _pendingProposalId!;
    print('🔗 [DEEP_LINK] ===== PROCESSANDO DEEP LINK PENDENTE =====');
    print('🔗 [DEEP_LINK] proposalId: $proposalId');

    // Limpar apenas da memória; o storage só é removido após consumo bem-sucedido.
    // Isso evita perder a proposta se o bootstrap/contexto ainda não estiver pronto.
    _pendingProposalId = null;

    try {
      final service = DeepLinkService();
      print('🔗 [DEEP_LINK] Chamando showProposalModal...');
      final consumed = await service.showProposalModal(proposalId);

      if (consumed) {
        await clearPendingDeepLinkStorage();
        print('✅ [DEEP_LINK] Deep link processado com sucesso');
      } else {
        print(
          '⚠️ [DEEP_LINK] Deep link ainda não pôde ser consumido; restaurando pendente',
        );
        setPendingProposalId(proposalId);
      }
    } catch (e, stackTrace) {
      print('❌ [DEEP_LINK] Erro ao processar deep link: $e');
      print('❌ [DEEP_LINK] StackTrace: $stackTrace');
      setPendingProposalId(proposalId);
    }
  }

  /// Salvar proposalId pendente (quando app está terminado)
  static void setPendingProposalId(String proposalId) {
    if (proposalId.isEmpty) {
      return;
    }

    if (_pendingProposalId == proposalId) {
      print('ℹ️ [DEEP_LINK] proposalId pendente já estava salvo: $proposalId');
      return;
    }

    print('💾 [DEEP_LINK] Salvando proposalId pendente: $proposalId');
    _pendingProposalId = proposalId;
    unawaited(_persistPendingDeepLink(proposalId));
  }

  /// Restaurar deep link pendente do SharedPreferences (ponte entre isolates)
  static Future<void> hydratePendingDeepLinkFromStorage() async {
    if (_pendingProposalId != null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedProposalId = prefs.getString(_pendingProposalIdKey);
      if (storedProposalId == null || storedProposalId.isEmpty) {
        return;
      }

      final timestampMs = prefs.getInt(_pendingProposalTimestampKey);
      if (timestampMs != null) {
        final storedAt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
        final age = DateTime.now().difference(storedAt);
        if (age > _maxPendingAge) {
          print(
            '⚠️ [DEEP_LINK] Pending deep link expirado em storage (age: ${age.inMinutes}min), limpando',
          );
          await _clearPendingDeepLinkStorage(prefs: prefs);
          return;
        }
      }

      _pendingProposalId = storedProposalId;
      print(
        '💾 [DEEP_LINK] Pending deep link restaurado do storage: $storedProposalId',
      );
    } catch (e) {
      print(
        '⚠️ [DEEP_LINK] Falha ao restaurar pending deep link do storage: $e',
      );
    }
  }

  /// Limpar pending deep link persistido
  static Future<void> clearPendingDeepLinkStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearPendingDeepLinkStorage(prefs: prefs);
    } catch (e) {
      print('⚠️ [DEEP_LINK] Falha ao limpar pending deep link do storage: $e');
    }
  }

  static Future<void> _persistPendingDeepLink(String proposalId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingProposalIdKey, proposalId);
      await prefs.setInt(
        _pendingProposalTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      print('💾 [DEEP_LINK] Pending deep link persistido em storage');
    } catch (e) {
      print('⚠️ [DEEP_LINK] Falha ao persistir pending deep link: $e');
    }
  }

  static Future<void> _clearPendingDeepLinkStorage({
    required SharedPreferences prefs,
  }) async {
    await prefs.remove(_pendingProposalIdKey);
    await prefs.remove(_pendingProposalTimestampKey);
  }

  /// Verificar se há deep link pendente
  static bool get hasPendingDeepLink => _pendingProposalId != null;

  /// Obter proposalId pendente (sem limpar)
  static String? get pendingProposalId => _pendingProposalId;

  /// Processar deep link de notificação
  /// Suporta URLs:
  ///   - proposalId simples (legado)
  ///   - treinopro://proposal-action/{proposalId}/{accept|reject}
  Future<void> handleDeepLink(String? proposalId) async {
    if (proposalId == null || proposalId.isEmpty) {
      print('⚠️ [DEEP_LINK] proposalId vazio ou nulo');
      return;
    }

    // ✅ Detectar URL de ação de proposta (vinda de Live Activity ou intent)
    if (proposalId.contains('proposal-action')) {
      await _handleProposalActionUrl(proposalId);
      return;
    }

    print('🔗 [DEEP_LINK] Processando deep link para proposta: $proposalId');

    // Verificar se app está inicializado
    final authService = GetIt.instance<AuthService>();
    if (!authService.isAuthenticated) {
      print(
        '⚠️ [DEEP_LINK] Usuário não autenticado, salvando para processar depois',
      );
      setPendingProposalId(proposalId);
      return;
    }

    // Aguardar contexto estar disponível usando WidgetsBinding
    print('⏳ [DEEP_LINK] Aguardando contexto estar disponível...');
    await _waitForContextReady();

    // Aguardar um pouco mais para garantir que app está totalmente pronto
    await Future.delayed(const Duration(milliseconds: 800));

    // Exibir modal
    final consumed = await showProposalModal(proposalId);
    if (!consumed) {
      print(
        '⚠️ [DEEP_LINK] Modal ainda não pôde ser exibido; mantendo proposalId pendente',
      );
      setPendingProposalId(proposalId);
    }
  }

  /// Processar URL de ação de proposta: treinopro://proposal-action/{id}/{accept|reject}
  Future<void> _handleProposalActionUrl(String url) async {
    print('🔗 [DEEP_LINK] Processando ação de proposta: $url');

    // Extrair proposalId e action da URL
    // Formato: treinopro://proposal-action/{proposalId}/{accept|reject}
    // Ou pode vir como: proposal-action/{proposalId}/{accept|reject}
    final uri = Uri.tryParse(url) ?? Uri.tryParse('treinopro://$url');
    if (uri == null) {
      print('❌ [DEEP_LINK] URL inválida: $url');
      return;
    }

    final segments = uri.pathSegments;
    // pathSegments pode ser [proposalId, accept|reject] (se host = proposal-action)
    // ou [proposal-action, proposalId, accept|reject]
    String? proposalId;
    String? action;

    if (uri.host == 'proposal-action' && segments.length >= 2) {
      proposalId = segments[0];
      action = segments[1];
    } else if (segments.length >= 3 && segments[0] == 'proposal-action') {
      proposalId = segments[1];
      action = segments[2];
    }

    if (proposalId == null || action == null) {
      print(
        '❌ [DEEP_LINK] Não foi possível extrair proposalId/action de: $url',
      );
      return;
    }

    print('🔗 [DEEP_LINK] Ação: $action para proposta: $proposalId');

    try {
      final personalProposalsApi =
          GetIt.instance<PersonalProposalsApiService>();

      if (action == 'accept') {
        await personalProposalsApi.acceptProposal(proposalId);
        print('✅ [DEEP_LINK] Proposta aceita via deep link: $proposalId');
        _showSuccessMessage('Proposta aceita com sucesso!');
      } else if (action == 'reject') {
        // Rejeitar = ignorar a proposta (não aceitar)
        print('✅ [DEEP_LINK] Proposta rejeitada via deep link: $proposalId');
        _showSuccessMessage('Proposta rejeitada.');
      }

      // Encerrar Live Activity
      await LiveActivityService.instance.endActivity(proposalId: proposalId);
    } catch (e) {
      print('❌ [DEEP_LINK] Erro ao processar ação da proposta: $e');
      _showErrorMessage('Erro ao processar proposta. Tente novamente.');
    }
  }

  /// Aguardar contexto estar pronto usando WidgetsBinding
  Future<void> _waitForContextReady() async {
    // Tentar aguardar até que o contexto esteja disponível
    for (int i = 0; i < 20; i++) {
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null) {
        print('✅ [DEEP_LINK] Contexto disponível após ${i * 100}ms');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    print('⚠️ [DEEP_LINK] Timeout aguardando contexto (2s)');
  }

  /// Validar se a proposta ainda está disponível
  Future<ProposalValidationResult> _validateProposal(
    ProposalResponseDto proposal,
  ) async {
    // 1. Verificar status
    final status = proposal.status.toLowerCase();

    if (status == 'matched') {
      return ProposalValidationResult(
        isValid: false,
        reason: ProposalUnavailableReason.alreadyAccepted,
        message:
            'A proposta não está mais disponível. Outro personal trainer já aceitou esta proposta.',
      );
    }

    if (status == 'completed') {
      return ProposalValidationResult(
        isValid: false,
        reason: ProposalUnavailableReason.completed,
        message: 'Esta proposta já foi concluída.',
      );
    }

    if (status == 'cancelled') {
      return ProposalValidationResult(
        isValid: false,
        reason: ProposalUnavailableReason.cancelled,
        message: 'Esta proposta foi cancelada.',
      );
    }

    if (status != 'pending') {
      return ProposalValidationResult(
        isValid: false,
        reason: ProposalUnavailableReason.invalidStatus,
        message: 'Esta proposta não está mais disponível.',
      );
    }

    // 2. Verificar se não expirou (se houver tempo de expiração)
    // TODO: Implementar validação de expiração se necessário

    return ProposalValidationResult(
      isValid: true,
      proposal: proposal,
      message: 'Proposta disponível',
    );
  }

  /// Exibir modal ou mensagem de erro baseado na validação
  Future<bool> showProposalModal(String proposalId) async {
    print('🔗 [DEEP_LINK] ===== showProposalModal CHAMADO =====');
    print('🔗 [DEEP_LINK] proposalId: $proposalId');
    print('🔗 [DEEP_LINK] _isProcessing: $_isProcessing');

    if (_isProcessing) {
      print('⚠️ [DEEP_LINK] Já processando uma proposta, ignorando...');
      return false;
    }

    _isProcessing = true;

    try {
      print('🔍 [DEEP_LINK] Buscando proposta: $proposalId');

      // 1. Buscar proposta
      final proposalsApi = GetIt.instance<ProposalsApiService>();
      final proposal = await proposalsApi.getProposalById(proposalId);

      // 2. Validar proposta
      final validation = await _validateProposal(proposal);

      if (!validation.isValid) {
        // Mostrar mensagem de erro
        print('❌ [DEEP_LINK] Proposta inválida: ${validation.message}');
        _showErrorMessage(validation.message);
        return true;
      }

      // 3. Aguardar contexto estar disponível
      print('⏳ [DEEP_LINK] Aguardando contexto para exibir modal...');
      await _waitForContext();

      // 4. Aguardar mais um pouco para garantir que página está pronta
      print(
        '⏳ [DEEP_LINK] Aguardando 500ms para garantir que página está pronta...',
      );
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Verificar contexto novamente antes de exibir
      final context = AppNavigator.navigatorKey.currentContext;
      print(
        '🔍 [DEEP_LINK] Contexto verificado: ${context != null ? "disponível" : "null"}',
      );
      if (context == null) {
        print('❌ [DEEP_LINK] Contexto ainda não disponível após aguardar');
        print(
          '⚠️ [DEEP_LINK] Falha temporária de contexto; proposta será tentada novamente',
        );
        return false;
      }

      // 6. Exibir modal (apenas se válida)
      print('✅ [DEEP_LINK] Tudo pronto, exibindo modal...');
      print('✅ [DEEP_LINK] Proposal ID: ${validation.proposal!.id}');
      print('✅ [DEEP_LINK] Proposal Status: ${validation.proposal!.status}');
      await _displayProposalModal(validation.proposal!);
      return true;
    } catch (e) {
      print('❌ [DEEP_LINK] Erro ao processar proposta: $e');
      if (e.toString().contains('404') ||
          e.toString().contains('não encontrada')) {
        _showErrorMessage('Proposta não encontrada.');
        return true;
      } else {
        _showErrorMessage('Erro ao carregar proposta. Tente novamente.');
        return false;
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Aguardar contexto estar disponível (método auxiliar)
  Future<void> _waitForContext() async {
    print('⏳ [DEEP_LINK] Aguardando contexto estar disponível...');
    int attempts = 0;
    while (attempts < 20) {
      // ✅ Aumentado de 15 para 20 (4s total)
      final context = AppNavigator.navigatorKey.currentContext;
      if (context != null) {
        print('✅ [DEEP_LINK] Contexto disponível após ${attempts * 200}ms');
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      attempts++;
    }
    print('⚠️ [DEEP_LINK] Timeout aguardando contexto (4s)');
  }

  /// Exibir modal de proposta
  Future<void> _displayProposalModal(ProposalResponseDto proposal) async {
    // ✅ CORREÇÃO: exibir modal imediatamente ao invés de usar addPostFrameCallback
    // O contexto já deve estar disponível quando este método é chamado (após os delays)
    final context = AppNavigator.navigatorKey.currentContext;
    if (context == null) {
      print('❌ [DEEP_LINK] Contexto não disponível');
      _showErrorMessage('Erro ao abrir proposta. Tente novamente.');
      return;
    }

    print('✅ [DEEP_LINK] Exibindo modal de proposta: ${proposal.id}');
    print('✅ [DEEP_LINK] Contexto disponível: ${context.runtimeType}');

    // ✅ Salvar ID da proposta atual e configurar listener para atualizações
    _currentProposalId = proposal.id;
    _setupProposalUpdateListener(proposal.id);

    // Formatar data
    final formattedDate = _formatTrainingDate(proposal.trainingDate);

    // Obter dados do aluno
    String studentName = proposal.student.name.isNotEmpty
        ? proposal.student.name
        : '${proposal.student.firstName} ${proposal.student.lastName}'.trim();

    // ✅ NOVO: Buscar rating e experiência do aluno (igual ao PersonalHomePage)
    String? studentRating;
    String? studentExperience;
    String? studentImageUrl = proposal.student.profilePicture;

    try {
      final studentId = proposal.student.id;
      if (studentId.isNotEmpty) {
        print('🔍 [DEEP_LINK] Buscando dados do aluno: $studentId');
        final usersApi = GetIt.instance<UsersApiService>();
        final basic = await usersApi.getUserBasicInfo(studentId);

        // Atualizar nome se disponível
        final firstName = (basic['firstName'] ?? '').toString();
        final lastName = (basic['lastName'] ?? '').toString();
        final fullName = ('$firstName $lastName').trim();
        if (fullName.isNotEmpty) {
          studentName = fullName;
        }

        // Obter rating
        final rating = (basic['rating'] ?? '0.0').toString();
        studentRating = rating.replaceAll('.', ',');

        // Obter experiência (tempo na plataforma)
        final createdAt = basic['createdAt'] as String?;
        if (createdAt != null) {
          studentExperience = usersApi.calculateTimeOnPlatform(createdAt);
        }

        // Atualizar foto se disponível
        final photo = (basic['profileImageUrl'] ?? '').toString();
        if (photo.isNotEmpty) {
          studentImageUrl = photo;
        }

        print('✅ [DEEP_LINK] Dados do aluno obtidos:');
        print('✅ [DEEP_LINK] - Nome: $studentName');
        print('✅ [DEEP_LINK] - Rating: $studentRating');
        print('✅ [DEEP_LINK] - Experiência: $studentExperience');
        print(
          '✅ [DEEP_LINK] - Foto: ${studentImageUrl != null ? "disponível" : "não disponível"}',
        );
      }
    } catch (e) {
      print('⚠️ [DEEP_LINK] Erro ao buscar dados do aluno: $e');
      // Continuar sem os dados enriquecidos se houver erro
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        // ✅ Salvar contexto do modal para poder fechar depois
        _currentModalContext = dialogContext;

        // ✅ NOVO: Criar GlobalKey para acessar o estado do modal
        // Como _ProposalModalState é privado, usar State<ProposalModal> e fazer cast
        final modalKey = GlobalKey<State<ProposalModal>>();

        // ✅ NOVO: Criar callback para atualizar modal quando match acontecer
        _onProposalMatched = () {
          print(
            '✅ [DEEP_LINK] Callback onMatched chamado - atualizando modal para matched',
          );
          final modalState = modalKey.currentState;
          if (modalState != null) {
            // Fazer cast para dynamic para acessar método público transitionToMatch()
            (modalState as dynamic).transitionToMatch();
            print('✅ [DEEP_LINK] Modal atualizado para matched via callback');
          } else {
            print('⚠️ [DEEP_LINK] Estado do modal não disponível');
          }
        };

        return Stack(
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
                  key: modalKey, // ✅ NOVO: Key para acessar o estado
                  studentName: studentName,
                  location: proposal.locationName,
                  price: proposal.price.round().toString(),
                  time: proposal.trainingTime,
                  date: formattedDate,
                  modality: proposal.modalityName,
                  countdownSeconds: 30,
                  studentRating: studentRating, // ✅ Buscado do perfil do aluno
                  studentExperience:
                      studentExperience, // ✅ Buscado do perfil do aluno
                  studentImageUrl:
                      studentImageUrl ?? proposal.student.profilePicture,
                  proposalId: proposal.id,
                  // ✅ NOVO: Callback para quando match acontecer via WebSocket
                  onMatched: _onProposalMatched,
                  // ✅ REMOVIDO: playSound: false
                  // O som do modal deve sempre tocar, independente de como foi aberto
                  // O som da notificação push (sistema) é apenas um aviso inicial
                  onAccept: () async {
                    // ✅ CORREÇÃO CRÍTICA: NÃO fechar o modal ainda!
                    // Primeiro aceitar a proposta via API
                    // O WebSocket vai notificar e o listener vai transicionar o modal para "matched"
                    print(
                      '✅ [DEEP_LINK] Botão Aceitar pressionado - aceitando proposta...',
                    );

                    try {
                      final personalProposalsApi =
                          GetIt.instance<PersonalProposalsApiService>();
                      await personalProposalsApi.acceptProposal(proposal.id);
                      print(
                        '✅ [DEEP_LINK] Proposta aceita com sucesso - aguardando confirmação via WebSocket...',
                      );

                      // ✅ Encerrar Live Activity (iOS)
                      LiveActivityService.instance.endActivity(
                        proposalId: proposal.id,
                      );
                    } catch (e) {
                      print('❌ [DEEP_LINK] Erro ao aceitar proposta: $e');
                      _showErrorMessage(
                        'Erro ao aceitar proposta. Tente novamente.',
                      );
                      // Se der erro, aí sim pode fechar o modal
                      _cleanupModal();
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  onIgnore: () {
                    // ✅ Limpar listener e contexto antes de fechar
                    _cleanupModal();
                    // ✅ Encerrar Live Activity (iOS)
                    LiveActivityService.instance.endActivity(
                      proposalId: proposal.id,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  onTimeout: () {
                    // ✅ Limpar listener e contexto antes de fechar
                    _cleanupModal();
                    // ✅ Encerrar Live Activity (iOS)
                    LiveActivityService.instance.endActivity(
                      proposalId: proposal.id,
                    );
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// ✅ RENOMEADO: Configurar listener para detectar atualizações da proposta
  /// (cancelamento, aceitação, match)
  void _setupProposalUpdateListener(String proposalId) {
    // Cancelar subscription anterior se existir
    _websocketSubscription?.cancel();

    print(
      '👂 [DEEP_LINK] Configurando listener para atualizações da proposta: $proposalId',
    );

    final wsService = GetIt.instance<WebSocketService>();

    // Escutar mensagens do WebSocket
    _websocketSubscription = wsService.messageStream.listen((message) {
      final type = message['type'] as String?;

      print('📥 [DEEP_LINK] Mensagem recebida - tipo: $type');
      print('📥 [DEEP_LINK] Mensagem completa: $message');

      if (type == 'proposal_update') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final action = data['action'] as String?;
          final proposal = data['proposal'] as Map<String, dynamic>?;
          final eventProposalId =
              proposal?['id']?.toString() ?? data['proposalId']?.toString();

          print('🔍 [DEEP_LINK] Verificando atualização:');
          print('🔍 [DEEP_LINK] - action: $action');
          print('🔍 [DEEP_LINK] - eventProposalId: $eventProposalId');
          print('🔍 [DEEP_LINK] - currentProposalId: $proposalId');
          print(
            '🔍 [DEEP_LINK] - _currentModalContext: ${_currentModalContext != null ? "disponível" : "null"}',
          );

          if (eventProposalId == proposalId && _currentModalContext != null) {
            // ✅ NOVO: Tratar proposta aceita (match)
            if (action == 'proposal_accepted') {
              print(
                '✅ [DEEP_LINK] Proposta aceita - atualizando modal para matched: $proposalId',
              );

              // Chamar callback onMatched se disponível
              if (_onProposalMatched != null) {
                _onProposalMatched!();
                print('✅ [DEEP_LINK] Callback onMatched chamado');
              } else {
                print('⚠️ [DEEP_LINK] Callback onMatched não disponível');
              }
            }
            // ✅ Tratar cancelamento
            else if (action == 'proposal_cancelled') {
              print(
                '❌ [DEEP_LINK] Proposta cancelada - fechando modal automaticamente: $proposalId',
              );

              // ✅ CORREÇÃO CRÍTICA: Salvar contexto ANTES de limpar
              final modalContext = _currentModalContext;

              // Limpar listener e contexto
              _cleanupModal();

              // Encerrar Live Activity
              LiveActivityService.instance.endActivity(
                proposalId: eventProposalId,
              );

              // Fechar modal usando o contexto salvo
              if (modalContext != null) {
                try {
                  Navigator.of(modalContext).pop();
                  print('✅ [DEEP_LINK] Modal fechado com sucesso');
                } catch (e) {
                  print('⚠️ [DEEP_LINK] Erro ao fechar modal: $e');
                }
              }

              // Mostrar mensagem informativa
              _showErrorMessage('A proposta foi cancelada pelo aluno.');
            }
          }
        }
      }
      // ✅ NOVO: Escutar evento proposal_accepted diretamente (pode vir separado)
      else if (type == 'proposal_accepted') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final proposal = data['proposal'] as Map<String, dynamic>?;
          final eventProposalId =
              proposal?['id']?.toString() ?? data['proposalId']?.toString();

          print('🔍 [DEEP_LINK] Evento proposal_accepted recebido:');
          print('🔍 [DEEP_LINK] - eventProposalId: $eventProposalId');
          print('🔍 [DEEP_LINK] - currentProposalId: $proposalId');
          print(
            '🔍 [DEEP_LINK] - _currentModalContext: ${_currentModalContext != null ? "disponível" : "null"}',
          );

          if (eventProposalId == proposalId && _currentModalContext != null) {
            print(
              '✅ [DEEP_LINK] Proposta aceita via evento direto - atualizando modal para matched: $proposalId',
            );

            // Chamar callback onMatched se disponível
            if (_onProposalMatched != null) {
              _onProposalMatched!();
              print(
                '✅ [DEEP_LINK] Callback onMatched chamado via proposal_accepted',
              );
            } else {
              print('⚠️ [DEEP_LINK] Callback onMatched não disponível');
            }
          }
        }
      }
      // ✅ NOVO: Escutar evento match_confirmed diretamente
      else if (type == 'match_confirmed') {
        final data = message['data'] as Map<String, dynamic>?;
        if (data != null) {
          final proposal = data['proposal'] as Map<String, dynamic>?;
          final eventProposalId =
              proposal?['id']?.toString() ?? data['proposalId']?.toString();

          print('🔍 [DEEP_LINK] Evento match_confirmed recebido:');
          print('🔍 [DEEP_LINK] - eventProposalId: $eventProposalId');
          print('🔍 [DEEP_LINK] - currentProposalId: $proposalId');
          print(
            '🔍 [DEEP_LINK] - _currentModalContext: ${_currentModalContext != null ? "disponível" : "null"}',
          );

          if (eventProposalId == proposalId && _currentModalContext != null) {
            print(
              '✅ [DEEP_LINK] Match confirmado via WebSocket - atualizando modal: $proposalId',
            );

            // Chamar callback onMatched se disponível
            if (_onProposalMatched != null) {
              _onProposalMatched!();
              print(
                '✅ [DEEP_LINK] Callback onMatched chamado via match_confirmed',
              );
            } else {
              print('⚠️ [DEEP_LINK] Callback onMatched não disponível');
            }
          }
        }
      }
    });

    print('✅ [DEEP_LINK] Listener de atualizações configurado com sucesso');
  }

  /// Limpar recursos do modal (listener e contexto)
  void _cleanupModal() {
    print('🧹 [DEEP_LINK] Limpando recursos do modal');
    _websocketSubscription?.cancel();
    _websocketSubscription = null;
    _currentProposalId = null;
    _currentModalContext = null;
    _onProposalMatched = null; // ✅ NOVO: Limpar callback também
  }

  /// Formatar data para exibição (dd/MM)
  String _formatTrainingDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  /// Mostrar mensagem de sucesso
  void _showSuccessMessage(String message) {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Mostrar mensagem de erro
  void _showErrorMessage(String message) {
    final context = AppNavigator.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      print('⚠️ [DEEP_LINK] Não foi possível exibir mensagem: $message');
    }
  }
}

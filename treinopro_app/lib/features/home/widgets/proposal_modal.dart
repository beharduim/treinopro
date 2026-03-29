import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/image_viewer_modal.dart';
import '../../chat/presentation/pages/chat_page.dart';
import '../../../core/di/dependency_injection.dart';
import '../../classes/data/services/classes_api_service.dart';
import '../../users/data/services/users_api_service.dart';

class ProposalModal extends StatefulWidget {
  final String studentName;
  final String location;
  final String time;
  final String? date; // dd/MM/yy
  final String modality;
  final String price; // esperado apenas número (sem R$)
  final String? studentRating; // ex: "5,0"
  final String? studentExperience; // ex: "7 dias"
  final String? studentImageUrl;
  final String? proposalId; // ID da proposta para buscar dados da aula
  final VoidCallback? onChatPressed; // usado no estado de match para abrir chat
  final VoidCallback onAccept;
  final VoidCallback onIgnore;
  final VoidCallback? onTimeout;
  final VoidCallback? onMatched; // ✅ NOVO: Callback para quando proposta é aceita (match)
  final int countdownSeconds;
  final bool playSound; // ✅ Controla se deve tocar som (false quando aberto via notificação push)

  const ProposalModal({
    super.key,
    required this.studentName,
    required this.location,
    required this.time,
    this.date,
    required this.modality,
    required this.price,
    required this.onAccept,
    required this.onIgnore,
    this.onTimeout,
    this.onMatched, // ✅ NOVO: Callback opcional para match
    this.countdownSeconds = 30,
    this.studentRating,
    this.studentExperience,
    this.studentImageUrl,
    this.proposalId,
    this.onChatPressed,
    this.playSound = true, // ✅ Padrão: tocar som (quando aberto via WebSocket)
  });

  @override
  State<ProposalModal> createState() => _ProposalModalState();
}

class _ProposalModalState extends State<ProposalModal>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 30;

  // Áudio de alerta (loop durante o modal de proposta)
  late final AudioPlayer _audioPlayer;

  // Controllers para animações
  late AnimationController _modalPulseController;
  late AnimationController _slideController;
  late AnimationController _progressController;

  // Animations
  late Animation<double> _modalPulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

  // Estado do modal (proposta ou match)
  bool _isMatched = false;

  // Variáveis para chat (similar ao proposal_status_modal)
  String? _enrichedClassId;
  String? _enrichedReceiverId; // studentId (para o personal)
  String? _enrichedStudentName;
  String? _enrichedLocation;
  String? _enrichedDate;
  String? _enrichedTime;
  String? _enrichedDuration;
  bool _isFetchingEnrichment = false;
  int _enrichmentAttempts = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.countdownSeconds;

    // Inicializa player de áudio
    _audioPlayer = AudioPlayer()
      ..setReleaseMode(ReleaseMode.loop);

    // Configurar animações
    _setupAnimations();

    // Iniciar countdown
    _startCountdown();

    // Som inicial
    _playInitialSound();

    // ✅ CORREÇÃO: Só tocar som se playSound for true
    // Quando modal é aberto via notificação push, playSound será false
    // (sistema Android/iOS já tocou o som da notificação)
    if (widget.playSound) {
      // Iniciar som de alerta (loop) durante a proposta
      _startProposalSound();
    } else {
      print('🔕 [PROPOSAL_MODAL] Som desabilitado (aberto via notificação push)');
    }

    // ✅ NOVO: Escutar callback onMatched se fornecido
    if (widget.onMatched != null) {
      // O callback será chamado externamente quando o match acontecer via WebSocket
      print('👂 [PROPOSAL_MODAL] Callback onMatched configurado - modal escutará eventos de match');
    }
  }

  void _setupAnimations() {
    // Animação de slide para entrada
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutQuart),
        );

    // Animação de pulsação do modal (últimos 5 segundos)
    _modalPulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _modalPulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _modalPulseController, curve: Curves.easeInOut),
    );

    // Animação do progresso circular
    _progressController = AnimationController(
      duration: Duration(seconds: widget.countdownSeconds),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.linear),
    );

    // Iniciar animações
    _slideController.forward();
    _progressController.forward();
  }

  // Som de entrada da proposta
  Future<void> _playInitialSound() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Ignora se não conseguir reproduzir
    }
  }

  Future<void> _startProposalSound() async {
    try {
      print('🔊 [PROPOSAL_MODAL] Iniciando reprodução de som...');
      
      // Tentar reproduzir primeiro, depois configurar contexto se necessário
      await _audioPlayer.setVolume(1.0);
      print('🔊 [PROPOSAL_MODAL] Volume definido como 1.0');
      
      await _audioPlayer.play(AssetSource('sounds/alert_proposal.mp3'));
      print('✅ [PROPOSAL_MODAL] Som tocando!');
      
      // Define contexto de áudio em Android DEPOIS de começar a tocar
      // iOS: não precisa configurar pois o contexto padrão já funciona
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.notificationEvent,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
      print('✅ [PROPOSAL_MODAL] Contexto de áudio configurado');
    } catch (e, stackTrace) {
      print('❌ [PROPOSAL_MODAL] Erro ao tocar som: $e');
      print('❌ [PROPOSAL_MODAL] StackTrace: $stackTrace');
    }
  }

  Future<void> _stopProposalSound() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        // Ativar pulsação nos últimos 5 segundos
        if (_remainingSeconds <= 5 && _remainingSeconds > 0) {
          if (!_modalPulseController.isAnimating) {
            _modalPulseController.repeat(reverse: true);
          }
        } else {
          _modalPulseController.stop();
          _modalPulseController.reset();
        }

        if (_remainingSeconds <= 0) {
          timer.cancel();
          _handleTimeout();
        }
      }
    });
  }

  void _handleTimeout() {
    print('⏰ [PROPOSAL_MODAL] Timeout chamado - fechando modal');
    // Para o som ao expirar
    _stopProposalSound();
    if (widget.onTimeout != null) {
      widget.onTimeout!();
    } else {
      widget.onIgnore();
    }
  }

  @override
  void dispose() {
    print('🗑️ [PROPOSAL_MODAL] Modal sendo descartado');
    _timer?.cancel();
    // Garante que o som pare ao fechar o modal
    _stopProposalSound();
    _audioPlayer.dispose();
    _modalPulseController.dispose();
    _slideController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // Função para transicionar para o estado de match
  void _transitionToMatch() {
    print('🔄 [PROPOSAL_MODAL] Transicionando para estado matched');
    
    // ✅ CORREÇÃO: Não fazer nada se já estiver matched
    if (_isMatched) {
      print('⚠️ [PROPOSAL_MODAL] Já está em estado matched, ignorando');
      return;
    }
    
    // Para o timer e animações da proposta
    _timer?.cancel();
    _modalPulseController.stop();
    _progressController.stop();

    // Para som de alerta ao entrar no estado de match
    _stopProposalSound();

    setState(() {
      _isMatched = true;
    });

    print('🔄 [PROPOSAL_MODAL] Estado matched definido como true');
    // Toca som de sucesso
    _playSuccessSound();
    
    // ✅ NOVO: Buscar dados da aula quando match acontecer
    _fetchAndEnrichMatchData();
  }

  // ✅ NOVO: Método público para ser chamado externamente via callback
  void transitionToMatch() {
    _transitionToMatch();
  }

  // Som de sucesso quando match é confirmado
  Future<void> _playSuccessSound() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Ignora se não conseguir reproduzir
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedBuilder(
          animation: _modalPulseAnimation,
          builder: (context, child) {
            return Transform.scale(
            // MODAL INTEIRO pulsa quando ≤ 5 segundos (apenas em modo proposta)
            scale: !_isMatched && _remainingSeconds <= 5
                ? _modalPulseAnimation.value
                : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: _isMatched ? const Color(0xFFF9F9F9) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                  children: [
                    // Conteúdo do modal
                    _isMatched ? _buildMatchContent() : _buildProposalContent(),

                    // Botão X de fechar (apenas no modo match)
                    if (_isMatched)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 20,
                            color: Color(0xFF6B7280),
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Método para construir o conteúdo da proposta
  Widget _buildProposalContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header compacto
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Contador menor
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        // Transição suave de cor baseada no tempo restante
                        final colorProgress =
                            (_remainingSeconds / widget.countdownSeconds).clamp(
                              0.0,
                              1.0,
                            );
                        final currentColor = Color.lerp(
                          Colors.red, // Cor final (vermelho)
                          AppColors.primaryOrange, // Cor inicial (laranja)
                          colorProgress,
                        )!;

                        return CircularProgressIndicator(
                          value: _progressAnimation.value,
                          strokeWidth: 3,
                          backgroundColor: const Color(0xFFF3F3F3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentColor,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: () {
                        // Mesma transição suave de cor para o container
                        final colorProgress =
                            (_remainingSeconds / widget.countdownSeconds).clamp(
                              0.0,
                              1.0,
                            );
                        return Color.lerp(
                          Colors.red, // Cor final (vermelho)
                          AppColors.primaryOrange, // Cor inicial (laranja)
                          colorProgress,
                        )!;
                      }(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_remainingSeconds',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Nova proposta!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Informações organizadas como no Uber
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // VALOR EM DESTAQUE (igual ao preço do Uber)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'R\$ ${widget.price.replaceAll(' reais', '').replaceAll('R\$', '').trim()}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 16),

              // Informações com border e alinhamento melhorado
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Nome e Pontuação
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Nome',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.studentName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Pontuação',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.studentRating ?? '0.0',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Local
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: const Color(0xFFFF6A00),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Local',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Data, Horário e Modalidade em uma única linha
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event,
                                    size: 16,
                                    color: AppColors.primaryOrange,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Data',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.date ?? '-',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Horário',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.time,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 16,
                                  color: AppColors.primaryOrange,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Modalidade',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.modality,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Botões compactos
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              // Botão Aceitar - destaque total
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isMatched
                      ? null
                      : () {
                          print('✅ [PROPOSAL_MODAL] Botão Aceitar pressionado');
                          // ✅ CORREÇÃO: NÃO transicionar para matched ainda!
                          // Apenas chamar onAccept - o WebSocket vai notificar quando o match acontecer
                          // e o callback onMatched vai transicionar o modal
                          print('✅ [PROPOSAL_MODAL] Chamando onAccept callback - aguardando confirmação via WebSocket');
                          widget.onAccept();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Aceitar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Botão Ignorar - outline
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    _stopProposalSound();
                    widget.onIgnore();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFFFF6A00), // Laranja principal
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ignorar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Método para construir o conteúdo do match (design baseado no Figma)
  Widget _buildMatchContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header com ícone de handshake
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.handshake,
                      size: 29,
                      color: Color(0xFFFF8C00),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Match confirmado',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF42464D),
                        fontFamily: 'Outfit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Encontramos para você um aluno qualificado para sua aula.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                    fontFamily: 'Fira Sans',
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Divisor
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFFA6A6A6),
          ),

          const SizedBox(height: 16),

          // Informações do aluno
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Foto e dados básicos
                Row(
                  children: [
                    // Foto do aluno
                    GestureDetector(
                      onTap: () {
                        if (widget.studentImageUrl != null && widget.studentImageUrl!.isNotEmpty) {
                          ImageViewerModal.show(
                            context,
                            imageUrl: widget.studentImageUrl!,
                            title: widget.studentName,
                            subtitle: 'Aluno',
                          );
                        }
                      },
                      child: Container(
                        width: 47,
                        height: 47,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primaryOrange,
                            width: 3,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            image: widget.studentImageUrl != null && widget.studentImageUrl!.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(widget.studentImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: widget.studentImageUrl == null || widget.studentImageUrl!.isEmpty
                              ? const Icon(
                                  Icons.school,
                                  size: 24,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nome e avaliação
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2D3748),
                              fontFamily: 'Fira Sans',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 22,
                                color: Color(0xFFFF8C00),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.studentRating ?? '0,0',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                  fontFamily: 'Fira Sans',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '|',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                  fontFamily: 'Fira Sans',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.studentExperience ?? '0 dias',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF2D3748),
                                  fontFamily: 'Fira Sans',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Local
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Local',
                    style: TextStyle(
                      fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Padding( 
                        padding: const EdgeInsets.only(left: 3),
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Data, Horário e Modalidade (uma linha) - EXATO do modal do aluno
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Data',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.date ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Horário',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.time,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: AppColors.primaryOrange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Modalidade',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.modality,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Botão Chat
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleChatPressed,
                    icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                    label: const Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontFamily: 'Fira Sans',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 40,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Removido botão "Cancelar aula" conforme solicitado
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Divisor
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: const Color(0xFFA6A6A6),
          ),

          const SizedBox(height: 24),

          // Seção de atenção
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF2D3748),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warning,
                      size: 21,
                      color: Color(0xFFF9F9F9),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Atenção',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF9F9F9),
                        fontFamily: 'Fira Sans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'O TreinoPro não se responsabiliza por eventuais custos adicionais que o profissional tenha com a academia onde irá atuar. É de responsabilidade do personal verificar e arcar com possíveis taxas exigidas pelo local.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF9F9F9),
                      fontFamily: 'Fira Sans',
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAndEnrichMatchData() async {
    final proposalId = widget.proposalId;
    if (proposalId == null || proposalId.isEmpty) return;
    if (_isFetchingEnrichment) return;
    
    print('🔎 [PROPOSAL_MODAL] Iniciando enrichment | proposalId=$proposalId | tentativa=$_enrichmentAttempts');
    setState(() {
      _isFetchingEnrichment = true;
    });
    
    try {
      final classesApi = sl<ClassesApiService>();
      final cls = await classesApi.getClassByProposalId(proposalId);
      if (!mounted) return;
      
      if (cls != null) {
        print('✅ [PROPOSAL_MODAL] Classe encontrada para proposalId=$proposalId | classId=${cls.id} | studentId=${cls.studentId}');
        print('✅ [PROPOSAL_MODAL] Dados do aluno: name=${cls.studentFirstName} ${cls.studentLastName}');
        
        setState(() {
          _enrichedClassId = cls.id;
          _enrichedReceiverId = cls.studentId; // personal fala com aluno
          _enrichedStudentName = '${cls.studentFirstName ?? ''} ${cls.studentLastName ?? ''}'.trim().isNotEmpty 
              ? '${cls.studentFirstName ?? ''} ${cls.studentLastName ?? ''}'.trim()
              : widget.studentName;
          _enrichedLocation = cls.location;
          _enrichedDate = _formatTrainingDate(cls.date);
          _enrichedTime = cls.time;
          _enrichedDuration = '${cls.duration}min';
        });
        
        // Complementar dados do aluno se necessário
        if (cls.studentId.isNotEmpty) {
          try {
            final usersApi = sl<UsersApiService>();
            final basic = await usersApi.getUserBasicInfo(cls.studentId);
            if (!mounted) return;
            
            print('ℹ️ [PROPOSAL_MODAL] Complementando com UsersApiService para studentId=${cls.studentId}');
            setState(() {
              final firstName = (basic['firstName'] ?? '').toString();
              final lastName = (basic['lastName'] ?? '').toString();
              final full = ('$firstName $lastName').trim();
              if (full.isNotEmpty) _enrichedStudentName = full;
            });
          } catch (_) {}
        }
      } else {
        print('⏳ [PROPOSAL_MODAL] Classe ainda não disponível para proposalId=$proposalId (tentativa=$_enrichmentAttempts)');
        // Tenta novamente algumas vezes para aguardar a consistência da API
        if (_enrichmentAttempts < 5) {
          _enrichmentAttempts += 1;
          await Future.delayed(const Duration(milliseconds: 700));
          _isFetchingEnrichment = false;
          if (mounted) return _fetchAndEnrichMatchData();
        }
      }
    } catch (e) {
      print('❌ [PROPOSAL_MODAL] Erro no enrichment: $e');
      // Silencioso: se falhar, mantém dados atuais
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingEnrichment = false;
        });
      }
    }
  }

  /// Formatar data para exibição (dd/mm)
  String _formatTrainingDate(DateTime? date) {
    if (date == null) return '--/--';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  void _handleChatPressed() async {
    print('💬 [PROPOSAL_MODAL] Botão Chat pressionado');
    
    final classId = _enrichedClassId;
    final receiverId = _enrichedReceiverId ?? '';
    
    print('💬 [PROPOSAL_MODAL] classId: $classId, receiverId: $receiverId');
    
    if (classId == null || classId.isEmpty) {
      print('❌ [PROPOSAL_MODAL] classId não disponível, tentando enriquecer...');
      await _fetchAndEnrichMatchData();
      
      if (_enrichedClassId == null || _enrichedClassId!.isEmpty) {
        print('❌ [PROPOSAL_MODAL] Ainda não há classId disponível');
        // Mostrar snackbar de erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aula ainda não está disponível. Tente novamente em alguns segundos.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }
  
    print('✅ [PROPOSAL_MODAL] Navegando para ChatPage...');
    
    // Fechar modal em background e navegar imediatamente
    if (widget.onChatPressed != null) {
      widget.onChatPressed!();
    }
    
    // Navegar para ChatPage em background
    if (mounted) {
      try {
        await Future.microtask(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatPage(
                classId: classId ?? _enrichedClassId!,
                receiverId: receiverId,
                receiverName: _enrichedStudentName ?? widget.studentName,
                location: _enrichedLocation ?? widget.location,
                date: _enrichedDate ?? widget.date ?? '',
                time: _enrichedTime ?? widget.time,
                duration: _enrichedDuration ?? '60min',
                currentUserIsStudent: false, // Personal é false
              ),
            ),
          );
        });
        print('✅ [PROPOSAL_MODAL] ChatPage aberta com sucesso');
      } catch (e) {
        print('❌ [PROPOSAL_MODAL] Erro ao navegar para ChatPage: $e');
      }
    }
  }
}

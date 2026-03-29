import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../../domain/entities/home_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../../../core/services/profile_image_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../profile/data/services/profile_api_service.dart';

/// Widget do card de saudação do usuário
class UserGreetingCard extends StatefulWidget {
  final HomeState homeState;
  final VoidCallback? onLevelTap;
  final VoidCallback? onAvatarTap;

  const UserGreetingCard({
    super.key,
    required this.homeState,
    this.onLevelTap,
    this.onAvatarTap,
  });

  @override
  State<UserGreetingCard> createState() => _UserGreetingCardState();
}

class _UserGreetingCardState extends State<UserGreetingCard> {
  String? _localProfileImagePath;
  String? _profileImageUrl;
  StreamSubscription<Map<String, String?>>? _profileImageSub;
  late String _userName;

  @override
  void initState() {
    super.initState();
    _userName = widget.homeState.userName;
    _profileImageUrl = widget.homeState.profileImageUrl;
    print(
      '🖼️ [USER_GREETING] Inicializando com profileImageUrl: "$_profileImageUrl"',
    );
    print(
      '🖼️ [USER_GREETING] widget.homeState.profileImageUrl: "${widget.homeState.profileImageUrl}"',
    );
    _subscribeToProfileImageUpdates();
    _loadProfileImageFromCache();
    _loadProfileImageFromAPI(); // Carregar diretamente da API como na home do personal
  }

  @override
  void didUpdateWidget(UserGreetingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('🖼️ [USER_GREETING] didUpdateWidget chamado');
    print(
      '🖼️ [USER_GREETING] oldWidget.homeState.profileImageUrl: "${oldWidget.homeState.profileImageUrl}"',
    );
    print(
      '🖼️ [USER_GREETING] widget.homeState.profileImageUrl: "${widget.homeState.profileImageUrl}"',
    );

    // Atualizar foto se o HomeState mudou
    if (oldWidget.homeState.profileImageUrl !=
        widget.homeState.profileImageUrl) {
      setState(() {
        _profileImageUrl = widget.homeState.profileImageUrl;
        print(
          '🖼️ [USER_GREETING] HomeState atualizado - nova profileImageUrl: "$_profileImageUrl"',
        );
      });
    }
    if (oldWidget.homeState.userName != widget.homeState.userName) {
      setState(() {
        _userName = widget.homeState.userName;
      });
    }
  }

  @override
  void dispose() {
    _profileImageSub?.cancel();
    super.dispose();
  }

  void _subscribeToProfileImageUpdates() {
    _profileImageSub = sl<ProfileImageNotificationService>().profileImageStream
        .listen((data) {
          final imagePath = data['imagePath'];
          final imageUrl = data['imageUrl'];
          final fullName = data['fullName'];

          if (mounted) {
            setState(() {
              if (imagePath != null && imagePath.isNotEmpty) {
                _localProfileImagePath = imagePath;
                _profileImageUrl =
                    null; // Limpar URL da API quando usando arquivo local
              } else if (imageUrl != null && imageUrl.isNotEmpty) {
                _profileImageUrl = imageUrl;
                _localProfileImagePath =
                    null; // Limpar cache local quando usando URL da API
              }
              // Atualizar nome imediatamente quando vier no evento
              if (fullName != null && fullName.isNotEmpty) {
                _userName = fullName;
              }
            });
            print(
              '🖼️ [USER_GREETING] Foto de perfil atualizada - Path: $imagePath, URL: $imageUrl',
            );
          }
        });
  }

  /// Carrega a foto de perfil do cache (SharedPreferences)
  Future<void> _loadProfileImageFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedImageUrl = prefs.getString('profile_image_url');

      print(
        '🔍 [USER_GREETING] Verificando cache - profile_image_url: "$cachedImageUrl"',
      );

      if (cachedImageUrl != null &&
          cachedImageUrl.isNotEmpty &&
          _profileImageUrl == null) {
        if (mounted) {
          setState(() {
            _profileImageUrl = cachedImageUrl;
          });
          print('✅ [USER_GREETING] Foto carregada do cache: "$cachedImageUrl"');
        }
      }
    } catch (e) {
      print('❌ [USER_GREETING] Erro ao carregar foto do cache: $e');
    }
  }

  /// Carrega a foto de perfil diretamente da API (igual na home do personal)
  Future<void> _loadProfileImageFromAPI() async {
    try {
      print('🔍 [USER_GREETING] Carregando foto da API...');

      final profileData = await sl<ProfileApiService>().getUserProfile();
      print('✅ [USER_GREETING] Perfil carregado da API: $profileData');

      final profileImageUrl =
          (profileData['profileImageUrl'] ??
                  profileData['imageUrl'] ??
                  profileData['avatarUrl'] ??
                  profileData['profileImage'] ??
                  '')
              .toString();

      print('🔍 [USER_GREETING] profileImageUrl da API: "$profileImageUrl"');

      if (profileImageUrl.isNotEmpty && mounted) {
        setState(() {
          _profileImageUrl = profileImageUrl;
        });
        print('✅ [USER_GREETING] Foto carregada da API: "$profileImageUrl"');
      }
    } catch (e) {
      print('❌ [USER_GREETING] Erro ao carregar foto da API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '🔍 [USER_GREETING] Construindo card com profileImageUrl: "${widget.homeState.profileImageUrl}"',
    );
    print('🔍 [USER_GREETING] _profileImageUrl atual: "$_profileImageUrl"');
    print(
      '🔍 [USER_GREETING] _localProfileImagePath atual: "$_localProfileImagePath"',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar circular 62px com borda laranja 3px
        GestureDetector(
          onTap: widget.onAvatarTap,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryOrange, width: 3),
            ),
            child: ClipOval(child: _buildProfileImage()),
          ),
        ),
        const SizedBox(width: 12),

        // Informações do usuário
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título "Olá, Lucas!" - 24px, semibold, #1C1C1C
              Text(
                'Olá, $_userName!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600, // semibold
                  color: const Color(0xFF1C1C1C), // #1C1C1C
                  height: 1.2,
                ),
              ),

              const SizedBox(
                height: 8,
              ), // Reduzido de 8 para 4 para diminuir espaçamento
              // Linha de status com alinhamento no topo
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Mantém textos no topo
                children: [
                  // Item 1: Medalha + "Iniciante"
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: AppColors.primaryOrange, // Laranja principal
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.homeState.userLevel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // medium
                          color: const Color(0xFF5A5A5A), // #5A5A5A
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),

                  // Separador "·" com 8px de padding
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '·',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color(0xFF5A5A5A), // #5A5A5A
                      ),
                    ),
                  ),

                  // Item 2: Medalha + "120 xp"
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 16,
                        color: AppColors.primaryOrange, // Laranja principal
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.homeState.userXp} xp',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500, // medium
                          color: const Color(0xFF5A5A5A), // #5A5A5A
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),

                  // Spacer para alinhar "Ver nível" à direita
                  const Spacer(),

                  // Botão "Ver nível" - 14px, semibold, #5A5A5A - alinhado no topo com os textos
                  TextButton(
                    onPressed: widget.onLevelTap,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44), // Alvo de toque mínimo
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.topLeft, // Alinha o texto no topo
                    ),
                    child: Text(
                      'Ver nível',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600, // semibold
                        color: const Color(0xFF5A5A5A), // #5A5A5A
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói a imagem do perfil priorizando arquivo local, depois URL da API
  Widget _buildProfileImage() {
    print('🖼️ [USER_GREETING] ===== CONSTRUINDO IMAGEM DO PERFIL =====');
    print(
      '🖼️ [USER_GREETING] _localProfileImagePath: "$_localProfileImagePath"',
    );
    print('🖼️ [USER_GREETING] _profileImageUrl: "$_profileImageUrl"');

    // Regra:
    // - Se há arquivo local (upload recente), usar arquivo local
    // - Se não há arquivo local mas há URL da API, usar NetworkImage
    // - Caso contrário, usar avatar com iniciais

    final bool hasLocalFile =
        _localProfileImagePath != null && _localProfileImagePath!.isNotEmpty;
    final bool hasApiUrl =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    if (hasLocalFile) {
      print('🖼️ [USER_GREETING] Exibindo arquivo local');
      return Image.file(
        File(_localProfileImagePath!),
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
      );
    }

    if (hasApiUrl) {
      print('🖼️ [USER_GREETING] Exibindo imagem da API');
      return Image.network(
        _profileImageUrl!,
        width: 62,
        height: 62,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6A00)),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print(
            '❌ [USER_GREETING] Erro ao carregar da API, usando fallback avatar. Erro: $error',
          );
          return _buildInitialsAvatar();
        },
      );
    }

    print('🖼️ [USER_GREETING] Exibindo avatar com iniciais');
    return _buildInitialsAvatar();
  }

  /// Constrói o avatar com iniciais
  Widget _buildInitialsAvatar() {
    return Container(
      width: 62,
      height: 62,
      decoration: const BoxDecoration(
        color: Color(0xFFEFEFEF),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(widget.homeState.userName),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2A2A2A),
          height: 1.0,
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = (fullName)
        .trim()
        .split(RegExp(r"\s+"))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    final first = parts.first.characters.first.toUpperCase();
    final last = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return (first + last).trim();
  }
}

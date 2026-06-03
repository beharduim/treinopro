import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/image_orientation_fix.dart';
import '../../../balance/presentation/pages/personal_balance_page.dart';
import '../../../payouts/presentation/widgets/add_payout_method_bottom_sheet.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../data/services/profile_api_service.dart';
import '../../data/services/profile_stats_service.dart';
import '../../../gamification/presentation/utils/level_labels.dart';
import '../../data/services/notifications_api_service.dart';
import '../../../auth/data/services/upload_service.dart';
import 'trainer_lessons_history_page.dart';
import '../../../classes/presentation/pages/my_disputes_page.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../../../core/services/account_access_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/login_bloc.dart';

/// Página de perfil do personal trainer
class PersonalProfilePage extends StatefulWidget {
  const PersonalProfilePage({super.key});

  @override
  State<PersonalProfilePage> createState() => _PersonalProfilePageState();
}

class _PersonalProfilePageState extends State<PersonalProfilePage> {
  static const double _profileImageMaxDimension = 1600;
  static const int _avatarCacheSize = 512;

  // Serviços
  final ProfileApiService _profileApiService = sl<ProfileApiService>();
  final ProfileStatsService _profileStatsService = sl<ProfileStatsService>();
  late final ProfileNotificationsApiService _notificationsApiService;
  final UploadService _uploadService = sl<UploadService>();

  // Estados de loading
  bool _isLoadingProfile = true;
  bool _isLoadingStats = true;
  bool _isUpdatingProfile = false;
  bool _isChangingPassword = false;
  bool _isUpdatingNotifications = false;
  bool _isUploadingImage = false;

  // Dados do perfil
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _profileImageUrl = '';
  String _profileImagePath = 'assets/images/trainer_profile.png';

  // Dados apenas para visualização
  String _documentType = '';
  String _documentNumber = '';
  String _birthDate = '';
  String _cref = '';

  // Dados de estatísticas
  int _xpLevel = 0;
  int _totalXp = 0;
  double _totalEarned = 0.0;
  double _walletAvailable = 0.0;
  double _stars = 0.0;
  int _totalClasses = 0;
  int _completedClasses = 0;

  // Key para forçar reconstrução apenas da imagem
  Key _profileImageKey = const ValueKey('profile_image_default');

  // Preferências de notificação
  bool _notificationsEnabled = true;
  bool _reminderEnabled = true;

  // Controllers para o modal de alteração de senha
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // WebSocket e debounce de preferências
  IO.Socket? _socket;
  Timer? _prefsDebounce;

  @override
  void initState() {
    super.initState();
    _notificationsApiService = sl<ProfileNotificationsApiService>();
    print('🚀 [PROFILE] ===== INICIANDO PERFIL =====');
    print('🚀 [PROFILE] Chamando _loadProfileData()...');
    _loadProfileData();
    print('🚀 [PROFILE] Chamando _loadStatsData()...');
    _loadStatsData();
    print('🚀 [PROFILE] Chamando _loadNotificationPreferences()...');
    _loadNotificationPreferences();
    print('🚀 [PROFILE] Chamando _setupRealTimeUpdates()...');
    _setupRealTimeUpdates();
    print('🚀 [PROFILE] ===== INICIALIZAÇÃO CONCLUÍDA =====');
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _prefsDebounce?.cancel();
    _cleanupRealTimeUpdates();
    super.dispose();
  }

  /// Configura atualizações em tempo real
  void _setupRealTimeUpdates() {
    // WebSocket para atualizações instantâneas
    _setupWebSocket();
  }

  /// Configura WebSocket para atualizações instantâneas
  void _setupWebSocket() {
    try {
      _socket = IO.io(
        AppConfig.apiBaseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build(),
      );

      _socket?.onConnect((_) {
        print('🔌 [PROFILE] WebSocket conectado');
      });

      _socket?.onDisconnect((_) {
        print('🔌 [PROFILE] WebSocket desconectado');
      });

      // Escutar eventos de atualização
      _socket?.on('class_completed', (data) {
        print('🔄 [PROFILE] Aula concluída - atualizando dados');
        _refreshStatsData();
      });

      _socket?.on('class_rated', (data) {
        print('🔄 [PROFILE] Aula avaliada - atualizando dados');
        _refreshStatsData();
      });

      _socket?.on('payment_processed', (data) {
        print('🔄 [PROFILE] Pagamento processado - atualizando dados');
        _refreshStatsData();
      });

      _socket?.on('xp_earned', (data) {
        print('🔄 [PROFILE] XP ganho - atualizando dados');
        _refreshStatsData();
      });
    } catch (e) {
      print('❌ [PROFILE] Erro ao conectar WebSocket: $e');
    }
  }

  /// Limpa recursos de atualização em tempo real
  void _cleanupRealTimeUpdates() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  /// Atualiza apenas dados de estatísticas (silent evita piscar loading)
  Future<void> _refreshStatsData() async {
    await _loadStatsData(silent: true);
  }

  /// Constrói a imagem do perfil priorizando a URL da API
  Widget _buildProfileImage() {
    print('🖼️ [PROFILE_IMAGE] ===== CONSTRUINDO IMAGEM DO PERFIL =====');
    print('🖼️ [PROFILE_IMAGE] _profileImagePath: "$_profileImagePath"');
    print('🖼️ [PROFILE_IMAGE] _profileImageUrl: "$_profileImageUrl"');

    // Regra:
    // - Se o usuário acabou de fazer upload nesta sessão, usamos o arquivo local (_profileImagePath inicia com '/')
    // - Após relogar (sem arquivo local), se a API trouxe URL válida, usamos NetworkImage
    // - Caso contrário, usamos o asset padrão

    final bool hasLocalFile = _profileImagePath.startsWith('/');
    final bool hasApiUrl = _profileImageUrl.isNotEmpty;

    if (hasLocalFile) {
      print('🖼️ [PROFILE_IMAGE] Exibindo arquivo local');
      return Container(key: _profileImageKey, child: _getLocalProfileImage());
    }

    if (hasApiUrl) {
      print('🖼️ [PROFILE_IMAGE] Exibindo imagem da API');
      return Container(
        key: _profileImageKey,
        child: ClipOval(
          child: Image.network(
            _profileImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print(
                '❌ [PROFILE_IMAGE] Erro ao carregar da API, usando fallback asset. Erro: $error',
              );
              return Image.asset(
                'assets/images/trainer_profile.png',
                fit: BoxFit.cover,
              );
            },
          ),
        ),
      );
    }

    print('🖼️ [PROFILE_IMAGE] Exibindo asset padrão');
    return Container(
      key: _profileImageKey,
      child: Image.asset(
        'assets/images/trainer_profile.png',
        fit: BoxFit.cover,
      ),
    );
  }

  /// Retorna a imagem local do perfil
  Widget _getLocalProfileImage() {
    if (_profileImagePath.startsWith('/')) {
      // Arquivo local selecionado
      return Image.file(
        File(_profileImagePath),
        fit: BoxFit.cover,
        cacheWidth: _avatarCacheSize,
        cacheHeight: _avatarCacheSize,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/trainer_profile.png',
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      // Asset padrão
      return Image.asset(_profileImagePath, fit: BoxFit.cover);
    }
  }

  /// Carrega dados do perfil da API
  Future<void> _loadProfileData() async {
    print('👤 [PROFILE] ===== INICIANDO _loadProfileData =====');
    try {
      setState(() {
        _isLoadingProfile = true;
      });

      print('👤 [PROFILE] Carregando dados do perfil...');
      print('👤 [PROFILE] kDebugMode: $kDebugMode');
      print('👤 [PROFILE] ApiConstants.baseUrl: ${ApiConstants.baseUrl}');
      print('👤 [PROFILE] AppConfig.apiBaseUrl: ${AppConfig.apiBaseUrl}');
      print('👤 [PROFILE] Chamando _profileApiService.getUserProfile()...');
      final profileData = await _profileApiService.getUserProfile();
      print('👤 [PROFILE] Resposta recebida da API');

      print('🔍 [PROFILE] ===== DADOS RECEBIDOS DA API =====');
      print('🔍 [PROFILE] Dados completos: $profileData');
      print('🔍 [PROFILE] Campos disponíveis: ${profileData.keys.toList()}');
      print(
        '🔍 [PROFILE] profileImageUrl: "${profileData['profileImageUrl']}"',
      );
      print('🔍 [PROFILE] profileImage: "${profileData['profileImage']}"');
      print('🔍 [PROFILE] imageUrl: "${profileData['imageUrl']}"');
      print('🔍 [PROFILE] avatarUrl: "${profileData['avatarUrl']}"');
      print('🔍 [PROFILE] documentType: "${profileData['documentType']}"');
      print('🔍 [PROFILE] documentNumber: "${profileData['documentNumber']}"');
      print('🔍 [PROFILE] birthDate: "${profileData['birthDate']}"');
      print('🔍 [PROFILE] cref: "${profileData['cref']}"');

      setState(() {
        _firstName = profileData['firstName'] ?? '';
        _lastName = profileData['lastName'] ?? '';
        _email = profileData['email'] ?? '';
        // Não sobrescrever _profileImageUrl se já temos um arquivo local recém enviado
        if (_profileImagePath == 'assets/images/trainer_profile.png') {
          final String candidateApiImageUrl =
              (profileData['profileImageUrl'] ??
              profileData['imageUrl'] ??
              profileData['avatarUrl'] ??
              profileData['profileImage'] ??
              '');
          _profileImageUrl = (candidateApiImageUrl is String)
              ? candidateApiImageUrl
              : '';
          print(
            '🖼️ [PROFILE_IMAGE] URL selecionada da API: "$_profileImageUrl"',
          );
        }
        // Documentos: aceitar chaves alternativas e padronizar CPF
        final String apiDocumentType =
            (profileData['documentType'] ?? '') as String;
        final String apiDocumentNumber =
            (profileData['documentNumber'] ?? profileData['cpf'] ?? '')
                as String;
        _documentType = apiDocumentType.isNotEmpty
            ? apiDocumentType
            : (apiDocumentNumber.isNotEmpty ? 'CPF' : '');
        _documentNumber = apiDocumentNumber;
        _birthDate = profileData['birthDate'] ?? '';
        // CREF: priorizar UF + número, com zero à esquerda no número (6 dígitos)
        final String crefUf = (profileData['crefUf'] ?? '') as String;
        final String crefNumberRaw =
            (profileData['crefNumber'] ?? '') as String;
        final String crefCombined =
            (crefUf.isNotEmpty && crefNumberRaw.isNotEmpty)
            ? '${crefUf}-${crefNumberRaw.padLeft(6, '0')}'
            : '';
        _cref = crefCombined.isNotEmpty
            ? crefCombined
            : (profileData['cref'] ?? '');
        _isLoadingProfile = false;
      });

      print('✅ [PROFILE] Dados do perfil carregados com sucesso');
      print('✅ [PROFILE] Profile Image URL: "$_profileImageUrl"');
      print('✅ [PROFILE] Profile Image Path: "$_profileImagePath"');
      print('✅ [PROFILE] Document Type: "$_documentType"');
      print('✅ [PROFILE] Document Number: "$_documentNumber"');
      print('✅ [PROFILE] Birth Date: "$_birthDate"');
      print('✅ [PROFILE] CREF: "$_cref"');
    } catch (e) {
      print('❌ [PROFILE] ===== ERRO NO _loadProfileData =====');
      print('❌ [PROFILE] Erro ao carregar dados do perfil: $e');
      if (await AccountAccessHandler.handle(e)) return;
      setState(() {
        _isLoadingProfile = false;
      });
      _showErrorSnackBar('Não foi possível carregar seus dados. Tente novamente.');
    }
  }

  /// Carrega dados de estatísticas da API
  Future<void> _loadStatsData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoadingStats = true;
        });
      }

      print('📊 [PROFILE] ===== INICIANDO CARREGAMENTO DE ESTATÍSTICAS =====');
      final stats = await _profileStatsService.getProfileStats();

      print('📊 [PROFILE] ===== DADOS RECEBIDOS DO SERVIÇO =====');
      print('📊 [PROFILE] Stats recebidos: $stats');
      print('📊 [PROFILE] XP Level: ${stats['xpLevel']}');
      print('📊 [PROFILE] Total XP: ${stats['totalXp']}');
      print('📊 [PROFILE] Total Earned: ${stats['totalEarned']}');

      setState(() {
        _xpLevel = stats['xpLevel'] ?? _xpLevel;
        _totalXp = stats['totalXp'] ?? _totalXp;
        _totalEarned = stats['totalEarned'] ?? _totalEarned;
        _walletAvailable = stats['walletBalance'] ?? _walletAvailable;
        _stars = stats['stars'] ?? _stars;
        _totalClasses = stats['totalClasses'] ?? _totalClasses;
        _completedClasses = stats['completedClasses'] ?? _completedClasses;
        _isLoadingStats = false;
      });

      print('✅ [PROFILE] ===== VALORES FINAIS SETADOS =====');
      print('✅ [PROFILE] _xpLevel: $_xpLevel');
      print('✅ [PROFILE] _totalXp: $_totalXp');
      print('✅ [PROFILE] _totalEarned: $_totalEarned');
      print('✅ [PROFILE] _stars: $_stars');
      print('✅ [PROFILE] _totalClasses: $_totalClasses');
    } catch (e) {
      print('❌ [PROFILE] Erro ao carregar estatísticas: $e');
      setState(() {
        _isLoadingStats = false;
      });
      _showErrorSnackBar('Erro ao carregar estatísticas');
    }
  }

  /// Carrega preferências de notificação
  Future<void> _loadNotificationPreferences() async {
    try {
      print('🔔 [PROFILE] Carregando preferências de notificação...');
      final preferences = await _notificationsApiService
          .getNotificationPreferences();

      setState(() {
        _notificationsEnabled = preferences['notificationsEnabled'] ?? true;
        _reminderEnabled = preferences['reminderEnabled'] ?? true;
      });

      print(
        '✅ [PROFILE] Preferências carregadas: $_notificationsEnabled, $_reminderEnabled',
      );
    } catch (e) {
      print('❌ [PROFILE] Erro ao carregar preferências: $e');
      // Usar valores padrão em caso de erro
    }
  }

  // Abre opções nativas para selecionar imagem (Câmera / Galeria)
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancelar'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  // Usa image_picker para capturar/selecionar imagem e faz upload
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: _profileImageMaxDimension,
        maxHeight: _profileImageMaxDimension,
        imageQuality: 88,
        requestFullMetadata: false,
      );
      if (picked != null) {
        // Corrigir orientação EXIF antes de fazer upload
        // Passar isFromCamera: true se veio da câmera, false se veio da galeria
        File imageFile = File(picked.path);
        imageFile = await fixImageOrientation(
          imageFile,
          isFromCamera: source == ImageSource.camera,
        );
        await _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('❌ [PROFILE] Erro ao selecionar imagem: $e');
      _showErrorSnackBar('Erro ao selecionar imagem');
    }
  }

  /// Faz upload da imagem de perfil
  Future<void> _uploadProfileImage(File imageFile) async {
    if (!mounted) return;
    try {
      setState(() {
        _isUploadingImage = true;
      });

      // 1. Atualizar interface IMEDIATAMENTE (setState local)
      setState(() {
        _profileImagePath = imageFile.path;
        _profileImageKey = ValueKey(
          'profile_image_${DateTime.now().millisecondsSinceEpoch}',
        );
      });

      print('📤 [PROFILE] Interface atualizada IMEDIATAMENTE');
      print('📤 [PROFILE] Fazendo upload da imagem em background...');

      // 2. Enviar para API em BACKGROUND (sem bloquear UI)
      final result = await _uploadService.uploadProfileImage(file: imageFile);
      if (!mounted) return;

      if (result.isProcessed) {
        print('✅ [UPLOAD] Upload realizado com sucesso');
        print('✅ [UPLOAD] Nova URL: ${result.url}');

        // 3. Atualizar URL da API (para futuras referências e pós-relogin)
        setState(() {
          _profileImageUrl = result.url;
        });
        // 3.1 Persistir ID da imagem no perfil do usuário para aparecer após relogar
        try {
          await _profileApiService.updateUserProfile({
            'profileImageId': result.id,
          });
          print('✅ [PROFILE] ID da imagem persistido no perfil: ${result.id}');
        } catch (e) {
          print('❌ [PROFILE] Falha ao persistir ID da imagem no perfil: $e');
        }

        _showSuccessSnackBar('Imagem de perfil atualizada com sucesso!');
        print('✅ [PROFILE] Upload realizado com sucesso');
      } else {
        throw Exception('Erro no processamento da imagem');
      }
    } catch (e) {
      print('❌ [PROFILE] Erro no upload: $e');
      if (mounted) {
        _showErrorSnackBar('Erro ao fazer upload da imagem');
      }

      // Opcional: reverter para imagem anterior em caso de erro
      if (mounted) {
        setState(() {
          _profileImagePath = 'assets/images/trainer_profile.png';
          _profileImageKey = const ValueKey('profile_image_default');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  /// Atualiza dados pessoais
  Future<void> _updateProfile() async {
    try {
      setState(() {
        _isUpdatingProfile = true;
      });

      print('👤 [PROFILE] Atualizando dados pessoais...');
      await _profileApiService.updateUserProfile({
        'firstName': _firstName,
        'lastName': _lastName,
      });

      _showSuccessSnackBar('Dados atualizados com sucesso!');
      print('✅ [PROFILE] Dados atualizados com sucesso');
    } catch (e) {
      print('❌ [PROFILE] Erro ao atualizar dados: $e');
      _showErrorSnackBar('Erro ao atualizar dados pessoais');
    } finally {
      setState(() {
        _isUpdatingProfile = false;
      });
    }
  }

  /// Atualiza preferências de notificação
  Future<void> _updateNotificationPreferences() async {
    try {
      setState(() {
        _isUpdatingNotifications = true;
      });

      print('🔔 [PROFILE] Atualizando preferências de notificação...');
      await _notificationsApiService.updateNotificationPreferences(
        notificationsEnabled: _notificationsEnabled,
        reminderEnabled: _reminderEnabled,
      );

      _showSuccessSnackBar('Preferências atualizadas com sucesso!');
      print('✅ [PROFILE] Preferências atualizadas com sucesso');
    } catch (e) {
      print('❌ [PROFILE] Erro ao atualizar preferências: $e');
      _showErrorSnackBar('Erro ao atualizar preferências');
    } finally {
      setState(() {
        _isUpdatingNotifications = false;
      });
    }
  }

  void _scheduleUpdateNotificationPreferences() {
    _prefsDebounce?.cancel();
    _prefsDebounce = Timer(const Duration(milliseconds: 600), () {
      _updateNotificationPreferences();
    });
  }

  /// Altera senha do usuário
  Future<void> _changePassword() async {
    if (!_isPasswordValid(_newPasswordController.text)) {
      _showErrorSnackBar('A nova senha não atende aos critérios de segurança');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('As senhas não coincidem');
      return;
    }

    try {
      setState(() {
        _isChangingPassword = true;
      });

      print('🔐 [PROFILE] Alterando senha...');
      await _profileApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      _showSuccessSnackBar('Senha alterada com sucesso!');
      _clearPasswordFields();
      Navigator.of(context).pop(); // Fechar modal
      print('✅ [PROFILE] Senha alterada com sucesso');
    } catch (e) {
      print('❌ [PROFILE] Erro ao alterar senha: $e');
      _showErrorSnackBar('Erro ao alterar senha');
    } finally {
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  /// Valida se a senha atende aos critérios de segurança
  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  /// Limpa campos de senha
  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  /// Mostra SnackBar de erro
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostra SnackBar de sucesso
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Item de checklist de senha
  Widget _buildPasswordRuleItem({
    required String label,
    required bool isValid,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isValid ? AppColors.primaryOrange : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 12,
            color: isValid ? AppColors.primaryOrange : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // Função para abrir modal de edição de dados pessoais
  void _showEditPersonalDataModal() {
    final TextEditingController firstNameController = TextEditingController(
      text: _firstName,
    );
    final TextEditingController lastNameController = TextEditingController(
      text: _lastName,
    );
    final TextEditingController emailController = TextEditingController(
      text: _email,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFDFE),
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  const Text(
                    'Editar dados pessoais',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo Nome
                  _buildEditField('Nome', firstNameController),
                  const SizedBox(height: 16),

                  // Campo Sobrenome
                  _buildEditField('Sobrenome', lastNameController),
                  const SizedBox(height: 16),

                  // Campo Email
                  _buildEditField(
                    'Email',
                    emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),

                  // Dados apenas para visualização
                  _buildReadOnlyField('RG', _documentNumber),
                  const SizedBox(height: 8),
                  _buildReadOnlyField('Data de Nascimento', _birthDate),

                  const SizedBox(height: 32),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: Color(0xFF2D3748)),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Fechar modal e delegar para o fluxo de salvamento.
                            // A troca de e-mail é tratada à parte (exige código).
                            Navigator.pop(context);
                            _savePersonalData(
                              firstNameController.text.trim(),
                              lastNameController.text.trim(),
                              emailController.text.trim(),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Salvar',
                            style: TextStyle(
                              fontFamily: 'Fira Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Salva nome/sobrenome imediatamente. Se o e-mail mudou, dispara o fluxo
  /// de troca com confirmação por código (não altera o e-mail sem confirmar).
  Future<void> _savePersonalData(
    String newFirstName,
    String newLastName,
    String newEmail,
  ) async {
    final emailChanged =
        newEmail.isNotEmpty && newEmail.toLowerCase() != _email.toLowerCase();

    // Atualiza nome localmente e persiste (comportamento anterior)
    setState(() {
      _firstName = newFirstName;
      _lastName = newLastName;
    });

    try {
      await _profileApiService.updateUserProfile({
        'firstName': _firstName,
        'lastName': _lastName,
      });
    } catch (e) {
      print('❌ [PROFILE] Erro ao persistir nome na API: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aviso: erro ao salvar no servidor. Tente novamente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    if (!emailChanged) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dados atualizados com sucesso!'),
            backgroundColor: AppColors.primaryOrange,
          ),
        );
      }
      return;
    }

    await _startEmailChangeFlow(newEmail);
  }

  /// Fluxo de troca de e-mail: envia código ao novo e-mail, pede confirmação
  /// e só então efetiva a alteração.
  Future<void> _startEmailChangeFlow(String newEmail) async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Enviar código para o novo e-mail
    try {
      await _profileApiService.sendEmailChangeCode(newEmail);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Enviamos um código de confirmação para $newEmail.'),
        backgroundColor: AppColors.primaryOrange,
        duration: const Duration(seconds: 3),
      ),
    );

    // 2. Pedir o código ao usuário
    final code = await _promptVerificationCode(newEmail);
    if (code == null || code.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Troca de e-mail cancelada.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }

    // 3. Verificar o código e efetivar a troca
    try {
      await _profileApiService.verifyEmailChangeCode(newEmail, code.trim());
      await _profileApiService.changeEmail(newEmail, code.trim());

      if (!mounted) return;
      setState(() {
        _email = newEmail;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('E-mail alterado com sucesso!'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_cleanError(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Diálogo para o usuário digitar o código de 6 dígitos.
  Future<String?> _promptVerificationCode(String newEmail) {
    final codeController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar novo e-mail',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite o código de 6 dígitos enviado para $newEmail.',
                style: const TextStyle(fontFamily: 'Fira Sans', height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF2D3748)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(codeController.text.trim()),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  /// Remove o prefixo "Exception: " das mensagens de erro.
  String _cleanError(Object error) {
    final raw = error.toString();
    const prefix = 'Exception: ';
    return raw.startsWith(prefix) ? raw.substring(prefix.length) : raw;
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryOrange),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 16,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    // Formatar data de nascimento se for o campo correto
    String displayValue = value;
    if (label == 'Data de Nascimento' && value.isNotEmpty) {
      displayValue = _formatBirthDate(value);
    }

    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF718096),
          ),
        ),
        Expanded(
          child: Text(
            displayValue.isEmpty ? 'Não informado' : displayValue,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Formata a data de nascimento para exibição
  String _formatBirthDate(String dateString) {
    try {
      if (dateString.isEmpty) return 'Não informado';

      // Se já está no formato correto (DD/MM/YYYY), retorna como está
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dateString)) {
        return dateString;
      }

      // Se é um timestamp ISO, converte para formato brasileiro
      if (dateString.contains('T') || dateString.contains('-')) {
        final date = DateTime.parse(dateString);
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }

      // Se é apenas uma string de data no formato YYYY-MM-DD
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dateString)) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }

      return dateString; // Retorna como está se não conseguir formatar
    } catch (e) {
      print('❌ [PROFILE] Erro ao formatar data de nascimento: $e');
      return dateString; // Retorna o valor original em caso de erro
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      isDarkBackground: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFDFE),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFCFDFE),
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: const Text(
            'Meu perfil',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primaryOrange,
          onRefresh: () async {
            await _loadProfileData();
            await _loadStatsData(silent: true);
            await _loadNotificationPreferences();
            await Future.delayed(const Duration(milliseconds: 400));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Card do perfil e progresso
                _buildProfileCard(),
                const SizedBox(height: 16),
                // Card de dados e preferências
                _buildDataPreferencesCard(),
                const SizedBox(height: 16),
                // Card de ganhos
                _buildEarningsCard(),
                const SizedBox(height: 16),
                // Card de configurações
                _buildSettingsCard(),
                const SizedBox(height: 32),
                // Botão de logout
                _buildLogoutButton(),
                const SizedBox(height: 16),
                // Botão de excluir conta
                _buildDeleteAccountButton(),
                const SizedBox(height: 24), // Espaço para navigation bar
              ],
            ),
          ),
        ),
        // Barra de navegação removida
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Informações do personal
            Row(
              children: [
                // Foto do perfil
                GestureDetector(
                  onTap: _showImageSourceOptions,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(43),
                      border: Border.all(
                        color: AppColors.primaryOrange,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(43),
                      child: _buildProfileImage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Informações textuais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome
                      if (_isLoadingProfile)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFF9F9F9),
                            ),
                          ),
                        )
                      else
                        Text(
                          '$_firstName $_lastName',
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFF9F9F9),
                          ),
                        ),
                      const SizedBox(height: 4),
                      // CREF
                      if (_cref.isNotEmpty)
                        Text(
                          _cref,
                          style: const TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 22,
                            color: AppColors.primaryOrange,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _isLoadingStats
                                  ? 'Carregando...'
                                  : '${_stars.toStringAsFixed(1)} ($_totalClasses aulas)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fira Sans',
                                fontSize: 16,
                                color: Color(0xFFF3F3F3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Indicador de atualização em tempo real
                          if (_socket?.connected == true)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Bio removida
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Estatísticas
            if (_isLoadingStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatItem(
                    Icons.emoji_events,
                    'Nível',
                    LevelLabels.getPersonalLabel(_xpLevel),
                  ),
                  const SizedBox(height: 12),
                  _buildDivider(),
                  const SizedBox(height: 12),
                  _buildStatItem(Icons.military_tech, 'XP total', '$_totalXp'),
                  const SizedBox(height: 12),
                  _buildDivider(),
                  const SizedBox(height: 12),
                  _buildStatItem(
                    Icons.monetization_on,
                    'Ganhos totais',
                    'R\$ ${_totalEarned.toStringAsFixed(2)}',
                  ),
                  if (_walletAvailable > 0 &&
                      (_walletAvailable - _totalEarned).abs() > 0.009) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Disponível para saque: R\$ ${_walletAvailable.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFFF9F9F9)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 12,
                  color: Color(0xFFF9F9F9),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF9F9F9),
          ),
        ),
      ],
    );
  }

  Widget _buildDataPreferencesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 22,
                  color: Color(0xFFF9F9F9),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Dados e preferência',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF9F9F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opções
            _buildOptionRow('Imagem de perfil', 'Alterar', Icons.edit, () {
              _showImageSourceOptions();
            }),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildOptionRow('Dados pessoais', 'Editar', Icons.edit, () {
              _showEditPersonalDataModal();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance,
                  size: 22,
                  color: Color(0xFFF9F9F9),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Minha carteira',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF9F9F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opção de saldo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Saldo e histórico',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: Color(0xFFF9F9F9),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PersonalBalancePage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF9F9F9)),
                      borderRadius: BorderRadius.circular(160),
                    ),
                    child: const Text(
                      'Acessar',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFFFAF9F6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Conta bancária',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: Color(0xFFF9F9F9),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _openBankAccountSetup,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF9F9F9)),
                      borderRadius: BorderRadius.circular(160),
                    ),
                    child: const Text(
                      'Alterar',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFFFAF9F6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openBankAccountSetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPayoutMethodBottomSheet(
        onSaved: () {},
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.settings, size: 22, color: Color(0xFFF9F9F9)),
                const SizedBox(width: 8),
                const Text(
                  'Configurações',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF9F9F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opções
            _buildToggleRow('Ativar notificações', _notificationsEnabled, (
              value,
            ) {
              setState(() {
                _notificationsEnabled = value;
              });
              _scheduleUpdateNotificationPreferences();
            }),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            // Removido: Lembrete de atualização
            _buildOptionRow(
              'Senha de acesso',
              'Alterar',
              Icons.lock_outline,
              () {
                _showPasswordChangeModal();
              },
            ),
            const SizedBox(height: 16),
            _buildDivider(),
            const SizedBox(height: 16),
            _buildOptionRow('Histórico de aulas', 'Ver', Icons.history, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrainerLessonsHistoryPage(),
                ),
              );
            }),
            const SizedBox(height: 16),
            _buildOptionRow('Minhas Disputas', 'Ver', Icons.gavel, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => sl<ClassesBloc>(),
                    child: const MyDisputesPage(),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Mostra modal de alteração de senha
  void _showPasswordChangeModal() {
    // Flags persistentes para visibilidade dos campos dentro do modal
    bool _obscureCurrent = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isFormValid() {
              final newPwd = _newPasswordController.text;
              final confirmPwd = _confirmPasswordController.text;
              final currentPwd = _currentPasswordController.text;
              if (currentPwd.isEmpty) return false;
              if (!_isPasswordValid(newPwd)) return false;
              if (newPwd != confirmPwd) return false;
              return true;
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Text(
                'Alterar senha',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Senha atual
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Senha atual',
                        labelStyle: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAFC),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setModalState(
                            () => _obscureCurrent = !_obscureCurrent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nova senha
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Nova senha',
                        labelStyle: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAFC),
                        // helper removido
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setModalState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    // Checklist de validação da nova senha
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordRuleItem(
                            label: 'Mínimo de 8 caracteres',
                            isValid: _newPasswordController.text.length >= 8,
                          ),
                          _buildPasswordRuleItem(
                            label: 'Pelo menos 1 letra maiúscula',
                            isValid: RegExp(
                              r'[A-Z]',
                            ).hasMatch(_newPasswordController.text),
                          ),
                          _buildPasswordRuleItem(
                            label: 'Pelo menos 1 letra minúscula',
                            isValid: RegExp(
                              r'[a-z]',
                            ).hasMatch(_newPasswordController.text),
                          ),
                          _buildPasswordRuleItem(
                            label: 'Pelo menos 1 número',
                            isValid: RegExp(
                              r'[0-9]',
                            ).hasMatch(_newPasswordController.text),
                          ),
                          _buildPasswordRuleItem(
                            label: 'Pelo menos 1 símbolo (!@#...)',
                            isValid: RegExp(
                              r'[!@#$%^&*(),.?":{}|<>]',
                            ).hasMatch(_newPasswordController.text),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Confirmar senha
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 16,
                        color: Color(0xFF2D3748),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Confirmar nova senha',
                        labelStyle: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7FAFC),
                        errorText:
                            _confirmPasswordController.text.isNotEmpty &&
                                _confirmPasswordController.text !=
                                    _newPasswordController.text
                            ? 'As senhas não coincidem'
                            : null,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setModalState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildPasswordRuleItem(
                        label: 'As senhas coincidem',
                        isValid:
                            _confirmPasswordController.text.isNotEmpty &&
                            _confirmPasswordController.text ==
                                _newPasswordController.text,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _clearPasswordFields();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFF2D3748)),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (!isFormValid() || _isChangingPassword)
                            ? null
                            : () async {
                                setModalState(() {});
                                await _changePassword();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isChangingPassword
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Salvar',
                                style: TextStyle(
                                  fontFamily: 'Fira Sans',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Salva a alteração de senha
  void _savePasswordChange() {
    // Validações básicas
    if (_currentPasswordController.text.isEmpty) {
      _showErrorSnackBar('Digite a senha atual');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorSnackBar('Digite a nova senha');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('A nova senha deve ter pelo menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('As senhas não coincidem');
      return;
    }

    // TODO: Implementar validação da senha atual e salvamento da nova senha
    print('Alterando senha...');
    print('Senha atual: ${_currentPasswordController.text}');
    print('Nova senha: ${_newPasswordController.text}');

    // Fechar modal e limpar campos
    _clearPasswordFields();
    Navigator.of(context).pop();

    // Mostrar sucesso
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Senha alterada com sucesso!',
          style: TextStyle(fontFamily: 'Fira Sans', color: Colors.white),
        ),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  // Mostra mensagem de erro

  Widget _buildOptionRow(
    String title,
    String actionText,
    IconData actionIcon,
    VoidCallback onTap,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 16,
            color: Color(0xFFF9F9F9),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Icon(actionIcon, size: 20, color: const Color(0xFFFAF9F6)),
              const SizedBox(width: 8),
              Text(
                actionText,
                style: const TextStyle(
                  fontFamily: 'Fira Sans',
                  fontSize: 16,
                  color: Color(0xFFFAF9F6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 16,
            color: Color(0xFFF9F9F9),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryOrange, // Cor laranja do toggle
          activeTrackColor: AppColors.primaryOrange.withOpacity(0.3),
          inactiveThumbColor: Colors.grey[400],
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFF9F9F9),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 22, color: Color(0xFFF9F9F9)),
                const SizedBox(width: 8),
                const Text(
                  'Sair da conta',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF9F9F9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Você será redirecionado para a tela de login',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14,
                color: Color(0xFFF3F3F3),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Botão de logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Sair',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return GestureDetector(
      onTap: _handleDeleteAccount,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF2D3748), width: 2),
          borderRadius: BorderRadius.circular(160),
        ),
        child: const Text(
          'Excluir conta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Excluir conta',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        content: const Text(
          'Tem certeza que deseja excluir sua conta?\n\n'
          'Sua solicitação passará por análise da equipe TreinoPro e, em até '
          '3 dias, a conta será excluída. Enquanto isso, ela continua ativa.\n\n'
          '• Não é possível excluir se houver aulas agendadas',
          style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Excluir conta',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        print('🗑️ [PROFILE] Solicitando exclusão da conta...');

        final result = await _profileApiService.requestAccountDeletion();
        if (!mounted) return;

        final message = result['message']?.toString() ??
            'Sua solicitação de exclusão está em análise. Em até 3 dias a '
                'conta será excluída.';

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Exclusão em análise',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            content: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryOrange,
                ),
                child: const Text('Entendi'),
              ),
            ],
          ),
        );
      } catch (e) {
        print('❌ [PROFILE] Erro ao solicitar exclusão: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmação
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Sair da conta',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        content: const Text(
          'Tem certeza que deseja sair da sua conta?',
          style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Outfit', color: Color(0xFF718096)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sair',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        print('🚪 [LOGOUT] Iniciando processo de logout...');
        print(
          'ℹ️ [LOGOUT] BLoCs são factory - serão recriados automaticamente no próximo login',
        );

        // 1. Limpar cache em memória
        try {
          final cacheService = sl<CacheService>();
          await cacheService.clearCache();
          print('✅ [LOGOUT] Cache limpo');
        } catch (e) {
          print('⚠️ [LOGOUT] Erro ao limpar cache: $e');
        }

        // 2. Desconectar WebSocket global
        try {
          final websocketService = sl<WebSocketService>();
          websocketService.disconnect(manual: true);
          print('✅ [LOGOUT] WebSocket desconectado');
        } catch (e) {
          print('⚠️ [LOGOUT] Erro ao desconectar WebSocket: $e');
        }

        // 3. Limpar RealtimeDataService
        try {
          final realtimeService = sl<RealtimeDataService>();
          realtimeService.dispose();
          print('✅ [LOGOUT] RealtimeDataService limpo');
        } catch (e) {
          print('⚠️ [LOGOUT] Erro ao limpar RealtimeDataService: $e');
        }

        // 5. Fazer logout na API (limpa tokens)
        final authDataSource = sl<AuthApiDataSource>();
        await authDataSource.logout();
        print('✅ [LOGOUT] Tokens limpos');

        // 6. Aguardar um pouco para garantir que tudo foi limpo
        await Future.delayed(const Duration(milliseconds: 500));

        // 7. Navegar para a tela de login
        print('🔄 [LOGOUT] Navegando para tela de login...');

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => sl<LoginBloc>(),
                child: const LoginPage(),
              ),
            ),
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ [LOGOUT] Erro durante logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao fazer logout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../health_questionnaire/presentation/pages/health_questionnaire_page.dart';
import 'student_lessons_history_page.dart';
import '../../../classes/presentation/pages/my_disputes_page.dart';
import '../../../classes/presentation/bloc/classes_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/realtime_data_service.dart';
import '../../../health_questionnaire/presentation/bloc/health_questionnaire_bloc.dart';
import '../../../health_questionnaire/domain/usecases/get_health_questionnaire.dart';
import '../../../health_questionnaire/domain/usecases/save_health_questionnaire.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../payment_methods/presentation/bloc/payment_methods_bloc.dart';
import '../../data/services/profile_api_service.dart';
import '../../data/models/user_profile_model.dart';
import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/data/services/upload_service.dart';
import '../../data/services/profile_stats_service.dart';
import '../../data/services/notifications_api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
import '../../../../core/services/profile_image_notification_service.dart';
import '../../../gamification/presentation/utils/level_labels.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/account_access_handler.dart';
import '../../../../core/utils/image_utils.dart';
import '../../../../core/utils/image_orientation_fix.dart';
import '../../../auth/presentation/bloc/login_bloc.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  static const double _profileImageMaxDimension = 1600;
  static const int _avatarCacheSize = 512;

  bool _notifications = true;
  bool _isLoading = true;
  bool _isChangingPassword = false;
  String? _error;

  // Controllers para alteração de senha
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Dados do usuário
  UserProfileModel? _userProfile;
  UserStatsModel? _userStats;

  // Estados para imagem de perfil
  String? _localProfileImagePath;
  String? _profileImageUrl;

  // Services
  late final ProfileApiService _profileApiService;
  final UploadService _uploadService = sl<UploadService>();
  final ProfileStatsService _profileStatsService = sl<ProfileStatsService>();
  late final ProfileNotificationsApiService _notificationsApiService;

  // WebSocket e debounce de preferências
  IO.Socket? _socket;
  Timer? _prefsDebounce;

  @override
  void initState() {
    super.initState();
    _profileApiService = sl<ProfileApiService>();
    _notificationsApiService = sl<ProfileNotificationsApiService>();
    _loadUserData();
    _loadNotificationPreferences();
    _setupRealTimeUpdates();
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

  /// Carrega dados de estatísticas da API
  Future<void> _loadStatsData({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _isLoading = true;
        });
      }

      print('📊 [PROFILE] ===== INICIANDO CARREGAMENTO DE ESTATÍSTICAS =====');
      final stats = await _profileStatsService.getProfileStats();

      print('📊 [PROFILE] ===== DADOS RECEBIDOS DO SERVIÇO =====');
      print('📊 [PROFILE] Stats recebidos: $stats');

      setState(() {
        _userStats = UserStatsModel.fromJson(stats);
        if (!silent) {
          _isLoading = false;
        }
      });

      print('✅ [PROFILE] ===== VALORES FINAIS SETADOS =====');
      print('✅ [PROFILE] Level: ${_userStats?.level}');
      print('✅ [PROFILE] Total XP: ${_userStats?.totalXp}');
      print('✅ [PROFILE] Completed Classes: ${_userStats?.completedClasses}');
    } catch (e) {
      print('❌ [PROFILE] Erro ao carregar estatísticas: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Erro ao carregar estatísticas');
      }
    }
  }

  /// Mostra SnackBar de erro
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Carrega preferências de notificação da API
  Future<void> _loadNotificationPreferences() async {
    try {
      print('🔔 [PROFILE] Carregando preferências de notificação...');
      final preferences = await _notificationsApiService
          .getNotificationPreferences();

      setState(() {
        _notifications = preferences['notificationsEnabled'] ?? true;
      });

      print('✅ [PROFILE] Preferências carregadas: $_notifications');
    } catch (e) {
      print('❌ [PROFILE] Erro ao carregar preferências: $e');
      // Manter valor padrão em caso de erro
    }
  }

  /// Carrega dados do usuário da API
  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Carregar perfil primeiro (obrigatório)
      final profileData = await _profileApiService.getUserProfile();
      print('🔍 [PROFILE] Dados do perfil recebidos: $profileData');
      print(
        '🔍 [PROFILE] profileImageUrl da API: ${profileData['profileImageUrl']}',
      );
      print('🔍 [PROFILE] imageUrl da API: ${profileData['imageUrl']}');
      print('🔍 [PROFILE] avatarUrl da API: ${profileData['avatarUrl']}');

      setState(() {
        _userProfile = UserProfileModel.fromJson(profileData);
        _profileImageUrl = _userProfile?.profileImageUrl;
        print('🔍 [PROFILE] _profileImageUrl após fromJson: $_profileImageUrl');
        _isLoading = false;
      });

      // Carregar estatísticas em paralelo
      await _loadStatsData();
    } catch (e, stackTrace) {
      print('❌ [PROFILE] Erro ao carregar dados: $e');
      print('❌ [PROFILE] Stack trace: $stackTrace');

      if (await AccountAccessHandler.handle(e)) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      setState(() {
        _error = 'Não foi possível carregar seus dados. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        actions: [
          if (_error != null)
            IconButton(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh),
              tooltip: 'Recarregar dados',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primaryOrange,
                ),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.primaryOrange,
              onRefresh: () async {
                await _loadUserData();
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
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange, // Laranja principal
            AppColors.primaryOrangeLight, // Laranja secundário
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Informações do aluno
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
                      border: Border.all(color: Colors.white, width: 3),
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
                      Text(
                        _userProfile?.fullName ?? 'Carregando...',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        _userProfile?.email ?? 'Carregando...',
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  Icons.emoji_events,
                  'Nível',
                  LevelLabels.getStudentLabel(
                    _parseLevelNumber(_userStats?.level),
                  ),
                ),
                _buildStatItem(
                  Icons.military_tech,
                  'XP total',
                  _userStats?.totalXp.toString() ?? '0',
                ),
                _buildStatItem(
                  Icons.sports_gymnastics,
                  'Aulas concluídas',
                  _userStats?.completedClasses.toString() ?? '0',
                ),
              ],
            ),
            // Indicador de conexão WebSocket
            if (_socket?.connected == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Atualizações em tempo real',
                      style: TextStyle(
                        fontFamily: 'Fira Sans',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _parseLevelNumber(String? levelRaw) {
    // Alguns endpoints retornam numérico, outros string; garantir fallback
    if (levelRaw == null) return 1;
    final n = int.tryParse(levelRaw);
    return n ?? 1;
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Colors.white,
                height: 1.3,
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
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDataPreferencesCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange, // Laranja principal
            AppColors.primaryOrangeLight, // Laranja secundário
          ],
        ),
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
                const Icon(Icons.person_outline, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Dados e preferência',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opções
            _buildRowOption(
              'Imagem de perfil',
              'Alterar',
              onTap: () => _showImageSourceOptions(),
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Dados pessoais',
              'Editar',
              onTap: () => _showEditStudentDataModal(),
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Questionário de Saúde',
              'Editar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (ctx) => HealthQuestionnaireBloc(
                        getQuestionnaire: sl<GetHealthQuestionnaire>(),
                        saveQuestionnaire: sl<SaveHealthQuestionnaire>(),
                      ),
                      child: const HealthQuestionnairePage(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Método de pagamento',
              'Editar',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (ctx) => sl<PaymentMethodsBloc>(),
                      child: const PaymentMethodsPage(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Histórico de aulas',
              'Ver',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const StudentLessonsHistoryPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Minhas Disputas',
              'Ver',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => sl<ClassesBloc>(),
                      child: const MyDisputesPage(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange, // Laranja principal
            AppColors.primaryOrangeLight, // Laranja secundário
          ],
        ),
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
                  Icons.settings_outlined,
                  size: 22,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Configurações',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Opções
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SwitchTheme(
                    data: SwitchThemeData(
                      trackOutlineColor:
                          MaterialStateProperty.resolveWith<Color?>((
                            Set<MaterialState> states,
                          ) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.white70; // Contorno quando ligado
                            }
                            return Colors
                                .white; // Contorno branco quando desligado
                          }),
                      trackOutlineWidth: MaterialStateProperty.all(1.0),
                    ),
                    child: Switch(
                      value: _notifications,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white70,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white30,
                      onChanged: (val) async {
                        setState(() {
                          _notifications = val;
                        });

                        // Persistir na API em background
                        try {
                          await _notificationsApiService
                              .updateNotificationPreferences(
                                notificationsEnabled: val,
                                reminderEnabled:
                                    false, // Valor padrão para lembretes
                              );
                          print(
                            '✅ [PROFILE] Preferência de notificação atualizada: $val',
                          );
                        } catch (e) {
                          print(
                            '❌ [PROFILE] Erro ao atualizar preferência: $e',
                          );
                          // Reverter em caso de erro
                          setState(() {
                            _notifications = !val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Alterar senha',
              'Alterar',
              onTap: () => _showPasswordChangeModal(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.primaryOrange, AppColors.primaryOrangeLight],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Sair da conta',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
                color: Colors.white70,
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _handleDeleteAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Excluir conta',
          style: TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRowOption(
    String label,
    String actionLabel, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.white70,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: const Color(0xFFB00020),
          ),
        );
      }
    }
  }

  /// Faz upload da imagem de perfil
  Future<void> _uploadProfileImage(File imageFile) async {
    if (!mounted) return;
    try {
      print('📤 [PROFILE] Iniciando upload da imagem: ${imageFile.path}');

      // 1. Atualizar interface IMEDIATAMENTE (setState local)
      setState(() {
        _localProfileImagePath = imageFile.path;
      });

      // Notificar a home sobre a mudança imediata
      sl<ProfileImageNotificationService>().notifyProfileImageUpdated(
        imagePath: imageFile.path,
      );

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
          _localProfileImagePath = null; // Limpar caminho local
        });

        // Notificar a home sobre a URL da API
        sl<ProfileImageNotificationService>().notifyProfileImageUpdated(
          imageUrl: result.url,
        );

        // 3.1 Persistir ID da imagem no perfil do usuário para aparecer após relogar
        try {
          await _profileApiService.updateUserProfile({
            'profileImageId': result.id,
          });
          print('✅ [PROFILE] ID da imagem persistido no perfil: ${result.id}');
        } catch (e) {
          print('❌ [PROFILE] Falha ao persistir ID da imagem no perfil: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagem de perfil atualizada com sucesso!'),
              backgroundColor: Color(0xFFFF6A00), // Laranja principal
            ),
          );
        }
        print('✅ [PROFILE] Upload realizado com sucesso');
      } else {
        throw Exception('Erro no processamento da imagem');
      }
    } catch (e) {
      print('❌ [PROFILE] Erro no upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer upload da imagem: $e'),
            backgroundColor: const Color(0xFFB00020),
          ),
        );
      }

      // Opcional: reverter para imagem anterior em caso de erro
      if (mounted) {
        setState(() {
          _localProfileImagePath = null;
        });
      }
    }
  }

  /// Constrói a imagem do perfil priorizando a URL da API
  Widget _buildProfileImage() {
    print('🖼️ [PROFILE_IMAGE] ===== CONSTRUINDO IMAGEM DO PERFIL =====');
    print(
      '🖼️ [PROFILE_IMAGE] _localProfileImagePath: "$_localProfileImagePath"',
    );
    print('🖼️ [PROFILE_IMAGE] _profileImageUrl: "$_profileImageUrl"');

    // Regra:
    // - Se o usuário acabou de fazer upload nesta sessão, usamos o arquivo local (_localProfileImagePath)
    // - Após relogar (sem arquivo local), se a API trouxe URL válida, usamos NetworkImage
    // - Caso contrário, usamos o avatar com iniciais

    final bool hasLocalFile =
        _localProfileImagePath != null && _localProfileImagePath!.isNotEmpty;
    final bool hasApiUrl =
        _profileImageUrl != null && _profileImageUrl!.isNotEmpty;

    if (hasLocalFile) {
      print('🖼️ [PROFILE_IMAGE] Exibindo arquivo local');
      return Image.file(
        File(_localProfileImagePath!),
        fit: BoxFit.cover,
        cacheWidth: _avatarCacheSize,
        cacheHeight: _avatarCacheSize,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
      );
    }

    if (hasApiUrl) {
      print('🖼️ [PROFILE_IMAGE] Exibindo imagem da API');
      return ImageUtils.buildNetworkImage(
        imageUrl: _profileImageUrl!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorWidget: _buildInitialsAvatar(),
      );
    }

    print('🖼️ [PROFILE_IMAGE] Exibindo avatar com iniciais');
    return _buildInitialsAvatar();
  }

  // Função para abrir modal de edição de dados pessoais do aluno
  void _showEditStudentDataModal() {
    final TextEditingController firstNameController = TextEditingController(
      text: _userProfile?.firstName ?? '',
    );
    final TextEditingController lastNameController = TextEditingController(
      text: _userProfile?.lastName ?? '',
    );
    final TextEditingController emailController = TextEditingController(
      text: _userProfile?.email ?? '',
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                _buildReadOnlyField(
                  'RG',
                  _userProfile?.documentNumber ?? 'Não informado',
                ),
                const SizedBox(height: 8),
                _buildReadOnlyField(
                  'Data de Nascimento',
                  _userProfile?.birthDate ?? 'Não informado',
                ),

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
                        onPressed: () async {
                          print(
                            '🔍 [STUDENT_PROFILE] Iniciando atualização de dados pessoais...',
                          );
                          print(
                            '🔍 [STUDENT_PROFILE] Nome: ${firstNameController.text}',
                          );
                          print(
                            '🔍 [STUDENT_PROFILE] Sobrenome: ${lastNameController.text}',
                          );
                          print(
                            '🔍 [STUDENT_PROFILE] Email: ${emailController.text}',
                          );

                          try {
                            // Salvar alterações na API
                            print(
                              '🔍 [STUDENT_PROFILE] Chamando _profileApiService.updateUserProfile...',
                            );
                            final result = await _profileApiService
                                .updateUserProfile({
                                  'firstName': firstNameController.text,
                                  'lastName': lastNameController.text,
                                  'email': emailController.text,
                                });
                            print('✅ [STUDENT_PROFILE] API retornou: $result');

                            // Recarregar dados do usuário
                            print(
                              '🔍 [STUDENT_PROFILE] Recarregando dados do usuário...',
                            );
                            await _loadUserData();

                            // Notificar Home imediatamente sobre o novo nome
                            final fullName =
                                '${firstNameController.text} ${lastNameController.text}'
                                    .trim();
                            sl<ProfileImageNotificationService>()
                                .notifyProfileNameUpdated(fullName: fullName);

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dados atualizados com sucesso!'),
                                backgroundColor: Color(
                                  0xFFFF6A00,
                                ), // Laranja principal
                              ),
                            );
                            print(
                              '✅ [STUDENT_PROFILE] Dados atualizados com sucesso!',
                            );
                          } catch (e) {
                            print(
                              '❌ [STUDENT_PROFILE] Erro ao atualizar dados: $e',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao atualizar dados: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
        );
      },
    );
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
              borderSide: const BorderSide(
                color: Color(0xFFFF6A00),
              ), // Laranja principal
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
    if (label == 'Data de Nascimento' &&
        value.isNotEmpty &&
        value != 'Não informado') {
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

  // Mostra modal de alteração de senha (implementação completa do personal)
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

  /// Mostra SnackBar de sucesso
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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

  // Widget para avatar com iniciais quando não há foto
  Widget _buildInitialsAvatar() {
    final initials = _userProfile?.initials ?? 'U';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(43),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
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

        // 1. Limpar WebSocket local desta página
        _cleanupRealTimeUpdates();

        // 2. Limpar cache em memória
        try {
          final cacheService = sl<CacheService>();
          await cacheService.clearCache();
          print('✅ [LOGOUT] Cache limpo');
        } catch (e) {
          print('⚠️ [LOGOUT] Erro ao limpar cache: $e');
        }

        // 3. Desconectar WebSocket global
        try {
          final websocketService = sl<WebSocketService>();
          websocketService.disconnect(manual: true);
          print('✅ [LOGOUT] WebSocket desconectado');
        } catch (e) {
          print('⚠️ [LOGOUT] Erro ao desconectar WebSocket: $e');
        }

        // 4. Limpar RealtimeDataService
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

  Future<void> _handleDeleteAccount() async {
    // Mostrar diálogo de confirmação
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
          '⚠️ Esta ação é irreversível!\n\n'
          'Sua conta será excluída permanentemente, mas:\n'
          '• Seu histórico de aulas será mantido\n'
          '• Você não poderá fazer login novamente\n'
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
        print('🗑️ [PROFILE] Iniciando exclusão da conta...');

        // Chamar API para excluir conta
        await _profileApiService.deleteAccount();

        print('✅ [PROFILE] Conta excluída com sucesso');

        // Fazer logout forçado
        final authDataSource = sl<AuthApiDataSource>();
        await authDataSource.logout();

        // Navegar para a tela de login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
        print('❌ [PROFILE] Erro ao excluir conta: $e');
        if (mounted) {
          // Extrair apenas a mensagem limpa do erro
          String errorMessage = e.toString();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}

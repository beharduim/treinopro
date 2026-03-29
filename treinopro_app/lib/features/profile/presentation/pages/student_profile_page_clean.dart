import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../health_questionnaire/presentation/pages/health_questionnaire_page.dart';
import 'student_lessons_history_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/dependency_injection.dart' show sl;
import '../../../../core/constants/app_colors.dart';
import '../../../health_questionnaire/presentation/bloc/health_questionnaire_bloc.dart';
import '../../../health_questionnaire/domain/usecases/get_health_questionnaire.dart';
import '../../../health_questionnaire/domain/usecases/save_health_questionnaire.dart';
import '../../../payment_methods/presentation/pages/payment_methods_page.dart';
import '../../../payment_methods/presentation/bloc/payment_methods_bloc.dart';
import '../../../auth/data/datasources/auth_api_datasource.dart';
import '../../../auth/presentation/pages/login_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  bool _notifications = true;
  bool _reminders = false;

  // Controllers para alteração de senha
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Dados do usuário
  String _firstName = 'Lucas';
  String _lastName = 'Souza';
  String _email = 'lucassouzap@gmail.com';

  // Image picker state (null = sem foto => placeholder com iniciais)
  String? _profileImagePath;
  // Dados apenas para visualização (placeholder)
  final String _cpf = '000.000.000-00';
  final String _birthDate = '01/01/1990';

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFDFE),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          padding: EdgeInsets.zero,
          iconSize: 28,
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.chevron_left,
            size: 28,
            color: Color(0xFF2D3748),
          ),
        ),
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
      body: SingleChildScrollView(
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
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(43),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(43),
                    child:
                        _profileImagePath != null &&
                            _profileImagePath!.isNotEmpty
                        ? (_profileImagePath!.startsWith('/')
                              ? (File(_profileImagePath!).existsSync()
                                    ? Image.file(
                                        File(_profileImagePath!),
                                        fit: BoxFit.cover,
                                      )
                                    : _buildInitialsAvatar())
                              : Image.network(
                                  _profileImagePath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildInitialsAvatar(),
                                ))
                        : _buildInitialsAvatar(),
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
                        '$_firstName $_lastName',
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
                        _email,
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Frase motivacional
                      const Text(
                        '"Transformando minha vida através do exercício!"',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Painel de progresso
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.query_stats, size: 22, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  'Painel de progresso',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(Icons.emoji_events, 'Nível', 'Bronze'),
                _buildStatItem(Icons.military_tech, 'XP total', '1240'),
                _buildStatItem(
                  Icons.sports_gymnastics,
                  'Aulas concluídas',
                  '12',
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
          ],
        ),
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
                const Icon(
                  Icons.settings_outlined,
                  size: 22,
                  color: Color(0xFFF9F9F9),
                ),
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
            _buildRowOption(
              'Notificações',
              _notifications ? 'Ativadas' : 'Desativadas',
              onTap: () {
                setState(() {
                  _notifications = !_notifications;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildRowOption(
              'Lembretes',
              _reminders ? 'Ativados' : 'Desativados',
              onTap: () {
                setState(() {
                  _reminders = !_reminders;
                });
              },
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
                  Icons.warning_outlined,
                  size: 22,
                  color: Color(0xFFF9F9F9),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Zona de perigo',
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
            // Botão de excluir conta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Excluir conta'),
                      content: const Text(
                        'Tem certeza que deseja excluir sua conta? Esta ação é irreversível.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Confirmar',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
            ),
          ],
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
                color: Color(0xFFF9F9F9),
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
                    color: Color(0xFFF3F3F3),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0xFFF3F3F3),
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

  // Usa image_picker para capturar/selecionar imagem e atualiza _profileImagePath
  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked != null) {
        setState(() {
          _profileImagePath = picked.path;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil atualizada com sucesso!'),
            backgroundColor: Color(0xFFFF6A00), // Laranja principal
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar imagem: $e'),
          backgroundColor: const Color(0xFFB00020),
        ),
      );
    }
  }

  // Função para abrir modal de edição de dados pessoais do aluno
  void _showEditStudentDataModal() {
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
                _buildReadOnlyField('CPF', _cpf),
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
                          // Salvar alterações
                          setState(() {
                            _firstName = firstNameController.text;
                            _lastName = lastNameController.text;
                            _email = emailController.text;
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dados atualizados com sucesso!'),
                              backgroundColor: Color(
                                0xFFFF6A00,
                              ), // Laranja principal
                            ),
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
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Fira Sans',
            fontSize: 14,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  // Mostra modal de alteração de senha (copiado do perfil do personal)
  void _showPasswordChangeModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  // Campo senha atual
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha atual',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo nova senha
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nova senha',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Campo confirmar senha
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirmar nova senha',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFF6A00)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      color: Color(0xFF718096),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Validar senhas
                    if (_newPasswordController.text !=
                        _confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('As senhas não coincidem'),
                          backgroundColor: Color(0xFFB00020),
                        ),
                      );
                      return;
                    }

                    if (_newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A senha deve ter pelo menos 6 caracteres',
                          ),
                          backgroundColor: Color(0xFFB00020),
                        ),
                      );
                      return;
                    }

                    // Aqui você implementaria a lógica de alteração de senha
                    _currentPasswordController.clear();
                    _newPasswordController.clear();
                    _confirmPasswordController.clear();
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Senha alterada com sucesso!'),
                        backgroundColor: Color(0xFFFF6A00),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Alterar',
                    style: TextStyle(
                      fontFamily: 'Fira Sans',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Widget para avatar com iniciais quando não há foto
  Widget _buildInitialsAvatar() {
    final initials =
        '${_firstName.isNotEmpty ? _firstName[0] : ''}${_lastName.isNotEmpty ? _lastName[0] : ''}';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
        borderRadius: BorderRadius.circular(43),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
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
        // Fazer logout
        final authDataSource = sl<AuthApiDataSource>();
        await authDataSource.logout();

        // Limpar dados locais se necessário
        // await sl<CacheService>().clearAll();

        // Navegar para a tela de login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      } catch (e) {
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

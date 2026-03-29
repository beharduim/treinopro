import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/health_questionnaire_model.dart';
import '../../data/services/health_questionnaire_api_service.dart';
import '../../../../core/di/dependency_injection.dart';

class StudentHealthModal extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? studentProfileImage;
  final int? studentScore;

  const StudentHealthModal({
    super.key,
    required this.studentId,
    required this.studentName,
    this.studentProfileImage,
    this.studentScore,
  });

  @override
  State<StudentHealthModal> createState() => _StudentHealthModalState();
}

class _StudentHealthModalState extends State<StudentHealthModal> {
  final HealthQuestionnaireApiService _apiService = sl<HealthQuestionnaireApiService>();
  
  StudentHealthQuestionnaireModel? _questionnaire;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final questionnaire = await _apiService.getStudentQuestionnaire(widget.studentId);
      
      setState(() {
        _questionnaire = questionnaire;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Flexible(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrangeLight,
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Foto do aluno
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: widget.studentProfileImage != null
                  ? Image.network(
                      widget.studentProfileImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildInitialsAvatar(),
                    )
                  : _buildInitialsAvatar(),
            ),
          ),
          const SizedBox(width: 16),
          // Informações do aluno
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                if (widget.studentScore != null) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.studentScore} pontos',
                        style: const TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Botão fechar
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initials = widget.studentName
        .split(' ')
        .take(2)
        .map((name) => name.isNotEmpty ? name[0].toUpperCase() : '')
        .join('');
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryOrange),
          ),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar questionário',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadQuestionnaire,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_questionnaire == null) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Questionário não encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este aluno ainda não preencheu o questionário de saúde.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status do questionário
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _questionnaire!.isCompleted 
                  ? Colors.green.shade50 
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _questionnaire!.isCompleted 
                    ? Colors.green.shade200 
                    : Colors.orange.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _questionnaire!.isCompleted 
                      ? Icons.check_circle 
                      : Icons.warning,
                  color: _questionnaire!.isCompleted 
                      ? Colors.green.shade700 
                      : Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _questionnaire!.isCompleted 
                            ? 'Questionário completo' 
                            : 'Questionário incompleto',
                        style: TextStyle(
                          fontFamily: 'Fira Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _questionnaire!.isCompleted 
                              ? Colors.green.shade700 
                              : Colors.orange.shade700,
                        ),
                      ),
                      if (_questionnaire!.completedAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Completado em ${_formatDate(_questionnaire!.completedAt!)}',
                          style: TextStyle(
                            fontFamily: 'Fira Sans',
                            fontSize: 12,
                            color: _questionnaire!.isCompleted 
                                ? Colors.green.shade600 
                                : Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Perguntas e respostas
          Text(
            'Questionário de Saúde',
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),

          // Condição médica
          _buildQuestionAnswer(
            'Condição médica preexistente',
            _questionnaire!.medicalCondition ?? 'Não informado',
            Icons.medical_services,
          ),
          const SizedBox(height: 16),

          // Medicamentos regulares
          _buildQuestionAnswer(
            'Medicamentos regulares',
            _questionnaire!.regularMedication ?? 'Não informado',
            Icons.medication,
          ),
          const SizedBox(height: 16),

          // Lesões crônicas
          _buildQuestionAnswer(
            'Lesões ou dores crônicas',
            _questionnaire!.chronicInjury ?? 'Não informado',
            Icons.healing,
          ),
          const SizedBox(height: 16),

          // Objetivo do treino
          _buildQuestionAnswer(
            'Objetivo principal do treino',
            _questionnaire!.trainingGoal ?? 'Não informado',
            Icons.fitness_center,
          ),
          const SizedBox(height: 16),

          // Restrições alimentares
          _buildQuestionAnswer(
            'Restrições alimentares ou alergias',
            _questionnaire!.dietaryRestrictions ?? 'Não informado',
            Icons.restaurant,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionAnswer(String question, String answer, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFF42464D),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

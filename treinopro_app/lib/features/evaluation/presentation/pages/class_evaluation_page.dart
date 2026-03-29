import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../data/services/evaluation_api_service.dart';
import '../../../classes/presentation/widgets/report_problem_modal.dart';

class ClassEvaluationPage extends StatefulWidget {
  final String studentName;
  final String classId;
  final int xpEarned;
  final double amountEarned;

  const ClassEvaluationPage({
    super.key,
    required this.studentName,
    required this.classId,
    this.xpEarned = 10,
    this.amountEarned = 40.0,
  });

  @override
  State<ClassEvaluationPage> createState() => _ClassEvaluationPageState();
}

class _ClassEvaluationPageState extends State<ClassEvaluationPage> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;
  bool _hasEvaluated = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _onStarTapped(int rating) {
    print('⭐ [STUDENT_EVAL] Estrela clicada: $rating');
    setState(() {
      _selectedRating = rating;
    });
    print('⭐ [STUDENT_EVAL] _selectedRating atualizado para: $_selectedRating');
  }

  void _onSendEvaluation() async {
    // ✅ Validação extra: garantir que rating está entre 1 e 5
    if (_selectedRating == 0 || _selectedRating < 1 || _selectedRating > 5) {
      print('⚠️ [STUDENT_EVAL] Rating inválido: $_selectedRating');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione uma avaliação'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    if (_hasEvaluated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você já avaliou este aluno'),
          backgroundColor: AppColors.primaryOrange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final evaluationService = sl<EvaluationApiService>();
      
      // ✅ Debug: Verificar valor antes de enviar
      print('⭐ [STUDENT_EVAL] Enviando avaliação - rating: $_selectedRating');
      
      await evaluationService.createStudentRating(
        classId: widget.classId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
        // Para simplificar, usamos a mesma nota para todos os critérios
        studentEngagement: _selectedRating,
        studentEffort: _selectedRating,
        studentProgress: _selectedRating,
      );
      
      print('✅ [STUDENT_EVAL] Avaliação enviada com sucesso - rating: $_selectedRating');

      // Estado será atualizado automaticamente via WebSocket

      setState(() {
        _hasEvaluated = true;
        _isLoading = false;
      });

      _showEvaluationSentModal();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar avaliação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEvaluationSentModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de check
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 16),

                // Título
                const Text(
                  'Avaliação enviada!',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Texto descritivo
                const Text(
                  'Foi creditado o seu pagamento para sua conta do TreinoPro, verifique seu saldo.',
                  style: TextStyle(
                    fontFamily: 'Fira Sans',
                    fontSize: 16,
                    color: Color(0xFF42464D),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Botão Fechar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fecha o modal
                      Navigator.of(context).pop(); // Volta para ClassesPage na pilha
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Fechar',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onReportProblem() {
    showDialog(
      context: context,
      builder: (context) => const ReportProblemModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFDFE),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Conteúdo rolável (evita overflow em telas menores)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildClassCompletedCard(),
                      const SizedBox(height: 16),
                      _buildEvaluationCard(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Botões fixos ao rodapé
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // Voltar pela pilha de navegação
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.chevron_left,
            size: 24,
            color: Color(0xFF2D3748),
          ),
        ),
        Expanded(
          child: const Text(
            'Avalie o aluno',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        const SizedBox(width: 24), // Para balancear o espaço
      ],
    );
  }

  Widget _buildClassCompletedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Ícone e título
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Aula concluída',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Texto descritivo
          const Text(
            'Meus parabéns, você realizou sua primeira aula de treino pelo app',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFFF9F9F9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          // XP e valor ganho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                '+ ${widget.xpEarned} xp',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                ),
              ),
              Text(
                'R\$ ${widget.amountEarned.toStringAsFixed(2).replaceAll('.', ',')}',
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF9F9F9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF42464D), width: 0.24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Título da avaliação
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(14.5),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Avalie seu Aluno',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Pergunta
          Text(
            'Como foi sua experiência com ${widget.studentName}?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 16,
              color: Color(0xFF2D3748),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Sistema de estrelas
          _buildStarRating(),
          const SizedBox(height: 24),

          // Campo de comentário
          _buildCommentField(),
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print('⭐ [STUDENT_EVAL] GestureDetector onTap - starIndex: $starIndex');
                _onStarTapped(starIndex);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.star,
                  size: 48,
                  color: starIndex <= _selectedRating
                      ? AppColors.primaryOrange
                      : const Color(0xFFE0E0E0),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ruim',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),
            Text(
              'Excelente',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF2D3748),
                height: 1.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Comentário (opcional)',
              style: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 16,
                color: Color(0xFF42464D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF42464D), width: 1),
          ),
          child: TextField(
            controller: _commentController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Conte como foi sua experiência...',
              hintStyle: TextStyle(
                fontFamily: 'Fira Sans',
                fontSize: 12,
                color: Color(0xFF42464D),
              ),
              border: InputBorder.none,
            ),
            style: const TextStyle(
              fontFamily: 'Fira Sans',
              fontSize: 14,
              color: Color(0xFF42464D),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Botão Enviar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _onSendEvaluation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enviar',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Botão Reportar problema
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _onReportProblem,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              side: const BorderSide(color: AppColors.primaryOrange, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reportar problema',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOrange,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

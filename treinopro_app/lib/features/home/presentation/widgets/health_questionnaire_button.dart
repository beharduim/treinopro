import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/health_questionnaire/presentation/presentation.dart';
import '../../../../features/health_questionnaire/domain/domain.dart';
import 'create_proposal_button.dart';

/// Widget que alterna entre o botão do questionário de saúde e "Criar proposta"
class HealthQuestionnaireButton extends StatefulWidget {
  final VoidCallback? onTap;

  const HealthQuestionnaireButton({
    super.key,
    this.onTap,
  });

  @override
  State<HealthQuestionnaireButton> createState() => _HealthQuestionnaireButtonState();
}

class _HealthQuestionnaireButtonState extends State<HealthQuestionnaireButton> {
  bool _isQuestionnaireCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkQuestionnaireStatus();
  }

  Future<void> _checkQuestionnaireStatus() async {
    try {
      final repository = GetIt.instance<HealthQuestionnaireRepository>();
      final isCompleted = await repository.isQuestionnaireCompleted();
      
      if (mounted) {
        setState(() {
          _isQuestionnaireCompleted = isCompleted;
        });
      }
    } catch (e) {
      // Em caso de erro, assume que não foi completado
      if (mounted) {
        setState(() {
          _isQuestionnaireCompleted = false;
        });
      }
    }
  }

  void _openQuestionnaire() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => HealthQuestionnaireBloc(
            getQuestionnaire: GetIt.instance(),
            saveQuestionnaire: GetIt.instance(),
          ),
          child: const HealthQuestionnairePage(),
        ),
      ),
    ).then((_) {
      // Recarregar status após retornar do questionário
      _checkQuestionnaireStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isQuestionnaireCompleted) {
      // Botão "Criar proposta" quando o questionário foi completado
      return CreateProposalButton(
        onTap: widget.onTap,
      );
    }

    // Botão "Questionário de saúde" quando ainda não foi completado
    return Container(
      width: double.infinity,
      height: 56, // Altura fixa 56px
      decoration: BoxDecoration(
        color: AppColors.primaryOrange, // Laranja principal
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? _openQuestionnaire,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // Centraliza texto e ícone
              children: [
                // Texto do botão
                Text(
                  'Questionário de saúde',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // semibold
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(width: 12), // Espaçamento entre texto e ícone
                
                // Ícone de coração à direita
                Icon(
                  Icons.favorite,
                  size: 20, // 18-20px conforme especificado
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  /// Chave de persistência do último status conhecido do questionário.
  static const String _completedPrefsKey = 'health_questionnaire_completed';

  /// Cache em memória para a sessão atual — evita reconstrução piscando o card
  /// toda vez que a home é reconstruída.
  static bool? _sessionCache;

  /// `null` enquanto o status ainda não foi resolvido. Nesse estado mostramos
  /// um placeholder de altura fixa em vez de "chutar" um card e depois trocar.
  bool? _isQuestionnaireCompleted;

  @override
  void initState() {
    super.initState();
    // 1) Se já resolvemos nesta sessão, usa direto (sem flicker).
    if (_sessionCache != null) {
      _isQuestionnaireCompleted = _sessionCache;
    } else {
      // 2) Caso contrário, tenta o último valor persistido para exibir o card
      //    correto imediatamente no cold start.
      _loadCachedStatus();
    }
    // 3) Sempre revalida com a API em segundo plano.
    _checkQuestionnaireStatus();
  }

  Future<void> _loadCachedStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(_completedPrefsKey);
      if (cached != null && mounted && _isQuestionnaireCompleted == null) {
        setState(() {
          _isQuestionnaireCompleted = cached;
        });
      }
    } catch (_) {
      // Cache indisponível — segue aguardando a API.
    }
  }

  Future<void> _checkQuestionnaireStatus() async {
    try {
      final repository = GetIt.instance<HealthQuestionnaireRepository>();
      final isCompleted = await repository.isQuestionnaireCompleted();

      _sessionCache = isCompleted;
      _persistStatus(isCompleted);

      if (mounted) {
        setState(() {
          _isQuestionnaireCompleted = isCompleted;
        });
      }
    } catch (e) {
      // Em caso de erro, mantém o último valor conhecido se houver; só assume
      // "não completado" se ainda não tínhamos nenhuma informação.
      if (mounted && _isQuestionnaireCompleted == null) {
        setState(() {
          _isQuestionnaireCompleted = false;
        });
      }
    }
  }

  Future<void> _persistStatus(bool isCompleted) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_completedPrefsKey, isCompleted);
    } catch (_) {
      // Falha de persistência não é crítica.
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
    // Status ainda desconhecido: assume questionário pendente (nunca fica vazio).
    if (_isQuestionnaireCompleted == null) {
      return _buildHealthQuestionnaireButton();
    }

    if (_isQuestionnaireCompleted!) {
      // Botão "Criar proposta" quando o questionário foi completado
      return CreateProposalButton(
        onTap: widget.onTap,
      );
    }

    return _buildHealthQuestionnaireButton();
  }

  Widget _buildHealthQuestionnaireButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Questionário de saúde',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  Icons.favorite,
                  size: 20,
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

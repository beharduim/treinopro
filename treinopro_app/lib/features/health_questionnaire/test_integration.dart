import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'domain/domain.dart';
import 'presentation/presentation.dart';

/// Página de teste para verificar a integração do questionário de saúde
class HealthQuestionnaireTestPage extends StatefulWidget {
  const HealthQuestionnaireTestPage({super.key});

  @override
  State<HealthQuestionnaireTestPage> createState() => _HealthQuestionnaireTestPageState();
}

class _HealthQuestionnaireTestPageState extends State<HealthQuestionnaireTestPage> {
  bool _isQuestionnaireCompleted = false;
  HealthQuestionnaire? _questionnaire;

  @override
  void initState() {
    super.initState();
    _checkQuestionnaireStatus();
  }

  Future<void> _checkQuestionnaireStatus() async {
    try {
      final repository = GetIt.instance<HealthQuestionnaireRepository>();
      final isCompleted = await repository.isQuestionnaireCompleted();
      final questionnaire = await repository.getQuestionnaire();
      
      if (mounted) {
        setState(() {
          _isQuestionnaireCompleted = isCompleted;
          _questionnaire = questionnaire;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
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

  void _resetQuestionnaire() async {
    try {
      final repository = GetIt.instance<HealthQuestionnaireRepository>();
      // Limpar dados salvos
      await repository.saveQuestionnaire(const HealthQuestionnaire());
      
      if (mounted) {
        setState(() {
          _isQuestionnaireCompleted = false;
          _questionnaire = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questionário resetado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao resetar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Questionário de saúde'),
        backgroundColor: const Color(0xFFFF8C00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status do questionário
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status do questionário',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completado: ${_isQuestionnaireCompleted ? "Sim" : "Não"}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dados salvos
            if (_questionnaire != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados salvos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Condição médica: ${_questionnaire!.medicalCondition ?? "Não informado"}'),
                      Text('Medicamentos: ${_questionnaire!.regularMedication ?? "Não informado"}'),
                      Text('Lesões: ${_questionnaire!.chronicInjury ?? "Não informado"}'),
                      Text('Objetivo: ${_questionnaire!.trainingGoal ?? "Não informado"}'),
                      Text('Restrições: ${_questionnaire!.dietaryRestrictions ?? "Não informado"}'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Botões de ação
            SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _openQuestionnaire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Abrir questionário de saúde',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton(
                    onPressed: _resetQuestionnaire,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Resetar questionário',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton(
                    onPressed: _checkQuestionnaireStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text(
                      'Atualizar status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Informações de teste
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Como testar:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Clique em "Abrir questionário de saúde"\n'
                      '2. Preencha todas as etapas\n'
                      '3. Volte e verifique o status\n'
                      '4. Use "Resetar" para testar novamente',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

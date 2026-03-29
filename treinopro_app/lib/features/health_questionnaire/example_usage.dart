import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'presentation/presentation.dart';

/// Exemplo de como integrar o questionário de saúde no projeto
/// 
/// 1. Primeiro, configure as dependências no service locator:
/// 
/// ```dart
/// // No arquivo service_locator.dart
/// void setupHealthQuestionnaire() {
///   // Repositório
///   GetIt.instance.registerLazySingleton<HealthQuestionnaireRepository>(
///     () => HealthQuestionnaireRepositoryImpl(),
///   );
///   
///   // Casos de uso
///   GetIt.instance.registerLazySingleton(
///     () => GetHealthQuestionnaire(GetIt.instance()),
///   );
///   GetIt.instance.registerLazySingleton(
///     () => SaveHealthQuestionnaire(GetIt.instance()),
///   );
/// }
/// ```
/// 
/// 2. Use o questionário em qualquer tela:
/// 
/// ```dart
/// // Navegar para o questionário
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (context) => BlocProvider(
///       create: (context) => HealthQuestionnaireBloc(
///         getQuestionnaire: GetIt.instance(),
///         saveQuestionnaire: GetIt.instance(),
///       ),
///       child: const HealthQuestionnairePage(),
///     ),
///   ),
/// );
/// ```
/// 
/// 3. Ou crie um botão que abre o questionário:
/// 
/// ```dart
/// ElevatedButton(
///   onPressed: () {
///     Navigator.of(context).push(
///       MaterialPageRoute(
///         builder: (context) => BlocProvider(
///           create: (context) => HealthQuestionnaireBloc(
///             getQuestionnaire: GetIt.instance(),
///             saveQuestionnaire: GetIt.instance(),
///           ),
///           child: const HealthQuestionnairePage(),
///         ),
///       ),
///     );
///   },
///   child: const Text('Questionário de Saúde'),
/// ),
/// ```
/// 
/// 4. Para verificar se o questionário foi completado:
/// 
/// ```dart
/// final repository = GetIt.instance<HealthQuestionnaireRepository>();
/// final isCompleted = await repository.isQuestionnaireCompleted();
/// 
/// if (isCompleted) {
///   // Usuário já completou o questionário
///   print('Questionário já foi completado');
/// } else {
///   // Usuário ainda não completou
///   print('Questionário não foi completado');
/// }
/// ```
/// 
/// 5. Para recuperar as respostas:
/// 
/// ```dart
/// final repository = GetIt.instance<HealthQuestionnaireRepository>();
/// final questionnaire = await repository.getQuestionnaire();
/// 
/// if (questionnaire != null) {
///   print('Condição médica: ${questionnaire.medicalCondition}');
///   print('Medicamentos: ${questionnaire.regularMedication}');
///   print('Lesões: ${questionnaire.chronicInjury}');
///   print('Objetivo: ${questionnaire.trainingGoal}');
///   print('Restrições: ${questionnaire.dietaryRestrictions}');
/// }
/// ```

class HealthQuestionnaireExample extends StatelessWidget {
  const HealthQuestionnaireExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo - Questionário de Saúde'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Clique no botão abaixo para abrir o questionário de saúde',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
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
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text(
                'Abrir questionário de saúde',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

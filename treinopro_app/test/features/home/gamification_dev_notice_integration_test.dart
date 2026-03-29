import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/gamification/presentation/services/gamification_dev_notice_coordinator.dart';
import 'package:treinopro_app/features/gamification/presentation/widgets/gamification_dev_notice_modal.dart';

/// Simula um widget de home (aluno ou personal) que chama o coordinator
/// via addPostFrameCallback, exatamente como as homes reais fazem.
class _FakeHomePage extends StatefulWidget {
  final GamificationDevNoticeCoordinator coordinator;
  const _FakeHomePage({required this.coordinator});

  @override
  State<_FakeHomePage> createState() => _FakeHomePageState();
}

class _FakeHomePageState extends State<_FakeHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.coordinator.maybeShow(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Home'));
  }
}

void main() {
  group('GamificationDevNoticeModal — integração com home', () {
    late GamificationDevNoticeCoordinator coordinator;

    setUp(() {
      coordinator = GamificationDevNoticeCoordinator();
    });

    testWidgets('T1/T2 — modal exibido ao entrar na home', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: _FakeHomePage(coordinator: coordinator)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsOneWidget);
      expect(find.text(GamificationDevNoticeModal.title), findsOneWidget);
      expect(find.text(GamificationDevNoticeModal.body), findsOneWidget);
      expect(find.text(GamificationDevNoticeModal.cta), findsOneWidget);
    });

    testWidgets('T3 — modal não reaparece em rebuild simples da home', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: _FakeHomePage(coordinator: coordinator)),
      );
      await tester.pumpAndSettle();

      // Fechar modal
      await tester.tap(find.text(GamificationDevNoticeModal.cta));
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsNothing);

      // Rebuild da home (simula setState ou aba alternada)
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsNothing);
    });

    testWidgets(
      'T4 — modal não duplica se segunda home chama coordinator na mesma sessão',
      (tester) async {
        // Primeira home entra e exibe o modal
        await tester.pumpWidget(
          MaterialApp(home: _FakeHomePage(coordinator: coordinator)),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GamificationDevNoticeModal), findsOneWidget);

        // Fechar modal
        await tester.tap(find.text(GamificationDevNoticeModal.cta));
        await tester.pumpAndSettle();

        // "Navegar" para outra home que usa o mesmo coordinator singleton
        await tester.pumpWidget(
          MaterialApp(home: _FakeHomePage(coordinator: coordinator)),
        );
        await tester.pumpAndSettle();

        // Não deve aparecer novamente
        expect(find.byType(GamificationDevNoticeModal), findsNothing);
      },
    );

    testWidgets('T6 — context desmontado não causa crash', (tester) async {
      // Monta a página mas desmonta imediatamente antes do postFrameCallback
      await tester.pumpWidget(
        MaterialApp(home: _FakeHomePage(coordinator: coordinator)),
      );
      // Substitui a árvore antes do primeiro frame ser completamente resolvido
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      // Sem crash — o teste passa se nenhuma exceção for lançada
    });
  });
}

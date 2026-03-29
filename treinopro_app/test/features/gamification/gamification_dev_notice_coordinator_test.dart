import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/gamification/presentation/services/gamification_dev_notice_coordinator.dart';
import 'package:treinopro_app/features/gamification/presentation/widgets/gamification_dev_notice_modal.dart';

void main() {
  group('GamificationDevNoticeCoordinator', () {
    late GamificationDevNoticeCoordinator coordinator;

    setUp(() {
      coordinator = GamificationDevNoticeCoordinator();
    });

    test('hasShownThisSession starts as false', () {
      expect(coordinator.hasShownThisSession, isFalse);
    });

    testWidgets('maybeShow exibe modal na primeira chamada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => coordinator.maybeShow(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsOneWidget);
      expect(find.text(GamificationDevNoticeModal.title), findsOneWidget);
      expect(find.text(GamificationDevNoticeModal.cta), findsOneWidget);
    });

    testWidgets(
      'maybeShow NÃO exibe modal na segunda chamada da mesma sessão',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    coordinator.maybeShow(context);
                    coordinator.maybeShow(context); // segunda chamada
                  },
                  child: const Text('show'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('show'));
        await tester.pumpAndSettle();

        // Deve haver apenas um modal, não dois
        expect(find.byType(GamificationDevNoticeModal), findsOneWidget);
      },
    );

    testWidgets('hasShownThisSession é true após maybeShow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => coordinator.maybeShow(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      );

      expect(coordinator.hasShownThisSession, isFalse);

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(coordinator.hasShownThisSession, isTrue);
    });

    test('resetForTesting redefine estado de sessão', () {
      coordinator.maybeShow; // não chama, só referencia — estado = false
      coordinator.resetForTesting();
      expect(coordinator.hasShownThisSession, isFalse);
    });

    testWidgets('botão Entendi fecha o modal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => coordinator.maybeShow(context),
                child: const Text('show'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsOneWidget);

      await tester.tap(find.text(GamificationDevNoticeModal.cta));
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDevNoticeModal), findsNothing);
    });
  });
}

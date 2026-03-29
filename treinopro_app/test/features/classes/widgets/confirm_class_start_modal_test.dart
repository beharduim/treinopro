import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/classes/presentation/widgets/confirm_class_start_modal.dart';
import 'package:treinopro_app/features/classes/data/models/class_response_dto.dart';
import 'package:treinopro_app/features/classes/data/models/class_timeline_dto.dart';

ClassResponseDto _buildClass() => ClassResponseDto(
      id: 'cls-1',
      proposalId: 'p-1',
      studentId: 's-1',
      personalId: 'pt-1',
      location: 'Academia',
      date: DateTime.now(),
      time: '10:00',
      duration: 60,
      status: ClassStatus.PENDING_CONFIRMATION,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

ClassTimelineDto _buildTimeline() => ClassTimelineDto(
      matchTime: DateTime.now(),
      currentTime: DateTime.now(),
      classTime: DateTime.now(),
      canCancel: false,
      canStart: false,
      canReportNoShow: false,
      canConfirmStart: true,
      canReportPersonalNoShow: false,
      canComplete: false,
    );

void main() {
  group('ConfirmClassStartModal', () {
    testWidgets('exibe erro quando código tem menos de 4 dígitos', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ConfirmClassStartModal(
          classData: _buildClass(),
          timeline: _buildTimeline(),
        ),
      ));
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(find.text('Digite o código de 4 dígitos'), findsOneWidget);
    });

    testWidgets('chama onConfirm com código válido de 4 dígitos', (tester) async {
      String? capturedCode;
      await tester.pumpWidget(MaterialApp(
        home: ConfirmClassStartModal(
          classData: _buildClass(),
          timeline: _buildTimeline(),
          onConfirm: (code) => capturedCode = code,
        ),
      ));
      await tester.enterText(find.byType(TextField), '1234');
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(capturedCode, '1234');
    });

    testWidgets('exibe aviso de geolocalização para o aluno', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ConfirmClassStartModal(
          classData: _buildClass(),
          timeline: _buildTimeline(),
        ),
      ));
      await tester.pump();
      expect(
        find.text(
            'Sua localização será registrada uma única vez ao confirmar o início da aula.'),
        findsOneWidget,
      );
    });
  });
}

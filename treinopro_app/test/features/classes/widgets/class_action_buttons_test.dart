import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:treinopro_app/features/classes/presentation/widgets/class_action_buttons.dart';
import 'package:treinopro_app/features/classes/data/models/class_response_dto.dart';
import 'package:treinopro_app/features/classes/data/models/class_timeline_dto.dart';

ClassResponseDto _buildActiveClass() => ClassResponseDto(
      id: 'cls-1',
      proposalId: 'p-1',
      studentId: 's-1',
      personalId: 'pt-1',
      location: 'Academia',
      date: DateTime.now(),
      time: '10:00',
      duration: 60,
      status: ClassStatus.ACTIVE,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

ClassTimelineDto _buildTimeline({required bool canComplete}) => ClassTimelineDto(
      matchTime: DateTime.now(),
      currentTime: DateTime.now(),
      classTime: DateTime.now(),
      canCancel: false,
      canStart: false,
      canReportNoShow: false,
      canConfirmStart: false,
      canReportPersonalNoShow: false,
      canComplete: canComplete,
    );

void main() {
  group('ClassActionButtons - botão Finalizar aula', () {
    testWidgets('está desabilitado quando canComplete=false (< 45min)', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ClassActionButtons(
            classData: _buildActiveClass(),
            timeline: _buildTimeline(canComplete: false),
            onCompleteClass: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.text('Finalizar aula'));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('está habilitado quando canComplete=true (>= 45min)', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ClassActionButtons(
            classData: _buildActiveClass(),
            timeline: _buildTimeline(canComplete: true),
            onCompleteClass: () => tapped = true,
          ),
        ),
      ));
      await tester.tap(find.text('Finalizar aula'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

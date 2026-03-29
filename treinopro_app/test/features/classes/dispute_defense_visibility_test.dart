// ignore_for_file: depend_on_referenced_packages

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:treinopro_app/features/classes/data/models/class_response_dto.dart';
import 'package:treinopro_app/features/classes/data/services/student_photo_cache_service.dart';
import 'package:treinopro_app/features/classes/presentation/bloc/classes_bloc.dart';
import 'package:treinopro_app/features/classes/presentation/pages/classes_page.dart';
import 'package:treinopro_app/features/classes/presentation/pages/student_classes_page.dart';
import 'package:treinopro_app/features/auth/domain/usecases/upload_usecase.dart';
import 'package:treinopro_app/core/di/dependency_injection.dart';

class MockClassesBloc extends MockBloc<ClassesEvent, ClassesState>
    implements ClassesBloc {}

class FakeClassesState extends Fake implements ClassesState {}

class FakeClassesEvent extends Fake implements ClassesEvent {}

class MockUploadUseCase extends Mock implements UploadUseCase {}

class MockStudentPhotoCacheService extends Mock
    implements StudentPhotoCacheService {}

ClassResponseDto _buildClass({
  required String id,
  required String location,
  required DateTime date,
  required String time,
  required ClassStatus status,
  String? noShowReportedBy,
  DateTime? noShowReportedAt,
  DateTime? endTime,
  double? studentRating,
}) => ClassResponseDto(
  id: id,
  proposalId: 'p-$id',
  studentId: 's-1',
  personalId: 'pt-1',
  location: location,
  date: date,
  time: time,
  duration: 60,
  status: status,
  noShowReportedBy: noShowReportedBy,
  noShowReportedAt: noShowReportedAt,
  endTime: endTime,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  studentFirstName: 'Aluno',
  studentLastName: 'Teste',
  personalFirstName: 'Personal',
  personalLastName: 'Teste',
  studentRating: studentRating,
);

// Helper atualizado para aceitar status
ClassResponseDto _buildDispute({
  required String? noShowReportedBy,
  ClassStatus status = ClassStatus.NO_SHOW_DISPUTE,
}) => _buildClass(
  id: 'cls-1',
  location: 'Academia Disputa',
  date: DateTime.now(),
  time: '10:00',
  status: status,
  noShowReportedBy: noShowReportedBy,
  noShowReportedAt: DateTime.now(),
);

ClassResponseDto _buildCompletedClass({
  required DateTime completedAt,
  DateTime? classDate,
  DateTime? endTime,
  String? time,
}) => _buildClass(
  id: 'cls-completed',
  location: 'Academia Finalizada',
  date: classDate ?? completedAt.subtract(const Duration(hours: 1)),
  time: time ?? '10:00',
  status: ClassStatus.COMPLETED,
  endTime: endTime ?? completedAt,
  studentRating: 5,
);

void main() {
  setUpAll(() {
    registerFallbackValue(FakeClassesState());
    registerFallbackValue(FakeClassesEvent());
  });

  late MockClassesBloc mockClassesBloc;
  late MockStudentPhotoCacheService mockStudentPhotoCacheService;

  setUp(() {
    mockClassesBloc = MockClassesBloc();
    mockStudentPhotoCacheService = MockStudentPhotoCacheService();
    when(() => mockClassesBloc.isClosed).thenReturn(false);
    when(
      () => mockStudentPhotoCacheService.getStudentPhoto(any()),
    ).thenAnswer((_) async => null);
    if (!sl.isRegistered<UploadUseCase>()) {
      sl.registerFactory<UploadUseCase>(() => MockUploadUseCase());
    }
    if (!sl.isRegistered<StudentPhotoCacheService>()) {
      sl.registerSingleton<StudentPhotoCacheService>(
        mockStudentPhotoCacheService,
      );
    }
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget createWidgetUnderTest(Widget child) {
    return MaterialApp(
      home: BlocProvider<ClassesBloc>.value(
        value: mockClassesBloc,
        child: Scaffold(body: child),
      ),
    );
  }

  group('Dispute Defense Visibility & Status Messages', () {
    group('Personal View (ClassesPage)', () {
      testWidgets(
        'default filter should show only today classes on personal view',
        (WidgetTester tester) async {
          final now = DateTime.now();
          final todayClass = _buildClass(
            id: 'pt-today',
            location: 'Academia Hoje Personal',
            date: now,
            time: '10:00',
            status: ClassStatus.SCHEDULED,
          );
          final tomorrowClass = _buildClass(
            id: 'pt-tomorrow',
            location: 'Academia Amanhã Personal',
            date: now.add(const Duration(days: 1)),
            time: '10:00',
            status: ClassStatus.SCHEDULED,
          );
          final initialState = ClassesLoaded(
            classes: [todayClass, tomorrowClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(createWidgetUnderTest(const ClassesPage()));
          await tester.pumpAndSettle();

          expect(find.text('Academia Hoje Personal'), findsOneWidget);
          expect(find.text('Academia Amanhã Personal'), findsNothing);
        },
      );

      testWidgets(
        'NO_SHOW_DISPUTE: should show defense button when personal is reported',
        (WidgetTester tester) async {
          final disputeClass = _buildDispute(noShowReportedBy: 'student');
          final initialState = ClassesLoaded(
            classes: [disputeClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(createWidgetUnderTest(const ClassesPage()));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.gavel), findsOneWidget);
          expect(
            find.textContaining('O aluno reportou sua ausência'),
            findsOneWidget,
          );
        },
      );

      testWidgets('CUSTODY: should show "Em análise" and NO defense button', (
        WidgetTester tester,
      ) async {
        final disputeClass = _buildDispute(
          noShowReportedBy: 'student',
          status: ClassStatus.CUSTODY,
        );
        final initialState = ClassesLoaded(
          classes: [disputeClass],
          timelines: const {},
          timers: const {},
        );

        when(
          () => mockClassesBloc.stream,
        ).thenAnswer((_) => Stream.value(initialState));
        when(() => mockClassesBloc.state).thenReturn(initialState);

        await tester.pumpWidget(createWidgetUnderTest(const ClassesPage()));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.gavel), findsNothing);
        expect(
          find.text('Disputa em análise pela equipe. Aguarde a resolução.'),
          findsOneWidget,
        );
      });

      testWidgets(
        'RESOLVED (COMPLETED): should show "Finalizada" and NO defense button',
        (WidgetTester tester) async {
          final disputeClass = _buildDispute(
            noShowReportedBy: 'student',
            status: ClassStatus.COMPLETED,
          );
          final initialState = ClassesLoaded(
            classes: [disputeClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(createWidgetUnderTest(const ClassesPage()));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.gavel), findsNothing);
          expect(
            find.text(
              'Disputa finalizada. Verifique o histórico para mais detalhes.',
            ),
            findsOneWidget,
          );
        },
      );
    });

    group('Student View (StudentClassesPage)', () {
      testWidgets(
        'default filter should show only today classes on student view',
        (WidgetTester tester) async {
          final now = DateTime.now();
          final todayClass = _buildClass(
            id: 'st-today',
            location: 'Academia Hoje Aluno',
            date: now,
            time: '10:00',
            status: ClassStatus.SCHEDULED,
          );
          final tomorrowClass = _buildClass(
            id: 'st-tomorrow',
            location: 'Academia Amanhã Aluno',
            date: now.add(const Duration(days: 1)),
            time: '10:00',
            status: ClassStatus.SCHEDULED,
          );
          final initialState = ClassesLoaded(
            classes: [todayClass, tomorrowClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(
            createWidgetUnderTest(const StudentClassesPage()),
          );
          await tester.pumpAndSettle();

          expect(find.text('Academia Hoje Aluno'), findsOneWidget);
          expect(find.text('Academia Amanhã Aluno'), findsNothing);
        },
      );

      testWidgets(
        'NO_SHOW_DISPUTE: should show defense button when student is reported',
        (WidgetTester tester) async {
          final disputeClass = _buildDispute(noShowReportedBy: 'personal');
          final initialState = ClassesLoaded(
            classes: [disputeClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(
            createWidgetUnderTest(const StudentClassesPage()),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.gavel), findsOneWidget);
          expect(
            find.textContaining('O personal reportou sua ausência'),
            findsOneWidget,
          );
        },
      );

      testWidgets('CUSTODY: should show "Em análise" and NO defense button', (
        WidgetTester tester,
      ) async {
        final disputeClass = _buildDispute(
          noShowReportedBy: 'personal',
          status: ClassStatus.CUSTODY,
        );
        final initialState = ClassesLoaded(
          classes: [disputeClass],
          timelines: const {},
          timers: const {},
        );

        when(
          () => mockClassesBloc.stream,
        ).thenAnswer((_) => Stream.value(initialState));
        when(() => mockClassesBloc.state).thenReturn(initialState);

        await tester.pumpWidget(
          createWidgetUnderTest(const StudentClassesPage()),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.gavel), findsNothing);
        expect(
          find.text('Disputa em análise pela equipe. Aguarde a resolução.'),
          findsOneWidget,
        );
      });

      testWidgets(
        'RESOLVED (CANCELLED): should show "Finalizada" and NO defense button',
        (WidgetTester tester) async {
          final disputeClass = _buildDispute(
            noShowReportedBy: 'personal',
            status: ClassStatus.CANCELLED,
          );
          final initialState = ClassesLoaded(
            classes: [disputeClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(
            createWidgetUnderTest(const StudentClassesPage()),
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.gavel), findsNothing);
          expect(
            find.text(
              'Disputa finalizada. Verifique o histórico para mais detalhes.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets('COMPLETED within 24h: should show rehire button', (
        WidgetTester tester,
      ) async {
        final completedClass = _buildCompletedClass(
          completedAt: DateTime.now().subtract(const Duration(hours: 6)),
        );
        final initialState = ClassesLoaded(
          classes: [completedClass],
          timelines: const {},
          timers: const {},
        );

        when(
          () => mockClassesBloc.stream,
        ).thenAnswer((_) => Stream.value(initialState));
        when(() => mockClassesBloc.state).thenReturn(initialState);

        await tester.pumpWidget(
          createWidgetUnderTest(const StudentClassesPage()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Recontratar personal trainer'), findsOneWidget);
      });

      testWidgets(
        'COMPLETED after 24h: should hide rehire button and show deadline message',
        (WidgetTester tester) async {
          final completedClass = _buildCompletedClass(
            completedAt: DateTime.now().subtract(const Duration(days: 2)),
            classDate: DateTime.now(),
          );
          final initialState = ClassesLoaded(
            classes: [completedClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(
            createWidgetUnderTest(const StudentClassesPage()),
          );
          await tester.pumpAndSettle();

          expect(find.text('Recontratar personal trainer'), findsNothing);
          expect(
            find.text(
              'Prazo de recontratação encerrado. Essa opção fica disponível por até 24h após a aula.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'COMPLETED within 24h without endTime: should show rehire button using class date fallback',
        (WidgetTester tester) async {
          final now = DateTime.now();
          final fallbackCompletedClass = _buildClass(
            id: 'cls-completed-fallback',
            location: 'Academia Fallback',
            date: now,
            time:
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
            status: ClassStatus.COMPLETED,
            endTime: null,
            studentRating: 5,
          );
          final initialState = ClassesLoaded(
            classes: [fallbackCompletedClass],
            timelines: const {},
            timers: const {},
          );

          when(
            () => mockClassesBloc.stream,
          ).thenAnswer((_) => Stream.value(initialState));
          when(() => mockClassesBloc.state).thenReturn(initialState);

          await tester.pumpWidget(
            createWidgetUnderTest(const StudentClassesPage()),
          );
          await tester.pumpAndSettle();

          expect(find.text('Recontratar personal trainer'), findsOneWidget);
        },
      );
    });
  });
}

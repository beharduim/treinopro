import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fake_async/fake_async.dart';
import 'package:treinopro_app/core/di/dependency_injection.dart';
import 'package:treinopro_app/core/services/class_presence_snapshot_service.dart';
import 'package:treinopro_app/features/classes/data/services/classes_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mocks
class MockClassesApiService extends Mock implements ClassesApiService {}

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

void main() {
  late ClassPresenceSnapshotService service;
  late MockClassesApiService mockApi;
  late MockGeolocatorPlatform mockGeolocator;

  // Mock Position para os testes
  final mockPosition = Position(
    latitude: -23.55052,
    longitude: -46.633308,
    timestamp: DateTime.now(),
    accuracy: 15.0,
    altitude: 500.0,
    altitudeAccuracy: 10.0,
    heading: 0.0,
    headingAccuracy: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ClassPresenceSnapshotService.resetForTesting();
    mockApi = MockClassesApiService();
    mockGeolocator = MockGeolocatorPlatform();

    // Injetar dependências mockadas
    sl.registerSingleton<ClassesApiService>(mockApi);
    GeolocatorPlatform.instance = mockGeolocator;

    // Configurar comportamentos padrão dos mocks
    when(
      () => mockGeolocator.isLocationServiceEnabled(),
    ).thenAnswer((_) async => true);
    when(
      () => mockGeolocator.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.always);
    when(
      () => mockGeolocator.getCurrentPosition(
        locationSettings: any(named: 'locationSettings'),
      ),
    ).thenAnswer((_) async => mockPosition);
    when(
      () => mockApi.createPresenceSnapshot(
        classId: any(named: 'classId'),
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        accuracyMeters: any(named: 'accuracyMeters'),
        capturedAt: any(named: 'capturedAt'),
        captureSource: any(named: 'captureSource'),
        appState: any(named: 'appState'),
      ),
    ).thenAnswer((_) async => <String, dynamic>{'success': true});

    // Criar uma nova instância do serviço para cada teste para isolamento
    service = ClassPresenceSnapshotService.instance;
  });

  tearDown(() async {
    ClassPresenceSnapshotService.resetForTesting();
    // Limpar o service locator após cada teste
    await sl.reset();
  });

  group('ClassPresenceSnapshotService Tests', () {
    test(
      'should schedule snapshot and capture on T0 successfully',
      () => fakeAsync((async) {
        // ARRANGE
        final t0 = DateTime.now().add(const Duration(minutes: 10));
        service.scheduleSnapshot(
          classId: 'class-1',
          userId: 'user-1',
          role: 'student',
          scheduledAt: t0,
        );

        // ACT: Avançar o tempo até T0
        async.elapse(const Duration(minutes: 10));

        // ASSERT: Verificar se a API foi chamada
        verify(
          () => mockApi.createPresenceSnapshot(
            classId: 'class-1',
            latitude: mockPosition.latitude,
            longitude: mockPosition.longitude,
            captureSource: 'foreground',
            appState: 'foreground',
            accuracyMeters: mockPosition.accuracy,
            capturedAt: any(named: 'capturedAt'),
          ),
        ).called(1);
      }),
    );

    test('should attempt to capture immediately if T0 is in the past', () async {
      // ARRANGE
      final t0 = DateTime.now().subtract(const Duration(minutes: 5));
      service.scheduleSnapshot(
        classId: 'class-past',
        userId: 'user-1',
        role: 'student',
        scheduledAt: t0,
      );

      // ACT: A chamada deve ser quase imediata, dar um pequeno delay para garantir
      await Future.delayed(const Duration(milliseconds: 50));

      // ASSERT
      verify(
        () => mockApi.createPresenceSnapshot(
          classId: 'class-past',
          captureSource: 'resume',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracyMeters: any(named: 'accuracyMeters'),
          capturedAt: any(named: 'capturedAt'),
          appState: any(named: 'appState'),
        ),
      ).called(1);
    });

    test('should retry capture onAppResumed if it was pending', () async {
      // ARRANGE: Agendar para o passado, mas simular que a captura falhou
      final t0 = DateTime.now().subtract(const Duration(minutes: 10));
      service.scheduleSnapshot(
        classId: 'class-resume',
        userId: 'user-1',
        role: 'personal',
        scheduledAt: t0,
      );
      // Limpar a chamada imediata que acontece no scheduleSnapshot
      clearInteractions(mockApi);

      // ACT: Simular que o app voltou para o foreground
      await service.onAppResumed();
      await Future.delayed(const Duration(milliseconds: 50));

      // ASSERT
      verify(
        () => mockApi.createPresenceSnapshot(
          classId: 'class-resume',
          captureSource: 'resume',
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracyMeters: any(named: 'accuracyMeters'),
          capturedAt: any(named: 'capturedAt'),
          appState: any(named: 'appState'),
        ),
      ).called(1);
    });

    test('should NOT call API if location is not available', () async {
      // ARRANGE
      when(
        () => mockGeolocator.getCurrentPosition(
          locationSettings: any(named: 'locationSettings'),
        ),
      ).thenThrow(Exception('Location unavailable'));

      // ACT
      service.scheduleSnapshot(
        classId: 'class-no-location',
        userId: 'user-1',
        role: 'student',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // ASSERT
      verifyNever(
        () => mockApi.createPresenceSnapshot(
          classId: any(named: 'classId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracyMeters: any(named: 'accuracyMeters'),
          capturedAt: any(named: 'capturedAt'),
          captureSource: any(named: 'captureSource'),
          appState: any(named: 'appState'),
        ),
      );
    });

    test(
      'should be idempotent and schedule only once for the same classId',
      () {
        fakeAsync((async) {
          // ARRANGE
          final t0 = DateTime.now().add(const Duration(minutes: 5));
          service.scheduleSnapshot(
            classId: 'class-idem',
            userId: 'user-1',
            role: 'student',
            scheduledAt: t0,
          );
          // Segunda chamada com o mesmo ID
          service.scheduleSnapshot(
            classId: 'class-idem',
            userId: 'user-1',
            role: 'student',
            scheduledAt: t0,
          );

          // ACT
          async.elapse(const Duration(minutes: 5));

          // ASSERT: API deve ser chamada apenas uma vez
          verify(
            () => mockApi.createPresenceSnapshot(
              classId: 'class-idem',
              latitude: any(named: 'latitude'),
              longitude: any(named: 'longitude'),
              accuracyMeters: any(named: 'accuracyMeters'),
              capturedAt: any(named: 'capturedAt'),
              captureSource: any(named: 'captureSource'),
              appState: any(named: 'appState'),
            ),
          ).called(1);
        });
      },
    );

    test('should keep retrying until snapshot is captured', () async {
      ClassPresenceSnapshotService.overrideRetryIntervalForTesting(
        const Duration(milliseconds: 20),
      );

      var callCount = 0;
      when(
        () => mockApi.createPresenceSnapshot(
          classId: any(named: 'classId'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracyMeters: any(named: 'accuracyMeters'),
          capturedAt: any(named: 'capturedAt'),
          captureSource: any(named: 'captureSource'),
          appState: any(named: 'appState'),
        ),
      ).thenAnswer((_) async {
        callCount += 1;
        if (callCount == 1) {
          throw Exception('Sem internet');
        }
        return <String, dynamic>{'success': true};
      });

      service.scheduleSnapshot(
        classId: 'class-retry',
        userId: 'user-1',
        role: 'student',
        scheduledAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      await Future.delayed(const Duration(milliseconds: 120));

      expect(callCount, greaterThanOrEqualTo(2));
    });
  });
}

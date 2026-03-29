// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:treinopro_app/core/di/dependency_injection.dart';
import 'package:treinopro_app/features/splash/presentation/bloc/splash_bloc.dart';
import 'package:treinopro_app/features/splash/presentation/pages/splash_page.dart';
import 'package:treinopro_app/features/splash/domain/usecases/initialize_app_usecase.dart';

void main() {
  testWidgets('TreinoPro smoke test', (WidgetTester tester) async {
    // Initialize dotenv with mock values
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://api.test.com');

    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    // Register app dependencies (GetIt)
    await setupDependencyInjection(prefs);

    // Replace InitializeAppUseCase with a fast implementation
    if (sl.isRegistered<InitializeAppUseCase>()) {
      sl.unregister<InitializeAppUseCase>();
    }
    sl.registerLazySingleton<InitializeAppUseCase>(() => _FastInit());

    // Build a simplified version of the app for smoke testing
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider(
          create: (context) => sl<SplashBloc>(),
          child: const SplashPage(),
        ),
      ),
    );

    // Wait for initial render
    await tester.pump();
    
    // Fast-forward any remaining timers
    await tester.pump(const Duration(seconds: 5));

    // Verify that the initial page renders
    expect(find.byType(SplashPage), findsOneWidget);
  });
}

class _FastInit implements InitializeAppUseCase {
  @override
  Future<bool> call() async => true;
}

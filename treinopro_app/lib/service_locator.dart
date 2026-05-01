import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'core/services/class_countdown_service.dart';
import 'core/services/api_service.dart';
import 'features/auth/data/datasources/auth_api_datasource.dart';
import 'features/auth/domain/usecases/login_usecases.dart';
import 'features/auth/domain/usecases/register_usecases.dart';
import 'features/auth/domain/usecases/validate_cref_usecase.dart';
import 'features/payouts/data/services/payout_methods_api_service.dart';
import 'features/payouts/presentation/services/stripe_connect_onboarding_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<ClassCountdownService>(
    () => ClassCountdownService(),
  );
  sl.registerLazySingleton<ApiService>(() => ApiService());

  // Payout Services
  sl.registerLazySingleton<PayoutMethodsApiService>(
    () => PayoutMethodsApiService(
      client: http.Client(),
      apiService: sl<ApiService>(),
    ),
  );
  sl.registerLazySingleton<StripeConnectOnboardingService>(
    () => StripeConnectOnboardingService(apiService: sl<ApiService>()),
  );

  // Auth Data Sources
  sl.registerLazySingleton<AuthApiDataSource>(
    () => AuthApiDataSource(sl<ApiService>()),
  );

  // Auth Use Cases
  sl.registerLazySingleton<LoginUserUseCase>(
    () => LoginUserUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<LoginWithGoogleUseCase>(
    () => LoginWithGoogleUseCase(),
  );
  sl.registerLazySingleton<LoginWithFacebookUseCase>(
    () => LoginWithFacebookUseCase(),
  );
  sl.registerLazySingleton<ForgotPasswordUseCase>(
    () => ForgotPasswordUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<RegisterUserUseCase>(
    () => RegisterUserUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<ValidateCrefUseCase>(
    () => ValidateCrefUseCase(sl<AuthApiDataSource>()),
  );
}

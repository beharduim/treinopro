import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../features/splash/domain/usecases/initialize_app_usecase.dart';
import '../../features/splash/presentation/bloc/splash_bloc.dart';
import '../../features/auth/domain/usecases/auth_navigation_usecases.dart';
import '../../features/auth/domain/usecases/login_usecases.dart';
import '../../features/auth/presentation/bloc/login_initial_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/onboarding/onboarding.dart';
import '../../features/home/home.dart';
import '../../features/gamification/data/services/gamification_service.dart';
import '../../features/home/data/services/classes_service.dart';
import '../../features/home/data/services/proposals_service.dart';
import '../../features/home/data/services/classes_scheduled_service.dart';
import '../../features/home/data/services/auth_service.dart';
import '../network/network_info.dart';
import '../services/cache_service.dart';
import '../../features/proposals/data/services/locations_service.dart';
import '../../features/notifications/notifications.dart';
import '../../features/health_questionnaire/data/services/health_questionnaire_api_service.dart';
import '../../features/health_questionnaire/data/repositories/health_questionnaire_repository_impl.dart';
import '../../features/health_questionnaire/domain/repositories/health_questionnaire_repository.dart';
import '../../features/health_questionnaire/domain/usecases/get_health_questionnaire.dart';
import '../../features/health_questionnaire/domain/usecases/save_health_questionnaire.dart';
import '../../features/proposals/proposals.dart';
import '../../features/proposals/data/services/proposals_api_service.dart';
import '../../features/proposals/data/services/personal_proposals_api_service.dart';
import '../../features/classes/data/services/classes_api_service.dart';
import '../../features/classes/data/services/student_photo_cache_service.dart';
import '../../features/classes/presentation/bloc/classes_bloc.dart';
import '../../features/classes/presentation/bloc/classes_history_bloc.dart';
import '../../features/home/data/services/personal_financial_api_service.dart';
import '../../features/profile/data/services/profile_api_service.dart';
import '../../features/profile/data/services/profile_stats_service.dart';
import '../../features/profile/data/services/notifications_api_service.dart';
import '../../features/support/data/services/support_api_service.dart';
import '../../features/evaluation/data/services/evaluation_api_service.dart';
import '../../features/proposals/presentation/bloc/proposal_search_bloc.dart';
import '../../features/payment_methods/data/datasources/payment_methods_api_datasource.dart';
import '../../features/payment_methods/data/services/stripe_payment_sheet_service.dart';
import '../../features/payment_methods/data/repositories/payment_methods_repository_impl.dart';
import '../../features/payment_methods/domain/repositories/payment_methods_repository.dart';
import '../../features/payment_methods/presentation/bloc/payment_methods_bloc.dart';
import '../services/class_countdown_service.dart';
import '../services/class_state_service.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/data_refresh_service.dart';
import '../services/websocket_service.dart';
import '../services/realtime_data_service.dart';
import '../services/shader_warmup_service.dart';
import '../services/animation_preloader.dart';
import '../services/profile_image_notification_service.dart';
import '../../features/gamification/data/services/gamification_websocket_service.dart';
import '../../features/gamification/data/services/mission_completion_service.dart';
import '../../features/gamification/data/repositories/gamification_repository_impl.dart';
import '../../features/gamification/domain/repositories/gamification_repository.dart';
import '../../features/gamification/presentation/bloc/gamification_bloc.dart';
import '../../features/gamification/presentation/services/gamification_dev_notice_coordinator.dart';
import '../../features/auth/data/datasources/auth_api_datasource.dart';
import '../../features/auth/domain/usecases/register_usecases.dart';
import '../../features/auth/data/services/guardian_authorization_service.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/domain/usecases/student_registration_usecases.dart';
import '../../features/auth/domain/usecases/personal_registration_usecases.dart';
import '../../features/auth/domain/usecases/validate_cref_usecase.dart';
import '../../features/auth/domain/usecases/send_verification_code_usecase.dart';
import '../../features/auth/domain/usecases/verify_code_usecase.dart';
import '../../features/auth/domain/usecases/validate_email_usecase.dart';
import '../../features/auth/domain/usecases/check_document_usecase.dart';
import '../../features/auth/data/services/upload_service.dart';
import '../../features/auth/domain/usecases/upload_usecase.dart';
import '../../features/chat/data/services/chat_api_service.dart';
import '../../features/payouts/data/services/payout_methods_api_service.dart';
import '../../features/payouts/presentation/services/stripe_connect_onboarding_service.dart';
import '../../features/balance/presentation/bloc/balance_bloc.dart';
import '../../features/users/data/services/users_api_service.dart';

/// Instância global do GetIt para injeção de dependência
final GetIt sl = GetIt.instance;

/// Configura todas as dependências da aplicação
Future<void> setupDependencyInjection(SharedPreferences prefs) async {
  // Splash Use cases
  sl.registerLazySingleton<InitializeAppUseCase>(() => InitializeAppUseCase());

  // Auth Use cases
  sl.registerLazySingleton<NavigateToSignUpUseCase>(
    () => NavigateToSignUpUseCase(),
  );

  sl.registerLazySingleton<NavigateToLoginUseCase>(
    () => NavigateToLoginUseCase(),
  );

  // Core Services
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<LocationService>(() => LocationService.instance);
  sl.registerLazySingleton<ProfileImageNotificationService>(
    () => ProfileImageNotificationService(),
  );
  sl.registerLazySingleton<ShaderWarmupService>(() => ShaderWarmupService());
  sl.registerLazySingleton<AnimationPreloader>(() => AnimationPreloader());

  // Support Feature (registrado logo após ApiService)
  sl.registerLazySingleton<SupportApiService>(
    () => SupportApiService(apiService: sl<ApiService>()),
  );

  // Evaluation Feature
  sl.registerLazySingleton<EvaluationApiService>(
    () => EvaluationApiService(apiService: sl<ApiService>()),
  );

  // Users Feature
  sl.registerLazySingleton<UsersApiService>(
    () => UsersApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );

  // Auth Data Sources
  sl.registerLazySingleton<AuthApiDataSource>(
    () => AuthApiDataSource(sl<ApiService>()),
  );

  // Login Use cases
  sl.registerLazySingleton<LoginUserUseCase>(
    () => LoginUserUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<LoginWithGoogleUseCase>(
    () => LoginWithGoogleUseCase(),
  );

  sl.registerLazySingleton<LoginWithFacebookUseCase>(
    () => LoginWithFacebookUseCase(),
  );

  sl.registerForgotPasswordUseCase(
    () => ForgotPasswordUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<RegisterUserUseCase>(
    () => RegisterUserUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<StudentRegistrationUseCase>(
    () => StudentRegistrationUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<PersonalRegistrationUseCase>(
    () => PersonalRegistrationUseCase(sl<AuthApiDataSource>()),
  );
  sl.registerLazySingleton<ValidateCrefUseCase>(
    () => ValidateCrefUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<SendVerificationCodeUseCase>(
    () => SendVerificationCodeUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<VerifyCodeUseCase>(
    () => VerifyCodeUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<ValidateEmailUseCase>(
    () => ValidateEmailUseCase(sl<AuthApiDataSource>()),
  );

  sl.registerLazySingleton<CheckDocumentUseCase>(
    () => CheckDocumentUseCase(sl<AuthApiDataSource>()),
  );

  // Upload Services
  sl.registerLazySingleton<UploadService>(
    () => UploadService(sl<ApiService>()),
  );

  sl.registerLazySingleton<UploadUseCase>(
    () => UploadUseCase(sl<UploadService>()),
  );

  // Repositories (deve ser registrado antes dos use cases)
  sl.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(),
  );

  // Onboarding Use cases
  sl.registerLazySingleton<CheckOnboardingCompletedUseCase>(
    () => CheckOnboardingCompletedUseCase(sl<OnboardingRepository>()),
  );

  sl.registerLazySingleton<GetOnboardingStateUseCase>(
    () => GetOnboardingStateUseCase(sl<OnboardingRepository>()),
  );

  sl.registerLazySingleton<CompleteOnboardingUseCase>(
    () => CompleteOnboardingUseCase(sl<OnboardingRepository>()),
  );

  // Health Questionnaire Feature
  sl.registerLazySingleton<HealthQuestionnaireApiService>(
    () => HealthQuestionnaireApiService(sl<ApiService>()),
  );

  sl.registerLazySingleton<HealthQuestionnaireRepository>(
    () =>
        HealthQuestionnaireRepositoryImpl(sl<HealthQuestionnaireApiService>()),
  );

  // Health Questionnaire Use Cases
  sl.registerLazySingleton<GetHealthQuestionnaire>(
    () => GetHealthQuestionnaire(sl<HealthQuestionnaireRepository>()),
  );

  sl.registerLazySingleton<SaveHealthQuestionnaire>(
    () => SaveHealthQuestionnaire(sl<HealthQuestionnaireRepository>()),
  );

  // SharedPreferences - inicializado no main.dart
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  }

  // HTTP Client
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(() => http.Client());
  }

  // Notifications Feature (registrado logo após http.Client)
  sl.registerLazySingleton<NotificationsApiService>(
    () => NotificationsApiService(client: sl<http.Client>()),
  );

  // Profile Notifications Service (específico para preferências de perfil)
  sl.registerLazySingleton<ProfileNotificationsApiService>(
    () => ProfileNotificationsApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );

  // Home Services
  if (!sl.isRegistered<GamificationService>()) {
    sl.registerLazySingleton<GamificationService>(
      () => GamificationService(
        client: sl<http.Client>(),
        networkInfo: sl<NetworkInfo>(),
      ),
    );
  }

  if (!sl.isRegistered<ClassesService>()) {
    sl.registerLazySingleton<ClassesService>(
      () => ClassesService(client: sl<http.Client>()),
    );
  }

  if (!sl.isRegistered<LocationsService>()) {
    sl.registerLazySingleton<LocationsService>(
      () => LocationsService(client: sl<http.Client>(),),
    );
  }

  // Network Info
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // Auth Service
  sl.registerLazySingleton<AuthService>(
    () => AuthService(prefs: sl<SharedPreferences>()),
  );

  // Forgot Password Auth Service
  sl.registerLazySingleton<ForgotPasswordAuthService>(
    () => ForgotPasswordAuthService(sl<AuthApiDataSource>()),
  );

  // Guardian Authorization Service
  sl.registerLazySingleton<GuardianAuthorizationService>(
    () => GuardianAuthorizationService(sl<ApiService>().dio),
  );

  // Cache Service
  sl.registerLazySingleton<CacheService>(
    () => CacheService(prefs: sl<SharedPreferences>()),
  );

  // WebSocket Service
  sl.registerLazySingleton<WebSocketService>(() {
    final service = WebSocketService();
    service.initialize(sl<AuthService>());
    return service;
  });

  // Chat Services
  sl.registerLazySingleton<ChatApiService>(
    () => ChatApiService(apiService: sl<ApiService>()),
  );

  // Gamification Services
  sl.registerLazySingleton<GamificationRepository>(
    () => GamificationRepositoryImpl(
      gamificationService: sl<GamificationService>(),
      authService: sl<AuthService>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // ✅ MUDANÇA: GamificationBloc agora é factory (nova instância por contexto)
  sl.registerFactory<GamificationBloc>(
    () =>
        GamificationBloc(gamificationRepository: sl<GamificationRepository>()),
  );

  sl.registerLazySingleton<GamificationWebSocketService>(
    () => GamificationWebSocketService(),
  );

  sl.registerLazySingleton<MissionCompletionService>(
    () => MissionCompletionService(),
  );

  sl.registerLazySingleton<GamificationDevNoticeCoordinator>(
    () => GamificationDevNoticeCoordinator(),
  );

  // Home Feature Services
  sl.registerLazySingleton<ClassesScheduledService>(
    () => ClassesScheduledService(
      client: sl<http.Client>(),
      networkInfo: sl<NetworkInfo>(),
      authService: sl<AuthService>(),
    ),
  );

  // Atualizar ProposalsService para incluir AuthService
  if (sl.isRegistered<ProposalsService>()) {
    sl.unregister<ProposalsService>();
  }
  sl.registerLazySingleton<ProposalsService>(
    () => ProposalsService(
      client: sl<http.Client>(),
      networkInfo: sl<NetworkInfo>(),
      authService: sl<AuthService>(),
    ),
  );

  // Home Feature
  if (!sl.isRegistered<HomeRepository>()) {
    sl.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        gamificationService: sl<GamificationService>(),
        classesService: sl<ClassesService>(),
        proposalsService: sl<ProposalsService>(),
        classesScheduledService: sl<ClassesScheduledService>(),
        authService: sl<AuthService>(),
        prefs: sl<SharedPreferences>(),
        cacheService: sl<CacheService>(),
        usersApiService: sl<UsersApiService>(),
      ),
    );
  }

  sl.registerLazySingleton<GetHomeStateUseCase>(
    () => GetHomeStateUseCase(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<UpdateWeeklyMissionProgressUseCase>(
    () => UpdateWeeklyMissionProgressUseCase(sl<HomeRepository>()),
  );

  sl.registerLazySingleton<CompleteHealthQuestionnaireUseCase>(
    () => CompleteHealthQuestionnaireUseCase(sl<HomeRepository>()),
  );

  // DataRefreshService (mantido para compatibilidade, mas desativado)
  sl.registerLazySingleton<DataRefreshService>(
    () => DataRefreshService(
      homeRepository: sl<HomeRepository>(),
      homeBloc: sl<HomeBloc>(),
      cacheService: sl<CacheService>(),
    ),
  );

  // RealtimeDataService (substitui DataRefreshService)
  sl.registerLazySingleton<RealtimeDataService>(() => RealtimeDataService());

  // Proposals Feature - Registrar após todos os serviços
  sl.registerLazySingleton<StripePaymentSheetService>(
    () => StripePaymentSheetService(),
  );

  sl.registerLazySingleton<ProposalsApiService>(
    () => ProposalsApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
      stripePaymentSheetService: sl<StripePaymentSheetService>(),
    ),
  );

  sl.registerLazySingleton<PersonalProposalsApiService>(
    () => PersonalProposalsApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );

  // Classes Feature
  sl.registerLazySingleton<ClassesApiService>(
    () => ClassesApiService(
      dio: sl<ApiService>().dio,
      apiService: sl<ApiService>(),
    ),
  );

  sl.registerLazySingleton<PersonalFinancialApiService>(
    () => PersonalFinancialApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );

  // Profile Feature
  sl.registerLazySingleton<ProfileApiService>(
    () => ProfileApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
      uploadService: sl<UploadService>(),
    ),
  );

  sl.registerLazySingleton<ProfileStatsService>(
    () => ProfileStatsService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );

  // Payout Methods Feature
  sl.registerLazySingleton<PayoutMethodsApiService>(
    () => PayoutMethodsApiService(
      client: sl<http.Client>(),
      apiService: sl<ApiService>(),
    ),
  );
  sl.registerLazySingleton<StripeConnectOnboardingService>(
    () => StripeConnectOnboardingService(apiService: sl<ApiService>()),
  );

  sl.registerLazySingleton<ProposalsRepository>(
    () => ProposalsRepositoryImpl(
      locationsService: sl<LocationsService>(),
      apiService: sl<ApiService>(),
      proposalsApiService: sl<ProposalsApiService>(),
      profileApiService: sl<ProfileApiService>(),
    ),
  );

  sl.registerLazySingleton<SaveProposal>(
    () => SaveProposal(sl<ProposalsRepository>()),
  );

  sl.registerLazySingleton<GetProposal>(
    () => GetProposal(sl<ProposalsRepository>()),
  );

  sl.registerLazySingleton<SearchLocations>(
    () => SearchLocations(sl<ProposalsRepository>()),
  );

  sl.registerLazySingleton<GetModalities>(
    () => GetModalities(sl<ProposalsRepository>()),
  );

  sl.registerLazySingleton<SubmitProposal>(
    () => SubmitProposal(sl<ProposalsRepository>()),
  );

  sl.registerLazySingleton<CreateProposal>(
    () => CreateProposal(sl<ProposalsRepository>()),
  );

  sl.registerFactory<ProposalsBloc>(
    () => ProposalsBloc(
      saveProposal: sl<SaveProposal>(),
      getProposal: sl<GetProposal>(),
      searchLocations: sl<SearchLocations>(),
      getModalities: sl<GetModalities>(),
      submitProposal: sl<SubmitProposal>(),
      createProposal: sl<CreateProposal>(),
      repository: sl<ProposalsRepository>(),
      paymentMethodsRepository: sl<PaymentMethodsRepository>(),
    ),
  );

  // Classes Feature
  // ✅ MUDANÇA: ClassesBloc agora é factory (nova instância por contexto)
  sl.registerFactory<ClassesBloc>(() => ClassesBloc());

  sl.registerLazySingleton<ClassesHistoryBloc>(
    () => ClassesHistoryBloc(classesApiService: sl<ClassesApiService>()),
  );

  // ✅ MUDANÇA: HomeBloc agora é factory (nova instância por contexto)
  sl.registerFactory<HomeBloc>(
    () => HomeBloc(
      getHomeStateUseCase: sl<GetHomeStateUseCase>(),
      updateWeeklyMissionProgressUseCase:
          sl<UpdateWeeklyMissionProgressUseCase>(),
      completeHealthQuestionnaireUseCase:
          sl<CompleteHealthQuestionnaireUseCase>(),
      homeRepository: sl<HomeRepository>(),
    ),
  );

  // Splash BLoCs
  sl.registerFactory<SplashBloc>(
    () => SplashBloc(initializeAppUseCase: sl<InitializeAppUseCase>()),
  );

  // Auth BLoCs
  sl.registerFactory<LoginInitialBloc>(
    () => LoginInitialBloc(
      navigateToSignUpUseCase: sl<NavigateToSignUpUseCase>(),
      navigateToLoginUseCase: sl<NavigateToLoginUseCase>(),
    ),
  );

  sl.registerFactory<LoginBloc>(
    () => LoginBloc(
      loginUserUseCase: sl<LoginUserUseCase>(),
      loginWithGoogleUseCase: sl<LoginWithGoogleUseCase>(),
      loginWithFacebookUseCase: sl<LoginWithFacebookUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
    ),
  );

  // Onboarding BLoCs
  sl.registerFactory<OnboardingBloc>(
    () => OnboardingBloc(
      getOnboardingStateUseCase: sl<GetOnboardingStateUseCase>(),
      checkOnboardingCompletedUseCase: sl<CheckOnboardingCompletedUseCase>(),
      completeOnboardingUseCase: sl<CompleteOnboardingUseCase>(),
    ),
  );

  // Proposal Search BLoC
  // ✅ MUDANÇA: ProposalSearchBloc agora é factory (nova instância por contexto)
  sl.registerFactory<ProposalSearchBloc>(() => ProposalSearchBloc());

  // Payment Methods Feature
  sl.registerLazySingleton<PaymentMethodsApiDataSource>(
    () => PaymentMethodsApiDataSourceImpl(
      apiService: sl<ApiService>(),
      stripePaymentSheetService: sl<StripePaymentSheetService>(),
    ),
  );

  sl.registerLazySingleton<PaymentMethodsRepository>(
    () => PaymentMethodsRepositoryImpl(
      apiDataSource: sl<PaymentMethodsApiDataSource>(),
    ),
  );

  sl.registerFactory<PaymentMethodsBloc>(
    () => PaymentMethodsBloc(repository: sl<PaymentMethodsRepository>()),
  );

  // Services
  sl.registerLazySingleton<StudentPhotoCacheService>(
    () => StudentPhotoCacheService(usersApiService: sl<UsersApiService>()),
  );
  sl.registerLazySingleton<ClassCountdownService>(
    () => ClassCountdownService(),
  );

  sl.registerLazySingleton<ClassStateService>(() => ClassStateService());

  // Balance Feature
  sl.registerFactory<BalanceBloc>(
    () => BalanceBloc(
      payoutApi: sl<PayoutMethodsApiService>(),
      financialApi: sl<PersonalFinancialApiService>(),
    ),
  );
}

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/home_state.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/home_model.dart';
import '../../../gamification/data/services/gamification_service.dart';
import '../../../gamification/data/models/gamification_dto.dart' show MissionStatus;
import '../services/classes_service.dart';
import '../services/proposals_service.dart';
import '../services/classes_scheduled_service.dart';
import '../services/auth_service.dart';
import '../models/weekly_mission_model.dart';
import '../models/gamification_profile_model.dart';
import '../models/class_response_dto.dart';
import '../models/proposal_response_dto.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/cache_service.dart';
import '../../../gamification/presentation/utils/level_labels.dart';
import '../../../users/data/services/users_api_service.dart';
import '../../../health_questionnaire/data/services/health_questionnaire_api_service.dart';

/// Implementação do repositório da home
class HomeRepositoryImpl implements HomeRepository {
  final GamificationService _gamificationService;
  final ClassesService _classesService;
  final ProposalsService _proposalsService;
  final ClassesScheduledService _classesScheduledService;
  final AuthService _authService;
  final SharedPreferences _prefs;
  final CacheService _cacheService;
  final UsersApiService _usersApiService;
  final HealthQuestionnaireApiService _healthQuestionnaireApiService;

  HomeRepositoryImpl({
    required GamificationService gamificationService,
    required ClassesService classesService,
    required ProposalsService proposalsService,
    required ClassesScheduledService classesScheduledService,
    required AuthService authService,
    required SharedPreferences prefs,
    required CacheService cacheService,
    required UsersApiService usersApiService,
    required HealthQuestionnaireApiService healthQuestionnaireApiService,
  }) : _gamificationService = gamificationService,
       _classesService = classesService,
       _proposalsService = proposalsService,
       _classesScheduledService = classesScheduledService,
       _authService = authService,
       _prefs = prefs,
       _cacheService = cacheService,
       _usersApiService = usersApiService,
       _healthQuestionnaireApiService = healthQuestionnaireApiService;

  @override
  Future<HomeState> getHomeState() async {
    try {
      // Aguardar um pouco para garantir que o AuthService terminou de salvar os dados
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Obter token do SharedPreferences
      final token = _prefs.getString('access_token');
      if (token == null) {
        throw Exception('Token de autenticação não encontrado');
      }
      final userData = await _authService.getMe(token);
      
      // Processar nome do usuário primeiro
      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      final userName = '$firstName $lastName'.trim();
      final userId = userData['id']; // UUID do usuário
      // Normalizar imagem de perfil vinda da API (diferentes chaves possíveis)
      final profileImageUrl = (
        userData['profileImageUrl'] ??
        userData['imageUrl'] ??
        userData['avatarUrl'] ??
        userData['profileImage'] ??
        ''
      ).toString();
      
      print('🔍 [HOME_REPO] Dados do usuário:');
      print('   - firstName: "$firstName"');
      print('   - lastName: "$lastName"');
      print('   - userName: "$userName"');
      print('   - userId: "$userId"');
      print('   - profileImageUrl: "$profileImageUrl"');
      
      // Tentar buscar dados de gamificação com fallback
      GamificationProfileModel gamificationProfile;
      List<WeeklyMissionModel> missions = [];
      
      try {
        final token = await _authService.getValidToken();
        final profileDto = await _gamificationService.getUserProfile(userId, token!);
        gamificationProfile = GamificationProfileModel(
          id: profileDto.id,
          userId: profileDto.userId,
          level: profileDto.level,
          totalXP: profileDto.totalXP,
          currentLevelXP: profileDto.currentLevelXP,
          nextLevelXP: profileDto.xpToNextLevel,
          badges: const [],
          achievements: const [],
          rank: 0,
        );
      } catch (e) {
        gamificationProfile = GamificationProfileModel(
          id: '',
          userId: userData['id'] ?? '',
          level: 1,
          totalXP: 0,
          currentLevelXP: 0,
          nextLevelXP: 100,
          badges: [],
          achievements: [],
          rank: 0,
        );
      }
      
      try {
        final token = await _authService.getValidToken();
        // Buscar ativas e completadas e unir
        final activeDto = await _gamificationService.getUserMissions(userId, token!, status: 'active');
        final completedDto = await _gamificationService.getUserMissions(userId, token, status: 'completed');
        final missionsDto = [...activeDto, ...completedDto];
        // Remover duplicatas por id
        final seen = <String>{};
        final unique = <dynamic>[];
        for (final m in missionsDto) {
          if (!seen.contains(m.id)) {
            seen.add(m.id);
            unique.add(m);
          }
        }
        missions = unique.map((m) => WeeklyMissionModel(
          id: m.id,
          title: m.mission.title,
          description: m.mission.description,
          type: m.mission.type.name,
          isActive: m.status == MissionStatus.active,
          progress: m.progress,
          target: m.totalRequired,
          xpReward: m.mission.xpReward,
          status: m.status.name,
        )).toList();
        
        // Se não há missões, criar missão padrão
        if (missions.isEmpty) {
          missions = [
            WeeklyMissionModel(
              id: 'default_mission',
              title: 'Complete 3 aulas esta semana',
              description: 'Participe de 3 aulas de treino para ganhar XP extra',
              type: 'weekly',
              isActive: true,
              progress: 0,
              target: 3,
              xpReward: 150,
              status: 'active',
            ),
          ];
        }
      } catch (e) {
        // Criar missão padrão quando há erro na API
        missions = [
          WeeklyMissionModel(
            id: 'default_mission',
            title: 'Complete 3 aulas esta semana',
            description: 'Participe de 3 aulas de treino para ganhar XP extra',
            type: 'weekly',
            isActive: true,
            progress: 0,
            target: 3,
            xpReward: 150,
            status: 'active',
          ),
        ];
      }
      
      // Tentar buscar dados de classes com fallback
      Map<String, dynamic> classesStats = {};
      try {
        classesStats = await _classesService.getStats(token);
      } catch (e) {
        classesStats = {
          'completedClasses': 0,
          'upcomingClasses': 0,
        };
      }
      
      // Tentar buscar dados de propostas com fallback
      Map<String, dynamic> proposalsData = {};
      try {
        proposalsData = await _proposalsService.getMyProposals(token);
      } catch (e) {
        proposalsData = {
          'proposals': [],
        };
      }

      // Processar missão semanal
      final weeklyMission = missions.isNotEmpty ? missions.first : null;
      final weeklyMissionProgress = weeklyMission?.progress ?? 0;
      final weeklyMissionTarget = weeklyMission?.target ?? 3;
      final weeklyMissionDescription = weeklyMission?.description ?? '';

      // Processar dados de treinos
      final completedWorkouts = classesStats['completed'] ?? 0;
      final hasWorkouts = (classesStats['scheduled'] ?? 0) > 0;

      // Processar propostas
      final proposals = proposalsData['proposals'] as List<dynamic>? ?? [];

      // SSOT: status real do questionário via API (não inferir por propostas pendentes)
      bool questionnaireCompleted = false;
      try {
        questionnaireCompleted =
            await _healthQuestionnaireApiService.isQuestionnaireCompleted();
        await _prefs.setBool(
          'health_questionnaire_completed',
          questionnaireCompleted,
        );
      } catch (e) {
        print('⚠️ [HOME] Falha ao consultar questionário de saúde: $e');
        questionnaireCompleted =
            _prefs.getBool('health_questionnaire_completed') ?? false;
      }

      final homeModel = HomeModel(
        userName: userName.isNotEmpty ? userName : 'Usuário',
        userId: userId,
        userLevel: LevelLabels.getLabelByUserType(userData['userType']?.toString() ?? 'student', gamificationProfile.level),
        userXp: gamificationProfile.totalXP,
        weeklyMissionProgress: weeklyMissionProgress,
        weeklyMissionTarget: weeklyMissionTarget,
        weeklyMissionDescription: weeklyMissionDescription,
        // true = ainda precisa preencher o questionário
        hasHealthQuestionnaire: !questionnaireCompleted,
        hasWorkouts: hasWorkouts,
        completedWorkouts: completedWorkouts,
        achievements: gamificationProfile.achievements.length,
        profileImageUrl: profileImageUrl.isNotEmpty ? profileImageUrl : null,
      );

      print('✅ DEBUG: HomeModel criado com userName: "${homeModel.userName}"');
      print('🏠 DEBUG: HomeModel completo: ${homeModel.toJson()}');
      
      return homeModel;
    } catch (e) {
      // Fallback para dados locais em caso de erro
      print('❌ DEBUG: Erro ao carregar dados da API: $e');
      print('🔄 DEBUG: Usando dados de fallback...');
      final fallbackState = _getFallbackHomeState();
      print('📦 DEBUG: Fallback state userName: "${fallbackState.userName}"');
      return fallbackState;
    }
  }

  HomeState _getFallbackHomeState() {
    return HomeModel(
      userName: _prefs.getString('user_name') ?? 'Usuário',
      userId: _prefs.getString('user_id'),
      userLevel: _prefs.getString('user_level') ?? '',
      userXp: _prefs.getInt('user_xp') ?? 0,
      weeklyMissionProgress: _prefs.getInt('weekly_mission_progress') ?? 0,
      weeklyMissionTarget: _prefs.getInt('weekly_mission_target') ?? 3,
      weeklyMissionDescription: _prefs.getString('weekly_mission_description') ?? '',
      hasHealthQuestionnaire: !(_prefs.getBool('health_questionnaire_completed') ?? false),
      hasWorkouts: _prefs.getBool('has_workouts') ?? false,
      completedWorkouts: _prefs.getInt('completed_workouts') ?? 0,
      achievements: _prefs.getInt('achievements') ?? 0,
    );
  }

  // Deprecated: nome de nível agora é calculado via LevelLabels por tipo de usuário

  @override
  Future<void> updateWeeklyMissionProgress(int progress) async {
    // Salvar localmente para cache
    await _prefs.setInt('weekly_mission_progress', progress);
    
    // TODO: Implementar atualização via API quando necessário
    // Por enquanto, apenas salva localmente
  }

  @override
  Future<void> completeHealthQuestionnaire() async {
    await _prefs.setBool('health_questionnaire_completed', true);
  }

  @override
  Future<String> getUserName() async {
    return _prefs.getString('user_name') ?? 'Usuário';
  }

  // ===== MÉTODOS PARA CARD DINÂMICO =====

  @override
  Future<List<Map<String, dynamic>>> loadScheduledClasses(String userId) async {
    try {
      print('🔍 DEBUG: Buscando aulas agendadas para userId: $userId');
      final classes = await _classesScheduledService.getScheduledClasses();
      print('📚 DEBUG: Encontradas ${classes.length} aulas agendadas');
      
      for (int i = 0; i < classes.length; i++) {
        final cls = classes[i];
        print('📚 DEBUG: Aula $i - ID: ${cls.id}, Status: ${cls.status.name}, Data: ${cls.date}, Local: ${cls.location}');
      }
      
      final mappedClasses = classes.map((cls) => _mapClassToMap(cls)).toList();
      print('✅ DEBUG: Aulas mapeadas com sucesso: ${mappedClasses.length}');

      // Enriquecimento rápido: garantir foto/rating do personal para o card
      for (final cls in mappedClasses) {
        try {
          final personalId = cls['personalId'] as String?;
          final currentPhoto = (cls['personalProfileImageUrl'] as String?) ?? '';
          final currentRating = cls['personalRating'];
          final needsPhoto = currentPhoto.isEmpty;
          final needsRating = currentRating == null || (currentRating is num && currentRating.toDouble() == 0.0);

          if (personalId != null && (needsPhoto || needsRating)) {
            print('🖼️ [HOME_REPO] Enriquecendo dados do personal $personalId (foto/rating)');
            final info = await _usersApiService.getUserBasicInfo(personalId);
            final apiPhoto = (info['profileImageUrl'] ?? info['imageUrl'] ?? info['avatarUrl'] ?? '').toString();
            final apiRating = double.tryParse((info['rating'] ?? info['averageRating'] ?? info['score'] ?? '').toString());
            if (apiPhoto.isNotEmpty) {
              cls['personalProfileImageUrl'] = apiPhoto;
            }
            if (apiRating != null) {
              cls['personalRating'] = apiRating;
            }
          }
        } catch (e) {
          print('⚠️ [HOME_REPO] Falha no enrichment de foto/rating: $e');
        }
      }
      
      return mappedClasses;
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar aulas agendadas: $e');
      
      // Se não há token, retornar lista vazia
      if (e is UnauthorizedException) {
        print('❌ DEBUG: Usuário não autenticado - não é possível carregar aulas');
        return [];
      }
      
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadPendingProposals(String userId) async {
    try {
      print('🔍 DEBUG: Carregando propostas pendentes para userId: $userId');
      
      // Buscar propostas pendentes via API
      var proposals = await _proposalsService.getPendingProposals(userId);
      
      // ✅ VALIDAÇÃO EXTRA: Garantir que apenas propostas com status 'pending' sejam retornadas
      // Isso evita que propostas matched/completed/cancelled apareçam como pendentes
      proposals = proposals.where((prop) => prop.status.name == 'pending').toList();
      
      print('📊 DEBUG: ${proposals.length} propostas pendentes válidas após filtro');
      
      final mappedProposals = proposals.map((prop) => _mapProposalToMap(prop)).toList();
      
      print('📋 DEBUG: Propostas mapeadas:');
      for (var prop in mappedProposals) {
        print('  - ID: ${prop['id']}, Status: ${prop['status']}, Data: ${prop['date']}, Local: ${prop['location']}');
      }
      
      return mappedProposals;
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar propostas pendentes: $e');
      
      // Se não há token, retornar lista vazia
      if (e is UnauthorizedException) {
        print('❌ DEBUG: Usuário não autenticado - não é possível carregar propostas');
        return [];
      }
      
      return [];
    }
  }


  @override
  Future<Map<String, dynamic>> loadWorkoutCardData(String userId) async {
    try {
      // SEMPRE carregar dados da API para garantir dados atualizados
      // O cache será usado apenas como fallback em caso de erro de rede
      final scheduledClasses = await loadScheduledClasses(userId);
      final pendingProposals = await loadPendingProposals(userId);
      
      // As propostas matched já criam aulas automaticamente
      // Não precisamos buscar propostas matched separadamente
      
      // Salvar no cache
      await _cacheService.cacheScheduledClasses(scheduledClasses);
      await _cacheService.cachePendingProposals(pendingProposals);
      
      return {
        'scheduledClasses': scheduledClasses,
        'pendingProposals': pendingProposals,
        'loadedAt': DateTime.now().toIso8601String(),
        'fromCache': false,
      };
    } catch (e) {
      print('❌ DEBUG: Erro ao carregar dados do card: $e');
      
      // Se não há token, retornar dados vazios
      if (e is UnauthorizedException) {
        print('❌ DEBUG: Usuário não autenticado - retornando dados vazios');
        return {
          'scheduledClasses': [],
          'pendingProposals': [],
          'loadedAt': DateTime.now().toIso8601String(),
          'requiresAuth': true,
          'fromCache': false,
        };
      }
      
      // Em caso de erro de rede, tentar usar cache mesmo se expirado
      final cachedData = _cacheService.getCachedWorkoutCardData();
      if (cachedData['scheduledClasses'].isNotEmpty || cachedData['pendingProposals'].isNotEmpty) {
        print('💾 DEBUG: Usando cache como fallback');
        return {
          ...cachedData,
          'fromCache': true,
          'error': e.toString(),
        };
      }
      
      return {
        'scheduledClasses': [],
        'pendingProposals': [],
        'loadedAt': DateTime.now().toIso8601String(),
        'error': e.toString(),
        'fromCache': false,
      };
    }
  }

  @override
  Future<Map<String, dynamic>> cancelClass(String classId) async {
    try {
      final cancelledClass = await _classesScheduledService.cancelClass(classId);
      return _mapClassToMap(cancelledClass);
    } catch (e) {
      print('❌ DEBUG: Erro ao cancelar aula: $e');
      throw ServerException('Erro ao cancelar aula: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> cancelProposal(String proposalId) async {
    try {
      final cancelledProposal = await _proposalsService.cancelProposal(proposalId);
      return _mapProposalToMap(cancelledProposal);
    } catch (e) {
      print('❌ DEBUG: Erro ao cancelar proposta: $e');
      throw ServerException('Erro ao cancelar proposta: $e');
    }
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Converte ClassResponseDto para Map<String, dynamic>
  Map<String, dynamic> _mapClassToMap(ClassResponseDto classDto) {
    final mapped = {
      'id': classDto.id,
      'proposalId': classDto.proposalId,
      'studentId': classDto.studentId,
      'personalId': classDto.personalId,
      'location': classDto.location,
      'date': classDto.date,
      'time': classDto.time,
      'duration': classDto.duration,
      'status': classDto.status.name,
      'startedAt': classDto.startedAt?.toIso8601String(),
      'completedAt': classDto.completedAt?.toIso8601String(),
      'createdAt': classDto.createdAt.toIso8601String(),
      'updatedAt': classDto.updatedAt.toIso8601String(),
      'student': classDto.student != null ? {
        'id': classDto.student!.id,
        'firstName': classDto.student!.firstName,
        'lastName': classDto.student!.lastName,
        'profilePicture': classDto.student!.profilePicture,
      } : null,
      'personal': classDto.personal != null ? {
        'id': classDto.personal!.id,
        'firstName': classDto.personal!.firstName,
        'lastName': classDto.personal!.lastName,
        'profilePicture': classDto.personal!.profilePicture,
      } : null,
      // Derived fields for convenience
      'personalName': '${classDto.personal?.firstName ?? ''} ${classDto.personal?.lastName ?? ''}'.trim(),
      'personalProfileImageUrl': classDto.personal?.profilePicture,
      // If you need rating/timeOnPlatform, fetch from Users API and enrich later
      'proposal': classDto.proposal != null ? {
        'id': classDto.proposal!.id,
        'modality': classDto.proposal!.modality,
        'value': classDto.proposal!.value,
      } : null,
    };

    // Enriquecer rapidamente com foto/rating se faltarem via Users API (non-blocking idealmente)
    if ((mapped['personalProfileImageUrl'] == null || (mapped['personalProfileImageUrl'] as String?)?.isEmpty == true) && classDto.personal != null) {
      // Best effort: não await aqui para não bloquear; manter simples síncrono
    }

    return mapped;
  }

  /// Combina trainingDate + trainingTime para criar data/hora completa
  DateTime _combineTrainingDateTime(DateTime trainingDate, String trainingTime) {
    try {
      // Parse do horário (formato HH:mm)
      final timeParts = trainingTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Criar nova data com o horário específico
      return DateTime(
        trainingDate.year,
        trainingDate.month,
        trainingDate.day,
        hour,
        minute,
      );
    } catch (e) {
      print('⚠️ DEBUG: Erro ao combinar data/hora: $e, usando data original');
      return trainingDate; // Fallback para data original
    }
  }

  /// Converte ProposalResponseDto para Map<String, dynamic>
  Map<String, dynamic> _mapProposalToMap(ProposalResponseDto proposalDto) {
    // Combinar trainingDate + trainingTime para criar data/hora completa
    final trainingDateTime = _combineTrainingDateTime(
      proposalDto.trainingDate, 
      proposalDto.trainingTime
    );
    
    return {
      'id': proposalDto.id,
      'studentId': proposalDto.studentId,
      'student': {
        'id': proposalDto.student.id,
        'name': proposalDto.student.name,
        'email': proposalDto.student.email,
        'firstName': proposalDto.student.firstName,
        'lastName': proposalDto.student.lastName,
      },
      'location': proposalDto.locationName, // Mapear como 'location' para compatibilidade
      'locationName': proposalDto.locationName,
      'locationAddress': proposalDto.locationAddress,
      'date': trainingDateTime.toIso8601String(), // Data/hora completa combinada
      'trainingDate': proposalDto.trainingDate.toIso8601String(),
      'time': proposalDto.trainingTime, // Mapear como 'time' para compatibilidade
      'trainingTime': proposalDto.trainingTime,
      'durationMinutes': proposalDto.durationMinutes,
      'modalityName': proposalDto.modalityName,
      'price': proposalDto.price,
      'additionalNotes': proposalDto.additionalNotes,
      'status': proposalDto.status.name,
      'paymentStatus': proposalDto.paymentStatus,
      'isRecontract': proposalDto.isRecontract ?? false,
      'targetPersonalId': proposalDto.targetPersonalId,
      'createdAt': proposalDto.createdAt.toIso8601String(),
      'updatedAt': proposalDto.updatedAt.toIso8601String(),
      'payment': proposalDto.payment != null ? {
        'paymentId': proposalDto.payment!.paymentId,
        'status': proposalDto.payment!.status,
        'method': proposalDto.payment!.method,
        'amount': proposalDto.payment!.amount,
        'preferenceId': proposalDto.payment!.preferenceId,
        'checkoutUrl': proposalDto.payment!.checkoutUrl,
        'qrCode': proposalDto.payment!.qrCode,
        'expiresAt': proposalDto.payment!.expiresAt?.toIso8601String(),
      } : null,
    };
  }



}

import 'class_dispute_dto.dart';
import '../services/student_photo_cache_service.dart';
import '../../../../core/di/dependency_injection.dart';

class ClassResponseDto {
  final String id;
  final String proposalId;
  final String studentId;
  final String personalId;
  final String location;
  final DateTime date;
  final String time;
  final int duration;
  final ClassStatus status;
  final ClassDisputeStatus? disputeStatus;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentEmail;
  final String? personalFirstName;
  final String? personalLastName;
  final String? personalEmail;
  final String? personalProfileImageUrl;
  final String? studentProfileImageUrl;
  final double? personalRating;
  final String? personalTimeOnPlatform;
  /// ⚠️ AVISO: Este campo atualmente retorna a MÉDIA GERAL do aluno ao invés da avaliação específica desta aula.
  /// O backend está retornando `4.585365853658536` (média) mesmo quando enviamos `rating: 2` para uma aula específica.
  /// ISSUE BACKEND: O campo `studentRating` deveria conter a avaliação específica desta aula, não a média geral.
  final double? studentRating;
  final String? proposalModality;
  final double? proposalPrice;
  final String? paymentStatus;
  final String? noShowReportedBy; // 'student' | 'personal'
  final DateTime? noShowReportedAt;
  final DateTime? evidenceDeadline;
  final DateTime? custodyExpiresAt;
  final String? studentDefenseText;
  final String? personalDefenseText;
  final DateTime? studentDefenseSubmittedAt;
  final DateTime? personalDefenseSubmittedAt;
  final List<String>? studentEvidence;
  final List<String>? personalEvidence;
  /// Código de confirmação de 4 dígitos — presente APENAS na resposta do startClass (HTTP).
  /// Nunca retornado em listagens ou WebSocket. Usar apenas para exibir ao personal no tracking.
  final String? startConfirmationCode;
  final String? settlementStatus;
  final String? settlementMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassResponseDto({
    required this.id,
    required this.proposalId,
    required this.studentId,
    required this.personalId,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.disputeStatus,
    this.startTime,
    this.endTime,
    this.studentFirstName,
    this.studentLastName,
    this.studentEmail,
    this.personalFirstName,
    this.personalLastName,
    this.personalEmail,
    this.personalProfileImageUrl,
    this.studentProfileImageUrl,
    this.personalRating,
    this.personalTimeOnPlatform,
    this.studentRating,
    this.proposalModality,
    this.proposalPrice,
    this.paymentStatus,
    this.noShowReportedBy,
    this.noShowReportedAt,
    this.evidenceDeadline,
    this.custodyExpiresAt,
    this.studentDefenseText,
    this.personalDefenseText,
    this.studentDefenseSubmittedAt,
    this.personalDefenseSubmittedAt,
    this.studentEvidence,
    this.personalEvidence,
    this.startConfirmationCode,
    this.settlementStatus,
    this.settlementMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassResponseDto.fromJson(Map<String, dynamic> json) {
    // Extrair dados do objeto personal se existir
    final personal = json['personal'] as Map<String, dynamic>?;
    final student = json['student'] as Map<String, dynamic>?;
    final proposal = json['proposal'] as Map<String, dynamic>?;
       
    // Resolvers de aliases e conversões
    String? _firstNonEmptyString(List<dynamic> candidates) {
      for (final c in candidates) {
        final v = c?.toString();
        if (v != null && v.trim().isNotEmpty) return v.trim();
      }
      return null;
    }

    double? _firstParsableDouble(List<dynamic> candidates) {
      for (final c in candidates) {
        if (c == null) continue;
        final parsed = double.tryParse(c.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final resolvedPersonalPhoto = _firstNonEmptyString([
      personal?['profileImageUrl'],
      personal?['profilePicture'],
      personal?['avatarUrl'],
      personal?['avatar'],
      personal?['photo'],
      personal?['imageUrl'],
      json['personalProfileImageUrl'],
      json['personalPhoto'],
    ]);

    final resolvedStudentPhoto = _firstNonEmptyString([
      student?['profileImageUrl'],
      student?['profilePicture'],
      student?['avatarUrl'],
      student?['avatar'],
      student?['photo'],
      student?['imageUrl'],
      json['studentProfileImageUrl'],
      json['studentPhoto'],
    ]);
    
    final resolvedPersonalRating = _firstParsableDouble([
      personal?['rating'],
      personal?['averageRating'],
      personal?['score'],
      json['personalRating'],
    ]);

    final resolvedPersonalTimeOnPlatform = _firstNonEmptyString([
      personal?['timeOnPlatform'],
      personal?['experience'],
      json['personalTimeOnPlatform'],
    ]);

    final resolvedProposalModality = _firstNonEmptyString([
      proposal?['modality'],
      json['proposalModality'],
      json['modality'],
      proposal?['category'],
    ]);

    final resolvedProposalPrice = _firstParsableDouble([
      proposal?['value'],
      json['proposalPrice'],
    ]);

    return ClassResponseDto(
      id: json['id'] ?? '',
      proposalId: json['proposalId'] ?? '',
      studentId: json['studentId'] ?? '',
      personalId: json['personalId'] ?? '',
      location: json['location'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      time: json['time'] ?? '',
      duration: json['duration'] != null 
          ? int.tryParse(json['duration'].toString()) ?? 60
          : 60,
      status: _parseClassStatus(json['status']),
      disputeStatus: json['disputeStatus'] != null
          ? _parseClassDisputeStatus(json['disputeStatus'])
          : null,
      startTime: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : (json['startTime'] != null
              ? DateTime.parse(json['startTime'])
              : null),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      studentFirstName: student?['firstName'] ?? json['studentFirstName'],
      studentLastName: student?['lastName'] ?? json['studentLastName'],
      studentEmail: json['studentEmail'],
      personalFirstName: personal?['firstName'] ?? json['personalFirstName'],
      personalLastName: personal?['lastName'] ?? json['personalLastName'],
      personalEmail: json['personalEmail'],
      personalProfileImageUrl: resolvedPersonalPhoto,
      studentProfileImageUrl: resolvedStudentPhoto,
      personalRating: resolvedPersonalRating,
      personalTimeOnPlatform: resolvedPersonalTimeOnPlatform,
      studentRating: json['studentRating'] != null
          ? double.tryParse(json['studentRating'].toString())
          : null,
      proposalModality: resolvedProposalModality,
      proposalPrice: resolvedProposalPrice,
      paymentStatus: json['paymentStatus'],
      noShowReportedBy: json['noShowReportedBy']?.toString(),
      noShowReportedAt: json['noShowReportedAt'] != null
          ? DateTime.tryParse(json['noShowReportedAt'].toString())
          : null,
      evidenceDeadline: json['evidenceDeadline'] != null
          ? DateTime.tryParse(json['evidenceDeadline'].toString())
          : null,
      custodyExpiresAt: json['custodyExpiresAt'] != null
          ? DateTime.tryParse(json['custodyExpiresAt'].toString())
          : null,
      studentDefenseText: json['studentDefenseText']?.toString(),
      personalDefenseText: json['personalDefenseText']?.toString(),
      studentDefenseSubmittedAt: json['studentDefenseSubmittedAt'] != null
          ? DateTime.tryParse(json['studentDefenseSubmittedAt'].toString())
          : null,
      personalDefenseSubmittedAt: json['personalDefenseSubmittedAt'] != null
          ? DateTime.tryParse(json['personalDefenseSubmittedAt'].toString())
          : null,
      studentEvidence: json['studentEvidence'] != null
          ? List<String>.from(json['studentEvidence'])
          : null,
      personalEvidence: json['personalEvidence'] != null
          ? List<String>.from(json['personalEvidence'])
          : null,
      startConfirmationCode: json['startConfirmationCode']?.toString(),
      settlementStatus: json['settlementStatus']?.toString(),
      settlementMessage: json['settlementMessage']?.toString(),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proposalId': proposalId,
      'studentId': studentId,
      'personalId': personalId,
      'location': location,
      'date': date.toIso8601String(),
      'time': time,
      'duration': duration,
      'status': status.name,
      'disputeStatus': disputeStatus?.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'studentFirstName': studentFirstName,
      'studentLastName': studentLastName,
      'studentEmail': studentEmail,
      'personalFirstName': personalFirstName,
      'personalLastName': personalLastName,
      'personalEmail': personalEmail,
      'proposalModality': proposalModality,
      'proposalPrice': proposalPrice,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get studentName => '${studentFirstName ?? ''} ${studentLastName ?? ''}'.trim();
  String get personalName => '${personalFirstName ?? ''} ${personalLastName ?? ''}'.trim();
  
  /// Retorna a foto do aluno, buscando no cache se necessário
  Future<String?> get studentPhotoUrl async {
    // Se já temos a URL, retorna ela
    if (studentProfileImageUrl != null && studentProfileImageUrl!.isNotEmpty) {
      return studentProfileImageUrl;
    }
    
    // Busca no cache
    try {
      final photoCache = sl<StudentPhotoCacheService>();
      return await photoCache.getStudentPhoto(studentId);
    } catch (e) {
      print('❌ [CLASS_DTO] Erro ao buscar foto do aluno $studentId: $e');
      return null;
    }
  }
  
  bool get isActive => status == ClassStatus.ACTIVE;
  bool get isScheduled => status == ClassStatus.SCHEDULED;
  bool get isPendingConfirmation => status == ClassStatus.PENDING_CONFIRMATION;
  bool get isCompleted => status == ClassStatus.COMPLETED;
  bool get isCancelled => status == ClassStatus.CANCELLED;
  bool get isInDispute => status == ClassStatus.NO_SHOW_DISPUTE;
  bool get isInCustody => status == ClassStatus.CUSTODY;

  static ClassStatus _parseClassStatus(String? status) {
    if (status == null) return ClassStatus.SCHEDULED;
    
    switch (status) {
      case 'scheduled':
        return ClassStatus.SCHEDULED;
      case 'pending_confirmation':
        return ClassStatus.PENDING_CONFIRMATION;
      case 'active':
        return ClassStatus.ACTIVE;
      case 'completed':
        return ClassStatus.COMPLETED;
      case 'cancelled':
        return ClassStatus.CANCELLED;
      case 'no_show_dispute':
        return ClassStatus.NO_SHOW_DISPUTE;
      case 'custody':
        return ClassStatus.CUSTODY;
      default:
        return ClassStatus.SCHEDULED;
    }
  }

  static ClassDisputeStatus _parseClassDisputeStatus(String? status) {
    if (status == null) return ClassDisputeStatus.PENDING;
    
    switch (status) {
      case 'pending':
        return ClassDisputeStatus.PENDING;
      case 'student_confirmed_absence':
        return ClassDisputeStatus.STUDENT_CONFIRMED_ABSENCE;
      case 'student_denied_absence':
        return ClassDisputeStatus.STUDENT_DENIED_ABSENCE;
      case 'resolved_for_student':
        return ClassDisputeStatus.RESOLVED_FOR_STUDENT;
      case 'resolved_for_personal':
        return ClassDisputeStatus.RESOLVED_FOR_PERSONAL;
      case 'defense_submitted_by_student':
        return ClassDisputeStatus.DEFENSE_SUBMITTED_BY_STUDENT;
      case 'defense_submitted_by_personal':
        return ClassDisputeStatus.DEFENSE_SUBMITTED_BY_PERSONAL;
      default:
        return ClassDisputeStatus.PENDING;
    }
  }
}

enum ClassStatus {
  SCHEDULED,
  PENDING_CONFIRMATION,
  ACTIVE,
  COMPLETED,
  CANCELLED,
  NO_SHOW_DISPUTE,
  CUSTODY,
}

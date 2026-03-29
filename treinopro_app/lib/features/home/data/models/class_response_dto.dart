import 'package:equatable/equatable.dart';

/// Enum para status das aulas
enum ClassStatus {
  scheduled,
  pendingConfirmation,
  active,
  completed,
  cancelled,
  noShowDispute,
  custody,
}

/// Enum para status de disputa
enum ClassDisputeStatus {
  pending,
  studentConfirmedAbsence,
  studentDeniedAbsence,
  resolvedForStudent,
  resolvedForPersonal,
}

/// DTO de resposta da API para aulas
class ClassResponseDto extends Equatable {
  final String id;
  final String proposalId;
  final String studentId;
  final String personalId;
  final String location;
  final DateTime date;
  final String time;
  final int duration;
  final ClassStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? pendingConfirmationAt;
  final DateTime? confirmedAt;
  final DateTime? noShowReportedAt;
  final String? noShowReportedBy;
  final ClassDisputeStatus? disputeStatus;
  final DateTime? custodyExpiresAt;
  final DateTime? evidenceDeadline;
  final String? studentEvidence;
  final String? personalEvidence;
  final String? resolution;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Relacionamentos
  final StudentInfo? student;
  final PersonalInfo? personal;
  final ProposalInfo? proposal;

  const ClassResponseDto({
    required this.id,
    required this.proposalId,
    required this.studentId,
    required this.personalId,
    required this.location,
    required this.date,
    required this.time,
    required this.duration,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.pendingConfirmationAt,
    this.confirmedAt,
    this.noShowReportedAt,
    this.noShowReportedBy,
    this.disputeStatus,
    this.custodyExpiresAt,
    this.evidenceDeadline,
    this.studentEvidence,
    this.personalEvidence,
    this.resolution,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
    this.student,
    this.personal,
    this.proposal,
  });

  factory ClassResponseDto.fromJson(Map<String, dynamic> json) {
    int _parseIntFlexible(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed ?? 0;
      }
      return 0;
    }

    return ClassResponseDto(
      id: json['id']?.toString() ?? '',
      proposalId: json['proposalId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      personalId: json['personalId']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      date: DateTime.parse(json['date']?.toString() ?? DateTime.now().toIso8601String()),
      time: json['time']?.toString() ?? '',
      duration: _parseIntFlexible(json['duration']),
      status: _parseClassStatus(json['status']?.toString() ?? 'scheduled'),
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'].toString()) : null,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'].toString()) : null,
      pendingConfirmationAt: json['pendingConfirmationAt'] != null ? DateTime.parse(json['pendingConfirmationAt'].toString()) : null,
      confirmedAt: json['confirmedAt'] != null ? DateTime.parse(json['confirmedAt'].toString()) : null,
      noShowReportedAt: json['noShowReportedAt'] != null ? DateTime.parse(json['noShowReportedAt'].toString()) : null,
      noShowReportedBy: json['noShowReportedBy']?.toString(),
      disputeStatus: json['disputeStatus'] != null ? _parseDisputeStatus(json['disputeStatus'].toString()) : null,
      custodyExpiresAt: json['custodyExpiresAt'] != null ? DateTime.parse(json['custodyExpiresAt'].toString()) : null,
      evidenceDeadline: json['evidenceDeadline'] != null ? DateTime.parse(json['evidenceDeadline'].toString()) : null,
      studentEvidence: json['studentEvidence']?.toString(),
      personalEvidence: json['personalEvidence']?.toString(),
      resolution: json['resolution']?.toString(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'].toString()) : null,
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? DateTime.now().toIso8601String()),
      student: json['student'] != null ? StudentInfo.fromJson(json['student'] as Map<String, dynamic>) : null,
      personal: json['personal'] != null ? PersonalInfo.fromJson(json['personal'] as Map<String, dynamic>) : null,
      proposal: json['proposal'] != null ? ProposalInfo.fromJson(json['proposal'] as Map<String, dynamic>) : null,
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
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'pendingConfirmationAt': pendingConfirmationAt?.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'noShowReportedAt': noShowReportedAt?.toIso8601String(),
      'noShowReportedBy': noShowReportedBy,
      'disputeStatus': disputeStatus?.name,
      'custodyExpiresAt': custodyExpiresAt?.toIso8601String(),
      'evidenceDeadline': evidenceDeadline?.toIso8601String(),
      'studentEvidence': studentEvidence,
      'personalEvidence': personalEvidence,
      'resolution': resolution,
      'resolvedAt': resolvedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'student': student?.toJson(),
      'personal': personal?.toJson(),
      'proposal': proposal?.toJson(),
    };
  }

  static ClassStatus _parseClassStatus(String status) {
    switch (status) {
      case 'scheduled':
        return ClassStatus.scheduled;
      case 'pending_confirmation':
        return ClassStatus.pendingConfirmation;
      case 'active':
        return ClassStatus.active;
      case 'completed':
        return ClassStatus.completed;
      case 'cancelled':
        return ClassStatus.cancelled;
      case 'no_show_dispute':
        return ClassStatus.noShowDispute;
      case 'custody':
        return ClassStatus.custody;
      default:
        return ClassStatus.scheduled;
    }
  }

  static ClassDisputeStatus _parseDisputeStatus(String status) {
    switch (status) {
      case 'pending':
        return ClassDisputeStatus.pending;
      case 'student_confirmed_absence':
        return ClassDisputeStatus.studentConfirmedAbsence;
      case 'student_denied_absence':
        return ClassDisputeStatus.studentDeniedAbsence;
      case 'resolved_for_student':
        return ClassDisputeStatus.resolvedForStudent;
      case 'resolved_for_personal':
        return ClassDisputeStatus.resolvedForPersonal;
      default:
        return ClassDisputeStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        proposalId,
        studentId,
        personalId,
        location,
        date,
        time,
        duration,
        status,
        startedAt,
        completedAt,
        pendingConfirmationAt,
        confirmedAt,
        noShowReportedAt,
        noShowReportedBy,
        disputeStatus,
        custodyExpiresAt,
        evidenceDeadline,
        studentEvidence,
        personalEvidence,
        resolution,
        resolvedAt,
        createdAt,
        updatedAt,
        student,
        personal,
        proposal,
      ];
}

/// Informações do aluno
class StudentInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  const StudentInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName, profilePicture];
}

/// Informações do personal trainer
class PersonalInfo extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  const PersonalInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) {
    return PersonalInfo(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePicture: json['profilePicture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profilePicture': profilePicture,
    };
  }

  @override
  List<Object?> get props => [id, firstName, lastName, profilePicture];
}

/// Informações da proposta
class ProposalInfo extends Equatable {
  final String id;
  final String modality;
  final double value;

  const ProposalInfo({
    required this.id,
    required this.modality,
    required this.value,
  });

  factory ProposalInfo.fromJson(Map<String, dynamic> json) {
    double _parseDoubleFlexible(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.replaceAll(',', '.'));
        return parsed ?? 0.0;
      }
      return 0.0;
    }

    return ProposalInfo(
      id: json['id']?.toString() ?? '',
      modality: json['modality']?.toString() ?? '',
      value: _parseDoubleFlexible(json['value']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'modality': modality,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [id, modality, value];
}

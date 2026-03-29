enum ClassDisputeStatus {
  PENDING,
  STUDENT_CONFIRMED_ABSENCE,
  STUDENT_DENIED_ABSENCE,
  RESOLVED_FOR_STUDENT,
  RESOLVED_FOR_PERSONAL,
  DEFENSE_SUBMITTED_BY_STUDENT,
  DEFENSE_SUBMITTED_BY_PERSONAL,
}

class ClassDisputeDto {
  final String id;
  final String classId;
  final String reportedBy; // 'student' | 'personal' (role de quem reportou)
  final String reporterUserId; // ID do usuário que reportou
  final String reportedUserId; // ID do usuário reportado
  final String? reporterName;
  final String? reportedUserName;
  final ClassDisputeStatus status;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? resolution;
  final List<String>? studentEvidence;
  final List<String>? personalEvidence;
  final String? studentDefenseText;
  final String? personalDefenseText;
  final DateTime? studentDefenseSubmittedAt;
  final DateTime? personalDefenseSubmittedAt;
  final DateTime evidenceDeadline;
  final DateTime custodyExpiresAt;
  // Geolocalização
  final bool reporterHasSnapshot;
  final bool reportedHasSnapshot;
  final DateTime? reporterSnapshotAt;
  final DateTime? reportedSnapshotAt;

  ClassDisputeDto({
    required this.id,
    required this.classId,
    required this.reportedBy,
    required this.reporterUserId,
    required this.reportedUserId,
    this.reporterName,
    this.reportedUserName,
    required this.status,
    required this.reportedAt,
    this.resolvedAt,
    this.resolution,
    this.studentEvidence,
    this.personalEvidence,
    this.studentDefenseText,
    this.personalDefenseText,
    this.studentDefenseSubmittedAt,
    this.personalDefenseSubmittedAt,
    required this.evidenceDeadline,
    required this.custodyExpiresAt,
    this.reporterHasSnapshot = false,
    this.reportedHasSnapshot = false,
    this.reporterSnapshotAt,
    this.reportedSnapshotAt,
  });

  factory ClassDisputeDto.fromJson(Map<String, dynamic> json) {
    return ClassDisputeDto(
      id: json['id'] ?? '',
      classId: json['classId'] ?? '',
      reportedBy: json['reportedBy'] ?? 'student',
      reporterUserId: json['reporterUserId'] ?? '',
      reportedUserId: json['reportedUserId'] ?? '',
      reporterName: json['reporterName'],
      reportedUserName: json['reportedUserName'],
      status: _parseClassDisputeStatus(json['status']),
      reportedAt: DateTime.parse(json['reportedAt'] ?? DateTime.now().toIso8601String()),
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      resolution: json['resolution'],
      studentEvidence: json['studentEvidence'] != null
          ? List<String>.from(json['studentEvidence'])
          : null,
      personalEvidence: json['personalEvidence'] != null
          ? List<String>.from(json['personalEvidence'])
          : null,
      studentDefenseText: json['studentDefenseText'],
      personalDefenseText: json['personalDefenseText'],
      studentDefenseSubmittedAt: json['studentDefenseSubmittedAt'] != null
          ? DateTime.parse(json['studentDefenseSubmittedAt'])
          : null,
      personalDefenseSubmittedAt: json['personalDefenseSubmittedAt'] != null
          ? DateTime.parse(json['personalDefenseSubmittedAt'])
          : null,
      evidenceDeadline: DateTime.parse(
          json['evidenceDeadline'] ?? DateTime.now().toIso8601String()),
      custodyExpiresAt: DateTime.parse(
          json['custodyExpiresAt'] ?? DateTime.now().toIso8601String()),
      reporterHasSnapshot: json['reporterHasSnapshot'] == true,
      reportedHasSnapshot: json['reportedHasSnapshot'] == true,
      reporterSnapshotAt: json['reporterSnapshotAt'] != null
          ? DateTime.parse(json['reporterSnapshotAt'])
          : null,
      reportedSnapshotAt: json['reportedSnapshotAt'] != null
          ? DateTime.parse(json['reportedSnapshotAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'classId': classId,
      'reportedBy': reportedBy,
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'reporterName': reporterName,
      'reportedUserName': reportedUserName,
      'status': status.name,
      'reportedAt': reportedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolution': resolution,
      'studentEvidence': studentEvidence,
      'personalEvidence': personalEvidence,
      'studentDefenseText': studentDefenseText,
      'personalDefenseText': personalDefenseText,
      'studentDefenseSubmittedAt': studentDefenseSubmittedAt?.toIso8601String(),
      'personalDefenseSubmittedAt': personalDefenseSubmittedAt?.toIso8601String(),
      'evidenceDeadline': evidenceDeadline.toIso8601String(),
      'custodyExpiresAt': custodyExpiresAt.toIso8601String(),
      'reporterHasSnapshot': reporterHasSnapshot,
      'reportedHasSnapshot': reportedHasSnapshot,
      'reporterSnapshotAt': reporterSnapshotAt?.toIso8601String(),
      'reportedSnapshotAt': reportedSnapshotAt?.toIso8601String(),
    };
  }

  bool get isPending => status == ClassDisputeStatus.PENDING;
  bool get isDefenseSubmitted =>
      status == ClassDisputeStatus.DEFENSE_SUBMITTED_BY_STUDENT ||
      status == ClassDisputeStatus.DEFENSE_SUBMITTED_BY_PERSONAL;
  bool get isStudentConfirmedAbsence => status == ClassDisputeStatus.STUDENT_CONFIRMED_ABSENCE;
  bool get isStudentDeniedAbsence => status == ClassDisputeStatus.STUDENT_DENIED_ABSENCE;
  bool get isResolvedForStudent => status == ClassDisputeStatus.RESOLVED_FOR_STUDENT;
  bool get isResolvedForPersonal => status == ClassDisputeStatus.RESOLVED_FOR_PERSONAL;
  bool get isResolved => isResolvedForStudent || isResolvedForPersonal;

  /// Verifica se tem defesa submetida (de qualquer lado)
  bool get hasAnyDefense =>
      studentDefenseText != null || personalDefenseText != null;

  /// Calcula tempo restante para envio de defesa
  Duration get timeUntilEvidenceDeadline {
    final now = DateTime.now();
    if (now.isAfter(evidenceDeadline)) return Duration.zero;
    return evidenceDeadline.difference(now);
  }

  bool get isWithinDeadline => timeUntilEvidenceDeadline.inSeconds > 0;

  /// Retorna string formatada do tempo restante
  String get formattedTimeUntilDeadline {
    final duration = timeUntilEvidenceDeadline;
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Prazo expirado';
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

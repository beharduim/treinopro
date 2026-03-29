class LevelLabels {
  // Mapeamento para Personal Trainer
  static const Map<int, String> personalLevelLabels = {
    1: 'Estreante',
    2: 'Em Ascensão',
    3: 'Destaque Pro',
    4: 'Referência',
    5: 'Mentor Pro',
    6: 'TreinoPro Lendário',
  };

  // Mapeamento para Aluno (caso precise usar no app)
  static const Map<int, String> studentLevelLabels = {
    1: 'Estreante',
    2: 'Focado',
    3: 'Disciplinado',
    4: 'Atleta Pro',
    5: 'Elite Pro',
    6: 'TreinoPro Master',
  };

  static String getPersonalLabel(int level) {
    if (level <= 1) return personalLevelLabels[1]!;
    if (level >= 6) return personalLevelLabels[6]!;
    return personalLevelLabels[level] ?? personalLevelLabels[1]!;
  }

  static String getStudentLabel(int level) {
    if (level <= 1) return studentLevelLabels[1]!;
    if (level >= 6) return studentLevelLabels[6]!;
    return studentLevelLabels[level] ?? studentLevelLabels[1]!;
  }

  static String getLabelByUserType(String userType, int level) {
    return (userType == 'personal') ? getPersonalLabel(level) : getStudentLabel(level);
  }
}



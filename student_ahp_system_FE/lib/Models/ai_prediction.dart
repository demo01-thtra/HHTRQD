class AiPrediction {
  final double testScore;
  final double attendance;
  final double studyHours;
  final String dtPrediction; // "Pass" or "Fail" from Decision Tree
  final double pFail;
  final double ahpScore;
  final double finalScore;
  final String riskLevel;
  final List<String> rules;
  final List<Map<String, dynamic>> topFactors;
  final String warningReason;
  final String suggestion;
  final Map<String, double> ahpWeights;
  final Map<String, double> featureImportance;
  final Map<String, dynamic> modelInfo;

  AiPrediction({
    required this.testScore,
    required this.attendance,
    required this.studyHours,
    required this.dtPrediction,
    required this.pFail,
    required this.ahpScore,
    required this.finalScore,
    required this.riskLevel,
    required this.rules,
    required this.topFactors,
    required this.warningReason,
    required this.suggestion,
    required this.ahpWeights,
    required this.featureImportance,
    required this.modelInfo,
  });

  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    return AiPrediction(
      testScore: (json['testScore'] as num).toDouble(),
      attendance: (json['attendance'] as num).toDouble(),
      studyHours: (json['studyHours'] as num).toDouble(),
      dtPrediction: json['dtPrediction'] ?? 'N/A',
      pFail: (json['pFail'] as num).toDouble(),
      ahpScore: (json['ahpScore'] as num).toDouble(),
      finalScore: (json['finalScore'] as num).toDouble(),
      riskLevel: json['riskLevel'] ?? '',
      rules: List<String>.from(json['rules'] ?? []),
      topFactors: (json['topFactors'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      warningReason: json['warningReason'] ?? '',
      suggestion: json['suggestion'] ?? '',
      ahpWeights: (json['ahpWeights'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
          {},
      featureImportance: (json['featureImportance'] as Map?)
              ?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ??
          {},
      modelInfo: Map<String, dynamic>.from(json['modelInfo'] ?? {}),
    );
  }
}

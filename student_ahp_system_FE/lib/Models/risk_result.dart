class RiskResult {
  final int studentId;
  final double riskScore;
  final String riskLevel;
  final String calculatedDate;

  RiskResult({
    required this.studentId,
    required this.riskScore,
    required this.riskLevel,
    required this.calculatedDate,
  });

  factory RiskResult.fromJson(Map<String, dynamic> json) {
    return RiskResult(
      studentId: json['studentId'],
      riskScore: json['riskScore'].toDouble(),
      riskLevel: json['riskLevel'],
      calculatedDate: json['calculatedDate'],
    );
  }
}
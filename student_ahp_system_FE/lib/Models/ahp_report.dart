class AhpCriteriaDetail {
  final List<List<double>> matrix;
  final List<double> columnSum;
  final List<List<double>> normalizedMatrix;
  final List<double> weights;
  final List<double> axW;
  final List<double> lambdaI;
  final double lambdaMax;
  final double ci;
  final double ri;
  final double cr;
  final List<String> criteriaNames;
  final List<int> ranking;

  AhpCriteriaDetail({
    required this.matrix,
    required this.columnSum,
    required this.normalizedMatrix,
    required this.weights,
    required this.axW,
    required this.lambdaI,
    required this.lambdaMax,
    required this.ci,
    required this.ri,
    required this.cr,
    required this.criteriaNames,
    required this.ranking,
  });

  factory AhpCriteriaDetail.fromJson(Map<String, dynamic> json) {
    return AhpCriteriaDetail(
      matrix: (json['matrix'] as List).map((r) => (r as List).map((v) => (v as num).toDouble()).toList()).toList(),
      columnSum: (json['columnSum'] as List).map((v) => (v as num).toDouble()).toList(),
      normalizedMatrix: (json['normalizedMatrix'] as List).map((r) => (r as List).map((v) => (v as num).toDouble()).toList()).toList(),
      weights: (json['weights'] as List).map((v) => (v as num).toDouble()).toList(),
      axW: (json['axW'] as List).map((v) => (v as num).toDouble()).toList(),
      lambdaI: (json['lambdaI'] as List).map((v) => (v as num).toDouble()).toList(),
      lambdaMax: (json['lambdaMax'] as num).toDouble(),
      ci: (json['ci'] as num).toDouble(),
      ri: (json['ri'] as num).toDouble(),
      cr: (json['cr'] as num).toDouble(),
      criteriaNames: (json['criteriaNames'] as List).map((v) => v.toString()).toList(),
      ranking: (json['ranking'] as List).map((v) => (v as num).toInt()).toList(),
    );
  }
}

class AhpReport {
  final AhpCriteriaDetail? criteriaDetail;
  final Map<String, dynamic> criteriaWeights;
  final double cr;
  final List<dynamic> matrices;
  final List<dynamic> alternativeWeights;
  final List<dynamic> finalScores;
  final String best;

  AhpReport({
    this.criteriaDetail,
    required this.criteriaWeights,
    required this.cr,
    required this.matrices,
    required this.alternativeWeights,
    required this.finalScores,
    required this.best,
  });

  factory AhpReport.fromJson(Map<String, dynamic> json) {
    return AhpReport(
      criteriaDetail: json['criteriaDetail'] != null
          ? AhpCriteriaDetail.fromJson(json['criteriaDetail'])
          : null,
      criteriaWeights: json['criteriaWeights'] ?? {},
      cr: (json['cr'] as num?)?.toDouble() ?? 0.0,
      matrices: (json['matrices'] as List?) ?? [],
      alternativeWeights: (json['alternativeWeights'] as List?) ?? [],
      finalScores: (json['finalScores'] as List?) ?? [],
      best: json['best']?.toString() ?? '',
    );
  }
}
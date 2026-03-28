class AhpMatrixRequest {

  final String criteriaName;
  final List<List<double>> matrix;

  AhpMatrixRequest({
    required this.criteriaName,
    required this.matrix,
  });

  Map<String,dynamic> toJson(){
    return {
      "criteriaName": criteriaName,
      "matrix": matrix
    };
  }

}
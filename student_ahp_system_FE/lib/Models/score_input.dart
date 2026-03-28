class ScoreInput {

  int studentId;
  double testScore;
  double attendance;
  double studyHours;

  ScoreInput({
    required this.studentId,
    required this.testScore,
    required this.attendance,
    required this.studyHours,
  });

  Map<String,dynamic> toJson(){
    return {
      "studentId": studentId,
      "testScore": testScore,
      "attendance": attendance,
      "studyHours": studyHours
    };
  }
  factory ScoreInput.fromJson(Map<String, dynamic> json) {
    return ScoreInput(
     studentId: (json["studentId"] as num).toInt(),
      testScore: (json["testScore"] as num).toDouble(),
      attendance: (json["attendance"] as num).toDouble(),
      studyHours: (json["studyHours"] as num).toDouble(),
    );
  }

}
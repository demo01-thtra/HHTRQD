import 'package:flutter/material.dart';
import '../Models/score_input.dart';
import '../Services/score_service.dart';

class ScoreViewModel extends ChangeNotifier {

  final ScoreService service = ScoreService();

  List<ScoreInput> scores = [];
  bool isLoading = false;
  Map<int, ScoreInput> scoreMap = {};
  Future submitScore(
      int studentId,
      double testScore,
      double attendance,
      double studyHours
      ) async {

    isLoading = true;
    notifyListeners();

    ScoreInput score = ScoreInput(

      studentId: studentId,
      testScore: testScore,
      attendance: attendance,
      studyHours: studyHours,

    );

    await service.submitScore(score);

    isLoading = false;
    notifyListeners();

  }
  Future<void> loadScores() async {
    try {
      isLoading = true;
      notifyListeners();

      scores = await service.getScores();

      scoreMap = {
        for (var s in scores) s.studentId: s
      };

    } catch (e) {
      debugPrint("Load score error: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // =============================
  // GET
  // =============================
  ScoreInput? getScoreByStudent(int studentId) {
    return scoreMap[studentId];
  }

}
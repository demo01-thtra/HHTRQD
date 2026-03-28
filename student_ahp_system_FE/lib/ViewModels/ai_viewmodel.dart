import 'package:flutter/material.dart';
import '../Models/ai_prediction.dart';
import '../Services/ai_service.dart';
import '../Services/student_service.dart';
import '../Services/score_service.dart';
import '../Models/student.dart';
import '../Models/score_input.dart';

class AiViewModel extends ChangeNotifier {
  final AiService _service = AiService();
  final StudentService _studentService = StudentService();
  final ScoreService _scoreService = ScoreService();

  AiPrediction? prediction;
  Map<String, dynamic>? modelInfo;
  bool isLoading = false;
  String error = "";

  // Student list + AI batch results
  List<Student> students = [];
  Map<int, ScoreInput> scoreMap = {};
  List<Map<String, dynamic>> batchResults = [];
  bool isBatchLoading = false;

  // Retrain
  Map<String, dynamic>? thresholds;
  Map<String, dynamic>? retrainResult;
  bool isRetraining = false;

  Future<void> predict({
    required double testScore,
    required double attendance,
    required double studyHours,
  }) async {
    try {
      isLoading = true;
      error = "";
      notifyListeners();

      prediction = await _service.predict(
        testScore: testScore,
        attendance: attendance,
        studyHours: studyHours,
      );
    } catch (e) {
      error = e.toString();
      prediction = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadModelInfo() async {
    try {
      modelInfo = await _service.getModelInfo();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  void clear() {
    prediction = null;
    error = "";
    notifyListeners();
  }

  /// Load students + scores, then batch predict via AI
  Future<void> loadStudentsAndPredict() async {
    try {
      isBatchLoading = true;
      error = "";
      notifyListeners();

      students = await _studentService.getAllStudent();
      final scores = await _scoreService.getScores();
      scoreMap = {for (var s in scores) s.studentId: s};

      // Build batch input from students that have scores
      final batchInput = <Map<String, dynamic>>[];
      for (var st in students) {
        final score = scoreMap[st.id];
        if (score != null) {
          batchInput.add({
            "studentId": st.id,
            "testScore": score.testScore,
            "attendance": score.attendance,
            "studyHours": score.studyHours,
          });
        }
      }

      if (batchInput.isNotEmpty) {
        batchResults = await _service.predictBatch(batchInput);
      } else {
        batchResults = [];
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isBatchLoading = false;
      notifyListeners();
    }
  }

  /// Get AI prediction result for a specific student
  Map<String, dynamic>? getBatchResultByStudent(int studentId) {
    try {
      return batchResults.firstWhere((r) => r["studentId"] == studentId);
    } catch (_) {
      return null;
    }
  }

  /// Load current label thresholds from server
  Future<void> loadThresholds() async {
    try {
      thresholds = await _service.getThresholds();
      notifyListeners();
    } catch (e) {
      error = e.toString();
    }
  }

  /// Retrain model with custom thresholds
  Future<void> retrain(Map<String, dynamic> newThresholds) async {
    try {
      isRetraining = true;
      error = "";
      retrainResult = null;
      notifyListeners();

      retrainResult = await _service.retrain(newThresholds);
      // Reload model info + re-predict after retrain
      await loadModelInfo();
      await loadStudentsAndPredict();
    } catch (e) {
      error = e.toString();
      retrainResult = null;
    } finally {
      isRetraining = false;
      notifyListeners();
    }
  }
}

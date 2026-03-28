import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/ai_prediction.dart';

class AiService {
  final String baseUrl = "http://localhost:5001/api/ai";

  /// Predict risk for a single student
  Future<AiPrediction> predict({
    required double testScore,
    required double attendance,
    required double studyHours,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "testScore": testScore,
        "attendance": attendance,
        "studyHours": studyHours,
      }),
    );
    if (res.statusCode == 200) {
      return AiPrediction.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("AI prediction failed: ${res.statusCode}");
    }
  }

  /// Get model info
  Future<Map<String, dynamic>> getModelInfo() async {
    final res = await http.get(Uri.parse("$baseUrl/model-info"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Get model info failed");
    }
  }

  /// Predict batch for multiple students
  Future<List<Map<String, dynamic>>> predictBatch(List<Map<String, dynamic>> students) async {
    final res = await http.post(
      Uri.parse("$baseUrl/predict-batch"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"students": students}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return List<Map<String, dynamic>>.from(data["results"]);
    } else {
      throw Exception("Batch prediction failed: ${res.statusCode}");
    }
  }

  /// Get current label thresholds
  Future<Map<String, dynamic>> getThresholds() async {
    final res = await http.get(Uri.parse("$baseUrl/thresholds"));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Get thresholds failed");
    }
  }

  /// Retrain model with custom thresholds
  Future<Map<String, dynamic>> retrain(Map<String, dynamic> thresholds) async {
    final res = await http.post(
      Uri.parse("$baseUrl/retrain"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(thresholds),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      final body = jsonDecode(res.body);
      throw Exception(body["error"] ?? "Retrain failed: ${res.statusCode}");
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/score_input.dart';

class ScoreService {

  Future submitScore(ScoreInput score) async {

    var response = await http.post(

        Uri.parse("http://localhost:5045/api/performance"),

        headers: {
          "Content-Type":"application/json"
        },

        body: jsonEncode(score.toJson())

    );

    if (response.statusCode != 200) {
      throw Exception("Lưu điểm thất bại: ${response.statusCode}");
    }

    return response.body;

  }
  Future<List<ScoreInput>> getScores() async {
    final res = await http.get(
      Uri.parse("http://localhost:5045/api/performance"),
    );

    if (res.statusCode == 200) {
      List data = jsonDecode(res.body);
      return data.map((e) => ScoreInput.fromJson(e)).toList();
    } else {
      throw Exception("Load scores failed");
    }
  }

  Future<ScoreInput?> getScoreByStudent(int studentId) async {
    final res = await http.get(
      Uri.parse("http://localhost:5045/api/performance/$studentId"),
    );

    if (res.statusCode == 200) {
      return ScoreInput.fromJson(jsonDecode(res.body));
    } else {
      return null;
    }
  }


}
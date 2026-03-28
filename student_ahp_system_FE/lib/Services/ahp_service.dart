import 'dart:convert';
import 'package:dssstudentfe/Models/ahp_model.dart';
import 'package:dssstudentfe/Models/ahp_matrix_request.dart';
import 'package:dssstudentfe/Models/ahp_report.dart';
import 'package:http/http.dart' as http;

class AhpService {

  final String baseUrl = "http://localhost:5045/api/ahp";

  Future<AhpResult> calculate(AhpModel model) async {

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(model.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Lỗi server: ${response.statusCode}");
    }

    final body=jsonDecode(response.body);
    if (body["data"] != null) {
      return AhpResult.fromJson(body["data"]);
    }

    throw Exception(body["message"] ?? "Lỗi tính AHP");
  }
  Future<void> calculateAlternative(AhpMatrixRequest request) async {

    final response = await http.post(
      Uri.parse("$baseUrl/alternative"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(request.toJson()),
    );

    if(response.statusCode != 200){
      throw Exception("Error calculating alternative");
    }
  }
  Future<Map<String,dynamic>> getFinalResult() async {

    final response = await http.get(Uri.parse("$baseUrl/final"));

    if(response.statusCode == 200){
      return jsonDecode(response.body);
    }

    throw Exception("Error final result");
  }
  Future<AhpReport> getReport()async{
    final response=await http.get(Uri.parse("$baseUrl/report"));
    if(response.statusCode==200){
      final data=jsonDecode(response.body);
      return AhpReport.fromJson(data);
    }else{
      throw Exception("Failed to load report");
    }
  }


}
import 'dart:convert';
import 'package:dssstudentfe/Models/calculate_all_response.dart';
import 'package:http/http.dart' as http;
import '../Models/risk_result.dart';

class RiskService {

  final String baseUrl = "http://localhost:5045/api/risk";
  /// calculate risk for 1 student
  Future<RiskResult> calculateRisk(int studentId) async {
    final res = await http.post(
      Uri.parse("$baseUrl/$studentId"),
    );
    if(res.statusCode == 200){
      return RiskResult.fromJson(json.decode(res.body));
    }else{
      throw Exception("Calculate risk failed");
    }
  }
  /// calculate risk for all students
  Future<CalculateAllResponse> calculateAll() async {
    final res = await http.post(Uri.parse("$baseUrl/calculate-all"));
    if (res.statusCode == 200) {
      return CalculateAllResponse.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Calculate failed");
    }
  }
  //summary
  Future<Map<String, dynamic>> getSummary()async{
    final res=await http.get(Uri.parse("$baseUrl/summary"));
    if(res.statusCode==200){
      return jsonDecode(res.body);
    }
    else{
      throw Exception("Load summary failed");
    }
  }

  /// get all results
  Future<List<RiskResult>> getResults() async {

    final res = await http.get(
      Uri.parse("$baseUrl/results"),
    );

    if(res.statusCode == 200){

      List data = json.decode(res.body);

      return data.map((e)=>RiskResult.fromJson(e)).toList();

    }else{
      throw Exception("Load risk results failed");
    }
  }

  /// top risk
  Future<List<RiskResult>> getTopRisk() async {

    final res = await http.get(
      Uri.parse("$baseUrl/top-risk"),
    );

    if (res.statusCode != 200) {
      throw Exception("Load top risk failed: ${res.statusCode}");
    }

    List data = json.decode(res.body);

    return data.map((e)=>RiskResult.fromJson(e)).toList();
  }
}
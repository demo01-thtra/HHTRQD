import 'package:flutter/material.dart';
import '../Models/risk_result.dart';
import '../Services/risk_service.dart';

class RiskViewModel extends ChangeNotifier {

  final RiskService _service = RiskService();
  Map<String, dynamic>? summary;
  bool isLoading = false;
  String message = "";
  List<RiskResult> results = [];

  List<RiskResult> topRisk = [];

  /// tính risk cho 1 sinh viên
  Future<void> calculateRisk(int studentId) async {

    isLoading = true;
    notifyListeners();

    await _service.calculateRisk(studentId);

    await loadResults();

    isLoading = false;
    notifyListeners();
  }

  /// tính risk cho tất cả sinh viên
  Future<void> calculateAll() async {
    try {
      isLoading = true;
      message = "Đang tính...";
      notifyListeners();

      await _service.calculateAll();

      await loadResults();

      message = "Tính xong!";
    } catch (e) {
      message = " $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  Future<void> loadSummary()async{
    try{
      isLoading=true;
      notifyListeners();
      summary=await _service.getSummary();
    }
    catch(e){
      debugPrint("Load summary error:$e");
    }
    finally{
      isLoading=false;
      notifyListeners();
    }
  }

  /// load danh sách risk
  Future<void> loadResults() async {

    isLoading = true;
    notifyListeners();

    results = await _service.getResults();

    isLoading = false;
    notifyListeners();
  }

  /// load top risk
  Future<void> loadTopRisk() async {

    isLoading = true;
    notifyListeners();

    topRisk = await _service.getTopRisk();

    isLoading = false;
    notifyListeners();
  }

  /// lấy risk của 1 student
  RiskResult? getRiskByStudent(int studentId) {

    try{
      return results.firstWhere(
              (r) => r.studentId == studentId
      );
    }catch(e){
      return null;
    }

  }

}
import 'package:dssstudentfe/Models/ahp_model.dart';
import 'package:dssstudentfe/Models/ahp_matrix_request.dart';
import 'package:dssstudentfe/Models/ahp_report.dart';
import 'package:dssstudentfe/Services/ahp_service.dart';
import 'package:flutter/material.dart';

class AhpViewModel extends ChangeNotifier {

  final AhpService _service = AhpService();
  AhpReport? report;
  bool isLoading = false;

  Map<String,double>? weights;
  double? cr=0;
  String? error;

  Future<void> calculateAHP(
      double testAttendance,
      double testStudy,
      double attendanceStudy) async {

    isLoading = true;
    notifyListeners();

    try {

      AhpModel model = AhpModel(
        testAttendance: testAttendance,
        testStudy: testStudy,
        attendanceStudy: attendanceStudy,
      );

      var result = await _service.calculate(model);

      weights = {
        "Điểm kiểm tra": result.testWeight,
        "Chuyên cần": result.attendanceWeight,
        "Giờ học/ngày": result.studyWeight,
      };

      cr = result.consistencyRatio;

    } catch(e) {
    error = e.toString();
    debugPrint(e.toString());
    }

    isLoading = false;
    notifyListeners();
  }
  Future<void> calculateAlternative(
      String criteria,
      List<List<double>> matrix
      ) async {

    final request = AhpMatrixRequest(
        criteriaName: criteria,
        matrix: matrix
    );

    await _service.calculateAlternative(request);
  }
  Future<void>fetchReport()async{
    try{
      isLoading=true;
      error=null;
      notifyListeners();
      report=await _service.getReport();
    }catch(e){
      error=e.toString();
    }finally{
      isLoading=false;
      notifyListeners();
    }
  }
}
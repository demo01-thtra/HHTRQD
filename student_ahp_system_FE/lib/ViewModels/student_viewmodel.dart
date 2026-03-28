import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../Models/student.dart';
import '../Services/student_service.dart';
import 'package:http/http.dart' as http;
class StudentViewModel extends ChangeNotifier {

  final StudentService _service = StudentService();
  bool isLoading=false;

  List<Student> students = [];

  Future<void> addStudent(
      String code,
      String name,
      String className,
      String email
      ) async {

    Student s = Student(
        studentCode: code,
        name: name,
        className: className,
      email: email,
      listPer: []
    );

    Student? created = await _service.createStudent(s);

    if(created != null){
      students.add(created);
      notifyListeners();
    }
  }
  Future<void> loadStudents()async{
    isLoading = true;
    notifyListeners();
    students = await _service.getAllStudent();
    isLoading=false;
    notifyListeners();
  }

  Future<bool> deleteStudent(int id) async {
    bool ok = await _service.deleteStudent(id);
    if (ok) {
      students.removeWhere((s) => s.id == id);
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateStudent(int id, String code, String name, String className, String email) async {
    Student s = Student(
      studentCode: code,
      name: name,
      className: className,
      email: email,
      listPer: [],
    );
    bool ok = await _service.updateStudent(id, s);
    if (ok) {
      final idx = students.indexWhere((st) => st.id == id);
      if (idx != -1) {
        students[idx].studentCode = code;
        students[idx].name = name;
        students[idx].className = className;
        students[idx].email = email;
      }
      notifyListeners();
    }
    return ok;
  }

  // Upload Excel (Web compatible)
  Future<void> importExcelWeb(Uint8List bytes, String filename) async {
    var uri = Uri.parse("http://localhost:5045/api/student/students-excel-json");

    var request = http.MultipartRequest("POST", uri);

    // Thêm file dưới dạng bytes
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      // import thành công → load lại danh sách
      await loadStudents();
    } else {
      throw Exception("Import thất bại: ${response.statusCode}");
    }
  }

}
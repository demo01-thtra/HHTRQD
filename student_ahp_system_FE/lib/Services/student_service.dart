import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/student.dart';

class StudentService {

  final String baseUrl = "http://localhost:5045/api/student";

  Future<Student?> createStudent(Student student) async {

    final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode(student.toJson())
    );

    if(response.statusCode == 200){
      return Student.fromJson(jsonDecode(response.body));
    }

    return null;
  }
  Future<List<Student>> getAllStudent() async {

    final response = await http.get(
      Uri.parse(baseUrl),
    );
    if(response.statusCode == 200){

      List data = jsonDecode(response.body);

      return data.map((e) => Student.fromJson(e)).toList();

    }else{
      throw Exception("Failed");
    }
  }

  Future<bool> deleteStudent(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl/$id"));
    return response.statusCode == 200;
  }

  Future<bool> updateStudent(int id, Student student) async {
    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(student.toJson()),
    );
    return response.statusCode == 200;
  }

  /// Import file Excel lên server

}
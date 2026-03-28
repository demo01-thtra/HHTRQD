import 'package:dssstudentfe/Models/score_input.dart';

class Student {
  int? id;
  String studentCode;
  String name;
  String className;
  String email;
  List<ScoreInput>? listPer;

  Student({
    this.id,
    required this.studentCode,
    required this.name,
    required this.className,
    required this.email,
    required this.listPer
  });


  Map<String, dynamic> toJson() {
    return {
      "studentCode": studentCode,
      "name": name,
      "className": className,
      "email":email
    };
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
        id: json["id"]??0,
        studentCode: json["studentCode"]??'',
        name: json["name"]??'',
        className: json["className"]??'',
      email: json["email"]??'',
      listPer: json["performances"] != null
          ? (json["performances"] as List)
          .map((e) => ScoreInput.fromJson(e))
          .toList()
          : [],
    );
  }
}
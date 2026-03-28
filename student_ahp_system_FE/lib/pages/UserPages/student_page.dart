
import 'package:dssstudentfe/Models/student.dart';
import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/score_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:dssstudentfe/pages/UserPages/student_edit_page.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentViewModel>().loadStudents();
      context.read<RiskViewModel>().loadResults();
      context.read<ScoreViewModel>().loadScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentViewModel>(
        builder: (context, vm, child) {

          final students = vm.students;

          /// SEARCH FILTER
          final displayList = searchController.text.isEmpty
              ? students
              : students.where((s) =>
          s.studentCode.toLowerCase().contains(searchController.text.toLowerCase()) ||
              s.name.toLowerCase().contains(searchController.text.toLowerCase()) ||
              s.className.toLowerCase().contains(searchController.text.toLowerCase())
          ).toList();

          return MainLayout(
            currentPage: "/students",
            title: "Quản lý sinh viên",
            body: Padding(
              padding: EdgeInsets.all(20),

              child: Column(
                children: [

                  /// SEARCH + ADD
                  Row(
                    children: [

                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (text){
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            hintText: "Tìm kiếm theo mã SV, tên, lớp...",
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      SizedBox(width: 10),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            onPressed: () {
                              showAddStudentDialog(context);
                            },
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              "Thêm sinh viên",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['xlsx'],
                                withData: true,
                              );

                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final bytes = file.bytes;
                                final fileName = file.name;
                                if (bytes != null) {
                                  try {
                                    // ignore: use_build_context_synchronously
                                    await context.read<StudentViewModel>().importExcelWeb(bytes, fileName);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Import thành công!"))
                                    );
                                  } catch (ex) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Import thất bại: $ex"))
                                    );
                                  }
                                }
                              }
                            },
                            icon: Icon(Icons.upload_file),
                            label: Text("Import Excel"),
                          ),
                          const SizedBox(width: 20,),
                          ElevatedButton(

                            onPressed: context.watch<RiskViewModel>().isLoading?null:()async{
                              await context.read<RiskViewModel>().calculateAll();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Đã tính risk cho tất cả học sinh"))
                              );
                            },
                            child: Text("Tính Risk "),
                          ),
                        ],
                      )
                    ],
                  ),

                  SizedBox(height: 20),

                  /// TABLE
                  Expanded(
                    child: Container(

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 5)
                        ],
                      ),

                      child: vm.isLoading
                          ? Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Mã SV")),
                            DataColumn(label: Text("Họ tên")),
                            DataColumn(label: Text("Lớp")),
                            DataColumn(label: Text("Email")),
                            DataColumn(label: Text("Test")),
                            DataColumn(label: Text("Attendance")),
                            DataColumn(label: Text("Study")),
                            DataColumn(label: Text("AHP Score")),
                            DataColumn(label: Text("Mức rủi ro")),
                            DataColumn(label: Text("Thao tác")),
                          ],

                          rows: displayList.map((s){

                            return DataRow(

                              cells: [

                                DataCell(Text(s.studentCode)),

                                DataCell(Text(s.name)),

                                DataCell(Text(
                                    s.className.isEmpty
                                        ? "Chưa có lớp"
                                        : s.className
                                )),

                                DataCell(Text(
                                    s.email.isEmpty
                                        ? "Chưa có email"
                                        : s.email
                                )),

                                //diem hoc sinh
                                DataCell(
                                  Consumer<ScoreViewModel>(
                                    builder: (context, scoreVm,_){
                                      final score=scoreVm.getScoreByStudent(s.id!);
                                      return Text(score?.testScore.toString()??"-");
                                    },
                                  )
                                ),
                                DataCell(
                                  Consumer<ScoreViewModel>(
                                    builder: (context, scoreVm, _) {
                                      final score = scoreVm.getScoreByStudent(s.id!);
                                      return Text(score?.attendance.toString() ?? "-");
                                    },
                                  ),
                                ),
                                DataCell(
                                  Consumer<ScoreViewModel>(
                                    builder: (context, scoreVm, _) {
                                      final score = scoreVm.getScoreByStudent(s.id!);
                                      return Text(score?.studyHours.toString() ?? "-");
                                    },
                                  ),
                                ),
                                    ////ahp score
                                DataCell(
                                  Consumer<RiskViewModel>(
                                    builder: (context, riskVm, child) {
                                      final risk = riskVm.getRiskByStudent(s.id!);
                                      if (risk == null) return const Text("-");
                                      return Text(
                                        risk.riskScore.toStringAsFixed(4),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ),
                                    ////risk
                                DataCell(
                                  Consumer<RiskViewModel>(
                                    builder: (context, riskVm, child) {

                                      final risk = riskVm.getRiskByStudent(s.id!);

                                      String level = risk?.riskLevel ?? "Chưa tính";

                                      Color color = Colors.grey;

                                      if(level == "High Risk") color = Colors.red;
                                      if(level == "Medium Risk") color = Colors.orange;
                                      if(level == "Low Risk") color = Colors.green;

                                      return Container(
                                        padding: EdgeInsets.symmetric(horizontal:10, vertical:4),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          level,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );

                                    },
                                  ),
                                ),

                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [

                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context)=>StudentEditPage(student: s)));
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text("Xác nhận xóa"),
                                              content: Text("Bạn có chắc muốn xóa sinh viên ${s.name}?"),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Huỷ")),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  onPressed: () => Navigator.pop(ctx, true),
                                                  child: const Text("Xóa", style: TextStyle(color: Colors.white)),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true) {
                                            if (!context.mounted) return;
                                            final ok = await context.read<StudentViewModel>().deleteStudent(s.id!);
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(ok ? "Đã xóa ${s.name}" : "Xóa thất bại")),
                                            );
                                          }
                                        },
                                      ),
                                      //ahp



                                    ],
                                  ),
                                )

                              ],

                            );

                          }).toList(),

                        ),
                      ),
                      ),

                    ),
                  )

                ],
              ),
            ),
          );
        }
    );
  }


  /// ADD STUDENT DIALOG
  void showAddStudentDialog(BuildContext context,{Student? student}){

    TextEditingController code =
    TextEditingController(text: student?.studentCode ?? "");
    TextEditingController name =
    TextEditingController(text: student?.name ?? "");
    TextEditingController className =
    TextEditingController(text: student?.className ?? "");
    TextEditingController email =
    TextEditingController(text: student?.email ?? "");

    showDialog(
        context: context,
        builder: (context){

          return AlertDialog(

            title: Text(student == null
                ? "Thêm sinh viên"
                : "Cập nhật sinh viên"),

            content: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                TextField(
                  controller: code,
                  decoration: InputDecoration(labelText: "Mã SV"),
                ),

                TextField(
                  controller: name,
                  decoration: InputDecoration(labelText: "Họ tên"),
                ),

                TextField(
                  controller: className,
                  decoration: InputDecoration(labelText: "Lớp"),
                ),

                TextField(
                    controller: email,
                    decoration: InputDecoration(labelText: "Email")
                ),

              ],
            ),

            actions: [

              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Huỷ")
              ),

              ElevatedButton(

                onPressed: () async {

                    await context.read<StudentViewModel>().addStudent(
                        code.text,
                        name.text,
                        className.text,
                        email.text
                    );

                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text("Lưu"),
              )

            ],

          );
        }
    );
  }

}

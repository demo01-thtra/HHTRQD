
import 'package:dssstudentfe/Models/student.dart';
import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/score_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:dssstudentfe/pages/UserPages/student_edit_page.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
              padding: const EdgeInsets.all(28),

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
                            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              showAddStudentDialog(context);
                            },
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text("Thêm SV", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
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
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),

                            onPressed: context.watch<RiskViewModel>().isLoading?null:()async{
                              await context.read<RiskViewModel>().calculateAll();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Đã tính risk cho tất cả học sinh"))
                              );
                            },
                            icon: const Icon(Icons.calculate_rounded, size: 20),
                            label: Text("Tính Risk", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// TABLE
                  Expanded(
                    child: Container(

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))
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
                                        padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                        ),
                                        child: Text(
                                          level,
                                          style: GoogleFonts.inter(
                                            color: color,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

            title: Text(student == null
                ? "Thêm sinh viên"
                : "Cập nhật sinh viên",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                TextField(
                  controller: code,
                  decoration: InputDecoration(
                    labelText: "Mã SV",
                    prefixIcon: const Icon(Icons.badge_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: "Họ tên",
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: className,
                  decoration: InputDecoration(
                    labelText: "Lớp",
                    prefixIcon: const Icon(Icons.class_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_rounded, size: 20),
                    )
                ),

              ],
            ),

            actions: [

              TextButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: Text("Huỷ", style: GoogleFonts.inter(color: const Color(0xFF94A3B8)))
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),

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

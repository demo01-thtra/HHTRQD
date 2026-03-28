import 'package:dssstudentfe/Models/student.dart';
import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/score_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';


class StudentEditPage extends StatefulWidget {

  final Student student;

  const StudentEditPage({super.key, required this.student});

  @override
  State<StudentEditPage> createState() => _StudentEditPageState();
}

class _StudentEditPageState extends State<StudentEditPage> {

  late TextEditingController codeController;
  late TextEditingController nameController;
  late TextEditingController classController;
  late TextEditingController emailController;
  late TextEditingController testScoreController;
  late TextEditingController attendanceController;
  late TextEditingController studyHoursController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    codeController = TextEditingController(text: widget.student.studentCode);
    nameController = TextEditingController(text: widget.student.name);
    classController = TextEditingController(text: widget.student.className);
    emailController = TextEditingController(text: widget.student.email);

    final perf = widget.student.listPer?.isNotEmpty == true
        ? widget.student.listPer!.last
        : null;
    testScoreController = TextEditingController(text: perf?.testScore.toString() ?? '');
    attendanceController = TextEditingController(text: perf?.attendance.toString() ?? '');
    studyHoursController = TextEditingController(text: perf?.studyHours.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Chỉnh sửa sinh viên",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 600,
            margin: const EdgeInsets.symmetric(vertical: 28),
            padding: const EdgeInsets.all(32),
          
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
          
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
          
              children: [
          
                /// TITLE
                Text(
                  "Chỉnh sửa thông tin sinh viên",
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
          
                const SizedBox(height: 6),
          
                Text(
                  "Cập nhật thông tin của sinh viên ${widget.student.studentCode}",
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                ),
          
                SizedBox(height: 25),
          
                /// STUDENT CODE
                Text("Mã sinh viên"),
          
                SizedBox(height: 6),
          
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(),
                  ),
                ),
          
                SizedBox(height: 16),
          
                /// NAME
                Text("Họ tên"),
          
                SizedBox(height: 6),
          
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(),
                  ),
                ),
          
                SizedBox(height: 16),
          
                /// CLASS
                Text("Lớp"),
          
                SizedBox(height: 6),
          
                TextField(
                  controller: classController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                /// EMAIL
                Text("Email"),
                SizedBox(height: 6),
          
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(),
                  ),
                ),
          
                SizedBox(height: 25),

                /// PERFORMANCE FIELDS
                Text("Dữ liệu học tập", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),

                Text("Điểm kiểm tra"),
                SizedBox(height: 6),
                TextField(
                  controller: testScoreController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.orange.shade50,
                    border: OutlineInputBorder(),
                    hintText: "VD: 7.5",
                  ),
                ),

                SizedBox(height: 16),

                Text("Chuyên cần (%)"),
                SizedBox(height: 6),
                TextField(
                  controller: attendanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.orange.shade50,
                    border: OutlineInputBorder(),
                    hintText: "VD: 85",
                  ),
                ),

                SizedBox(height: 16),

                Text("Giờ học/ngày"),
                SizedBox(height: 6),
                TextField(
                  controller: studyHoursController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.orange.shade50,
                    border: OutlineInputBorder(),
                    hintText: "VD: 3",
                  ),
                ),

                SizedBox(height: 16),

                Divider(),
                Consumer<RiskViewModel>(
                  builder: (context, riskVm, child) {

                    final risk = riskVm.getRiskByStudent(widget.student.id!);

                    if(risk == null){
                      return Text(
                        "Chưa tính Risk AHP",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    Color color = Colors.green;

                    if(risk.riskLevel == "High Risk") color = Colors.red;
                    if(risk.riskLevel == "Medium Risk") color = Colors.orange;

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),

                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        
                            Text(
                              "Kết quả AHP",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                        
                            SizedBox(height: 10),
                        
                            Text("Risk Score: ${risk.riskScore.toStringAsFixed(2)}"),
                        
                            Text(
                              "Risk Level: ${risk.riskLevel}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 16,
                              ),
                            ),
                        
                          ],
                        ),
                      ),
                    );
                  },
                ),
                ///ket thuc
                Divider(),
          
                SizedBox(height: 10),
          
                /// BUTTONS
                Row(
          
                  children: [
          
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
          
                        onPressed: _isSaving ? null : () async {
                        final scoreText = testScoreController.text.trim();
                        final attText = attendanceController.text.trim();
                        final hoursText = studyHoursController.text.trim();

                        if (scoreText.isEmpty || attText.isEmpty || hoursText.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Vui lòng nhập đầy đủ dữ liệu học tập")),
                          );
                          return;
                        }

                        final score = double.tryParse(scoreText);
                        final att = double.tryParse(attText);
                        final hours = double.tryParse(hoursText);

                        if (score == null || att == null || hours == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Dữ liệu không hợp lệ")),
                          );
                          return;
                        }

                        setState(() => _isSaving = true);

                        try {
                          // 0. Lưu thông tin sinh viên (tên, mã, lớp, email)
                          await context.read<StudentViewModel>().updateStudent(
                            widget.student.id!,
                            codeController.text.trim(),
                            nameController.text.trim(),
                            classController.text.trim(),
                            emailController.text.trim(),
                          );

                          if (!context.mounted) return;

                          // 1. Lưu điểm
                          await context.read<ScoreViewModel>().submitScore(
                            widget.student.id!,
                            score,
                            att,
                            hours,
                          );

                          if (!context.mounted) return;

                          // 2. Tính AHP ngay
                          await context.read<RiskViewModel>().calculateRisk(widget.student.id!);

                          if (!context.mounted) return;

                          setState(() => _isSaving = false);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Đã lưu điểm & tính AHP thành công!"), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          setState(() => _isSaving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
                          );
                        }
                      },
          
                        icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          _isSaving ? "Đang lưu..." : "Lưu & Tính AHP",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
          
                    const SizedBox(width: 12),
          
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
          
                      onPressed: () {
                        Navigator.pop(context);
                      },
          
                      child: Text("Hủy"),
                    )
          
                  ],
                )
          
              ],
            ),
          ),
        ),
      ),
    );
  }
}
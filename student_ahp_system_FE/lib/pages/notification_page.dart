import 'package:dssstudentfe/Services/notification_service.dart';
import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/score_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Track which students have been sent notifications
  final Map<int, DateTime> _sentNotifications = {};
  final NotificationService _notificationService = NotificationService();
  String _filterLevel = "Tất cả";
  bool _isSendingAll = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentViewModel>().loadStudents();
      context.read<RiskViewModel>().loadResults();
      context.read<ScoreViewModel>().loadScores();
    });
  }

  List<_WarningStudent> _getWarningStudents() {
    final studentVm = context.read<StudentViewModel>();
    final riskVm = context.read<RiskViewModel>();
    final scoreVm = context.read<ScoreViewModel>();

    final list = <_WarningStudent>[];

    for (var s in studentVm.students) {
      if (s.id == null) continue;
      final risk = riskVm.getRiskByStudent(s.id!);
      if (risk == null) continue;
      if (risk.riskLevel != "High Risk" && risk.riskLevel != "Medium Risk") continue;

      final score = scoreVm.getScoreByStudent(s.id!);

      list.add(_WarningStudent(
        studentId: s.id!,
        studentCode: s.studentCode,
        name: s.name,
        className: s.className,
        email: s.email,
        riskLevel: risk.riskLevel,
        riskScore: risk.riskScore,
        testScore: score?.testScore,
        attendance: score?.attendance,
        studyHours: score?.studyHours,
      ));
    }

    // Sort: High Risk first, then by score descending
    list.sort((a, b) {
      if (a.riskLevel == "High Risk" && b.riskLevel != "High Risk") return -1;
      if (a.riskLevel != "High Risk" && b.riskLevel == "High Risk") return 1;
      return b.riskScore.compareTo(a.riskScore);
    });

    if (_filterLevel == "High Risk") {
      return list.where((s) => s.riskLevel == "High Risk").toList();
    } else if (_filterLevel == "Medium Risk") {
      return list.where((s) => s.riskLevel == "Medium Risk").toList();
    }
    return list;
  }

  String _buildWarningMessage(_WarningStudent s) {
    final parts = <String>[];
    parts.add("Kính gửi sinh viên ${s.name} (${s.studentCode}),");
    parts.add("");

    if (s.riskLevel == "High Risk") {
      parts.add("⚠️ CẢNH BÁO NGHIÊM TRỌNG: Bạn đang ở mức RỦI RO CAO (${s.riskScore.toStringAsFixed(2)}) về nguy cơ rớt môn.");
    } else {
      parts.add("⚠️ CẢNH BÁO: Bạn đang ở mức RỦI RO TRUNG BÌNH (${s.riskScore.toStringAsFixed(2)}) về nguy cơ rớt môn.");
    }
    parts.add("");

    // Add specific warnings
    final warnings = <String>[];
    if (s.testScore != null && s.testScore! < 5) {
      warnings.add("• Điểm kiểm tra thấp: ${s.testScore} (cần cải thiện)");
    }
    if (s.attendance != null && s.attendance! < 80) {
      warnings.add("• Tỷ lệ chuyên cần thấp: ${s.attendance}% (yêu cầu tối thiểu 80%)");
    }
    if (s.studyHours != null && s.studyHours! < 2) {
      warnings.add("• Thời gian tự học ít: ${s.studyHours} giờ/ngày (khuyến nghị tối thiểu 2 giờ)");
    }

    if (warnings.isNotEmpty) {
      parts.add("Chi tiết:");
      parts.addAll(warnings);
      parts.add("");
    }

    parts.add("Đề xuất:");
    if (s.testScore != null && s.testScore! < 5) {
      parts.add("• Tăng cường ôn tập, tham gia nhóm học tập");
    }
    if (s.attendance != null && s.attendance! < 80) {
      parts.add("• Đi học đầy đủ, không bỏ buổi");
    }
    if (s.studyHours != null && s.studyHours! < 2) {
      parts.add("• Lập kế hoạch tự học, tăng thời gian học mỗi ngày");
    }
    if (s.riskLevel == "High Risk") {
      parts.add("• Liên hệ cố vấn học tập để được hỗ trợ");
    }

    parts.add("");
    parts.add("Trân trọng,");
    parts.add("Hệ thống Cảnh Báo Sớm DSS");

    return parts.join("\n");
  }

  void _sendNotification(_WarningStudent s) {
    final message = _buildWarningMessage(s);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              s.riskLevel == "High Risk" ? Icons.warning : Icons.info,
              color: s.riskLevel == "High Risk" ? Colors.red : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text("Gửi cảnh báo - ${s.name}")),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text("Gửi đến: ${s.email.isNotEmpty ? s.email : 'Chưa có email'}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Nội dung thông báo:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    message,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Huỷ"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () async {
              Navigator.pop(ctx);

              final subject = s.riskLevel == "High Risk"
                  ? "⚠️ CẢNH BÁO NGHIÊM TRỌNG - Nguy cơ rớt môn"
                  : "⚠️ Cảnh báo - Nguy cơ rớt môn";

              final result = await _notificationService.sendEmail(
                s.studentId,
                subject,
                message,
              );

              if (!mounted) return;

              if (result["success"] == true) {
                setState(() {
                  _sentNotifications[s.studentId] = DateTime.now();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("✅ Đã gửi email cảnh báo cho ${s.name} (${s.email})"),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Lỗi gửi email: ${result["error"]}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.send, color: Colors.white),
            label: const Text("Gửi thông báo", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _sendAllNotifications(List<_WarningStudent> students) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận gửi hàng loạt"),
        content: Text("Bạn có chắc muốn gửi thông báo cảnh báo cho tất cả ${students.length} sinh viên có nguy cơ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Huỷ")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Gửi tất cả", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSendingAll = true);

    int successCount = 0;
    int failCount = 0;

    try {
      final emails = students.map((s) {
        final message = _buildWarningMessage(s);
        final subject = s.riskLevel == "High Risk"
            ? "⚠️ CẢNH BÁO NGHIÊM TRỌNG - Nguy cơ rớt môn"
            : "⚠️ Cảnh báo - Nguy cơ rớt môn";
        return {
          "studentId": s.studentId,
          "subject": subject,
          "body": message,
        };
      }).toList();

      final results = await _notificationService.sendBatch(emails);

      for (var r in results) {
        if (r["success"] == true) {
          _sentNotifications[r["studentId"] as int] = DateTime.now();
          successCount++;
        } else {
          failCount++;
        }
      }
    } catch (e) {
      // If batch fails, try individually
      for (var s in students) {
        final message = _buildWarningMessage(s);
        final subject = s.riskLevel == "High Risk"
            ? "⚠️ CẢNH BÁO NGHIÊM TRỌNG - Nguy cơ rớt môn"
            : "⚠️ Cảnh báo - Nguy cơ rớt môn";
        final result = await _notificationService.sendEmail(s.studentId, subject, message);
        if (result["success"] == true) {
          _sentNotifications[s.studentId] = DateTime.now();
          successCount++;
        } else {
          failCount++;
        }
      }
    }

    setState(() => _isSendingAll = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failCount == 0
            ? "✅ Đã gửi email cho $successCount sinh viên"
            : "⚠️ Gửi thành công: $successCount, thất bại: $failCount"),
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPage: "/notifications",
      title: "📢 Thông báo cảnh cáo",
      body: Consumer3<StudentViewModel, RiskViewModel, ScoreViewModel>(
        builder: (context, studentVm, riskVm, scoreVm, _) {
          if (studentVm.isLoading || riskVm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final warningStudents = _getWarningStudents();
          final highCount = warningStudents.where((s) => s.riskLevel == "High Risk").length;
          final mediumCount = warningStudents.where((s) => s.riskLevel == "Medium Risk").length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.red.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "📢 Hệ thống Thông báo Cảnh cáo",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Gửi thông báo cảnh cáo cho sinh viên có nguy cơ rớt môn cao",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildStatChip("🔴 Nguy cơ cao", highCount, Colors.red.shade300),
                          const SizedBox(width: 12),
                          _buildStatChip("🟠 Nguy cơ TB", mediumCount, Colors.orange.shade300),
                          const SizedBox(width: 12),
                          _buildStatChip("📊 Tổng cảnh báo", warningStudents.length, Colors.white24),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Actions bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      // Filter
                      const Text("Lọc: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("Tất cả"),
                        selected: _filterLevel == "Tất cả",
                        onSelected: (_) => setState(() => _filterLevel = "Tất cả"),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("🔴 High Risk"),
                        selected: _filterLevel == "High Risk",
                        onSelected: (_) => setState(() => _filterLevel = "High Risk"),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("🟠 Medium Risk"),
                        selected: _filterLevel == "Medium Risk",
                        onSelected: (_) => setState(() => _filterLevel = "Medium Risk"),
                      ),

                      const Spacer(),

                      // Send all button
                      ElevatedButton.icon(
                        onPressed: warningStudents.isEmpty || _isSendingAll
                            ? null
                            : () => _sendAllNotifications(warningStudents),
                        icon: _isSendingAll
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, color: Colors.white),
                        label: Text(
                          _isSendingAll ? "Đang gửi..." : "Gửi tất cả (${warningStudents.length})",
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Student warning list
                if (warningStudents.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 48),
                        SizedBox(height: 12),
                        Text(
                          "Không có sinh viên nào cần cảnh báo!",
                          style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  ...warningStudents.map((s) => _buildStudentWarningCard(s)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "$label: $count",
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStudentWarningCard(_WarningStudent s) {
    final isSent = _sentNotifications.containsKey(s.studentId);
    final sentTime = _sentNotifications[s.studentId];

    final isHigh = s.riskLevel == "High Risk";
    final borderColor = isHigh ? Colors.red : Colors.orange;
    final bgColor = isHigh ? Colors.red.shade50 : Colors.orange.shade50;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        children: [
          // Risk icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHigh ? Icons.warning : Icons.info_outline,
              color: borderColor,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.riskLevel,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "Mã SV: ${s.studentCode}  |  Lớp: ${s.className.isNotEmpty ? s.className : '-'}  |  Email: ${s.email.isNotEmpty ? s.email : 'Chưa có'}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniStat("Điểm KT", s.testScore != null ? "${s.testScore}" : "-", s.testScore != null && s.testScore! < 5 ? Colors.red : Colors.black54),
                    const SizedBox(width: 16),
                    _buildMiniStat("Chuyên cần", s.attendance != null ? "${s.attendance}%" : "-", s.attendance != null && s.attendance! < 80 ? Colors.red : Colors.black54),
                    const SizedBox(width: 16),
                    _buildMiniStat("Giờ học", s.studyHours != null ? "${s.studyHours}h" : "-", s.studyHours != null && s.studyHours! < 2 ? Colors.red : Colors.black54),
                    const SizedBox(width: 16),
                    _buildMiniStat("Risk Score", s.riskScore.toStringAsFixed(2), borderColor),
                  ],
                ),
              ],
            ),
          ),

          // Send status / button
          Column(
            children: [
              if (isSent) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(height: 4),
                      const Text("Đã gửi", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(
                        "${sentTime!.hour}:${sentTime.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(color: Colors.green.shade700, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
              ElevatedButton.icon(
                onPressed: () => _sendNotification(s),
                icon: Icon(isSent ? Icons.replay : Icons.send, size: 16, color: Colors.white),
                label: Text(
                  isSent ? "Gửi lại" : "Gửi cảnh báo",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSent ? Colors.grey : borderColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ],
    );
  }
}

class _WarningStudent {
  final int studentId;
  final String studentCode;
  final String name;
  final String className;
  final String email;
  final String riskLevel;
  final double riskScore;
  final double? testScore;
  final double? attendance;
  final double? studyHours;

  _WarningStudent({
    required this.studentId,
    required this.studentCode,
    required this.name,
    required this.className,
    required this.email,
    required this.riskLevel,
    required this.riskScore,
    this.testScore,
    this.attendance,
    this.studyHours,
  });
}

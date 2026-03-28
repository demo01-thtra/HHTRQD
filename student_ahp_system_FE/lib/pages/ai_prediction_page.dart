import 'package:dssstudentfe/ViewModels/ai_viewmodel.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AiPredictionPage extends StatefulWidget {
  const AiPredictionPage({super.key});

  @override
  State<AiPredictionPage> createState() => _AiPredictionPageState();
}

class _AiPredictionPageState extends State<AiPredictionPage> {
  final testScoreController = TextEditingController();
  final attendanceController = TextEditingController();
  final studyHoursController = TextEditingController();

  // Threshold controllers
  final scoreHardCtrl = TextEditingController(text: "4.0");
  final attendHardCtrl = TextEditingController(text: "65.0");
  final studyHardCtrl = TextEditingController(text: "2.0");
  final scoreAttendScoreCtrl = TextEditingController(text: "5.0");
  final scoreAttendAttCtrl = TextEditingController(text: "75.0");
  final scoreStudyScoreCtrl = TextEditingController(text: "5.5");
  final scoreStudyHoursCtrl = TextEditingController(text: "2.5");
  final attendStudyAttCtrl = TextEditingController(text: "70.0");
  final attendStudyHoursCtrl = TextEditingController(text: "3.0");

  bool _showThresholdConfig = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AiViewModel>();
      vm.loadModelInfo();
      vm.loadStudentsAndPredict();
      vm.loadThresholds().then((_) => _applyThresholdsToControllers(vm));
    });
  }

  void _applyThresholdsToControllers(AiViewModel vm) {
    final t = vm.thresholds;
    if (t == null) return;
    scoreHardCtrl.text = "${t['scoreHard'] ?? 4.0}";
    attendHardCtrl.text = "${t['attendHard'] ?? 65.0}";
    studyHardCtrl.text = "${t['studyHard'] ?? 2.0}";
    final sa = t['scoreAttend'] ?? [5.0, 75.0];
    scoreAttendScoreCtrl.text = "${sa[0]}";
    scoreAttendAttCtrl.text = "${sa[1]}";
    final ss = t['scoreStudy'] ?? [5.5, 2.5];
    scoreStudyScoreCtrl.text = "${ss[0]}";
    scoreStudyHoursCtrl.text = "${ss[1]}";
    final as2 = t['attendStudy'] ?? [70.0, 3.0];
    attendStudyAttCtrl.text = "${as2[0]}";
    attendStudyHoursCtrl.text = "${as2[1]}";
  }

  @override
  void dispose() {
    testScoreController.dispose();
    attendanceController.dispose();
    studyHoursController.dispose();
    scoreHardCtrl.dispose();
    attendHardCtrl.dispose();
    studyHardCtrl.dispose();
    scoreAttendScoreCtrl.dispose();
    scoreAttendAttCtrl.dispose();
    scoreStudyScoreCtrl.dispose();
    scoreStudyHoursCtrl.dispose();
    attendStudyAttCtrl.dispose();
    attendStudyHoursCtrl.dispose();
    super.dispose();
  }

  void _predict() {
    final testScore = double.tryParse(testScoreController.text);
    final attendance = double.tryParse(attendanceController.text);
    final studyHours = double.tryParse(studyHoursController.text);

    if (testScore == null || attendance == null || studyHours == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ và đúng định dạng số")),
      );
      return;
    }

    context.read<AiViewModel>().predict(
          testScore: testScore,
          attendance: attendance,
          studyHours: studyHours,
        );
  }

  void _retrain() {
    final thresholds = {
      "scoreHard": double.tryParse(scoreHardCtrl.text) ?? 4.0,
      "attendHard": double.tryParse(attendHardCtrl.text) ?? 65.0,
      "studyHard": double.tryParse(studyHardCtrl.text) ?? 2.0,
      "scoreAttend": [
        double.tryParse(scoreAttendScoreCtrl.text) ?? 5.0,
        double.tryParse(scoreAttendAttCtrl.text) ?? 75.0,
      ],
      "scoreStudy": [
        double.tryParse(scoreStudyScoreCtrl.text) ?? 5.5,
        double.tryParse(scoreStudyHoursCtrl.text) ?? 2.5,
      ],
      "attendStudy": [
        double.tryParse(attendStudyAttCtrl.text) ?? 70.0,
        double.tryParse(attendStudyHoursCtrl.text) ?? 3.0,
      ],
    };
    context.read<AiViewModel>().retrain(thresholds);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPage: "/ai-predict",
      title: "🤖 AI Dự đoán nguy cơ",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Consumer<AiViewModel>(
          builder: (context, vm, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🌳 Decision Tree – Dự đoán Pass / Fail",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Cây quyết định (Decision Tree) phân loại Pass/Fail bằng các quy tắc if-else\n"
                        "được học tự động từ dữ liệu huấn luyện (Gini splitting).\n"
                        "Đầu vào: Điểm kiểm tra, Chuyên cần (%), Giờ tự học/ngày",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      if (vm.modelInfo != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          runSpacing: 4,
                          children: [
                            _buildModelInfoChip("Loại", "${vm.modelInfo!['modelType']}", Icons.account_tree),
                            _buildModelInfoChip("Độ sâu", "${vm.modelInfo!['depth']}", Icons.layers),
                            _buildModelInfoChip("Số lá", "${vm.modelInfo!['nLeaves']}", Icons.eco),
                            _buildModelInfoChip("Tiêu chí", "Gini", Icons.auto_graph),
                          ],
                        ),
                        if (vm.modelInfo!['dtDescription'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            "${vm.modelInfo!['dtDescription']}",
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Input form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📝 Nhập thông tin sinh viên",
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: testScoreController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Điểm kiểm tra (0-10)",
                                prefixIcon: const Icon(Icons.school),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: attendanceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Chuyên cần (%)",
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: studyHoursController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Giờ học/ngày",
                                prefixIcon: const Icon(Icons.access_time),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: vm.isLoading ? null : _predict,
                          icon: vm.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.psychology_rounded, color: Colors.white),
                          label: Text(
                            vm.isLoading ? "Đang dự đoán..." : "🔮 Dự đoán nguy cơ",
                            style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Error
                if (vm.error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(vm.error, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Threshold config (collapsible)
                _buildThresholdConfigSection(vm),

                // Results
                if (vm.prediction != null) ...[
                  const SizedBox(height: 24),
                  _buildResultSection(vm),
                ],

                const SizedBox(height: 32),

                // Student list with AI risk
                _buildStudentListSection(vm),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStudentListSection(AiViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "📋 Danh sách sinh viên – Dự đoán AI toàn bộ",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: vm.isBatchLoading ? null : () {
                  context.read<AiViewModel>().loadStudentsAndPredict();
                },
                icon: vm.isBatchLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.psychology, color: Colors.white, size: 18),
                label: Text(
                  vm.isBatchLoading ? "Đang dự đoán..." : "🔮 Dự đoán tất cả",
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            "Dự đoán Pass/Fail + AHP Risk cho tất cả sinh viên trong hệ thống",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),

          if (vm.isBatchLoading && vm.students.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (vm.students.isEmpty)
            const Center(child: Text("Không có sinh viên nào", style: TextStyle(color: Colors.grey)))
          else
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(Colors.blue.shade50),
                      columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text("STT", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Mã SV", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Họ tên", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Lớp", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Điểm KT", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Chuyên cần", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Giờ học", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("DT Result", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("P(Rớt)", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("AHP Score", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Final Score", style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text("Mức rủi ro", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: List.generate(vm.students.length, (i) {
                  final s = vm.students[i];
                  final score = vm.scoreMap[s.id];
                  final result = s.id != null ? vm.getBatchResultByStudent(s.id!) : null;

                  String dtPred = result?["dtPrediction"] ?? "-";
                  Color dtColor = dtPred == "Fail" ? Colors.red : (dtPred == "Pass" ? Colors.green : Colors.grey);

                  String riskLevel = result?["riskLevel"] ?? "-";
                  Color riskColor = riskLevel.contains("High") ? Colors.red
                      : riskLevel.contains("Medium") ? Colors.orange
                      : riskLevel.contains("Low") ? Colors.green : Colors.grey;

                  return DataRow(
                    color: WidgetStateProperty.all(i % 2 == 0 ? Colors.white : Colors.grey.shade50),
                    cells: [
                      DataCell(Text("${i + 1}")),
                      DataCell(Text(s.studentCode)),
                      DataCell(Text(s.name)),
                      DataCell(Text(s.className.isEmpty ? "-" : s.className)),
                      DataCell(Text(score?.testScore.toString() ?? "-")),
                      DataCell(Text(score != null ? "${score.attendance}%" : "-")),
                      DataCell(Text(score != null ? "${score.studyHours}h" : "-")),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: dtColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dtPred,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(Text(
                        result != null ? "${((result["pFail"] ?? 0) * 100).toStringAsFixed(1)}%" : "-",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (result?["pFail"] ?? 0) >= 0.5 ? Colors.red : Colors.green,
                        ),
                      )),
                      DataCell(Text(
                        result != null ? (result["ahpScore"] as num).toStringAsFixed(4) : "-",
                      )),
                      DataCell(Text(
                        result != null ? (result["finalScore"] as num).toStringAsFixed(4) : "-",
                        style: TextStyle(fontWeight: FontWeight.bold, color: riskColor),
                      )),
                      DataCell(
                        result != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: riskColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  riskLevel,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              )
                            : const Text("-"),
                      ),
                    ],
                  );
                }),
                  ),
                ),
              );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildResultSection(AiViewModel vm) {
    final p = vm.prediction!;

    final bool isDtFail = p.dtPrediction == "Fail";
    final Color dtColor = isDtFail ? Colors.red : Colors.green;
    final IconData dtIcon = isDtFail ? Icons.cancel : Icons.check_circle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DT Pass/Fail card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: dtColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: dtColor.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(dtIcon, color: dtColor, size: 56),
              const SizedBox(height: 8),
              const Text("🌳 Decision Tree – Kết quả dự đoán", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                p.dtPrediction,
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: dtColor),
              ),
              const SizedBox(height: 8),
              Text(
                "Xác suất rớt: ${(p.pFail * 100).toStringAsFixed(1)}%",
                style: TextStyle(fontSize: 16, color: dtColor.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // P(Rớt) score card
        _buildScoreCard("📊 P(Rớt) – Xác suất rớt từ Decision Tree", p.pFail, Colors.blue),

        const SizedBox(height: 16),

        // Input summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📋 Thông tin đầu vào", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoChip("Điểm KT", "${p.testScore}", Icons.school),
                  _buildInfoChip("Chuyên cần", "${p.attendance}%", Icons.calendar_today),
                  _buildInfoChip("Giờ học", "${p.studyHours}h", Icons.access_time),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Decision Tree Rules
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🌳 Decision Tree - Đường đi quyết định", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...p.rules.asMap().entries.map((e) {
                int idx = e.key;
                String rule = e.value;
                bool isLeaf = rule.startsWith("Kết luận");
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isLeaf ? Colors.green : Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            isLeaf ? "✓" : "${idx + 1}",
                            style: TextStyle(
                              color: isLeaf ? Colors.white : Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isLeaf ? Colors.green.shade50 : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            rule,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isLeaf ? FontWeight.bold : FontWeight.normal,
                              color: isLeaf ? Colors.green.shade800 : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Feature Importance
        if (p.featureImportance.isNotEmpty)
          _buildFeatureImportanceSection(p.featureImportance),

        const SizedBox(height: 16),

        // Warning & Suggestion
        if (isDtFail) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: dtColor),
                    const SizedBox(width: 8),
                    Text("Cảnh báo & Đề xuất", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dtColor)),
                  ],
                ),
                if (p.warningReason.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text("❗ ${p.warningReason}", style: const TextStyle(fontSize: 14)),
                ],
                if (p.suggestion.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text("💡 ${p.suggestion}", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "✅ Sinh viên không có nguy cơ rớt môn. Tiếp tục duy trì!",
                    style: TextStyle(fontSize: 15, color: Colors.green),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScoreCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            value.toStringAsFixed(4),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 24),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModelInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 4),
          Text("$label: ", style: const TextStyle(color: Colors.white60, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildThresholdConfigSection(AiViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showThresholdConfig = !_showThresholdConfig),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "⚙️ Cấu hình ngưỡng tiêu chí (Label Rule)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Icon(_showThresholdConfig ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          if (!_showThresholdConfig)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                "Nhấn để mở — Tùy chỉnh ngưỡng rớt cho từng tiêu chí → Huấn luyện lại mô hình",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          if (_showThresholdConfig) ...[
            const SizedBox(height: 12),
            const Text(
              "🔴 Ngưỡng rớt nặng (1 tiêu chí quá yếu)",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _thresholdField(scoreHardCtrl, "Điểm < X → Rớt", Icons.school)),
                const SizedBox(width: 12),
                Expanded(child: _thresholdField(attendHardCtrl, "Chuyên cần < X% → Rớt", Icons.calendar_today)),
                const SizedBox(width: 12),
                Expanded(child: _thresholdField(studyHardCtrl, "Giờ học < X → Rớt", Icons.access_time)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              "🟡 Ngưỡng rớt kết hợp (2 tiêu chí yếu cùng lúc)",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _comboPair("Điểm <", scoreAttendScoreCtrl, "AND Chuyên cần <", scoreAttendAttCtrl, "%"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _comboPair("Điểm <", scoreStudyScoreCtrl, "AND Giờ học <", scoreStudyHoursCtrl, "h"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _comboPair("Chuyên cần <", attendStudyAttCtrl, "% AND Giờ học <", attendStudyHoursCtrl, "h"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: vm.isRetraining ? null : _retrain,
                icon: vm.isRetraining
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.model_training, color: Colors.white),
                label: Text(
                  vm.isRetraining ? "Đang huấn luyện..." : "🔄 Huấn luyện lại mô hình",
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            // Retrain result
            if (vm.retrainResult != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "✅ Huấn luyện thành công! Accuracy: ${((vm.retrainResult!['accuracy'] ?? 0) * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Depth: ${vm.retrainResult!['depth']}, Leaves: ${vm.retrainResult!['nLeaves']} | "
                      "Fail: ${vm.retrainResult!['labelDistribution']?['fail']}, "
                      "Pass: ${vm.retrainResult!['labelDistribution']?['pass']}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _thresholdField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey.shade50,
        isDense: true,
      ),
    );
  }

  Widget _comboPair(String label1, TextEditingController ctrl1, String label2, TextEditingController ctrl2, String suffix) {
    return Row(
      children: [
        Text(label1, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: TextField(
            controller: ctrl1,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label2, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: TextField(
            controller: ctrl2,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            ),
          ),
        ),
        Text(suffix, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _buildFeatureImportanceSection(Map<String, double> importance) {
    final labelMap = {
      "Test_Score": "Điểm kiểm tra",
      "Attendance (%)": "Chuyên cần (%)",
      "Study_Hours": "Giờ tự học",
    };
    final colorMap = {
      "Test_Score": Colors.red.shade400,
      "Attendance (%)": Colors.orange.shade400,
      "Study_Hours": Colors.blue.shade400,
    };

    final sorted = importance.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.isNotEmpty ? sorted.first.value : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "📊 Feature Importance (Mức đóng góp - Gini)",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            "Đặc trưng nào ảnh hưởng nhiều nhất đến quyết định Pass/Fail của cây",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...sorted.map((e) {
            final label = labelMap[e.key] ?? e.key;
            final color = colorMap[e.key] ?? Colors.grey;
            final pct = (e.value * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text("$pct%", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: maxVal > 0 ? e.value / maxVal : 0,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

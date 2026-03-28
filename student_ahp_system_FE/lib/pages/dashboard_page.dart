import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiskViewModel>().loadSummary();
      context.read<RiskViewModel>().loadTopRisk();
      context.read<RiskViewModel>().loadResults();
      context.read<StudentViewModel>().loadStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPage: "/dashboard",
      title: "Dashboard",
      body: Consumer2<RiskViewModel, StudentViewModel>(
        builder: (context, riskVm, studentVm, _) {
          if (riskVm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (riskVm.summary == null) {
            return const Center(child: Text("Chưa có dữ liệu. Hãy tính AHP trước."));
          }

          final total = riskVm.summary!['total'] ?? 0;
          final high = riskVm.summary!['high'] ?? 0;
          final medium = riskVm.summary!['medium'] ?? 0;
          final low = riskVm.summary!['low'] ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hệ thống Cảnh Báo Sớm DSS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Phân tích rủi ro sinh viên bằng AHP & AI | Tổng: $total sinh viên",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Summary cards row
                Row(
                  children: [
                    _buildSummaryCard(
                      icon: Icons.people,
                      label: "Tổng sinh viên",
                      value: total,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      icon: Icons.check_circle,
                      label: "Rủi ro thấp",
                      value: low,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      icon: Icons.warning_amber,
                      label: "Rủi ro TB",
                      value: medium,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      icon: Icons.dangerous,
                      label: "Rủi ro cao",
                      value: high,
                      color: Colors.red,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Charts row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pie chart
                    Expanded(
                      flex: 1,
                      child: _buildChartCard(
                        title: "Phân bổ mức rủi ro",
                        child: SizedBox(
                          height: 260,
                          child: total > 0
                              ? PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 50,
                                    sections: [
                                      PieChartSectionData(
                                        value: low.toDouble(),
                                        title: low > 0 ? "Low\n$low" : "",
                                        color: Colors.green.shade400,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: medium.toDouble(),
                                        title: medium > 0 ? "Med\n$medium" : "",
                                        color: Colors.orange.shade400,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      PieChartSectionData(
                                        value: high.toDouble(),
                                        title: high > 0 ? "High\n$high" : "",
                                        color: Colors.red.shade400,
                                        radius: 60,
                                        titleStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const Center(child: Text("Không có dữ liệu")),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Bar chart
                    Expanded(
                      flex: 1,
                      child: _buildChartCard(
                        title: "Biểu đồ cột rủi ro",
                        child: SizedBox(
                          height: 260,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: (total > 0 ? total.toDouble() : 10) * 1.2,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final labels = ["Low Risk", "Medium Risk", "High Risk"];
                                    return BarTooltipItem(
                                      "${labels[group.x]}\n${rod.toY.toInt()} SV",
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      if (value == value.roundToDouble()) {
                                        return Text("${value.toInt()}", style: const TextStyle(fontSize: 11));
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text("Low", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                        case 1:
                                          return const Text("Medium", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                        case 2:
                                          return const Text("High", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12));
                                      }
                                      return const Text("");
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 1,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.grey.shade200,
                                  strokeWidth: 1,
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: low.toDouble(),
                                    color: Colors.green.shade400,
                                    width: 40,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: medium.toDouble(),
                                    color: Colors.orange.shade400,
                                    width: 40,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                ]),
                                BarChartGroupData(x: 2, barRods: [
                                  BarChartRodData(
                                    toY: high.toDouble(),
                                    color: Colors.red.shade400,
                                    width: 40,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Top risk students table
                _buildChartCard(
                  title: "🔴 Sinh viên nguy cơ cao nhất",
                  child: riskVm.topRisk.isNotEmpty
                      ? DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text("STT", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Mã SV", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Họ tên", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Lớp", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Risk Score", style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text("Mức rủi ro", style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: List.generate(riskVm.topRisk.length, (i) {
                            final risk = riskVm.topRisk[i];
                            final student = studentVm.students.where((s) => s.id == risk.studentId).firstOrNull;
                            final isHigh = risk.riskLevel == "High Risk";

                            return DataRow(
                              color: WidgetStateProperty.all(
                                i % 2 == 0 ? Colors.white : Colors.grey.shade50,
                              ),
                              cells: [
                                DataCell(Text("${i + 1}")),
                                DataCell(Text(student?.studentCode ?? "-")),
                                DataCell(Text(student?.name ?? "SV #${risk.studentId}")),
                                DataCell(Text(student?.className ?? "-")),
                                DataCell(
                                  Text(
                                    risk.riskScore.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isHigh ? Colors.red : Colors.orange,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isHigh ? Colors.red : Colors.orange,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      risk.riskLevel,
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        )
                      : const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("Chưa có dữ liệu top risk. Hãy tính AHP trước."),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
          ],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$value",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
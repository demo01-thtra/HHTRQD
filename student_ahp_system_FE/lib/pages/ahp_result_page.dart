import 'package:dssstudentfe/pages/evaluate_criteria_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AhpResultPage extends StatelessWidget {

  final Map<String, double> weights;
  final double cr;

  const AhpResultPage({
    super.key,
    required this.weights,
    required this.cr
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text("Kết quả tính trọng số",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Container(
          width: 680,
          padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                /// CARD RESULT
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (cr < 0.1 ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              cr < 0.1 ? Icons.check_circle_rounded : Icons.warning_rounded,
                              color: cr < 0.1 ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Kết quả tính trọng số",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Tỷ lệ nhất quán (CR): ${cr.toStringAsFixed(3)} ${cr < 0.1 ? '✓' : '⚠'}",
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cr < 0.1 ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cr < 0.1 ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
                          ),
                        ),
                        child: Text(
                          cr < 0.1
                              ? "Ma trận so sánh có tính nhất quán tốt (CR < 0.1). Kết quả trọng số đáng tin cậy."
                              : "⚠️ Cảnh báo: CR = ${cr.toStringAsFixed(3)} > 0.1. Ma trận không nhất quán, vui lòng nhập lại!",
                          style: GoogleFonts.inter(
                            color: cr < 0.1 ? const Color(0xFF166534) : const Color(0xFF991B1B),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// WEIGHTS CARD
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trọng số các tiêu chí",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Mức độ ảnh hưởng của từng tiêu chí đến quyết định",
                        style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                      ),
                      const SizedBox(height: 20),

                      ...weights.entries.map((entry) {
                        double percent = entry.value * 100;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                Text("${percent.toStringAsFixed(0)}%",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: entry.value,
                                minHeight: 10,
                                backgroundColor: const Color(0xFFE2E8F0),
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Trọng số: ${entry.value.toStringAsFixed(3)}",
                              style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// EXPLANATION
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Diễn giải kết quả",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      const SizedBox(height: 12),

                      ...weights.entries.map((entry){
                        double percent = entry.value * 100;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            "• ${entry.key}: đóng góp ${percent.toStringAsFixed(0)}% vào quyết định đánh giá rủi ro",
                            style: GoogleFonts.inter(color: const Color(0xFF475569), fontSize: 14),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          "Kết quả này sẽ được sử dụng để đánh giá mức độ rủi ro của sinh viên trong hệ thống Decision Tree.",
                          style: GoogleFonts.inter(color: const Color(0xFF1D4ED8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EvaluateCriteriaPage(
                            criteriaIndex: 0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                    label: Text(
                      "Tính độ ưu tiên của các phương án theo từng tiêu chí",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
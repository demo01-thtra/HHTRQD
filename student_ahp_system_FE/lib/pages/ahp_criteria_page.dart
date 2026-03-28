import 'package:dssstudentfe/pages/ahp_comparison_page.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AhpCriteriaPage extends StatefulWidget {
  const AhpCriteriaPage({super.key});

  @override
  State<AhpCriteriaPage> createState() => _AhpCriteriaPageState();
}
class _AhpCriteriaPageState extends State<AhpCriteriaPage> {
  List<Map<String, dynamic>> criteria = [
    {"name": "Test_Score (Học thuật)", "icon": Icons.school_rounded, "desc": "Điểm kiểm tra, đánh giá năng lực"},
    {"name": "Attendance (Kỷ luật)", "icon": Icons.calendar_today_rounded, "desc": "Tỷ lệ chuyên cần trên lớp"},
    {"name": "Study_Hours (Nỗ lực)", "icon": Icons.access_time_rounded, "desc": "Số giờ tự học mỗi ngày"},
  ];
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPage: "/ahp",
      title: "AHP Criteria",
      body: Center(
              child: Container(
                width: 520,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withValues(alpha: 0.06),
                      offset: const Offset(0, 8),
                    )
                  ],
                ),

                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.balance_rounded, color: Color(0xFF3B82F6), size: 36),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Quản lý tiêu chí đánh giá",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Các tiêu chí để đánh giá rủi ro sinh viên",
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Danh sách tiêu chí (${criteria.length})",
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF475569)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: List.generate(criteria.length, (index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(criteria[index]["icon"], color: const Color(0xFF3B82F6), size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      criteria[index]["name"],
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      criteria[index]["desc"],
                                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "#${index + 1}",
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
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
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>AhpComparisonPage()));
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Text("Tiếp theo: So sánh cặp",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
    );
  }

}
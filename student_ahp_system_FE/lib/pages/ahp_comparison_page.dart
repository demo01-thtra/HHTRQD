import 'package:dssstudentfe/ViewModels/ahp_viewmodel.dart';
import 'package:dssstudentfe/pages/ahp_result_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AhpComparisonPage extends StatefulWidget {
  const AhpComparisonPage({super.key});

  @override
  State<AhpComparisonPage> createState() => _AhpComparisonPageState();
}

class _AhpComparisonPageState extends State<AhpComparisonPage> {
  List<List<double>> getMatrix(){
    double a = _convertScale(selectedValues["Điểm kiểm tra|Chuyên cần"]!);
    double b = _convertScale(selectedValues["Điểm kiểm tra|Giờ học/ngày"]!);
    double c = _convertScale(selectedValues["Chuyên cần|Giờ học/ngày"]!);

    return [
      [1, a, b],
      [1/a, 1, c],
      [1/b, 1/c, 1]
    ];
  }

  List<String> criteria = [
    "Điểm kiểm tra",
    "Chuyên cần",
    "Giờ học/ngày"
  ];

  List<String> saatyScale = [
    "1 - Ngang nhau",
    "3 - Hơi quan trọng hơn",
    "5 - Quan trọng hơn",
    "7 - Rất quan trọng",
    "9 - Cực kỳ quan trọng"
  ];

  Map<String, String> selectedValues = {};

  List<Map<String, String>> pairs = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < criteria.length; i++) {
      for (int j = i + 1; j < criteria.length; j++) {

        String key = "${criteria[i]}|${criteria[j]}";

        pairs.add({
          "a": criteria[i],
          "b": criteria[j],
          "key": key
        });

        selectedValues[key] = saatyScale[0];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        title: Text("So sánh các cặp tiêu chí",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),

      body: Center(
        child: Container(

          width: 620,
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

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                Text(
                  "So sánh cặp các tiêu chí",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "So sánh mức độ quan trọng giữa các cặp tiêu chí theo thang đo Saaty (1-9)",
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                ),

                const SizedBox(height: 24),

                /// PAIRS
                Column(
                  children: pairs.map((pair) {

                    String key = pair["key"]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.compare_arrows_rounded, color: Color(0xFF3B82F6), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "${pair["a"]}  vs  ${pair["b"]}",
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            initialValue: selectedValues[key],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            items: saatyScale.map((value) {
                              return DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedValues[key] = value!;
                              });
                            },
                          )
                        ],
                      ),
                    );

                  }).toList(),
                ),

                SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Color(0xFF0284C7), size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Hướng dẫn thang đo Saaty:",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF0369A1)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      ...[
                        "1 : Hai tiêu chí có mức độ quan trọng ngang nhau",
                        "3 : Tiêu chí thứ nhất hơi quan trọng hơn",
                        "5 : Tiêu chí thứ nhất quan trọng hơn",
                        "7 : Tiêu chí thứ nhất rất quan trọng",
                        "9 : Tiêu chí thứ nhất cực kỳ quan trọng",
                      ].map((text) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(text, style: GoogleFonts.inter(color: const Color(0xFF0369A1), fontSize: 13)),
                      )),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                Text(
                  "Ma trận so sánh cặp",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                SizedBox(height: 10),

                buildMatrix(),
                /// BUTTON
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
                    onPressed: caculate,
                    icon: const Icon(Icons.calculate_rounded, size: 20),
                    label: Text(
                      "Tính trọng số",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  //tinh toan cac tieu chi de cuat ra ma tran
  void caculate() async{

  var vm = context.read<AhpViewModel>();

  double testAttendance = _convertScale(
      selectedValues["Điểm kiểm tra|Chuyên cần"]!
  );

  double testStudy = _convertScale(
      selectedValues["Điểm kiểm tra|Giờ học/ngày"]!
  );

  double attendanceStudy = _convertScale(
      selectedValues["Chuyên cần|Giờ học/ngày"]!
  );

  await vm.calculateAHP(
      testAttendance,
      testStudy,
      attendanceStudy
      );

  if (!mounted) return;

  if (vm.weights == null || vm.cr == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(vm.error ?? "Lỗi tính AHP")),
    );
    return;
  }

  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
  builder: (context)=>
      AhpResultPage(
  weights: vm.weights!,
  cr: vm.cr!,
  )
  )
  );

}
  double _convertScale(String value){

    if(value.startsWith("1")) return 1;
    if(value.startsWith("3")) return 3;
    if(value.startsWith("5")) return 5;
    if(value.startsWith("7")) return 7;
    if(value.startsWith("9")) return 9;

    return 1;
  }
  Widget buildMatrix() {

    var matrix = getMatrix();

    return Center(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// TABLE
            DataTable(

              headingRowColor:
              WidgetStateProperty.all(Colors.blue.shade50),

              border: TableBorder.all(
                color: Colors.grey.shade300,
              ),

              columns: const [

                DataColumn(
                    label: Center(child: Text(""))),

                DataColumn(
                    label: Center(child: Text("C1"))),

                DataColumn(
                    label: Center(child: Text("C2"))),

                DataColumn(
                    label: Center(child: Text("C3"))),

              ],

              rows: [

                DataRow(cells: [

                  DataCell(Center(child: Text("C1",
                      style: TextStyle(fontWeight: FontWeight.bold)))),

                  DataCell(Center(child: Text(matrix[0][0].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[0][1].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[0][2].toStringAsFixed(2)))),

                ]),

                DataRow(cells: [

                  DataCell(Center(child: Text("C2",
                      style: TextStyle(fontWeight: FontWeight.bold)))),

                  DataCell(Center(child: Text(matrix[1][0].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[1][1].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[1][2].toStringAsFixed(2)))),

                ]),

                DataRow(cells: [

                  DataCell(Center(child: Text("C3",
                      style: TextStyle(fontWeight: FontWeight.bold)))),

                  DataCell(Center(child: Text(matrix[2][0].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[2][1].toStringAsFixed(2)))),

                  DataCell(Center(child: Text(matrix[2][2].toStringAsFixed(2)))),

                ]),

              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../ViewModels/ahp_viewmodel.dart';
import 'final_result_page.dart';

class EvaluateCriteriaPage extends StatefulWidget {

  final int criteriaIndex;


  const EvaluateCriteriaPage({
    super.key,
    required this.criteriaIndex
  });

  @override
  State<EvaluateCriteriaPage> createState() => _EvaluateCriteriaPageState();
}

class _EvaluateCriteriaPageState extends State<EvaluateCriteriaPage> {

  late final AhpViewModel viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    viewModel = context.read<AhpViewModel>();
  }

  /// tiêu chí
  List<String> criterias = [
    "TIÊU CHÍ 1 — HỌC THUẬT",
    "TIÊU CHÍ 2 — KỶ LUẬT ",
    "TIÊU CHÍ 3 — NỖ LỰC"
  ];

  /// tên backend
  List<String> criteriaKeys = [
    "TestScore",
    "Attendance",
    "StudyHours"
  ];

  /// phương án
  List<String> alternatives = [
    "Nguy cơ cao",
    "Nguy cơ trung bình",
    "An toàn"
  ];

  /// Saaty scale
  List<double> scale = [
    1,2,3,4,5,6,7,8,9
  ];
  List<List<double>> getMatrix(){

    return [

      [1, a1a2, a1a3],

      [1/a1a2, 1, a2a3],

      [1/a1a3, 1/a2a3, 1]

    ];

  }

  double a1a2 = 1;
  double a1a3 = 1;
  double a2a3 = 1;
  //hien thi ma tran
  Widget matrixCell(dynamic value){

    return Padding(

      padding: EdgeInsets.all(8),

      child: Center(
        child: Text(
          value is double
              ? value.toStringAsFixed(3)
              : value.toString(),
          style: TextStyle(fontSize: 14),
        ),
      ),

    );

  }
  Widget matrixTable(){

    List<List<double>> matrix = getMatrix();

    return Card(

      elevation: 3,

      child: Padding(

        padding: EdgeInsets.all(10),

        child: Table(

          border: TableBorder.all(color: Colors.grey),

          children: [

            TableRow(children: [

              matrixCell(""),

              matrixCell("A1"),

              matrixCell("A2"),

              matrixCell("A3"),

            ]),

            TableRow(children: [

              matrixCell("A1"),

              matrixCell(matrix[0][0]),

              matrixCell(matrix[0][1]),

              matrixCell(matrix[0][2]),

            ]),

            TableRow(children: [

              matrixCell("A2"),

              matrixCell(matrix[1][0]),

              matrixCell(matrix[1][1]),

              matrixCell(matrix[1][2]),

            ]),

            TableRow(children: [

              matrixCell("A3"),

              matrixCell(matrix[2][0]),

              matrixCell(matrix[2][1]),

              matrixCell(matrix[2][2]),

            ])

          ],

        ),

      ),

    );

  }

  Widget compareCard(String title,double value,Function(double?) onChanged){

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
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
              Text(title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          DropdownButtonFormField<double>(

            initialValue: value,

            items: scale.map((v){

              return DropdownMenuItem(
                value: v,
                child: Text(v.toString()),
              );

            }).toList(),

            onChanged: onChanged,

            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),

          )

        ],
      ),

    );

  }

  void submit() async {

    String criteria = criteriaKeys[widget.criteriaIndex];

    List<List<double>> matrix = [

      [1,a1a2,a1a3],
      [1/a1a2,1,a2a3],
      [1/a1a3,1/a2a3,1]

    ];

    await viewModel.calculateAlternative(criteria, matrix);

    if (!mounted) return;

    if(widget.criteriaIndex < 2){

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EvaluateCriteriaPage(
            criteriaIndex: widget.criteriaIndex + 1,
          ),
        ),
      );

    }else{

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FinalResultPage(),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    String criteria = criterias[widget.criteriaIndex];

    return Scaffold(

      appBar: AppBar(
        title: Text("So sánh mức rủi ro", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1E293B),
        iconTheme: const IconThemeData(color: Colors.white),
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

                Text(
                  "Tiêu chí: $criteria",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Chọn mức độ quan trọng giữa các mức rủi ro theo thang đo Saaty (1-9)",
                  style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 14),
                ),

                SizedBox(height:20),

                compareCard(
                    "${alternatives[0]} vs ${alternatives[1]}",
                    a1a2,
                        (v)=>setState(()=>a1a2=v!)
                ),

                compareCard(
                    "${alternatives[0]} vs ${alternatives[2]}",
                    a1a3,
                        (v)=>setState(()=>a1a3=v!)
                ),

                compareCard(
                    "${alternatives[1]} vs ${alternatives[2]}",
                    a2a3,
                        (v)=>setState(()=>a2a3=v!)
                ),

                SizedBox(height:24),

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

                    onPressed: submit,

                    icon: const Icon(Icons.calculate_rounded, size: 20),
                    label: Text(
                      "Tính trọng số phương án",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),

                  ),
                ),
                SizedBox(height:24),

                Text(
                  "Ma trận so sánh AHP",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),

                SizedBox(height:10),

                matrixTable(),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
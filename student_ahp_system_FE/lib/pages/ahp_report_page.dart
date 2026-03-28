import 'package:dssstudentfe/Models/ahp_report.dart';
import 'package:dssstudentfe/pages/components/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ViewModels/ahp_viewmodel.dart';

class AhpReportPage extends StatefulWidget {
  const AhpReportPage({super.key});

  @override
  State<AhpReportPage> createState() => _AhpReportPageState();
}

class _AhpReportPageState extends State<AhpReportPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<AhpViewModel>(context, listen: false);
      vm.fetchReport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AhpViewModel>(context);

    return MainLayout(
      currentPage: "/ahp-report",
      title: "AHP Report",
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: _buildBody(vm),
        ),
      ),
    );
  }

  Widget _buildBody(AhpViewModel vm) {
    if (vm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return Center(child: Text("Error: ${vm.error}"));
    }
    if (vm.report == null) {
      return const Center(child: Text("Nhấn nút để load dữ liệu"));
    }
    final r = vm.report!;
    final d = r.criteriaDetail;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== BƯỚC 1: Ma trận so sánh cặp =====
          if (d != null) ...[
            _title("1) Ma trận so sánh cặp"),
            _buildCriteriaTable(d.criteriaNames, d.matrix),
            const SizedBox(height: 20),

            // ===== BƯỚC 2: Bảng tổng từng cột =====
            _title("2) Bảng tổng từng cột"),
            _buildColumnSumTable(d.criteriaNames, d.matrix, d.columnSum),
            const SizedBox(height: 20),

            // ===== BƯỚC 3: Ma trận chuẩn hóa =====
            _title("3) Ma trận chuẩn hóa"),
            const Text("Mỗi phần tử được chia cho tổng cột tương ứng.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildNormalizedTable(d.criteriaNames, d.matrix, d.columnSum, d.normalizedMatrix),
            const SizedBox(height: 20),

            // ===== BƯỚC 4: Bảng trọng số =====
            _title("4) Bảng trọng số"),
            const Text("Lấy trung bình theo hàng của ma trận chuẩn hóa.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            _buildWeightsTable(d.criteriaNames, d.normalizedMatrix, d.weights),
            const SizedBox(height: 20),

            // ===== BƯỚC 5: Bảng kiểm tra nhất quán =====
            _title("5) Bảng kiểm tra nhất quán"),
            _buildConsistencySection(d),
            const SizedBox(height: 20),

            // ===== BƯỚC 6: Kết luận =====
            _title("6) Kết luận bảng ma trận"),
            _buildConclusionTable(d),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: d.cr < 0.1 ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: d.cr < 0.1 ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                d.cr < 0.1
                    ? "Kết luận: Ma trận đạt yêu cầu vì CR = ${(d.cr * 100).toStringAsFixed(2)}% < 10%."
                    : "⚠️ Cảnh báo: Ma trận KHÔNG đạt yêu cầu vì CR = ${(d.cr * 100).toStringAsFixed(2)}% > 10%. Vui lòng nhập lại!",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: d.cr < 0.1 ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),
          ],

          const SizedBox(height: 30),

          // ===== PHƯƠNG ÁN =====
          _title("— Phương án"),
          buildTable(
            headers: ["Ký hiệu", "Phương án", "Ý nghĩa"],
            data: [
              ["A1", "Nguy cơ cao", "Sinh viên dễ rớt môn"],
              ["A2", "Nguy cơ thấp", "Có dấu hiệu cảnh báo"],
              ["A3", "An toàn", "Học tập ổn định"],
            ],
          ),

          const SizedBox(height: 20),

          // ===== Ma trận so sánh theo từng tiêu chí =====
          if (r.matrices.where((m) => m['criteriaName'] != "Criteria").isNotEmpty) ...[
            _title("— Độ ưu tiên của các phương án theo từng tiêu chí"),
            _title("Ma trận so sánh theo từng tiêu chí"),
            ...r.matrices
                .where((m) => m['criteriaName'] != "Criteria")
                .map<Widget>((m) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m['criteriaName'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildMatrix(m['matrix']),
                  const SizedBox(height: 10),
                ],
              );
            }),
          ],

          // ===== Trọng số theo từng tiêu chí =====
          if (r.alternativeWeights.isNotEmpty) ...[
            _title("Ma trận trọng số theo từng tiêu chí"),
            ...r.alternativeWeights.map<Widget>((a) {
              List weights = a['weights'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['criteriaName'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  buildTable(
                    headers: ["Phương án", "Trọng số"],
                    data: List<List<dynamic>>.generate(
                      weights.length,
                      (i) => ["A${i + 1}", (weights[i] as num).toStringAsFixed(3)],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            }),
          ],

          // ===== KẾT QUẢ CUỐI =====
          if (r.finalScores.isNotEmpty) ...[
            _title("Kết quả cuối"),
            buildTable(
              headers: ["Phương án", "Trọng số"],
              data: List<List<dynamic>>.generate(
                r.finalScores.length,
                (i) => ["A${i + 1}", (r.finalScores[i] as num).toStringAsFixed(3)],
              ),
            ),
          ],

          // ===== BEST =====
          if (r.best.isNotEmpty) ...[
            _title("Kết luận"),
            _bestCard(r.best),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade800,
              ),
              padding: const EdgeInsets.all(12),
              width: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("A1 : Cảnh báo ngay, hỗ trợ học tập",
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  Text("A2 : Nhắc nhở, theo dõi thêm",
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                  Text("A3 : Không cần cảnh báo, tiếp tục theo dõi",
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===== 1) Ma trận so sánh cặp =====
  Widget _buildCriteriaTable(List<String> names, List<List<double>> matrix) {
    return buildTable(
      headers: ["Tiêu chí", ...names],
      data: List.generate(names.length, (i) {
        return [
          names[i],
          ...List.generate(names.length, (j) => _formatFraction(matrix[i][j])),
        ];
      }),
    );
  }

  // ===== 2) Bảng tổng từng cột =====
  Widget _buildColumnSumTable(List<String> names, List<List<double>> matrix, List<double> colSum) {
    List<List<dynamic>> data = [];
    for (int j = 0; j < names.length; j++) {
      List<String> parts = [];
      for (int i = 0; i < names.length; i++) {
        parts.add(_formatFraction(matrix[i][j]));
      }
      String formula = "${parts.join(' + ')} = ${colSum[j].toStringAsFixed(3)}";
      data.add([names[j], formula]);
    }
    return buildTable(
      headers: ["Cột", "Giá trị"],
      data: data,
    );
  }

  // ===== 3) Ma trận chuẩn hóa =====
  Widget _buildNormalizedTable(
      List<String> names, List<List<double>> matrix, List<double> colSum, List<List<double>> norm) {
    return buildTable(
      headers: ["Tiêu chí", ...names],
      data: List.generate(names.length, (i) {
        return [
          names[i],
          ...List.generate(names.length, (j) {
            return "${_formatFraction(matrix[i][j])}/${colSum[j].toStringAsFixed(3)} = ${norm[i][j].toStringAsFixed(3)}";
          }),
        ];
      }),
    );
  }

  // ===== 4) Bảng trọng số =====
  Widget _buildWeightsTable(List<String> names, List<List<double>> norm, List<double> weights) {
    int n = names.length;
    return buildTable(
      headers: ["Tiêu chí", "Trung bình hàng", "Trọng số"],
      data: List.generate(n, (i) {
        List<String> parts = norm[i].map((v) => v.toStringAsFixed(3)).toList();
        String formula = "(${parts.join(' + ')})/$n";
        return [names[i], formula, weights[i].toStringAsFixed(3)];
      }),
    );
  }

  // ===== 5) Bảng kiểm tra nhất quán =====
  Widget _buildConsistencySection(AhpCriteriaDetail d) {
    int n = d.criteriaNames.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // a) Tính A × W
        Text("a) Tính A × W",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        buildTable(
          headers: ["Tiêu chí", "Giá trị"],
          data: List.generate(n, (i) {
            List<String> parts = [];
            for (int j = 0; j < n; j++) {
              parts.add("${_formatFraction(d.matrix[i][j])}×${d.weights[j].toStringAsFixed(3)}");
            }
            return [
              d.criteriaNames[i],
              "${parts.join(' + ')} = ${d.axW[i].toStringAsFixed(3)}"
            ];
          }),
        ),

        const SizedBox(height: 16),

        // b) Tính λ_i
        Text("b) Tính λᵢ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        buildTable(
          headers: ["Tiêu chí", "Công thức", "Kết quả"],
          data: List.generate(n, (i) {
            return [
              d.criteriaNames[i],
              "${d.axW[i].toStringAsFixed(3)} / ${d.weights[i].toStringAsFixed(3)}",
              d.lambdaI[i].toStringAsFixed(3),
            ];
          }),
        ),

        const SizedBox(height: 16),

        // c) Tính λ_max, CI, CR
        Text("c) Tính λmax, CI, CR",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),

        buildTable(
          headers: ["Chỉ số", "Công thức", "Kết quả"],
          data: [
            [
              "λmax",
              "(${d.lambdaI.map((v) => v.toStringAsFixed(3)).join(' + ')})/$n",
              d.lambdaMax.toStringAsFixed(3),
            ],
            [
              "CI",
              "(${d.lambdaMax.toStringAsFixed(3)} - $n)/($n - 1)",
              d.ci.toStringAsFixed(4),
            ],
            [
              "RI",
              "n = $n",
              d.ri.toStringAsFixed(2),
            ],
            [
              "CR",
              "${d.ci.toStringAsFixed(4)} / ${d.ri.toStringAsFixed(2)}",
              "${d.cr.toStringAsFixed(4)} = ${(d.cr * 100).toStringAsFixed(2)}%",
            ],
          ],
        ),
      ],
    );
  }

  // ===== 6) Kết luận bảng ma trận =====
  Widget _buildConclusionTable(AhpCriteriaDetail d) {
    return buildTable(
      headers: ["Tiêu chí", "Trọng số", "Xếp hạng"],
      data: List.generate(d.criteriaNames.length, (i) {
        return [
          d.criteriaNames[i],
          d.weights[i].toStringAsFixed(3),
          d.ranking[i].toString(),
        ];
      }),
    );
  }

  // ===== format phân số =====
  String _formatFraction(double value) {
    if (value == 1) return "1";
    if (value == 2) return "2";
    if (value == 3) return "3";
    if (value == 4) return "4";
    if (value == 5) return "5";
    if (value == 6) return "6";
    if (value == 7) return "7";
    if (value == 8) return "8";
    if (value == 9) return "9";

    // Kiểm tra nếu là nghịch đảo
    double inv = 1.0 / value;
    if ((inv - inv.roundToDouble()).abs() < 0.001) {
      return "1/${inv.round()}";
    }

    return value.toStringAsFixed(3);
  }

  // ===== TITLE =====
  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ===== BEST CARD =====
  Widget _bestCard(String best) {
    return Card(
      color: Colors.green.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            best,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
        ),
      ),
    );
  }

  // ===== TABLE CHUNG =====
  Widget buildTable({
    required List<String> headers,
    required List<List<dynamic>> data,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        border: TableBorder.all(color: Colors.black54),
        defaultColumnWidth: const FixedColumnWidth(170),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.blue.shade800),
            children: headers.map((h) => _cell(h, isHeader: true)).toList(),
          ),
          ...data.map((row) {
            return TableRow(
              children: row.map((cell) => _cell(cell.toString())).toList(),
            );
          }),
        ],
      ),
    );
  }

  // ===== FIX MATRIX TYPE =====
  Widget _buildMatrix(dynamic matrix) {
    List<List<dynamic>> data =
        (matrix as List).map((row) => List<dynamic>.from(row)).toList();

    return buildTable(
      headers: List.generate(data[0].length, (i) => "C${i + 1}"),
      data: data,
    );
  }

  // ===== CELL =====
  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: isHeader ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
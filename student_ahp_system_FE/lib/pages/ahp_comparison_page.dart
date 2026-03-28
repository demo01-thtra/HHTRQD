import 'package:dssstudentfe/ViewModels/ahp_viewmodel.dart';
import 'package:dssstudentfe/pages/ahp_result_page.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(title: Text("So sánh các cặp tiêu chí",style: TextStyle(color: Colors.white),),
      backgroundColor: Colors.blue.shade800,),

      backgroundColor: Color(0xfff5f7fb),

      body: Center(
        child: Container(

          width: 600,
          padding: EdgeInsets.all(20),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black12,
              )
            ],
          ),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                /// TITLE
                Text(
                  "So sánh cặp các tiêu chí",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  "So sánh mức độ quan trọng giữa các cặp tiêu chí theo thang đo Saaty (1-9)",
                  style: TextStyle(color: Colors.grey),
                ),

                SizedBox(height: 20),

                /// PAIRS
                Column(
                  children: pairs.map((pair) {

                    String key = pair["key"]!;

                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            "So sánh: ${pair["a"]} với ${pair["b"]}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 8),

                          DropdownButtonFormField<String>(
                            initialValue: selectedValues[key],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
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
                  padding: EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        "Hướng dẫn thang đo Saaty:",
                        style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blue.shade800),
                      ),

                      SizedBox(height: 8),

                      Text("1 : Hai tiêu chí có mức độ quan trọng ngang nhau",style: TextStyle(color: Colors.blue.shade900),),
                      Text("3 : Tiêu chí thứ nhất hơi quan trọng hơn",style: TextStyle(color: Colors.blue.shade900)),
                      Text("5 : Tiêu chí thứ nhất quan trọng hơn",style: TextStyle(color: Colors.blue.shade900)),
                      Text("7 : Tiêu chí thứ nhất rất quan trọng",style: TextStyle(color: Colors.blue.shade900)),
                      Text("9 : Tiêu chí thứ nhất cực kỳ quan trọng",style: TextStyle(color: Colors.blue.shade900)),

                    ],
                  ),
                ),

                SizedBox(height: 20),
                //ma tran theo tieu chi

                Text(
                  "Ma trận so sánh cặp",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 10),

                buildMatrix(),
                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: caculate,
                    child: Text(
                      "Tính trọng số",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
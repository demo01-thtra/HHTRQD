import 'package:dssstudentfe/pages/evaluate_criteria_page.dart';
import 'package:flutter/material.dart';

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
        backgroundColor: Colors.blue.shade800,
        title: Text("Kết quả tính trọng số",style: TextStyle(color: Colors.white),),),
      backgroundColor: Color(0xfff5f7fb),
      body: Center(
        child: Container(
          width: 650,
          padding: EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                /// CARD RESULT
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Row(
                          children: [

                            Icon(Icons.check_circle,
                                color: Colors.green),

                            SizedBox(width: 10),

                            Text(
                              "Kết quả tính trọng số",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),

                        SizedBox(height: 8),

                        Text("Tỷ lệ nhất quán (CR): ${cr.toStringAsFixed(3)} ${cr < 0.1 ? '✓' : '⚠'}"),

                        SizedBox(height: 12),

                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: cr < 0.1 ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                              cr < 0.1
                                  ? "Ma trận so sánh có tính nhất quán tốt (CR < 0.1). Kết quả trọng số đáng tin cậy."
                                  : "⚠️ Cảnh báo: CR = ${cr.toStringAsFixed(3)} > 0.1. Ma trận không nhất quán, vui lòng nhập lại!"
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// WEIGHTS CARD
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Trọng số các tiêu chí",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),

                        Text(
                            "Mức độ ảnh hưởng của từng tiêu chí đến quyết định",),

                        SizedBox(height: 20),

                        ...weights.entries.map((entry) {

                          double percent = entry.value * 100;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(entry.key),
                                  Text("${percent.toStringAsFixed(0)}%",
                                      style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold))
                                ],
                              ),

                              SizedBox(height: 5),

                              LinearProgressIndicator(
                                value: entry.value,
                                minHeight: 8,
                                backgroundColor: Colors.grey[300],
                                color: Colors.blue,
                              ),

                              SizedBox(height: 5),

                              Text("Trọng số: ${entry.value.toStringAsFixed(3)}"),

                              SizedBox(height: 15)
                            ],
                          );

                        })

                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                /// EXPLANATION
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(16),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "Diễn giải kết quả",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),

                        SizedBox(height: 10),

                        ...weights.entries.map((entry){

                          double percent = entry.value * 100;

                          return Text(
                              "- ${entry.key}: đóng góp ${percent.toStringAsFixed(0)}% vào quyết định đánh giá rủi ro"
                          );

                        }),

                        SizedBox(height: 10),

                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8)
                          ),
                          child: Text(
                              "Kết quả này sẽ được sử dụng để đánh giá mức độ rủi ro của sinh viên trong hệ thống Decision Tree.",
                            style: TextStyle(color: Colors.blue.shade800),
                          ),
                        )

                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20,),
                Center(
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                      ),
                      onPressed: (){

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EvaluateCriteriaPage(
                              criteriaIndex: 0,
                            ),
                          ),
                        );
                  },
                      child: Text("Tính độ ưu tiên của các phương án theo từng tiêu chí. ",style: TextStyle(color: Colors.white),)),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}
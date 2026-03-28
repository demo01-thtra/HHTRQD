import 'package:dssstudentfe/pages/ahp_report_page.dart';
import 'package:flutter/material.dart';
import '../Services/ahp_service.dart';

class FinalResultPage extends StatefulWidget {
  const FinalResultPage({super.key});

  @override
  State<FinalResultPage> createState() => _FinalResultPageState();
}

class _FinalResultPageState extends State<FinalResultPage> {

  Map<String,dynamic>? result;

  List<String> alternatives = [
    "Nguy cơ cao(Sinh viên có nguy cơ học kém / rớt môn)",
    "Nguy cơ trung bình(Sinh viên có nguy cơ trung bình)",
    "An toàn(Sinh viên học ổn)"
  ];

  @override
  void initState() {
    super.initState();
    load();
  }

  void load() async {
    try {
      final service = AhpService();
      final data = await service.getFinalResult();
      setState(() {
        result = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải kết quả: $e")),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    if(result == null){
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    List<double> scores = [
      result!["a1"],
      result!["a2"],
      result!["a3"]
    ];

    int bestIndex = scores.indexOf(scores.reduce((a,b)=>a>b?a:b));

    return Scaffold(

      appBar: AppBar(
        title: Text("Kết quả đánh giá rủi ro"),
        backgroundColor: Colors.blue.shade800,
      ),

      body: Center(

        child: Container(

          width: 600,
          padding: EdgeInsets.all(20),

          child: Column(

            children: [

              Text(
                "Kết quả AHP",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold
                ),
              ),

              SizedBox(height:20),

              for(int i=0;i<alternatives.length;i++)

                Card(

                  child: ListTile(

                    title: Text(alternatives[i]),

                    trailing: Text(
                      scores[i].toStringAsFixed(3),
                      style: TextStyle(
                          fontWeight: FontWeight.bold
                      ),
                    ),

                  ),

                ),

              SizedBox(height:30),

              Container(

                padding: EdgeInsets.all(15),

                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(10)
                ),

                child: Text(
                  "Kết luận: ${alternatives[bestIndex]}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),


              ),
              const SizedBox(height: 50,),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15)
                ),
                onPressed: () {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>AhpReportPage()));


                },
                child: Text(
                  "Lưu & Xem báo cáo AHP",
                  style: TextStyle(color: Colors.white),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
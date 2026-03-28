import 'package:dssstudentfe/ViewModels/ahp_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/ai_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/risk_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/score_viewmodel.dart';
import 'package:dssstudentfe/ViewModels/student_viewmodel.dart';
import 'package:dssstudentfe/pages/ahp_criteria_page.dart';
import 'package:dssstudentfe/pages/ahp_report_page.dart';
import 'package:dssstudentfe/pages/UserPages/student_page.dart';
import 'package:dssstudentfe/pages/ai_prediction_page.dart';
import 'package:dssstudentfe/pages/dashboard_page.dart';
import 'package:dssstudentfe/pages/notification_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
      MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => StudentViewModel(),
      ),
      ChangeNotifierProvider(
        create: (_) => ScoreViewModel(),
      ),
      ChangeNotifierProvider(
        create: (_) => AhpViewModel(),
      ),
      ChangeNotifierProvider(
        create: (_) => RiskViewModel(),
      ),
      ChangeNotifierProvider(
        create: (_) => AiViewModel(),
      ),

    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/dashboard",
    routes: {
        "/dashboard":(context)=>DashboardPage(),
         "/students": (context) => StudentPage(),
        "/ahp": (context) => AhpCriteriaPage(),
       "/ahp-report":(context)=>AhpReportPage(),
       "/ai-predict":(context)=>const AiPredictionPage(),
       "/notifications":(context)=>const NotificationPage(),
    },
      title: 'DSS Cảnh Báo Sớm',
      debugShowCheckedModeBanner: false,
    );
  }
}
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
import 'package:google_fonts/google_fonts.dart';

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
    final baseTextTheme = GoogleFonts.interTextTheme(Theme.of(context).textTheme);

    return MaterialApp(
      initialRoute: "/dashboard",
      routes: {
        "/dashboard": (context) => DashboardPage(),
        "/students": (context) => StudentPage(),
        "/ahp": (context) => AhpCriteriaPage(),
        "/ahp-report": (context) => AhpReportPage(),
        "/ai-predict": (context) => const AiPredictionPage(),
        "/notifications": (context) => const NotificationPage(),
      },
      title: 'DSS Cảnh Báo Sớm',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A5F),
        brightness: Brightness.light,
        textTheme: baseTextTheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        dataTableTheme: DataTableThemeData(
          headingTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: const Color(0xFF4A5568),
          ),
          dataTextStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF2D3748),
          ),
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF7FAFC)),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            return Colors.white;
          }),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
      ),
    );
  }
}
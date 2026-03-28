import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final String currentPage;
  final String title;
  final Widget body;

  const MainLayout({
    super.key,
    required this.currentPage,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Fixed sidebar
          Container(
            width: 240,
            color: Colors.blue.shade800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    "DSS Cảnh Báo Sớm",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                _menuItem(context, Icons.dashboard, "Dashboard", "/dashboard"),
                _menuItem(context, Icons.people, "Sinh viên", "/students"),
                _menuItem(context, Icons.analytics, "AHP", "/ahp"),
                _menuItem(context, Icons.report, "Báo cáo AHP", "/ahp-report"),
                _menuItem(context, Icons.psychology, "AI Dự đoán", "/ai-predict"),
                _menuItem(context, Icons.notifications_active, "Thông báo", "/notifications"),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // App bar
                Container(
                  height: 56,
                  color: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade200,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Body
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    bool active = currentPage == route;

    return Material(
      color: active ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withValues(alpha: active ? 1.0 : 0.7)),
        title: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1.0 : 0.7),
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          if (!active) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}

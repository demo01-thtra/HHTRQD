import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl = "http://localhost:5045/api/notification";

  Future<Map<String, dynamic>> sendEmail(int studentId, String subject, String body) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "studentId": studentId,
        "subject": subject,
        "body": body,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {"success": true, "message": data["message"] ?? "Sent"};
    } else {
      return {"success": false, "error": data["error"] ?? data.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> sendBatch(List<Map<String, dynamic>> emails) async {
    final response = await http.post(
      Uri.parse("$baseUrl/send-batch"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"emails": emails}),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception(jsonDecode(response.body)["error"] ?? "Failed to send batch");
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class AiService {
  // ✅ Put your current backend IP here
  Future<String> _getBaseUrl() async {
    return "http://10.34.124.1:5000";
    //return"http://10.12.175.224:5000";
  }

  // ================= RECEIPT EXTRACTION =================
  Future<Map<String, dynamic>?> extractDataFromImage(File image) async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/extract');

      var request = http.MultipartRequest("POST", uri);
      request.files.add(await http.MultipartFile.fromPath("file", image.path));

      var response = await request.send().timeout(
        const Duration(seconds: 200),
      );

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      } else {
        final err = await response.stream.bytesToString();
        print("Extract failed: ${response.statusCode}");
        print("Extract body: $err");
        return null;
      }
    } catch (e) {
      print("Extract error: $e");
      return null;
    }
  }

  // ================= CATEGORY-WISE PREDICTION =================
  Future<Map<String, double>?> predictExpenses() async {
    try {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/predict');

      final uid = FirebaseAuth.instance.currentUser!.uid;

      print("Sending prediction request for UID: $uid");

      final response = await http
          .post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": uid,
        }),
      )
          .timeout(const Duration(seconds: 120));

      print("Predict status: ${response.statusCode}");
      print("Predict response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final Map<String, dynamic> raw =
            data["category_predictions"] ?? {};

        final Map<String, double> result = {};

        raw.forEach((key, value) {
          result[key] = (value as num).toDouble();
        });

        return result;
      } else {
        print("Predict failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Predict error: $e");
      return null;
    }
  }
}
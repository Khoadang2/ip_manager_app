import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service API cho Android + iOS
class ApiService {
  // LAN (dùng khi cùng WiFi trong công ty)
  static const String localBaseUrl = "http://192.168.71.9:5501";

  // Public domain hoặc ngrok (dùng khi 3G/4G hoặc WiFi khác)
  static const String remoteBaseUrl = "https://xxxx-1234.ngrok-free.app";

  /// Chọn baseUrl theo tình huống
  static String get baseUrl {
    // ⚡ Nếu đang chạy Emulator Android → dùng IP LAN
    if (Platform.isAndroid || Platform.isIOS) {
      return localBaseUrl; // 👉 ưu tiên LAN trước
    }
    return remoteBaseUrl;
  }

  /// API: Login
  static Future<Map<String, dynamic>> login(String userid, String pwd) async {
    final uri = Uri.parse("$baseUrl/api/login");
    final res = await http
        .post(uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userid": userid, "pwd": pwd}))
        .timeout(const Duration(seconds: 12));

    if (res.statusCode == 200) {
      try {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (e) {
        throw Exception("Invalid JSON from server: ${res.body}");
      }
    } else {
      throw Exception("Server returned ${res.statusCode}: ${res.body}");
    }
  }

  /// API: Get devices
  static Future<List<dynamic>> getDevices() async {
    final res = await http
        .get(Uri.parse("$baseUrl/api/devices"))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception("Get devices failed: ${res.statusCode}");
    }
  }

  /// API: Add device
  static Future<void> addDevice(Map<String, dynamic> data) async {
    final res = await http
        .post(Uri.parse("$baseUrl/api/devices"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception("Add device failed: ${res.statusCode}");
    }
  }

  /// API: Update device
  static Future<void> updateDevice(int id, Map<String, dynamic> data) async {
    final res = await http
        .put(Uri.parse("$baseUrl/api/devices/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception("Update device failed: ${res.statusCode}");
    }
  }

  /// API: Delete device
  static Future<void> deleteDevice(int id) async {
    final res = await http
        .delete(Uri.parse("$baseUrl/api/devices/$id"))
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception("Delete device failed: ${res.statusCode}");
    }
  }

  /// API: Scan network
  static Future<List<dynamic>> scanNetwork(String range) async {
    final res = await http
        .post(Uri.parse("$baseUrl/api/discover"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"range": range}))
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    } else {
      throw Exception("Scan failed: ${res.statusCode}");
    }
  }
}

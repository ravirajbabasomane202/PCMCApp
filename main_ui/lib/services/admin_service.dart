import 'package:dio/dio.dart';
import 'api_service.dart';  // Add this import

class AdminService {
  static Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await ApiService.get('/admin/dashboard'); // Assuming an endpoint
      return response.data;
    } catch (e) {
      throw Exception('Failed to load dashboard data');
    }
  }

  static Future<List<dynamic>> getAuditLogs() async {
  try {
    final response = await ApiService.get('/admin/audit-logs');
    return response.data as List<dynamic>;
  } catch (e) {
    throw Exception('Failed to load audit logs: $e');
  }
}
}


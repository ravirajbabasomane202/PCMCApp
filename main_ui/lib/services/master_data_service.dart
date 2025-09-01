import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/master_data_model.dart';
import '../services/api_service.dart';

// Providers for fetching master data
final subjectsProvider = FutureProvider<List<MasterSubject>>((ref) async {
  return MasterDataService.getSubjects();
});

final areasProvider = FutureProvider<List<MasterArea>>((ref) async {
  return MasterDataService.getAreas();
});

class MasterDataService {
  static Future<List<MasterArea>> getAreas() async {
    try {
      print('MasterDataService: Sending GET /areas');
      final response = await ApiService.get('/areas');
      return (response.data as List).map((a) => MasterArea.fromJson(a)).toList();
    } catch (e) {
      print('Error fetching areas: $e');
      rethrow;
    }
  }

  static Future<void> addArea(Map<String, dynamic> data) async {
    try {
      print('MasterDataService: Sending POST /areas with data: $data');
      await ApiService.post('/areas', data);
    } catch (e) {
      print('Error adding area: $e');
      rethrow;
    }
  }

  static Future<List<MasterSubject>> getSubjects() async {
    try {
      print('MasterDataService: Sending GET /subjects');
      final response = await ApiService.get('/subjects');
      return (response.data as List).map((s) => MasterSubject.fromJson(s)).toList();
    } on DioException catch (e) {
      print('DioError fetching subjects: ${e.response?.statusCode} - ${e.response?.data}');
      if (e.response?.statusCode == 405) {
        throw Exception('Use GET for listing subjects.');
      }
      throw Exception('Error fetching subjects: ${e.message}');
    } catch (e) {
      print('Unexpected error fetching subjects: $e');
      rethrow;
    }
  }
}
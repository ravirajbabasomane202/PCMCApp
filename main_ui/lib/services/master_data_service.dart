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

  static Future<MasterArea> addArea(Map<String, dynamic> data) async {
    try {
      print('MasterDataService: Sending POST /admins/areas with data: $data');
      final response = await ApiService.post('/admins/areas', data);
      return MasterArea.fromJson(response.data);
    } catch (e) {
      print('Error adding area: $e');
      rethrow;
    }
  }

  static Future<MasterArea> updateArea(int id, Map<String, dynamic> data) async {
    try {
      print('MasterDataService: Sending PUT /admins/areas/$id with data: $data');
      final response = await ApiService.put('/admins/areas/$id', data);
      return MasterArea.fromJson(response.data);
    } catch (e) {
      print('Error updating area: $e');
      rethrow;
    }
  }

  static Future<void> deleteArea(int areaId) async {
    try {
      print('MasterDataService: Sending DELETE /admins/areas/$areaId');
      await ApiService.delete('/admins/areas/$areaId');
    } on DioException catch (e) {
      print('Error deleting area: ${e.response?.data}');
      // Extract user-friendly message from backend
      final errorMsg = e.response?.data?['msg'] ?? 'Failed to delete area.';
      throw Exception(errorMsg);
    } catch (e) {
      print('Error deleting area: $e');
      rethrow;
    }
  }

  static Future<MasterSubject> addSubject(Map<String, dynamic> data) async {
    try {
      print('MasterDataService: Sending POST /admins/subjects with data: $data');
      final response = await ApiService.post('/admins/subjects', data);
      return MasterSubject.fromJson(response.data);
    } catch (e) {
      print('Error adding subject: $e');
      rethrow;
    }
  }

  static Future<MasterSubject> updateSubject(int id, Map<String, dynamic> data) async {
    try {
      print('MasterDataService: Sending PUT /admins/subjects/$id with data: $data');
      final response = await ApiService.put('/admins/subjects/$id', data);
      return MasterSubject.fromJson(response.data);
    } catch (e) {
      print('Error updating subject: $e');
      rethrow;
    }
  }

  static Future<void> deleteSubject(int subjectId) async {
    try {
      print('MasterDataService: Sending DELETE /admins/subjects/$subjectId');
      await ApiService.delete('/admins/subjects/$subjectId');
    } on DioException catch (e) {
      print('Error deleting subject: ${e.response?.data}');
      // Extract user-friendly message from backend
      final errorMsg = e.response?.data?['msg'] ?? 'Failed to delete subject.';
      throw Exception(errorMsg);
    } catch (e) {
      print('Error deleting subject: $e');
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
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/grievance_model.dart';
import 'api_service.dart';
import 'package:geolocator/geolocator.dart';

class GrievanceService {
  static final Dio _dio = ApiService.dio;

  // Note: This service assumes a Dio interceptor is configured in ApiService
  // to automatically handle the JWT Authorization header.
  GrievanceService();

  // Helper to parse grievance lists from response, reducing code duplication.
  List<Grievance> _parseGrievanceList(Response response) {
    if (response.data is List) {
      return (response.data as List).map((g) => Grievance.fromJson(g)).toList();
    }
    if (response.data is Map && response.data['grievances'] is List) {
      return (response.data['grievances'] as List).map((g) => Grievance.fromJson(g)).toList();
    }
    throw Exception('Unexpected response format: ${response.data}');
  }

  // Helper to create consistent error messages from DioExceptions.
  Exception _handleDioException(DioException e, String action) {
    String errorMessage;
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Unable to connect to the server. Please check your network or server status.';
    } else if (e.response?.statusCode == 401) {
      errorMessage = 'Unauthorized: Please log in again.';
    } else {
      errorMessage = 'Failed to $action: ${e.response?.data?['msg'] ?? e.message}';
    }
    return Exception(errorMessage);
  }

  static Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<Grievance> getGrievanceDetails(int id) async {
  try {
    
    final response = await _dio.get('/grievances/mine');
    
    // Check if response.data is a List
    if (response.data is List) {
      final grievances = (response.data as List)
          .map((json) => Grievance.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Find the grievance with the matching id
      final grievance = grievances.firstWhere(
        (g) => g.id == id,
        orElse: () => throw Exception('Grievance with id $id not found'),
      );
      print(grievance.toJson() );
      return grievance;
    } else {
      // If response.data is already a single object
      return Grievance.fromJson(response.data as Map<String, dynamic>);
    }
  } on DioException catch (e) {
   
    throw _handleDioException(e, 'fetch grievance details');
  } catch (e) {
    
    rethrow;
  }
}



Future<Grievance> getGrievanceById(int id) async {
  try {
    final response = await _dio.get('/grievances/$id');
    return Grievance.fromJson(response.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw _handleDioException(e, 'fetch grievance details');
  } catch (e) {
    rethrow;
  }
}




  Future<List<Grievance>> getAllGrievances() async {
  try {
    
    final response = await _dio.get('/admin/grievances/all');
    
    return _parseGrievanceList(response);
  } on DioException catch (e) {
    
    throw _handleDioException(e, 'fetch all grievances');
  } catch (e) {
   
    rethrow;
  }
}







  Future<List<Grievance>> getGrievancesByUserId(int userId) async {
    try {
      
      final response = await _dio.get('/grievances/track');
      
      return _parseGrievanceList(response);
    } on DioException catch (e) {
      
      throw _handleDioException(e, 'fetch user grievances');
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> addComment(int id, String commentText, {List<PlatformFile>? attachments}) async {
    try {
      final formData = FormData.fromMap({
        'comment_text': commentText,
      });

      if (attachments != null && attachments.isNotEmpty) {
        for (var file in attachments) {
          if (kIsWeb) {
            formData.files.add(MapEntry(
              'attachments',
              MultipartFile.fromBytes(file.bytes!, filename: file.name),
            ));
          } else {
            formData.files.add(MapEntry(
              'attachments',
              await MultipartFile.fromFile(file.path!, filename: file.name),
            ));
          }
        }
      }
      final response = await _dio.post(
        '/grievances/$id/comments',
        data: formData,
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add comment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'add comment');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Grievance>> getMyGrievances() async {
    try {
      
      final response = await _dio.get('/grievances/mine');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'fetch my grievances');
    } catch (e) {
      
      rethrow;
    }
  }

  Future<List<Grievance>> getNewGrievances() async {
    try {
    
      final response = await _dio.get('/grievances/new');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
    
      throw _handleDioException(e, 'fetch new grievances');
    } catch (e) {
     
      rethrow;
    }
  }

  Future<List<Grievance>> getAssignedGrievances() async {
    try {
     
      final response = await _dio.get('/grievances/assigned');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'fetch assigned grievances');
    } catch (e) {
     
      rethrow;
    }
  }

  Future<void> createGrievance({
    required String title,
    required String description,
    required int subjectId,
    required int areaId,
    String? priority,
    double? latitude,
    double? longitude,
    String? address,
    List<PlatformFile>? attachments,
  }) async {
    try {
      Position? position = await _getLocation();
      final formData = FormData.fromMap({
        'title': title,
        'description': description,
        'subject_id': subjectId,
        'area_id': areaId,
        'priority': priority ?? 'medium',
        if (position != null) 'latitude': position.latitude,
        if (position != null) 'longitude': position.longitude,
        if (address != null) 'address': address,
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments.map((file) {
            if (kIsWeb) {
              return MultipartFile.fromBytes(file.bytes!, filename: file.name);
            } else {
              return MultipartFile.fromFileSync(file.path!, filename: file.path!.split('/').last);
            }
          }).toList(),
      });
      final response = await _dio.post('/grievances/', data: formData);
      if (response.statusCode == 201) {
        
      } else {
        throw Exception('Failed to create grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'create grievance');
    } catch (e) {
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateGrievance(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/grievances/$id',
        data: data,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to update grievance: ${response.data?['msg'] ?? response.statusMessage}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'update grievance');
    }
  }





  Future<void> submitFeedback(int grievanceId, int rating, String feedbackText) async {
    try {
     
      final response = await _dio.post(
        '/grievances/$grievanceId/feedback',
        data: {
          'rating': rating,
          'feedback_text': feedbackText,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to submit feedback: ${response.statusMessage}');
      }
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'submit feedback');
    } catch (e) {
    
      rethrow;
    }
  }

  Future<void> reassignGrievance(int grievanceId, int assigneeId) async {
    try {
     
      final response = await _dio.put(
        '/grievances/$grievanceId/reassign',
        data: {'assignee_id': assigneeId},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reassign grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'reassign grievance');
    } catch (e) {
     
      rethrow;
    }
  }

  Future<void> updateGrievanceStatus(int grievanceId, String status) async {
    try {
     
      final response = await _dio.put(
        '/grievances/$grievanceId/status',
        data: {'status': status},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update grievance status: ${response.statusMessage}');
      }
    } on DioException catch (e) {
    
      throw _handleDioException(e, 'update grievance status');
    } catch (e) {
     
      rethrow;
    }
  }



















  Future<void> escalateGrievance(int grievanceId, {int? assigneeId}) async {
    try {
     
      final data = assigneeId != null ? {'assignee_id': assigneeId} : {};
      final response = await _dio.post(
        '/grievances/$grievanceId/escalate',
        data: data,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to escalate grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
     
      throw _handleDioException(e, 'escalate grievance');
    } catch (e) {
      
      rethrow;
    }
  }

  Future<void> deleteGrievance(int grievanceId) async {
    try {
      final response = await _dio.delete('/grievances/$grievanceId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete grievance: ${response.data?['message'] ?? response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'delete grievance');
    } catch (e) {
      rethrow;
    }
  }
}
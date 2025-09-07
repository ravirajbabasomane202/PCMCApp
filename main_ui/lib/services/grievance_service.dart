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
    print('GrievanceService: Sending GET /grievances/mine');
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
      
      return grievance;
    } else {
      // If response.data is already a single object
      return Grievance.fromJson(response.data as Map<String, dynamic>);
    }
  } on DioException catch (e) {
    print('GrievanceService: DioError fetching grievance details: ${e.response?.statusCode} - ${e.response?.data}');
    throw _handleDioException(e, 'fetch grievance details');
  } catch (e) {
    print('GrievanceService: Unexpected error fetching grievance details: $e');
    rethrow;
  }
}







Future<Grievance> GGDBID(int id) async {
  try {
    print('GrievanceService: Sending GET /grievances/$id');
    final response = await _dio.get('/grievances/$id');
    
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
      
      return grievance;
    } else {
      // If response.data is already a single object
      return Grievance.fromJson(response.data as Map<String, dynamic>);
    }
  } on DioException catch (e) {
    print('GrievanceService: DioError fetching grievance details: ${e.response?.statusCode} - ${e.response?.data}');
    throw _handleDioException(e, 'fetch grievance details');
  } catch (e) {
    print('GrievanceService: Unexpected error fetching grievance details: $e');
    rethrow;
  }
}




  Future<List<Grievance>> getAllGrievances() async {
  try {
    print('GrievanceService: Sending GET /admin/grievances/all');
    final response = await _dio.get('/admin/grievances/all');
    print('Full request URL: ${response.requestOptions.uri}');
    return _parseGrievanceList(response);
  } on DioException catch (e) {
    print('GrievanceService: DioError fetching all grievances: ${e.response?.statusCode} - ${e.response?.data}');    
    throw _handleDioException(e, 'fetch all grievances');
  } catch (e) {
    print('GrievanceService: Unexpected error fetching all grievances: $e');
    rethrow;
  }
}

  Future<List<Grievance>> getGrievancesByUserId(int userId) async {
    try {
      // NOTE: The endpoint was changed from '/grievance/track' to use the userId.
      // Ensure your backend has a corresponding route like '/grievances/user/<int:user_id>'.
      print('GrievanceService: Sending GET /track');
      final response = await _dio.get('/grievances/track');
      print('Response: ${response.data}');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
      print('GrievanceService: DioError fetching user grievances: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'fetch user grievances');
    } catch (e) {
      print('GrievanceService: Unexpected error fetching user grievances: $e');
      rethrow;
    }
  }

  Future<void> addComment(int id, String commentText) async {
    try {
      print('GrievanceService: Sending POST /grievances/$id/comments with comment: $commentText');
      final response = await _dio.post(
        '/grievances/$id/comments',
        data: {'comment_text': commentText},
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to add comment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('GrievanceService: DioError adding comment: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'add comment');
    } catch (e) {
      print('GrievanceService: Unexpected error adding comment: $e');
      rethrow;
    }
  }

  Future<List<Grievance>> getMyGrievances() async {
    try {
      print('GrievanceService: Sending GET /grievances/mine with headers: ${_dio.options.headers}');
      final response = await _dio.get('/grievances/mine');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
      print('GrievanceService: DioError fetching my grievances: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'fetch my grievances');
    } catch (e) {
      print('GrievanceService: Unexpected error fetching my grievances: $e');
      rethrow;
    }
  }

  Future<List<Grievance>> getNewGrievances() async {
    try {
      print('GrievanceService: Sending GET /grievances/new');
      final response = await _dio.get('/grievances/new');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
      print('GrievanceService: DioError fetching new grievances: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'fetch new grievances');
    } catch (e) {
      print('GrievanceService: Unexpected error fetching new grievances: $e');
      rethrow;
    }
  }

  Future<List<Grievance>> getAssignedGrievances() async {
    try {
      print('GrievanceService: Sending GET /grievances/assigned');
      final response = await _dio.get('/grievances/assigned');
      return _parseGrievanceList(response);
    } on DioException catch (e) {
      print('GrievanceService: DioError fetching assigned grievances: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'fetch assigned grievances');
    } catch (e) {
      print('GrievanceService: Unexpected error fetching assigned grievances: $e');
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
        print('GrievanceService: Grievance created successfully');
      } else {
        throw Exception('Failed to create grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('GrievanceService: DioError submitting grievance: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'create grievance');
    } catch (e) {
      print('GrievanceService: Unexpected error submitting grievance: $e');
      rethrow;
    }
  }

  Future<void> submitFeedback(int grievanceId, int rating, String feedbackText) async {
    try {
      print('GrievanceService: Sending POST /grievances/$grievanceId/feedback with rating: $rating, feedback: $feedbackText');
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
      print('GrievanceService: DioError submitting feedback: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'submit feedback');
    } catch (e) {
      print('GrievanceService: Unexpected error submitting feedback: $e');
      rethrow;
    }
  }

  Future<void> reassignGrievance(int grievanceId, int assigneeId) async {
    try {
      print('GrievanceService: Sending PUT /grievances/$grievanceId/reassign with assignee_id: $assigneeId');
      final response = await _dio.put(
        '/grievances/$grievanceId/reassign',
        data: {'assignee_id': assigneeId},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to reassign grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('GrievanceService: DioError reassigning grievance: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'reassign grievance');
    } catch (e) {
      print('GrievanceService: Unexpected error reassigning grievance: $e');
      rethrow;
    }
  }

  Future<void> updateGrievanceStatus(int grievanceId, String status) async {
    try {
      print('GrievanceService: Sending PUT /grievances/$grievanceId/status with status: $status');
      final response = await _dio.put(
        '/grievances/$grievanceId/status',
        data: {'status': status},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update grievance status: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('GrievanceService: DioError updating grievance status: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'update grievance status');
    } catch (e) {
      print('GrievanceService: Unexpected error updating grievance status: $e');
      rethrow;
    }
  }

  Future<void> escalateGrievance(int grievanceId, {int? assigneeId}) async {
    try {
      print('GrievanceService: Sending POST /grievances/$grievanceId/escalate');
      final data = assigneeId != null ? {'assignee_id': assigneeId} : {};
      final response = await _dio.post(
        '/grievances/$grievanceId/escalate',
        data: data,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to escalate grievance: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('GrievanceService: DioError escalating grievance: ${e.response?.statusCode} - ${e.response?.data}');
      throw _handleDioException(e, 'escalate grievance');
    } catch (e) {
      print('GrievanceService: Unexpected error escalating grievance: $e');
      rethrow;
    }
  }
}
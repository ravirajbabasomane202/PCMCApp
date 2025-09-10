import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/grievance_model.dart';
import '../models/kpi_model.dart';
import '../services/api_service.dart';

// Define the apiServiceProvider for dependency injection
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Define a Config model
class Config {
  final String key;
  final String value;

  Config({required this.key, required this.value});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class AdminState {
  final KpiData? kpiData;
  final List<Grievance> grievances;
  final List<Config> configs; // Added for config management
  final String? error;

  AdminState({
    this.kpiData,
    this.grievances = const [],
    this.configs = const [], // Initialize empty configs list
    this.error,
  });

  AdminState copyWith({
    KpiData? kpiData,
    List<Grievance>? grievances,
    List<Config>? configs,
    String? error,
  }) {
    return AdminState(
      kpiData: kpiData ?? this.kpiData,
      grievances: grievances ?? this.grievances,
      configs: configs ?? this.configs,
      error: error ?? this.error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  // ignore: unused_field
  final ApiService _apiService;

  AdminNotifier(this._apiService) : super(AdminState()) {
    getConfigs(); // Fetch configs on initialization
  }

  Future<void> fetchAdvancedKPIs({String timePeriod = 'all'}) async {
    try {
      final response = await ApiService.get('/admins/reports/kpis/advanced?time_period=$timePeriod');
      final kpiData = KpiData.fromJson(response.data);
      state = state.copyWith(kpiData: kpiData, error: null);
     
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<List<Grievance>> getAllGrievances({
    String? status ,
    String? priority,
    int? areaId,
    int? subjectId,}) async {
    try {
      final response = await ApiService.get('/admins/grievances/all' );
      final grievances =
          (response.data as List).map((g) => Grievance.fromJson(g)).toList();
      state = state.copyWith(grievances: grievances, error: null);
      

      return grievances;
    } catch (e) {
      state = state.copyWith(grievances: [], error: e.toString());
      return [];
    }
  }

  Future<void> escalateGrievance(int grievanceId, int newAssigneeId, int userId ) async {
  try {
    
    await ApiService.post(
      '/admins/grievances/$grievanceId/escalate', 
      {'escalated_by': userId,
      'assignee_id': newAssigneeId},
    );
    state = state.copyWith(error: null);
    await getAllGrievances();
  } catch (e) {
    state = state.copyWith(error: e.toString());
    
  }
}

  Future<void> reassignGrievance(int grievanceId, int assigneeId) async {
    try {
      await ApiService
          .post('/admins/reassign/$grievanceId', {'assigned_to': assigneeId});
      state = state.copyWith(error: null);
      
       
      await getAllGrievances();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      
      
    }
  }

  Future<void> updateGrievanceStatus(int grievanceId, String status) async {
    try {
      
      await ApiService.post('/grievances/$grievanceId/status', {'status': status});
      state = state.copyWith(error: null);
      
      await getAllGrievances();
    } catch (e) {
      state = state.copyWith(error: e.toString());
     
    }
  }

  Future<List<Grievance>> getCitizenHistory(int userId) async {
    try {
      final response = await ApiService.get('/admins/users/$userId/history');
      final grievances =
          (response.data as List).map((g) => Grievance.fromJson(g)).toList();
      state = state.copyWith(grievances: grievances, error: null);
      return grievances;
    } catch (e) {
      state = state.copyWith(grievances: [], error: e.toString());
      return [];
    }
  }

  Future<List<int>> generateReport(String filter, String format) async {
    try {
      // Note: For web, handle ResponseType.bytes (e.g., base64 or blob for downloads)
      final response = await ApiService.get('/admins/reports?filter_type=$filter&format=$format', responseType: ResponseType.bytes);
      state = state.copyWith(error: null);
      return response.data;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return [];
    }
  }

  // New methods for config management
  Future<void> getConfigs() async {
    try {
      state = state.copyWith(error: null); // Clear previous errors
      final response = await ApiService.get('/admins/configs');
      final configs =
          (response.data as List).map((json) => Config.fromJson(json)).toList();
      state = state.copyWith(configs: configs, error: null);
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch configs: $e');
    }
  }

  Future<void> addConfig(String key, String value) async {
    try {
      state = state.copyWith(error: null); // Clear previous errors
      await ApiService.post('/admins/configs', {'key': key, 'value': value});
      await getConfigs(); // Refresh configs after adding
    } catch (e) {
      state = state.copyWith(error: 'Failed to add config: $e');
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AdminNotifier(apiService);
});
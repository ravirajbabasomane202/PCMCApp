import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/grievance_model.dart';
import '../services/grievance_service.dart';

// Provider for fetching citizen grievance history by user ID
final citizenHistoryProvider = FutureProvider.family<List<Grievance>, int>((ref, userId) async {
  final grievanceService = GrievanceService();
  return await grievanceService.getGrievancesByUserId(userId);
});

// StateNotifier for managing grievance lists (e.g., my grievances, new grievances, assigned grievances)
class GrievanceNotifier extends StateNotifier<List<Grievance>> {
  GrievanceNotifier() : super([]);
  bool _isFetching = false;

  final GrievanceService _service = GrievanceService();

  Future<void> fetchMyGrievances() async {
    if (_isFetching) return; // Skip if already fetching
    _isFetching = true;
    try {
      state = await _service.getMyGrievances();
      print('Grievances updated: ${state.length} items');
    } catch (e) {
      print('Error fetching grievances: $e');
      state = [];
      rethrow;
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchNewGrievances() async {
    try {
      state = await _service.getNewGrievances();
      print('New grievances fetched: ${state.length} items');
    } catch (e) {
      print('Error fetching new grievances: $e');
      state = [];
      rethrow;
    }
  }

  Future<void> fetchAssignedGrievances() async {
    try {
      state = await _service.getAssignedGrievances();
      print('Assigned grievances fetched: ${state.length} items');
    } catch (e) {
      print('Error fetching assigned grievances: $e');
      state = [];
      rethrow;
    }
  }
}

// Provider for the GrievanceNotifier
final grievanceProvider = StateNotifierProvider<GrievanceNotifier, List<Grievance>>((ref) {
  return GrievanceNotifier();
});
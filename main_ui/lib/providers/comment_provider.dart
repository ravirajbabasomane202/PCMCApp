import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:main_ui/services/grievance_service.dart';
import 'package:main_ui/models/comment_model.dart';
class CommentNotifier extends StateNotifier<List<Comment>> {
  final int _grievanceId;
  final GrievanceService _service;

  CommentNotifier(this._grievanceId, this._service) : super([]);

  Future<void> fetchComments() async {
    try {
      final grievance = await _service.getGrievanceDetails(_grievanceId);
      state = grievance.comments ?? [];
    } catch (e) {
      print('Error fetching comments: $e');
      state = [];
    }
  }

  Future<void> addComment(String content) async {
    try {
      await _service.addComment(_grievanceId, content);
      await fetchComments();
    } catch (e) {
      print('Error adding comment: $e');
    }
  }
}

final commentProvider =
    StateNotifierProvider.family<CommentNotifier, List<Comment>, int>(
  (ref, grievanceId) => CommentNotifier(grievanceId, GrievanceService()),
);
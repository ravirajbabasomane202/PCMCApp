import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/services/grievance_service.dart';

final citizenHistoryProvider = FutureProvider.family<List<Grievance>, int>((ref, userId) async {
  return await GrievanceService().getGrievancesByUserId(userId);
});
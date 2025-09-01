// lib/providers/master_data_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/master_data_model.dart';
import '../services/master_data_service.dart';

final subjectsProvider = FutureProvider<List<MasterSubject>>((ref) async {
  return MasterDataService.getSubjects();
});

final areasProvider = FutureProvider<List<MasterArea>>((ref) async {
  return MasterDataService.getAreas();
});
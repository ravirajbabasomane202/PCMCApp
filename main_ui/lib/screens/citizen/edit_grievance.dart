import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/providers/master_data_provider.dart';
import 'package:main_ui/services/grievance_service.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/loading_indicator.dart';

// Provider to fetch a single grievance
final editGrievanceProvider = FutureProvider.family<Grievance, int>((ref, id) {
  return GrievanceService().getGrievanceDetails(id);
});

class EditGrievance extends ConsumerStatefulWidget {
  final int id;
  const EditGrievance({super.key, required this.id});

  @override
  ConsumerState<EditGrievance> createState() => _EditGrievanceState();
}

class _EditGrievanceState extends ConsumerState<EditGrievance> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  int? _selectedAreaId;
  int? _selectedSubjectId;

  bool _isSubmitting = false;
  bool _initialDataLoaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadGrievanceData(Grievance grievance) {
    if (!_initialDataLoaded) {
      _titleController.text = grievance.title ?? '';
      _descriptionController.text = grievance.description ?? '';
      _addressController.text = grievance.address ?? '';
      _selectedAreaId = grievance.areaId;
      _selectedSubjectId = grievance.subjectId;
      _initialDataLoaded = true;
    }
  }

  Future<void> _submitUpdate() async {
  if (!_formKey.currentState!.validate() ||
      _selectedAreaId == null ||
      _selectedSubjectId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllFields ?? 'Please fill all required fields')),
    );
    return;
  }

  setState(() => _isSubmitting = true);

  try {
    // Construct the data map with snake_case keys to match backend
    final Map<String, dynamic> data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'area_id': _selectedAreaId,
      'subject_id': _selectedSubjectId,
      'address': _addressController.text.trim(),
    };

    // Create an instance of GrievanceService
    final grievanceService = GrievanceService();
    await grievanceService.updateGrievance(widget.id, data);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Grievance updated successfully'),
          backgroundColor: Colors.green),
    );
    Navigator.of(context).pop(true); // Pop with a result to indicate success
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Failed to update: $e'), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final grievanceAsync = ref.watch(editGrievanceProvider(widget.id));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editGrievance ?? 'Edit Grievance')),
      body: grievanceAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading grievance: $err')),
        data: (grievance) {
          _loadGrievanceData(grievance);

          final areasAsync = ref.watch(areasProvider);
          final subjectsAsync = ref.watch(subjectsProvider);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.title ?? 'Title',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? (l10n.titleRequired ?? 'Title is required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: l10n.description ?? 'Description',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value?.isEmpty ?? true ? (l10n.descriptionRequired ?? 'Description is required') : null,
                  ),
                  const SizedBox(height: 16),
                  areasAsync.when(
                    data: (areas) => DropdownButtonFormField<int>(
                      value: _selectedAreaId,
                      decoration: InputDecoration(
                        labelText: l10n.filterByArea ?? 'Area',
                        border: const OutlineInputBorder(),
                      ),
                      items: areas
                          .map((area) => DropdownMenuItem(
                                value: area.id,
                                child: Text(area.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedAreaId = value),
                      validator: (value) =>
                          value == null ? (l10n.areaRequired ?? 'Area is required') : null,
                    ),
                    loading: () => const LoadingIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 16),
                  subjectsAsync.when(
                    data: (subjects) => DropdownButtonFormField<int>(
                      value: _selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: l10n.filterBySubject ?? 'Subject',
                        border: const OutlineInputBorder(),
                      ),
                      items: subjects
                          .map((subject) => DropdownMenuItem(
                                value: subject.id,
                                child: Text(subject.name),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedSubjectId = value),
                      validator: (value) =>
                          value == null ? (l10n.subjectRequired ?? 'Subject is required') : null,
                    ),
                    loading: () => const LoadingIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: l10n.submit ?? 'Submit',
                    isLoading: _isSubmitting,
                    onPressed: _submitUpdate,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  } 
}
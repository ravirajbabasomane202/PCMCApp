// lib/screens/citizen/submit_grievance.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/providers/master_data_provider.dart';
import 'package:main_ui/services/grievance_service.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/file_upload_widget.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SubmitGrievance extends ConsumerStatefulWidget {
  const SubmitGrievance({super.key});

  @override
  ConsumerState<SubmitGrievance> createState() => _SubmitGrievanceState();
}

class _SubmitGrievanceState extends ConsumerState<SubmitGrievance> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  int? _selectedSubjectId;
  int? _selectedAreaId;
  List<PlatformFile> _attachments = [];
  Position? _currentPosition;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() => _currentPosition = position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<bool> _handleLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.error)),
      );
      return false;
    }
  }

  Future<void> _pickImage() async {
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null) {
    // Prepare values outside setState
    final fileBytes = kIsWeb ? await pickedFile.readAsBytes() : null;
    final filePath = kIsWeb ? null : pickedFile.path;
    final fileName = pickedFile.name;
    // Compute size: Use bytes length for web, file length for non-web
    final fileSize = kIsWeb
        ? fileBytes?.length ?? 0
        : await File(pickedFile.path).length();

    // Now call setState with already computed values
    setState(() {
      _attachments.add(PlatformFile(
        name: fileName,
        size: fileSize, // Size in bytes, required
        path: filePath, // Path for non-web
        bytes: fileBytes, // Bytes for web
      ));
    });
  }
}

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSubjectId == null ||
        _selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final grievanceService = GrievanceService();
await grievanceService.createGrievance(
  title: _titleController.text,
  description: _descriptionController.text,
  subjectId: _selectedSubjectId!,
  areaId: _selectedAreaId!,
  latitude: _currentPosition?.latitude,
  longitude: _currentPosition?.longitude,
  address: _addressController.text.isNotEmpty ? _addressController.text : null,
  attachments: _attachments,
);


      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.submitGrievance),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.submitGrievance),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: localizations.name,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? localizations.error : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: localizations.feedback,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? localizations.error : null,
              ),
              const SizedBox(height: 16),
              ref.watch(subjectsProvider).when(
                    data: (subjects) => DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: localizations.filterBySubject,
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedSubjectId,
                      items: subjects
                          .map((subject) => DropdownMenuItem<int>(
                                value: subject.id,
                                child: Text(subject.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedSubjectId = value),
                      validator: (value) => value == null ? localizations.error : null,
                    ),
                    loading: () => const LoadingIndicator(),
                    error: (error, stack) => Text('${localizations.error}: $error'),
                  ),
              const SizedBox(height: 16),
              ref.watch(areasProvider).when(
                    data: (areas) => DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: localizations.filterByArea,
                        border: const OutlineInputBorder(),
                      ),
                      value: _selectedAreaId,
                      items: areas
                          .map((area) => DropdownMenuItem<int>(
                                value: area.id,
                                child: Text(area.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedAreaId = value),
                      validator: (value) => value == null ? localizations.error : null,
                    ),
                    loading: () => const LoadingIndicator(),
                    error: (error, stack) => Text('${localizations.error}: $error'),
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CustomButton(
                    text: 'Get Location',
                    onPressed: _getCurrentLocation,
                    icon: Icons.location_on,
                    fullWidth: false,
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: 'Pick Image',
                    onPressed: _pickImage,
                    icon: Icons.image,
                    fullWidth: false,
                  ),
                  const SizedBox(width: 8),
                  if (_currentPosition != null)
                    Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FileUploadWidget(
                onFilesSelected: (files) {
                  setState(() => _attachments.addAll(files));
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isSubmitting ? 'Submitting...' : localizations.submit,
                onPressed: _isSubmitting ? null : _submitGrievance,
                icon: Icons.send,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
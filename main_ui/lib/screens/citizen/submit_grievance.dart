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
      setState(() => _isSubmitting = true);
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
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
        SnackBar(content: Text(AppLocalizations.of(context)!.locationPermissionDenied)),
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

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitGrievance() async {
    if (!_formKey.currentState!.validate() ||
        _selectedSubjectId == null ||
        _selectedAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillAllFields),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Log before send
      // Log count
      print("===============================================================================================================================================Sending multipart with ${_attachments.length} files");
      for (var i = 0; i < _attachments.length; i++) {
        // Log each file added
        print("Adding file[$i]: ${_attachments[i].name}");
        // Log details like name size
        print("  size: ${_attachments[i].size}");
      }
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
          content: Text(AppLocalizations.of(context)!.grievanceSubmitted),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xffecf2fe),
      appBar: AppBar(
        title: Text(localizations.submitGrievance),
        elevation: 0,
      ),
      body: _isSubmitting && _currentPosition == null
          ? const Center(child: LoadingIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.grievanceDetails,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: localizations.title,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value!.isEmpty ? localizations.titleRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: localizations.description,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      validator: (value) => value!.isEmpty ? localizations.descriptionRequired : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.categorization,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ref.watch(subjectsProvider).when(
                          data: (subjects) => DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: localizations.filterBySubject,
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: _selectedSubjectId,
                            items: subjects
                                .map((subject) => DropdownMenuItem<int>(
                                      value: subject.id,
                                      child: Text(subject.name),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedSubjectId = value),
                            validator: (value) => value == null ? localizations.subjectRequired : null,
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
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            value: _selectedAreaId,
                            items: areas
                                .map((area) => DropdownMenuItem<int>(
                                      value: area.id,
                                      child: Text(area.name),
                                    ))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedAreaId = value),
                            validator: (value) => value == null ? localizations.areaRequired : null,
                          ),
                          loading: () => const LoadingIndicator(),
                          error: (error, stack) => Text('${localizations.error}: $error'),
                        ),
                    const SizedBox(height: 24),
                    Text(
                      localizations.locationDetails,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            text: _isSubmitting ? 'Getting Location...' : 'Get Location',
                            onPressed: _isSubmitting ? null : _getCurrentLocation,
                            icon: Icons.location_on,
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomButton(
                            text: 'Add Media',
                            onPressed: _pickImage,
                            icon: Icons.image,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_currentPosition != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Location captured: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                                '${_currentPosition!.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_attachments.isNotEmpty) ...[
                      Text(
                        'Attachments (${_attachments.length})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_attachments.length, (index) {
                          final file = _attachments[index];
                          return Chip(
                            label: Text(
                              file.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            avatar: const Icon(Icons.attachment, size: 18),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeAttachment(index),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                    ],
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
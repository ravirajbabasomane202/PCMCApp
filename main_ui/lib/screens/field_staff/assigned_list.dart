import 'dart:io'
    if (dart.library.html) 'dart:html'; // Conditional import for web
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:intl/intl.dart'; // For formatting dates

class AssignedList extends ConsumerStatefulWidget {
  const AssignedList({super.key});

  @override
  ConsumerState<AssignedList> createState() => _AssignedListState();
}

class _AssignedListState extends ConsumerState<AssignedList> {
  late Future<List<Grievance>> _grievancesFuture;

  @override
  void initState() {
    super.initState();
    _grievancesFuture = _fetchAssignedGrievances();
  }

  Future<List<Grievance>> _fetchAssignedGrievances() async {
    try {
      final response = await ApiService.get('/grievances/assigned');
      
      return (response.data as List)
          .map((json) => Grievance.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load assigned grievances: $e');
    }
  }

  Future<void> _acceptGrievance(int grievanceId) async {
    try {
      await ApiService.post('/grievances/$grievanceId/accept', {});
      setState(() => _grievancesFuture = _fetchAssignedGrievances());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grievance accepted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to accept: $e')));
    }
  }

  Future<void> _updateStatus(int grievanceId, String newStatus) async {
  try {
    print("➡️ Updating grievance $grievanceId with status: $newStatus");

    // Perform the API call
    await ApiService.put('/grievances/$grievanceId/status', {
      'status': newStatus,
    });

    // Fetch updated grievances first (async work outside setState)
    final updatedGrievances = _fetchAssignedGrievances();

    if (!mounted) return;

    // Update the state synchronously
    setState(() {
      _grievancesFuture = updatedGrievances;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status updated')),
    );
  } catch (e, stack) {
    print("❌ Error updating status: $e");
    print(stack);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update status: $e')),
    );
  }
}


  Future<void> _uploadWorkproof(int grievanceId, PlatformFile file) async {
    try {
      await ApiService.postMultipart(
        '/grievances/$grievanceId/workproof',
        files: [file],
        fieldName: 'file',
      );
      setState(() => _grievancesFuture = _fetchAssignedGrievances());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Work proof uploaded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
    }
  }

  Future<void> _closeGrievance(int grievanceId) async {
    try {
      await ApiService.post('/grievances/$grievanceId/close', {});
      setState(() => _grievancesFuture = _fetchAssignedGrievances());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Grievance closed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to close: $e')));
    }
  }

  void _showUpdateStatusPopup(Grievance grievance) {
    String? selectedStatus;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Update Status'),
              content: DropdownButton<String>(
                hint: const Text('Select New Status'),
                value: selectedStatus,
                items: ['in_progress', 'on_hold', 'resolved'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedStatus != null) {
                      _updateStatus(grievance.id, selectedStatus!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUploadWorkproofPopup(Grievance grievance) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt', 'mp4', 'mov'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _uploadWorkproof(grievance.id, file);
    }
  }

  Widget _buildGrievanceItem(Grievance grievance) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat(
      'yyyy-MM-dd HH:mm:ss',
    ); // For formatting dates

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Complaint ID
            Text(
              grievance.title ?? 'No Title',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Complaint ID: ${grievance.complaintId}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Divider
            const Divider(height: 16),

            // Description
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              grievance.description ?? 'No Description',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Status and Priority
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${grievance.status?.toUpperCase() ?? "N/A"}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Priority: ${grievance.priority?.toUpperCase() ?? 'N/A'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

            // Dates
            const SizedBox(height: 8),
            Text(
              'Created: ${grievance.createdAt != null ? dateFormat.format(grievance.createdAt!) : 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Updated: ${grievance.updatedAt != null ? dateFormat.format(grievance.updatedAt!) : 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (grievance.resolvedAt != null)
              Text(
                'Resolved: ${dateFormat.format(grievance.resolvedAt!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

            // Location
            const SizedBox(height: 8),
            Text('Location:', style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Area: ${grievance.area?.name ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Latitude: ${grievance.latitude ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Longitude: ${grievance.longitude ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // People
            // const SizedBox(height: 8),
            // Text(
            //   'Citizen: ${grievance.citizen?.name ?? 'N/A'}',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
            // Text(
            //   'Assignee: ${grievance.assignee?.name ?? 'N/A'}',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
            // Text(
            //   'Assigner: ${grievance.assignedBy ?? 'N/A'}',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),

            // Subject
            const SizedBox(height: 8),
            Text('Subject:', style: Theme.of(context).textTheme.titleMedium),
            Text(
              'Name: ${grievance.subject?.name ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Description: ${grievance.subject?.description ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Additional Fields
            const SizedBox(height: 8),
            if (grievance.rejectionReason != null)
              Text(
                'Rejection Reason: ${grievance.rejectionReason}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            Text(
              'Attachments: ${grievance.attachments?.isEmpty ?? true ? 'None' : grievance.attachments!.length}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Action Buttons
            const Divider(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              alignment: WrapAlignment.end,
              children: [
                if (grievance.status == 'new')
                  ElevatedButton.icon(
                    onPressed: () => _acceptGrievance(grievance.id),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showUpdateStatusPopup(grievance),
                  icon: const Icon(Icons.update),
                  label: const Text('Update Status'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showUploadWorkproofPopup(grievance),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Proof'),
                ),
                if (grievance.status == 'resolved')
                  ElevatedButton.icon(
                    onPressed: () => _closeGrievance(grievance.id),
                    icon: const Icon(Icons.close),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignedGrievances ?? 'Assigned Grievances'),
      ),
      drawer: const CustomNavigationDrawer(),
      body: FutureBuilder<List<Grievance>>(
        future: _grievancesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          } else if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error,
              title: l10n.error,
              message: '${snapshot.error}',
              actionButton: ElevatedButton(
                onPressed: () => setState(
                  () => _grievancesFuture = _fetchAssignedGrievances(),
                ),
                child: Text(l10n.retry),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyState(
              icon: Icons.hourglass_empty,
              title: l10n.noAssigned,
              message: l10n.noAssignedMessage,
            );
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _grievancesFuture = _fetchAssignedGrievances());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final grievance = snapshot.data![index];
                  return _buildGrievanceItem(grievance);
                },
              ),
            );
          }
        },
      ),
    );
  }
}

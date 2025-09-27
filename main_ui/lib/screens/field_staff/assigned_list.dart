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
  } catch (e) {
   
    
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Text(
                'Update Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                hint: const Text('Select New Status'),
                initialValue: selectedStatus,
                items: ['in_progress', 'on_hold', 'resolved'].map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 14),
                    ),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A64F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  onPressed: () {
                    if (selectedStatus != null) {
                      _updateStatus(grievance.id, selectedStatus!);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    'Update',
                    style: TextStyle(color: Colors.white),
                  ),
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

    // Status color mapping
    Color getStatusColor(String status) {
      switch (status) {
        case 'new':
          return Colors.blue;
        case 'in_progress':
          return Colors.orange;
        case 'on_hold':
          return Colors.red;
        case 'resolved':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    // Priority color mapping
    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFECF2FE), // Card background color
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    grievance.title ?? 'No Title',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A237E),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: getStatusColor(grievance.status ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: getStatusColor(grievance.status ?? ''),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    grievance.status?.toUpperCase() ?? "N/A",
                    style: TextStyle(
                      color: getStatusColor(grievance.status ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Complaint ID: ${grievance.complaintId}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),

            // Divider
            const Divider(height: 24, thickness: 1),

            // Description
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              grievance.description ?? 'No Description',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Status and Priority
            const SizedBox(height: 16),
            Row(
              children: [
                // Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: getStatusColor(grievance.status ?? ''),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            grievance.status?.replaceAll('_', ' ').toUpperCase() ?? "N/A",
                            style: TextStyle(
                              color: getStatusColor(grievance.status ?? ''),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Priority
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: getPriorityColor(grievance.priority ?? ''),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            grievance.priority?.toUpperCase() ?? 'N/A',
                            style: TextStyle(
                              color: getPriorityColor(grievance.priority ?? ''),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Dates
            const SizedBox(height: 16),
            Text(
              'Dates',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${dateFormat.format(grievance.createdAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Updated: ${dateFormat.format(grievance.updatedAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (grievance.resolvedAt != null)
              Text(
                'Resolved: ${dateFormat.format(grievance.resolvedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            // Location
            const SizedBox(height: 16),
            Text(
              'Location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Area: ${grievance.area?.name ?? 'N/A'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lat: ${grievance.latitude ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Long: ${grievance.longitude ?? 'N/A'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),

            // Subject
            const SizedBox(height: 16),
            Text(
              'Subject',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              grievance.subject?.name ?? 'N/A',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (grievance.subject?.description != null)
              Text(
                '${grievance.subject?.description}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            // Additional Fields
            const SizedBox(height: 16),
            if (grievance.rejectionReason != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    grievance.rejectionReason!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            Text(
              'Attachments: ${grievance.attachments?.isEmpty ?? true ? 'None' : grievance.attachments!.length}',
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // Action Buttons
            const Divider(height: 24, thickness: 1),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.end,
              children: [
                if (grievance.status == 'new')
                  ElevatedButton(
                    onPressed: () => _acceptGrievance(grievance.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 4),
                        Text('Accept'),
                      ],
                    ),
                  ),
                ElevatedButton(
                  onPressed: () => _showUpdateStatusPopup(grievance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.update, size: 18),
                      SizedBox(width: 4),
                      Text('Update Status'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showUploadWorkproofPopup(grievance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9800),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.upload_file, size: 18),
                      SizedBox(width: 4),
                      Text('Upload Proof'),
                    ],
                  ),
                ),
                if (grievance.status == 'resolved')
                  ElevatedButton(
                    onPressed: () => _closeGrievance(grievance.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, size: 18),
                        SizedBox(width: 4),
                        Text('Close'),
                      ],
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Background color
      appBar: AppBar(
        title: Text(l10n.assignedGrievances),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A64F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
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
                padding: const EdgeInsets.all(16.0),
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
// lib/screens/admin/complaint_management.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/services/user_service.dart';
import 'package:main_ui/services/master_data_service.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/grievance_card.dart';
import 'package:main_ui/providers/admin_provider.dart';

class ComplaintManagement extends ConsumerStatefulWidget {
  const ComplaintManagement({super.key});

  @override
  _ComplaintManagementState createState() => _ComplaintManagementState();
}

class _ComplaintManagementState extends ConsumerState<ComplaintManagement> {
  String? _selectedStatus;
  int? _selectedAreaId;
  int? _selectedSubjectId;
  String? _selectedPriority;
  List<Grievance> _grievances = [];
  List<User> _assignees = [];
  List<MasterArea> _areas = [];
  List<MasterSubject> _subjects = [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // Fetch grievances using adminProvider with proper parameters
      final grievances = await ref.read(adminProvider.notifier).getAllGrievances(
            status: _selectedStatus,
            priority: _selectedPriority,
            areaId: _selectedAreaId,
            subjectId: _selectedSubjectId,
          );
      final assignees = await UserService.getUsers();
      final areas = await MasterDataService.getAreas();
      final subjects = await MasterDataService.getSubjects();
      setState(() {
        _grievances = grievances;
        _assignees = assignees.where((u) => u.role?.toLowerCase() == 'field_staff').toList();
        _areas = areas;
        _subjects = subjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          centerTitle: true,
        ),
        body: EmptyState(
          icon: Icons.error,
          title: l10n.error,
          message: _errorMessage!,
          actionButton: CustomButton(
            text: l10n.retry,
            onPressed: _fetchData,
            icon: Icons.refresh,
          ),
        ),
      );
    }

    if (_grievances.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.appTitle),
          centerTitle: true,
        ),
        body: EmptyState(
          icon: Icons.inbox,
          title: l10n.noComplaints,
          message: l10n.noComplaintsMessage,
          actionButton: CustomButton(
            text: l10n.retry,
            onPressed: _fetchData,
            icon: Icons.refresh,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filters
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: [
                DropdownButton<String>(
                  hint: Text(l10n.filterByStatus),
                  value: _selectedStatus,
                  isExpanded: true,
                  items: ['new', 'in_progress', 'on_hold', 'resolved', 'closed', 'rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _fetchData();
                  },
                ),
                DropdownButton<String>(
                  hint: Text(l10n.filterByPriority),
                  value: _selectedPriority,
                  isExpanded: true,
                  items: ['low', 'medium', 'high', 'urgent']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.capitalize())))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedPriority = value);
                    _fetchData();
                  },
                ),
                DropdownButton<int>(
                  hint: Text(l10n.filterByArea),
                  value: _selectedAreaId,
                  isExpanded: true,
                  items: _areas
                      .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedAreaId = value);
                    _fetchData();
                  },
                ),
                DropdownButton<int>(
                  hint: Text(l10n.filterBySubject),
                  value: _selectedSubjectId,
                  isExpanded: true,
                  items: _subjects
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubjectId = value);
                    _fetchData();
                  },
                ),
                // Add a clear filters button
                CustomButton(
                  text: l10n.clearFilters,
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedPriority = null;
                      _selectedAreaId = null;
                      _selectedSubjectId = null;
                    });
                    _fetchData();
                  },
                  icon: Icons.clear,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _grievances.length,
                itemBuilder: (ctx, idx) {
                  final grievance = _grievances[idx];
                  return Card(
                    child: Column(
                      children: [
                        GrievanceCard(grievance: grievance),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Flexible(
                                child: CustomButton(
                                  text: l10n.reassignComplaint,
                                  onPressed: () => _showReassignDialog(grievance.id),
                                  icon: Icons.person_add,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: CustomButton(
                                  text: l10n.escalateComplaint,
                                  onPressed: () async {
                                    try {
                                      int newAssigneeId = 13;
                                      int admin=4;
                                      await ref.read(adminProvider.notifier).escalateGrievance(grievance.id,newAssigneeId,admin);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${l10n.escalateComplaint} Successful')),
                                      );
                                      _fetchData();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                                  icon: Icons.arrow_upward,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: CustomButton(
                                  text: l10n.updateStatus,
                                  onPressed: () => _showStatusDialog(grievance.id),
                                  icon: Icons.update,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: CustomButton(
                                  text: l10n.viewDetails,
                                  onPressed: () {
                                    if (grievance.id > 0) {
                                      Navigator.pushNamed(
                                        context,
                                        '/citizen/detail',
                                        arguments: grievance.id,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Invalid grievance ID")),
                                      );
                                    }
                                  },
                                  icon: Icons.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReassignDialog(int grievanceId) {
    final l10n = AppLocalizations.of(context)!;
    int? selectedAssigneeId;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.reassignComplaint),
              content: _assignees.isEmpty
                  ? Text('No field staff available')
                  : DropdownButton<int>(
                      hint: Text(l10n.selectAssignee),
                      value: selectedAssigneeId,
                      isExpanded: true,
                      items: _assignees
                          .map((u) => DropdownMenuItem(
                                value: u.id,
                                child: Text(u.name ?? "Unknown User"),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedAssigneeId = value);
                      },
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedAssigneeId != null) {
                      try {
                        await ref.read(adminProvider.notifier).reassignGrievance(grievanceId, selectedAssigneeId!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10n.reassignComplaint} Successful')),
                        );
                        _fetchData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.selectAssignee)),
                      );
                    }
                  },
                  child: Text(l10n.reassign),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStatusDialog(int grievanceId) {
    final l10n = AppLocalizations.of(context)!;
    String? selectedStatus;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.updateStatus),
              content: DropdownButton<String>(
                hint: Text(l10n.selectStatus),
                value: selectedStatus,
                isExpanded: true,
                items: ['new', 'in_progress', 'on_hold', 'resolved', 'closed', 'rejected']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                    .toList(),
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedStatus != null) {
                      try {
                        await ref.read(adminProvider.notifier).updateGrievanceStatus(grievanceId, selectedStatus!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${l10n.updateStatus} Successful')),
                        );
                        _fetchData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.selectStatus)),
                      );
                    }
                  },
                  child: Text(l10n.update),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
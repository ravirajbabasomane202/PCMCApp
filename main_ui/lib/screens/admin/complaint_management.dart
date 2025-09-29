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
import 'package:main_ui/widgets/custom_button_.dart';

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
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fbff),
        appBar: AppBar(
          title: Text(l10n.complaintManagement),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fbff),
        appBar: AppBar(
          title: Text(l10n.complaintManagement),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
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
        backgroundColor: const Color(0xFFf8fbff),
        appBar: AppBar(
          title: Text(l10n.complaintManagement),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 2,
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
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(l10n.complaintManagement),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            color: const Color(0xFFecf2fe),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filters,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: [
                      FilterChip(
                        label: Text(_selectedStatus?.capitalize() ?? l10n.filterByStatus),
                        selected: _selectedStatus != null,
                        onSelected: (selected) {
                          if (!selected) {
                            setState(() => _selectedStatus = null);
                            _fetchData();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedStatus != null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                        ),
                      ),
                      FilterChip(
                        label: Text(_selectedPriority?.capitalize() ?? l10n.filterByPriority),
                        selected: _selectedPriority != null,
                        onSelected: (selected) {
                          if (!selected) {
                            setState(() => _selectedPriority = null);
                            _fetchData();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedPriority != null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                        ),
                      ),
                      FilterChip(
                        label: Text(
                          _selectedAreaId != null 
                            ? _areas.firstWhere((a) => a.id == _selectedAreaId, orElse: () => MasterArea(id: 0, name: 'Unknown')).name
                            : l10n.filterByArea
                        ),
                        selected: _selectedAreaId != null,
                        onSelected: (selected) {
                          if (!selected) {
                            setState(() => _selectedAreaId = null);
                            _fetchData();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedAreaId != null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                        ),
                      ),
                      FilterChip(
                        label: Text(
                          _selectedSubjectId != null 
                            ? _subjects.firstWhere((s) => s.id == _selectedSubjectId, orElse: () => MasterSubject(id: 0, name: 'Unknown')).name
                            : l10n.filterBySubject
                        ),
                        selected: _selectedSubjectId != null,
                        onSelected: (selected) {
                          if (!selected) {
                            setState(() => _selectedSubjectId = null);
                            _fetchData();
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedSubjectId != null 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.onSurface,
                        ),
                      ),
                      ActionChip(
                        label: Text(l10n.clearFilters),
                        onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                            _selectedPriority = null;
                            _selectedAreaId = null;
                            _selectedSubjectId = null;
                          });
                          _fetchData();
                        },
                        backgroundColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(color: theme.colorScheme.onPrimary),
                        avatar: Icon(Icons.clear, size: 18, color: theme.colorScheme.onPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                itemCount: _grievances.length,
                itemBuilder: (ctx, idx) {
                  final grievance = _grievances[idx];
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 16),
                    color: const Color(0xFFecf2fe),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GrievanceCard(grievance: grievance),
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: CustomButton2(
                                      text: l10n.reassignComplaint,
                                      onPressed: grievance.assignedTo != null
                                          ? null : () => _showReassignDialog(grievance.id),
                                      icon: Icons.person_add,                                      
                                      size: ButtonSize.small,
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  // const SizedBox(width: 8),
                                  // Expanded(
                                  //   child: CustomButton2(
                                  //     text: l10n.escalateComplaint,
                                  //     onPressed: () => _showEscalateDialog(grievance.id),
                                  //     icon: Icons.arrow_upward,
                                  //     variant: ButtonVariant.outlined,
                                  //     size: ButtonSize.small,
                                  //   ),
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: CustomButton2(
                                      text: l10n.updateStatus, // Changed from updateStatus
                                      onPressed: grievance.status == 'resolved'
                                          ? null
                                          : () => _showStatusDialog(grievance.id),
                                      icon: Icons.update,                                      
                                      size: ButtonSize.small,
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomButton2(
                                      text: l10n.viewDetails,
                                      onPressed: () { // Changed from viewDetails
                                        if (grievance.id > 0) {
                                          Navigator.pushNamed(
                                            context,
                                            '/citizen/detail',
                                            arguments: grievance.id,
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text("Invalid grievance ID"),
                                              backgroundColor: theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icons.info,                                      
                                      size: ButtonSize.small,
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _showFilterDialog() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    String? tempStatus = _selectedStatus;
    String? tempPriority = _selectedPriority;
    int? tempAreaId = _selectedAreaId;
    int? tempSubjectId = _selectedSubjectId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.filters, style: theme.textTheme.titleLarge),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.filterByStatus,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: tempStatus,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.filterByStatus)),
                        ...['new', 'in_progress', 'on_hold', 'resolved', 'closed', 'rejected']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                            ,
                      ],
                      onChanged: (value) {
                        setState(() => tempStatus = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.filterByPriority,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: tempPriority,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.filterByPriority)),
                        ...['low', 'medium', 'high', 'urgent']
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.capitalize())))
                            ,
                      ],
                      onChanged: (value) {
                        setState(() => tempPriority = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n.filterByArea,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: tempAreaId,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.filterByArea)),
                        ..._areas
                            .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                            ,
                      ],
                      onChanged: (value) {
                        setState(() => tempAreaId = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n.filterBySubject,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      value: tempSubjectId,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.filterBySubject)),
                        ..._subjects
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            ,
                      ],
                      onChanged: (value) {
                        setState(() => tempSubjectId = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = tempStatus;
                      _selectedPriority = tempPriority;
                      _selectedAreaId = tempAreaId;
                      _selectedSubjectId = tempSubjectId;
                    });
                    Navigator.pop(ctx);
                    _fetchData();
                  },
                  child: Text(l10n.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // void _showEscalateDialog(int grievanceId) {
  //   final l10n = AppLocalizations.of(context)!;
  //   final theme = Theme.of(context);
  //   int? selectedAssigneeId;

  //   showDialog(
  //     context: context,
  //     builder: (ctx) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           return AlertDialog(
  //             title: Text(l10n.escalateComplaint, style: theme.textTheme.titleLarge),
  //             content: _assignees.isEmpty
  //                 ? Text('No field staff available for escalation.')
  //                 : DropdownButtonFormField<int>(
  //                     decoration: InputDecoration(
  //                       labelText: l10n.selectAssignee,
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(8),
  //                       ),
  //                     ),
  //                     value: selectedAssigneeId,
  //                     isExpanded: true,
  //                     items: _assignees
  //                         .map((u) => DropdownMenuItem(
  //                               value: u.id,
  //                               child: Text(u.name ?? "Unknown User"),
  //                             ))
  //                         .toList(),
  //                     onChanged: (value) {
  //                       setState(() => selectedAssigneeId = value);
  //                     },
  //                   ),
  //             actions: [
  //               TextButton(
  //                 onPressed: () => Navigator.pop(ctx),
  //                 child: Text(l10n.cancel),
  //               ),
  //               ElevatedButton(
  //                 onPressed: () async {
  //                   if (selectedAssigneeId != null) {
  //                     try {
  //                       // Assuming the current user is an admin with a static ID for now.
  //                       // This should be replaced with the actual logged-in admin's ID.
  //                       int adminId = 4;
  //                       await ref.read(adminProvider.notifier).escalateGrievance(grievanceId, selectedAssigneeId!, adminId);
  //                       Navigator.pop(ctx);
  //                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Grievance escalated successfully')));
  //                       _fetchData();
  //                     } catch (e) {
  //                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Escalation failed: $e')));
  //                     }
  //                   }
  //                 },
  //                 child: Text(l10n.escalate),
  //               ),
  //             ],
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  void _showReassignDialog(int grievanceId) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    int? selectedAssigneeId;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.reassignComplaint, style: theme.textTheme.titleLarge),
              content: _assignees.isEmpty
                  ? Text('No field staff available')
                  : DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: l10n.selectAssignee,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                ElevatedButton(
                  onPressed: () async {
                    if (selectedAssigneeId != null) {
                      try {
                        await ref.read(adminProvider.notifier).reassignGrievance(grievanceId, selectedAssigneeId!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.reassignComplaint} Successful'),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                        _fetchData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.selectAssignee),
                          backgroundColor: theme.colorScheme.error,
                        ),
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
    final theme = Theme.of(context);
    String? selectedStatus;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.updateStatus, style: theme.textTheme.titleLarge),
              content: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: l10n.selectStatus,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                value: selectedStatus,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.selectStatus)),
                  ...['new', 'in_progress', 'on_hold', 'resolved', 'closed', 'rejected']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.capitalize())))
                      ,
                ],
                onChanged: (value) {
                  setState(() => selectedStatus = value);
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStatus != null) {
                      try {
                        await ref.read(adminProvider.notifier).updateGrievanceStatus(grievanceId, selectedStatus!);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${l10n.updateStatus} Successful'),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                        _fetchData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: theme.colorScheme.error,
                          ),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.selectStatus),
                          backgroundColor: theme.colorScheme.error,
                        ),
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
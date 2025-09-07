import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/status_badge.dart';

class ViewGrievances extends StatefulWidget {
  const ViewGrievances({super.key});

  @override
  State<ViewGrievances> createState() => _ViewGrievancesState();
}

class _ViewGrievancesState extends State<ViewGrievances> {
  List<Grievance> grievances = [];
  List<Grievance> filteredGrievances = [];
  bool isLoading = true;
  String? selectedStatus;
  String? selectedPriority;
  String? selectedArea;
  String? selectedSubject;
  List<Map<String, dynamic>> areas = [];
  List<Map<String, dynamic>> subjects = [];
  List<Map<String, dynamic>> fieldStaff = [];
  String errorMessage = '';
  final CancelToken _cancelToken = CancelToken();

  final List<String> statuses = [
    'new',
    'in_progress',
    'on_hold',
    'resolved',
    'closed',
    'rejected'
  ];

  final List<String> priorities = ['low', 'medium', 'high', 'urgent'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await ApiService.get('/grievances/all' );
      print("📥 Raw API response: ${response.data}");

      if (response.data is! List) {
        throw Exception("Expected a list from API, got ${response.data.runtimeType}");
      }

      grievances = (response.data as List).map((e) {
        try {
          print("🔍 Parsing grievance: $e");
          return Grievance.fromJson(e);
        } catch (e) {
          print("❌ Error parsing grievance: $e");
          rethrow;
        }
      }).toList();

      print("✅ Parsed grievances list: $grievances");
      filteredGrievances = List.from(grievances);
      print("📌 Filtered grievances initialized: $filteredGrievances");

      final areasResponse = await ApiService.get('/areas' );
      areas = (areasResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];

      final subjectsResponse = await ApiService.get('/subjects' );
      subjects = (subjectsResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];

      final staffResponse = await ApiService.get('/fieldStaff/fieldStaff?role=field_staff' );
      fieldStaff = (staffResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      print("❌ Error in _loadData: $e");
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.error)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    filteredGrievances = grievances.where((g) {
      return (selectedStatus == null || g.status == selectedStatus) &&
          (selectedPriority == null || g.priority == selectedPriority) &&
          (selectedArea == null || g.areaId.toString() == selectedArea) &&
          (selectedSubject == null || g.subjectId.toString() == selectedSubject);
    }).toList();
    if (mounted) {
      setState(() {});
    }
  }

  void _showActionSheet(Grievance grievance) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.update),
              title: Text(AppLocalizations.of(context)!.updateStatus),
              onTap: () {
                Navigator.pop(ctx);
                _showUpdateStatusDialog(grievance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_ind),
              title: Text(AppLocalizations.of(context)!.assignGrievance),
              onTap: () {
                Navigator.pop(ctx);
                _showAssignDialog(grievance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: Text(AppLocalizations.of(context)!.rejectGrievance),
              onTap: () {
                Navigator.pop(ctx);
                _showRejectDialog(grievance);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(AppLocalizations.of(context)!.viewDetails),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/citizen/detail', arguments: grievance.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(Grievance grievance) {
    String? newStatus;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.updateStatus),
        content: DropdownButtonFormField<String>(
          value: newStatus,
          hint: Text(AppLocalizations.of(context)!.selectStatus),
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => newStatus = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newStatus != null) {
                try {
                  await ApiService.put('/grievances/${grievance.id}/status', {'status': newStatus});
                  if (context.mounted) Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.update),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(Grievance grievance) {
    String? assigneeId;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.assignGrievance),
        content: DropdownButtonFormField<String>(
          value: assigneeId,
          hint: Text(AppLocalizations.of(context)!.selectAssignee),
          items: fieldStaff.map((staff) => DropdownMenuItem(value: staff['id'].toString(), child: Text(staff['name'] ?? 'Unknown'))).toList(),
          onChanged: (value) => assigneeId = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (assigneeId != null) {
                try {
                  await ApiService.put('/grievances/${grievance.id}/reassign', {'assigned_to': assigneeId});
                  if (context.mounted) Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.assignGrievance),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Grievance grievance) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rejectGrievance),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(hintText: AppLocalizations.of(context)!.rejectionReason ?? 'Enter rejection reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text;
              if (reason.isNotEmpty) {
                try {
                  await ApiService.post('/grievances/${grievance.id}/reject', {'reason': reason});
                  if (context.mounted) Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.reject),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.viewgrievanceetails),
      ),
      body: isLoading
          ? const LoadingIndicator()
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  grievances.isEmpty
                      ? EmptyState(
                          icon: Icons.hourglass_empty,
                          title: l.noGrievances,
                          message: l.noGrievancesMessage,
                          actionButton: ElevatedButton(
                            onPressed: _loadData,
                            child: Text(l.retry),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterDropdown(
                                      l.filterByStatus,
                                      statuses,
                                      selectedStatus,
                                      (v) {
                                        selectedStatus = v;
                                        _applyFilters();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterDropdown(
                                      l.filterByPriority,
                                      priorities,
                                      selectedPriority,
                                      (v) {
                                        selectedPriority = v;
                                        _applyFilters();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterDropdown(
                                      l.filterByArea,
                                      areas.map((a) => a['name'] as String).toList(),
                                      selectedArea,
                                      (v) {
                                        selectedArea = v == null ? null : areas.firstWhere((a) => a['name'] == v, orElse: () => {'id': null})['id']?.toString();
                                        _applyFilters();
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    _buildFilterDropdown(
                                      l.filterBySubject,
                                      subjects.map((s) => s['name'] as String).toList(),
                                      selectedSubject,
                                      (v) {
                                        selectedSubject = v == null ? null : subjects.firstWhere((s) => s['name'] == v, orElse: () => {'id': null})['id']?.toString();
                                        _applyFilters();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: RefreshIndicator(
                                onRefresh: _loadData,
                                child: ListView.builder(
                                  itemCount: filteredGrievances.length,
                                  itemBuilder: (ctx, i) {
                                    final g = filteredGrievances[i];
                                    return Card(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(child: Text(g.title ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold))),
                                                StatusBadge(status: g.status ?? 'new'),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(g.description ?? ''),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: () => _showActionSheet(g),
                                              child: Text(l.takeAction ?? 'Take Action'),
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
                ],
              ),
            ),
    );
  }

  Widget _buildFilterDropdown(
  String label,
  dynamic items, // Can be List<String> or List<Map<String, dynamic>>
  String? selected,
  ValueChanged<String?> onChanged,
) {
  List<DropdownMenuItem<String?>> dropdownItems = [];

  // Default "All" option
  dropdownItems.add(const DropdownMenuItem(
    value: null,
    child: Text("All"),
  ));

  if (items is List<String>) {
    // Handle plain string lists (status, priority)
    dropdownItems.addAll(
      items.map(
        (s) => DropdownMenuItem(
          value: s,
          child: Text(s),
        ),
      ),
    );
  } else if (items is List<Map<String, dynamic>>) {
    // Handle maps with {id, name} (areas, subjects, staff)
    dropdownItems.addAll(
      items.map(
        (m) => DropdownMenuItem(
          value: m['id']?.toString(),
          child: Text(m['name'] ?? 'Unknown'),
        ),
      ),
    );
  }

  return DropdownButton<String?>(
    hint: Text(label),
    value: selected,
    items: dropdownItems,
    onChanged: onChanged,
  );
}

}
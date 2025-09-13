import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/loading_indicator.dart';
import 'package:main_ui/widgets/status_badge.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';

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
      final response = await ApiService.get('/grievances/all');
     

      if (response.data is! List) {
        throw Exception("Expected a list from API, got ${response.data.runtimeType}");
      }

      grievances = (response.data as List).map((e) {
        try {
         
          return Grievance.fromJson(e);
        } catch (e) {
          
          rethrow;
        }
      }).toList();

     
      filteredGrievances = List.from(grievances);
    

      final areasResponse = await ApiService.get('/areas');
      areas = (areasResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];

      final subjectsResponse = await ApiService.get('/subjects');
      subjects = (subjectsResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];

      final staffResponse = await ApiService.get('/fieldStaff/fieldStaff?role=field_staff');
      fieldStaff = (staffResponse.data as List?)?.cast<Map<String, dynamic>>() ?? [];
    } catch (e) {
      
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.update, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.updateStatus,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _showUpdateStatusDialog(grievance);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.assignment_ind, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.assignGrievance,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                _showAssignDialog(grievance);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.rejectGrievance,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _showRejectDialog(grievance);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.viewDetails,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
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
        title: Text(AppLocalizations.of(context)!.updateStatus,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: DropdownButtonFormField<String>(
          initialValue: newStatus,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffecf2fe),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(AppLocalizations.of(context)!.selectStatus),
          items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (value) => newStatus = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            child: Text(AppLocalizations.of(context)!.update,
                style: const TextStyle(color: Colors.white)),
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
        title: Text(AppLocalizations.of(context)!.assignGrievance,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: DropdownButtonFormField<String>(
          initialValue: assigneeId,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xffecf2fe),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          hint: Text(AppLocalizations.of(context)!.selectAssignee),
          items: fieldStaff.map((staff) => DropdownMenuItem(value: staff['id'].toString(), child: Text(staff['name'] ?? 'Unknown'))).toList(),
          onChanged: (value) => assigneeId = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            child: Text(AppLocalizations.of(context)!.assignGrievance,
                style: const TextStyle(color: Colors.white)),
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
        title: Text(AppLocalizations.of(context)!.rejectGrievance,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.rejectionReason ?? 'Enter rejection reason',
            filled: true,
            fillColor: const Color(0xffecf2fe),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
            child: Text(AppLocalizations.of(context)!.reject,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xfff8fbff),
      appBar: AppBar(
        title: Text(l.viewgrievanceetails,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      drawer: const CustomNavigationDrawer(),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l.retry, style: const TextStyle(color: Colors.white)),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.white,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Filters",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
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
                                      _buildFilterDropdown(
                                        l.filterByPriority,
                                        priorities,
                                        selectedPriority,
                                        (v) {
                                          selectedPriority = v;
                                          _applyFilters();
                                        },
                                      ),
                                      _buildFilterDropdown(
                                        l.filterByArea,
                                        areas.map((a) => a['name'] as String).toList(),
                                        selectedArea,
                                        (v) {
                                          selectedArea = v == null
                                              ? null
                                              : areas.firstWhere((a) => a['name'] == v, orElse: () => {'id': null})['id']?.toString();
                                          _applyFilters();
                                        },
                                      ),
                                      _buildFilterDropdown(
                                        l.filterBySubject,
                                        subjects.map((s) => s['name'] as String).toList(),
                                        selectedSubject,
                                        (v) {
                                          selectedSubject = v == null
                                              ? null
                                              : subjects.firstWhere((s) => s['name'] == v, orElse: () => {'id': null})['id']?.toString();
                                          _applyFilters();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filteredGrievances.length,
                                itemBuilder: (ctx, i) {
                                  final g = filteredGrievances[i];
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffecf2fe),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(g.title ?? 'Untitled',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold, fontSize: 16)),
                                              ),
                                              StatusBadge(status: g.status ?? 'new'),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(g.description ?? '',
                                              style: TextStyle(color: Colors.grey[700])),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (g.priority != null)
                                                Chip(
                                                  label: Text(g.priority!,
                                                      style: const TextStyle(fontSize: 12, color: Colors.white)),
                                                  backgroundColor: _getPriorityColor(g.priority!),
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                ),
                                              const Spacer(),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: () => _showActionSheet(g),
                                                child: Text(l.takeAction ?? 'Take Action',
                                                    style: const TextStyle(color: Colors.white)),
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
                          ],
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    dynamic items,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    List<DropdownMenuItem<String?>> dropdownItems = [];

    // Default "All" option
    dropdownItems.add(const DropdownMenuItem(
      value: null,
      child: Text("All", style: TextStyle(color: Colors.grey)),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffecf2fe),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String?>(
        hint: Text(label, style: const TextStyle(fontSize: 14)),
        value: selected,
        items: dropdownItems,
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
        isDense: true,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.orangeAccent;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
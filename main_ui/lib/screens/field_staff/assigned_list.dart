// lib/screens/field_staff/assigned_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/providers/user_provider.dart';

// Define a provider for fetching assigned grievances
final assignedGrievancesProvider = FutureProvider<List<Grievance>>((ref) async {
  final user = ref.watch(userNotifierProvider);
  if (user == null || user.role != 'field_staff') {
    return [];
  }
  final response = await ApiService.get('/grievances/assigned');
  return (response.data as List)
      .map((json) => Grievance.fromJson(json))
      .toList();
});

// Separate card widget for field staff grievances
class FieldStaffGrievanceCard extends StatelessWidget {
  final Grievance grievance;
  const FieldStaffGrievanceCard({super.key, required this.grievance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.colorScheme.surfaceVariant,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.pushNamed(
          context,
          '/employer/detail',
          arguments: grievance.id,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      grievance.title ?? 'Untitled Grievance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(grievance.status ?? 'new', theme),
                      const SizedBox(width: 8),
                      Text(
                        grievance.priority?.toUpperCase() ?? 'N/A',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                grievance.description ?? 'No description provided',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        grievance.createdAt != null
                            ? _formatDate(grievance.createdAt!)
                            : 'Unknown date',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (grievance.escalationLevel != null &&
                      grievance.escalationLevel! > 0)
                    Chip(
                      label: Text('Escalated: Level ${grievance.escalationLevel}'),
                      backgroundColor: Colors.orange.withOpacity(0.2),
                      labelStyle: const TextStyle(color: Colors.orange),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Quick action buttons specific to field staff
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/employer/update',
                      arguments: grievance.id,
                    ),
                    icon: const Icon(Icons.update),
                    label: const Text('Update Status'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/employer/upload',
                      arguments: grievance.id,
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Proof'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ThemeData theme) {
    Color color;
    switch (status) {
      case 'new':
        color = Colors.blue;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'resolved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'on_hold':
        color = Colors.yellow;
        break;
      case 'closed':
        color = Colors.grey;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 1) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

class AssignedList extends ConsumerWidget {
  const AssignedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final grievancesAsync = ref.watch(assignedGrievancesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignedGrievances ?? 'Assigned Grievances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(),
      body: grievancesAsync.when(
        data: (grievances) {
          if (grievances.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_turned_in,
              title: l10n.noAssigned,
              message:
                  l10n.noAssignedMessage ?? 'No assigned grievances yet.',
              actionButton: TextButton(
                onPressed: () => ref.refresh(assignedGrievancesProvider),
                child: Text(l10n.retry),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(assignedGrievancesProvider.future),
            child: ListView.builder(
              itemCount: grievances.length,
              itemBuilder: (context, index) {
                final grievance = grievances[index];
                return FieldStaffGrievanceCard(grievance: grievance);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.error,
          message: l10n.failedToLoadGrievance,
          actionButton: TextButton(
            onPressed: () => ref.refresh(assignedGrievancesProvider),
            child: Text(l10n.retry),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employer/update');
        },
        child: const Icon(Icons.update),
        tooltip: l10n.updateStatus,
      ),
    );
  }
}

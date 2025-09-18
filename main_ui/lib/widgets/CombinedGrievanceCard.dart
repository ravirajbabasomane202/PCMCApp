import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/status_badge.dart';

class CombinedGrievanceCard extends StatelessWidget {
  final Grievance grievance;

  const CombinedGrievanceCard({super.key, required this.grievance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = grievance.status?.toLowerCase() ?? 'new';

    return Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  color: const Color(0xFFECF2FE),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.pushNamed(
      context,
      '/citizen/detail',
      arguments: grievance.id,
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Grievance Details Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grievance.title ?? 'Untitled Grievance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      grievance.description ?? 'No description provided',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(179),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(grievance.createdAt!),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  StatusBadge(status: status),
                  const SizedBox(width: 8),
                  Text(
                    grievance.priority ?? 'N/A',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Divider Line
          const SizedBox(height: 16),
          Divider(
            color: theme.colorScheme.onSurface.withAlpha(128),
            thickness: 1,
          ),
          const SizedBox(height: 16),
          // Grievance Progress Section
          Text(
            'Grievance Progress',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(4, (index) {
              final stage = {
                0: {'status': 'new', 'label': 'Submitted', 'icon': Icons.send},
                1: {'status': 'in_progress', 'label': 'Reviewed by Supervisor ', 'icon': Icons.visibility},
                2: {'status': 'in_progress', 'label': 'Assigned to Field Staff', 'icon': Icons.assignment_ind},
                3: {'status': 'resolved', 'label': 'Resolved', 'icon': Icons.check_circle},
              }[index]!;
              final isActive = index <= _getCurrentStageIndex(status, grievance);
              final isCompleted = index < _getCurrentStageIndex(status, grievance);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(51),
                        ),
                        child: Icon(
                          stage['icon'] as IconData,
                          size: 20,
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withAlpha(102),
                        ),
                      ),
                      if (index < 3)
                        Container(
                          width: 2,
                          height: 40,
                          color: isActive
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(51),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage['label'] as String,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                        if (isActive)
                          Text(
                            _getStageDetails(index, status, grievance),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(179),
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ),
  ),
);

  }

  int _getCurrentStageIndex(String status, Grievance grievance) {
    if (status == 'in_progress' && grievance.assignedTo != null) {
      return 2; // Assigned to Field Staff
    } else if (status == 'in_progress') {
      return 1; // Reviewed by Member Head
    } else if (status == 'resolved' || status == 'closed') {
      return 3; // Resolved
    }
    return 0; // Submitted
  }

  String _getStageDetails(int index, String status, Grievance grievance) {
    switch (index) {
      case 0:
        return 'Submitted on ${_formatDate(grievance.createdAt)}';
      case 1:
        return 'Reviewed by Supervisor ${grievance.assignedBy != null ? " (User ${grievance.assignedBy})" : ""}';
      case 2:
        return 'Assigned to${grievance.assignee?.name != null ? " ${grievance.assignee!.name}" : " Field Staff"}';
      case 3:
        return 'Resolved on ${_formatDate(grievance.resolvedAt)}';
      default:
        return '';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 1) {
      return 'Submitted ${difference.inDays} days ago';
    } else if (difference.inDays == 1) {
      return 'Submitted 1 day ago';
    } else if (difference.inHours > 1) {
      return 'Submitted ${difference.inHours} hours ago';
    } else if (difference.inMinutes > 1) {
      return 'Submitted ${difference.inMinutes} minutes ago';
    } else {
      return 'Submitted just now';
    }
  }
}
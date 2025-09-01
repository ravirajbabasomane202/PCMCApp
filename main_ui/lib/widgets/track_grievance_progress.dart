import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/status_badge.dart';

class TrackGrievanceProgress extends StatelessWidget {
  final Grievance grievance;

  const TrackGrievanceProgress({super.key, required this.grievance});

  static const _stages = [
    {'status': 'new', 'label': 'Submitted', 'icon': Icons.send},
    {'status': 'in_progress', 'label': 'Reviewed by Member Head', 'icon': Icons.visibility},
    {'status': 'in_progress', 'label': 'Assigned to Field Staff', 'icon': Icons.assignment_ind},
    {'status': 'resolved', 'label': 'Resolved', 'icon': Icons.check_circle},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = grievance.status?.toLowerCase() ?? 'new';

    final currentStageIndex = _getCurrentStageIndex(status, grievance);

    return Card(
      elevation: 2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grievance Progress',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              children: List.generate(_stages.length, (index) {
                final stage = _stages[index];
                final isActive = index <= currentStageIndex;
                final isCompleted = index < currentStageIndex;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Semantics(
                          label: stage['label'] as String, // Provide accessibility label
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withOpacity(0.2),
                            ),
                            child: Icon(
                              stage['icon'] as IconData,
                              size: 20,
                              color: isActive
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          ),
                        ),
                        if (index < _stages.length - 1)
                          Container(
                            width: 2,
                            height: 40,
                            color: isActive
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.2),
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
                                  : theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          if (isActive)
                            Text(
                              _getStageDetails(index, status, grievance),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
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
        return 'Reviewed by Member Head${grievance.assignedBy != null ? " (User ${grievance.assignedBy})" : ""}';
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
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
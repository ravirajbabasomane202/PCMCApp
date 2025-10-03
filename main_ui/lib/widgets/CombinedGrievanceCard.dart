import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/status_badge.dart';
import 'package:main_ui/l10n/app_localizations.dart'; // Import AppLocalizations

class CombinedGrievanceCard extends StatelessWidget {
  final Grievance grievance;
  final VoidCallback? onTap;

  // Define stage keys for localization
  static const _stageKeys = [
    {'status': 'new', 'key': 'stageSubmitted', 'icon': Icons.send},
    {'status': 'in_progress', 'key': 'stageReviewedBySupervisor', 'icon': Icons.visibility},
    {'status': 'in_progress', 'key': 'stageAssignedToFieldStaff', 'icon': Icons.assignment_ind},
    {'status': 'resolved', 'key': 'stageResolved', 'icon': Icons.check_circle},
  ];

  const CombinedGrievanceCard({super.key, required this.grievance, this.onTap});

  // Helper to get localized stage labels
  String _getLocalizedStageLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'stageSubmitted':
        return l10n.stageSubmitted;
      case 'stageReviewedBySupervisor':
        return l10n.stageReviewedBySupervisor;
      case 'stageAssignedToFieldStaff':
        return l10n.stageAssignedToFieldStaff;
      case 'stageResolved':
        return l10n.stageResolved;
      default:
        return key; // Fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = grievance.status?.toLowerCase() ?? 'new';
    final l10n = AppLocalizations.of(context)!; // Get l10n instance

    return Card(
  elevation: 2,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  color: const Color(0xFFECF2FE),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),    onTap: onTap,
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
                          _formatDate(grievance.createdAt!, l10n), // Pass l10n
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
                  Text( // Priority is data, but 'N/A' is a static string
                    grievance.priority ?? l10n.notApplicable,
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
          Text( // Localize "Grievance Progress"
            l10n.grievanceProgressTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(_stageKeys.length, (index) {
              final stageData = _stageKeys[index];
              final String stageLabel = _getLocalizedStageLabel(stageData['key'] as String, l10n);
              final isActive = index <= _getCurrentStageIndex(status, grievance);

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
                              stageData['icon'] as IconData,
                          size: 20,
                          color: isActive
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface.withAlpha(102),
                        ),
                      ),
                      if (index < 3)
                          Container( // Corrected to use _stageKeys.length - 1 for maintainability
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
                          Text( // Use localized label
                            stageLabel,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                            color: isActive
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withAlpha(128),
                          ),
                        ),
                        if (isActive)
                          Text(
                              _getStageDetails(index, status, grievance, l10n), // Pass l10n
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

  String _getStageDetails(int index, String status, Grievance grievance, AppLocalizations l10n) {
    switch (index) {
      case 0:
        return '${l10n.submittedOn} ${_formatDate(grievance.createdAt, l10n)}';
      case 1:
        return '${l10n.stageReviewedBySupervisor}${grievance.assignedBy != null ? " (${l10n.userLabel} ${grievance.assignedBy})" : ""}';
      case 2:
        return '${l10n.assignedToLabel}${grievance.assignee?.name != null ? " ${grievance.assignee!.name}" : " ${l10n.fieldStaffLabel}"}';
      case 3:
        return '${l10n.resolvedOn} ${_formatDate(grievance.resolvedAt, l10n)}';
      default:
        return '';
    }
  }

  String _formatDate(DateTime? date, AppLocalizations l10n) {
    if (date == null) return l10n.notApplicable;
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays > 1) {
      return l10n.timeAgoDays(difference.inDays);
    } else if (difference.inDays == 1) {
      return l10n.timeAgoDays(1); // Use plural for singular case
    } else if (difference.inHours > 1) {
      return l10n.timeAgoHours(difference.inHours);
    } else if (difference.inMinutes > 1) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    } else {
      return l10n.timeAgoJustNow;
    }
  }
}
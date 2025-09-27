// main_ui/lib/widgets/status_badge.dart
import 'package:flutter/material.dart';
import 'package:main_ui/l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get color {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'on_hold':
        // return Colors.yellow;
        return const Color(0xFF6B21A8);
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String displayText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'new':
        return l10n.statusNew;
      case 'in_progress':
        return l10n.statusInProgress;
      case 'resolved':
        return l10n.statusResolved;
      case 'rejected':
        return l10n.statusRejected;
      case 'on_hold':
        return l10n.statusOnHold;
      case 'closed':
        return l10n.statusClosed;
      default:
        return l10n.statusUnknown;
    }
  }

  IconData get icon {
    switch (status) {
      case 'new':
        return Icons.fiber_new_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'on_hold':
        return Icons.pause_circle_rounded;
      case 'closed':
        return Icons.done_all_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues (alpha:0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues (alpha:0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            displayText(context),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
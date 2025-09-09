import 'package:flutter/material.dart';
import '../models/grievance_model.dart';
import 'status_badge.dart';

class GrievanceCard extends StatelessWidget {
  final Grievance grievance;
  
  const GrievanceCard({super.key, required this.grievance,});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      grievance.title ?? 'Untitled Grievance',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      StatusBadge(status: grievance.status ?? 'new'),
                      const SizedBox(width: 8),
                      Text(
                        grievance.priority ?? 'N/A',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues (alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                grievance.description ?? 'No description provided',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues (alpha: 0.7),
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
                    color: theme.colorScheme.onSurface.withValues (alpha:0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    grievance.createdAt != null
                        ? _formatDate(grievance.createdAt!)
                        : 'Unknown date',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues (alpha:0.5),
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

  String _formatDate(DateTime date) {
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
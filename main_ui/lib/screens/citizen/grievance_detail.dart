import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/grievance_model.dart';
import '../../models/comment_model.dart';
import '../../services/grievance_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/comment_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_button.dart';

// Provider for grievance details
final grievanceProvider = FutureProvider.family<Grievance, int>((ref, id) async {
  return await GrievanceService().getGrievanceDetails(id);
});

class GrievanceDetail extends ConsumerStatefulWidget {
  final int id;

  const GrievanceDetail({super.key, required this.id});

  @override
  ConsumerState<GrievanceDetail> createState() => _GrievanceDetailState();
}

class _GrievanceDetailState extends ConsumerState<GrievanceDetail> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int? _rating;

  @override
  void dispose() {
    _feedbackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commentCannotBeEmpty),
        ),
      );
      return;
    }
    
    try {
      await GrievanceService().addComment(widget.id, _commentController.text);
      _commentController.clear();
      ref.refresh(grievanceProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commentAddedSuccess),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToAddComment),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grievanceAsync = ref.watch(grievanceProvider(widget.id));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.grievanceDetails),
      ),
      body: grievanceAsync.when(
        data: (grievance) => _buildGrievanceDetail(theme, l10n, grievance),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.error,
          title: l10n.error,
          message: l10n.failedToLoadGrievance,
        ),
      ),
    );
  }

  Widget _buildGrievanceDetail(ThemeData theme, AppLocalizations l10n, Grievance grievance) {
    return Column(
      children: [
        // Grievance details section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with title and status
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grievance.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            StatusBadge(status: grievance.status ?? 'Unknown'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () {
                                ref.refresh(grievanceProvider(widget.id));
                              },
                              tooltip: 'Refresh',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Details section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildDetailRow(theme, 'Description', grievance.description),
                        
                        if (grievance.subject != null)
                          _buildDetailRow(theme, 'Subject', grievance.subject!.name),
                        
                        if (grievance.area != null)
                          _buildDetailRow(theme, 'Area', grievance.area!.name),
                        
                        if (grievance.priority != null)
                          _buildDetailRow(theme, 'Priority', grievance.priority?.toString() ?? 'medium'),
                        
                        _buildDetailRow(
                          theme, 
                          'Created', 
                          DateFormat('MMM dd, yyyy - HH:mm').format(grievance.createdAt)
                        ),
                        
                        if (grievance.updatedAt != grievance.createdAt)
                          _buildDetailRow(
                            theme, 
                            'Last Updated', 
                            DateFormat('MMM dd, yyyy - HH:mm').format(grievance.updatedAt)
                          ),
                        
                        if (grievance.assignee != null)
                          _buildDetailRow(theme, 'Assigned To', grievance.assignee!.name ?? ""),
                      ],
                    ),
                  ),
                ),
                
                // Attachments section
                if (grievance.attachments != null && grievance.attachments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: grievance.attachments!.map((attachment) {
                              return Chip(
                                avatar: const Icon(Icons.attachment, size: 18),
                                label: Text(
                                  attachment.filePath.split('/').last,
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // Comments section
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comments',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (grievance.comments != null && grievance.comments!.isNotEmpty)
                          ...grievance.comments!.map((comment) {
                            return CommentTile(comment: comment);
                          }).toList()
                        else
                          EmptyState(
                            icon: Icons.comment,
                            title: l10n.noComments,
                            message: l10n.noCommentsMessage,
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Feedback section (only for resolved grievances)
                if (grievance.status == 'resolved') ...[
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.submitFeedback,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Text(
                            l10n.selectRating,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          
                          Wrap(
                            spacing: 8,
                            children: List.generate(5, (index) {
                              final rating = index + 1;
                              return ChoiceChip(
                                label: Text('$rating'),
                                selected: _rating == rating,
                                onSelected: (selected) {
                                  setState(() {
                                    _rating = selected ? rating : null;
                                  });
                                },
                              );
                            }),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextField(
                            controller: _feedbackController,
                            decoration: InputDecoration(
                              labelText: l10n.feedback,
                              border: const OutlineInputBorder(),
                              filled: true,
                            ),
                            maxLines: 3,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          CustomButton(
                            text: l10n.submit,
                            onPressed: () async {
                              if (_rating == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.pleaseProvideRating),
                                  ),
                                );
                                return;
                              }
                              
                              try {
                                await GrievanceService().submitFeedback(
                                  widget.id,
                                  _rating!,
                                  _feedbackController.text,
                                );
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(l10n.feedbackSubmitted),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                
                                _feedbackController.clear();
                                setState(() {
                                  _rating = null;
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${l10n.error}: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icons.send,
                            fullWidth: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Add comment section
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: l10n.addComment,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _addComment,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/grievance_model.dart';
import '../../models/comment_model.dart';
import '../../services/grievance_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/comment_tile.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_button.dart';
import '../../services/api_service.dart'; // Import ApiService for baseUrl
import '../../providers/user_provider.dart';
import 'package:main_ui/utils/constants.dart';
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
  List<PlatformFile> _selectedFiles = [];

  @override
  void dispose() {
    _feedbackController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String path) async {
    final String url = '${Constants.baseUrl}/uploads/$path';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.couldNotLaunchUrl(url))),
        );
      }
    }
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
      await GrievanceService().addComment(widget.id, _commentController.text, attachments: _selectedFiles);
      _commentController.clear();
      setState(() {
        _selectedFiles = [];
      });
      ref.refresh(grievanceProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.commentAddedSuccess),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToAddComment}: $e'),
        ),
      );
    }
  }

  Future<void> _deleteGrievance() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await GrievanceService().deleteGrievance(widget.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.grievanceDeletedSuccessfully ?? 'Grievance deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Pop with a result to indicate success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.failedToDeleteGrievance}: $e')),
      );
    }
  }

  void _onMenuSelected(String value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == 'edit') {
      // The route '/citizen/edit' is not defined in your routes.dart.
      // Assuming you have an EditGrievance screen.
      // Navigator.push(context, MaterialPageRoute(builder: (context) => EditGrievance(id: widget.id))).then((_) {
      Navigator.pushNamed(context, '/citizen/edit', arguments: widget.id).then((result) {
        // Refresh data after returning from the edit screen
        ref.refresh(grievanceProvider(widget.id));
      });
    } else if (value == 'delete') {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.confirmDelete),
          content: Text(l10n.areYouSureDeleteGrievance),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteGrievance();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.delete),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final grievanceAsync = ref.watch(grievanceProvider(widget.id));
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentUser = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.grievanceDetails),
        actions: [
          // Show menu only if user is the owner (citizen) or admin
          if (currentUser != null &&
              (grievanceAsync.value?.citizenId == currentUser.id ||
                  currentUser.role?.toLowerCase() == 'admin'))
            PopupMenuButton<String>( // Already localized
              onSelected: _onMenuSelected,
              itemBuilder: (context) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            )
        ],
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
                  color: const Color(0xFFecf2fe), 
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
                              tooltip: l10n.refresh,
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
                  color: const Color(0xFFecf2fe), 
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.details,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        _buildDetailRow(theme, l10n.description, grievance.description),
                        
                        if (grievance.subject != null)
                          _buildDetailRow(theme, l10n.filterBySubject, grievance.subject!.name),
                        
                        if (grievance.area != null)
                          _buildDetailRow(theme, l10n.filterByArea, grievance.area!.name),
                        
                        if (grievance.priority != null)
                          _buildDetailRow(theme, l10n.filterByPriority, grievance.priority?.toString() ?? 'medium'),
                        
                        _buildDetailRow(
                          theme, 
                          l10n.created,
                          DateFormat('MMM dd, yyyy - HH:mm').format(grievance.createdAt)
                        ),
                        
                        if (grievance.updatedAt != grievance.createdAt)
                          _buildDetailRow(
                            theme, 
                            l10n.lastUpdated,
                            DateFormat('MMM dd, yyyy - HH:mm').format(grievance.updatedAt)
                          ),
                        
                        if (grievance.assignee != null)
                          _buildDetailRow(theme, l10n.assignedToLabel, grievance.assignee!.name ?? ""),
                      ],
                    ),
                  ),
                ),
                
                // Attachments section
                if (grievance.attachments != null && grievance.attachments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: const Color(0xFFecf2fe), 
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.attachments,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Show file previews
                          Column(
                            children: grievance.attachments!.map((attachment) {
                              final fileName = attachment.filePath.split('/').last;
                              final isImage = fileName.endsWith('.jpg') ||
                                              fileName.endsWith('.jpeg') ||
                                              fileName.endsWith('.png');

                              return GestureDetector(
                                onTap: () {
                                  _launchURL(attachment.filePath);
                                },
                                child: Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        isImage
                                            ? Image.network(
                                                '${Constants.baseUrl}/uploads/${attachment.filePath}', // Prepend base URL and /uploads/
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const Icon(Icons.broken_image, size: 40),
                                              )
                                            : const Icon(Icons.insert_drive_file, size: 40),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(fileName,
                                              style: theme.textTheme.bodyMedium),
                                        ),
                                        const Icon(Icons.open_in_new, size: 20),
                                      ],
                                    ),
                                  ),
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
                  color: const Color(0xFFecf2fe), 
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.comments,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (grievance.comments != null && grievance.comments!.isNotEmpty)
                          ...grievance.comments!.map((comment) {
                            return CommentTile(comment: comment);
                          })
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
                    color: const Color(0xFFecf2fe), 
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedFiles.isNotEmpty)
                SizedBox(
                  height: 50,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedFiles.map((file) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(
                        label: Text(file.name, overflow: TextOverflow.ellipsis),
                        onDeleted: () {
                          setState(() {
                            _selectedFiles.remove(file);
                          });
                        },
                      ),
                    )).toList(),
                  ),
                ),
              Row(
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
                    icon: const Icon(Icons.attach_file),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
                      if (result != null) {
                        setState(() => _selectedFiles.addAll(result.files));
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ],
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
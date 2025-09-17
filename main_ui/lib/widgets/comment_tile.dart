// lib/widgets/comment_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/comment_model.dart';
import '../utils/constants.dart';
import '../../providers/user_provider.dart';


class CommentTile extends ConsumerWidget {
  final Comment comment;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const CommentTile({
    super.key,
    required this.comment,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userNotifierProvider);
    final isCurrentUser = currentUser != null && currentUser.id == comment.userId;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            _buildAvatar(context, isCurrentUser),
            const SizedBox(width: 12.0),
          ],
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isCurrentUser 
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: _getBorderRadius(isCurrentUser),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isCurrentUser),
                    const SizedBox(height: 8.0),
                    _buildCommentText(context),
                    const SizedBox(height: 8.0),
                    _buildTimestamp(context),
                    if (comment.attachments != null && comment.attachments!.isNotEmpty)
                      _buildAttachments(context, isCurrentUser),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 12.0),
            _buildAvatar(context, isCurrentUser),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool isCurrentUser) {
    return CircleAvatar(
      radius: 16.0,
      backgroundColor: isCurrentUser
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.secondary,
      child: Text(
        comment.userName?.isNotEmpty == true 
            ? comment.userName![0].toUpperCase()
            : 'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isCurrentUser) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isCurrentUser) ...[
          Icon(
            Icons.comment_outlined,
            size: 14.0,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6.0),
        ],
        Flexible(
          child: Text(
            comment.userName ?? 'User ${comment.userId}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isCurrentUser 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isCurrentUser) ...[
          const SizedBox(width: 6.0),
          Icon(
            Icons.comment_outlined,
            size: 14.0,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
        ],
      ],
    );
  }

  Widget _buildCommentText(BuildContext context) {
    return Text(
      comment.commentText ?? "",
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        height: 1.4,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildTimestamp(BuildContext context) {
    return Text(
      _formatDateTime(comment.createdAt),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontSize: 11.0,
      ),
    );
  }

  Widget _buildAttachments(BuildContext context, bool isCurrentUser) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: comment.attachments!.map((attachment) {
          final fileName = attachment.filePath.split('/').last;
          final isImage = fileName.endsWith('.jpg') ||
              fileName.endsWith('.jpeg') ||
              fileName.endsWith('.png');

          return GestureDetector(
            onTap: () => _launchURL(context, attachment.filePath),
            child: Container(
              margin: const EdgeInsets.only(top: 8.0),
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: isCurrentUser
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.dividerColor,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: Image.network(
                            '${Constants.baseUrl}/uploads/${attachment.filePath}',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 30),
                          ),
                        )
                      : Icon(Icons.insert_drive_file, size: 30, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(fileName, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  BorderRadius _getBorderRadius(bool isCurrentUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(16.0),
      topRight: const Radius.circular(16.0),
      bottomLeft: isCurrentUser ? const Radius.circular(16.0) : const Radius.circular(4.0),
      bottomRight: isCurrentUser ? const Radius.circular(4.0) : const Radius.circular(16.0),
    );
  }

  String _formatDateTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime.toLocal());

  print('DEBUG: now=$now, dateTime=$dateTime');
  print('DEBUG: difference=$difference '
      '(minutes=${difference.inMinutes}, hours=${difference.inHours}, days=${difference.inDays})');

  if (difference.inMinutes < 1) {
    print('DEBUG: Returning → Just now');
    return 'Just now';
  } else if (difference.inMinutes < 60) {
    print('DEBUG: Returning → ${difference.inMinutes}m ago');
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    print('DEBUG: Returning → ${difference.inHours}h ago');
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    print('DEBUG: Returning → ${difference.inDays}d ago');
    return '${difference.inDays}d ago';
  } else {
    final formatted = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    print('DEBUG: Returning → $formatted');
    return formatted;
  }
}

  Future<void> _launchURL(BuildContext context, String path) async {
    final String url = '${Constants.baseUrl}/uploads/$path';
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

}
// lib/widgets/comment_tile.dart
import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class CommentTile extends StatelessWidget {
  final Comment comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final created =
        comment.createdAt.toLocal().toString().split('.').first; // simple format
    return ListTile(
      leading: const Icon(Icons.comment, color: Colors.blue),
      title: Text(
        comment.commentText ?? "" , // <- from your model
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        'User ${comment.userId} • $created',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

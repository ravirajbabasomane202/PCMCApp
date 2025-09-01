// lib/screens/admin/manage_subjects.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/master_data_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../services/master_data_service.dart'; // Import MasterDataService for subjectsProvider

class ManageSubjects extends ConsumerStatefulWidget {
  const ManageSubjects({super.key});

  @override
  ConsumerState<ManageSubjects> createState() => _ManageSubjectsState();
}

class _ManageSubjectsState extends ConsumerState<ManageSubjects> {
  void _showSubjectDialog({MasterSubject? subject}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(subject == null ? 'Add Subject' : 'Edit Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Name'),
                controller: TextEditingController(text: subject?.name ?? ''),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: TextEditingController(text: subject?.description ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                // TODO: Implement actual save logic with form data
                await ApiService.post('/admin/subjects', {/* form data */});
                ref.invalidate(subjectsProvider); // Refresh subjectsProvider
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider); // Use subjectsProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSubjectDialog(),
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.error,
          title: 'Error',
          message: error.toString(),
          actionButton: CustomButton(
            text: 'Retry',
            onPressed: () => ref.refresh(subjectsProvider), // Refresh provider
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return const EmptyState(
              icon: Icons.category,
              title: 'No Subjects',
              message: 'There are no subjects to display.',
            );
          }
          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ListTile(
                title: Text(subject.name),
                subtitle: Text(subject.description ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showSubjectDialog(subject: subject),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
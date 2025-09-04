import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/master_data_model.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../services/master_data_service.dart';

class ManageSubjects extends ConsumerStatefulWidget {
  const ManageSubjects({super.key});

  @override
  ConsumerState<ManageSubjects> createState() => _ManageSubjectsState();
}

class _ManageSubjectsState extends ConsumerState<ManageSubjects> {
  void _showSubjectDialog({MasterSubject? subject}) {
    final nameController = TextEditingController(text: subject?.name ?? '');
    final descriptionController = TextEditingController(text: subject?.description ?? '');

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
                controller: nameController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Description'),
                controller: descriptionController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                final data = {
                  "name": nameController.text.trim(),
                  "description": descriptionController.text.trim(),
                };

                try {
                  final response = subject == null
                      ? await ApiService.post('/admins/subjects', data)
                      : await ApiService.put('/admins/subjects/${subject.id}', data);
                  print(response); // debug
                  ref.invalidate(subjectsProvider); // refresh list
                  Navigator.pop(context);
                } catch (e) {
                  print("Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);

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
            onPressed: () => ref.refresh(subjectsProvider),
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
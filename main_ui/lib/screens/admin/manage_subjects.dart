import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/master_data_model.dart';
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fbff),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject == null ? 'Add Subject' : 'Edit Subject',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: nameController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        // FIX: Wrap CustomButton with SizedBox to provide constraints
                        SizedBox(
                          width: 100, // Provide explicit width constraint
                          child: CustomButton(
                            text: 'Save',
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                final data = {
                                  "name": nameController.text.trim(),
                                  "description": descriptionController.text.trim(),
                                };

                                try {
                                  if (subject == null) {
                                    await MasterDataService.addSubject(data);
                                  } else {
                                    await MasterDataService.updateSubject(subject.id, data);
                                  }
                                  ref.invalidate(subjectsProvider); // refresh list
                                  Navigator.pop(context);
                                } catch (e) {
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSubject(MasterSubject subject) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Subject'),
        content: Text(
            'Are you sure you want to delete "${subject.name}"? This might fail if it is being used by any grievances.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await MasterDataService.deleteSubject(subject.id);
        ref.invalidate(subjectsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subject deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: const Text(
          'Manage Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showSubjectDialog(),
            tooltip: 'Add New Subject',
          ),
        ],
      ),
      body: subjectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: EmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Subjects',
            message: error.toString(),
            actionButton: CustomButton(
              text: 'Retry',
              onPressed: () => ref.refresh(subjectsProvider),
              icon: Icons.refresh,
            ),
          ),
        ),
        data: (subjects) {
          if (subjects.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.category,
                title: 'No Subjects',
                message: 'There are no subjects to display. Add a new subject to get started.',
                actionButton: CustomButton(
                  text: 'Add Subject',
                  onPressed: () => _showSubjectDialog(),
                  icon: Icons.add,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subjects (${subjects.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: subjects.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFecf2fe),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Text(
                            subject.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: subject.description != null && subject.description!.isNotEmpty
                              ? Text(
                                  subject.description!,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: theme.colorScheme.primary,
                                ),
                                onPressed: () => _showSubjectDialog(subject: subject),
                                tooltip: 'Edit Subject',
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => _confirmDeleteSubject(subject),
                                tooltip: 'Delete Subject',
                              ),
                            ],
                          ),
                          onTap: () => _showSubjectDialog(subject: subject),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSubjectDialog(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:main_ui/services/master_data_service.dart';
import 'package:dio/dio.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/widgets/loading_indicator.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({super.key});

  @override
  _ManageAreasScreenState createState() => _ManageAreasScreenState();
}

class _ManageAreasScreenState extends State<ManageAreasScreen> {
  late Future<List<MasterArea>> _areasFuture;

  @override
  void initState() {
    super.initState();
    _areasFuture = MasterDataService.getAreas();
  }

  void _refreshAreas() {
    setState(() {
      _areasFuture = MasterDataService.getAreas();
    });
  }

  void _showAreaDialog({MasterArea? area}) {
    showDialog(
      context: context,
      builder: (context) => AreaFormDialog(onSuccess: _refreshAreas, area: area),
    );
  }

  Future<void> _confirmDeleteArea(MasterArea area) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Area'),
        content: Text(
            'Are you sure you want to delete "${area.name}"? This might fail if it is being used by any grievances.'),
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
        await MasterDataService.deleteArea(area.id);
        _refreshAreas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Area deleted successfully'), backgroundColor: Colors.green),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // soft background
      appBar: AppBar(
        title: const Text(
          'Manage Areas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
      ),
      /* floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade600,
        onPressed: () => _showAreaDialog(),
        child: const Icon(Icons.add),
      ), */
      body: FutureBuilder<List<MasterArea>>(
        future: _areasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final areas = snapshot.data ?? [];
          if (areas.isEmpty) {
            return const Center(
              child: Text(
                "No areas found",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return Card(
                color: const Color(0xFFECF2FE), // card background
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Text(
                    area.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    area.description ?? 'No description',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /* IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue.shade800),
                        onPressed: () => _showAreaDialog(area: area),
                        tooltip: 'Edit Area',
                      ), */
                      /* IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade700),
                        onPressed: () => _confirmDeleteArea(area),
                        tooltip: 'Delete Area',
                      ), */
                    ],
                  ),
                  onTap: () => _showAreaDialog(area: area),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AreaFormDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final MasterArea? area;

  const AreaFormDialog({super.key, required this.onSuccess, this.area});

  @override
  _AreaFormDialogState createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.area?.name ?? '');
    _descriptionController = TextEditingController(text: widget.area?.description ?? '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final data = {
        'name': _nameController.text,
        'description': _descriptionController.text,
      };
      if (widget.area == null) {
        await MasterDataService.addArea(data);
      } else {
        await MasterDataService.updateArea(widget.area!.id, data);
      }
      widget.onSuccess();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save area: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.area != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Edit Area' : 'Add Area',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Area Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an area name';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

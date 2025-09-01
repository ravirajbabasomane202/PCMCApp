import 'package:flutter/material.dart';
import 'package:main_ui/services/master_data_service.dart';
import 'package:main_ui/models/master_data_model.dart';
import 'package:main_ui/widgets/loading_indicator.dart';

class ManageAreasScreen extends StatefulWidget {
  const ManageAreasScreen({Key? key}) : super(key: key);

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

  void _showAddAreaDialog() {
    showDialog(
      context: context,
      builder: (context) => AreaFormDialog(onAreaAdded: _refreshAreas),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Areas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddAreaDialog,
          ),
        ],
      ),
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
          return ListView.builder(
            itemCount: areas.length,
            itemBuilder: (context, index) {
              final area = areas[index];
              return ListTile(
                title: Text(area.name),
                subtitle: Text(area.description ?? 'No description'),
              );
            },
          );
        },
      ),
    );
  }
}

class AreaFormDialog extends StatefulWidget {
  final VoidCallback onAreaAdded;

  const AreaFormDialog({Key? key, required this.onAreaAdded}) : super(key: key);

  @override
  _AreaFormDialogState createState() => _AreaFormDialogState();
}

class _AreaFormDialogState extends State<AreaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

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
      await MasterDataService.addArea(data);
      widget.onAreaAdded();
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add area: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
    return AlertDialog(
      title: const Text('Add Area'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Area Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an area name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description (Optional)'),
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
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:main_ui/services/api_service.dart';

class ManageNearbyScreen extends StatefulWidget {
  const ManageNearbyScreen({super.key});

  @override
  State<ManageNearbyScreen> createState() => _ManageNearbyScreenState();
}

class _ManageNearbyScreenState extends State<ManageNearbyScreen> {
  List<dynamic> nearbyList = [];
  bool loading = false;

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController descriptionCtrl = TextEditingController();
  final TextEditingController contactCtrl = TextEditingController();
  String selectedCategory = "Hospital";

  final List<Map<String, dynamic>> categories = [
    {"label": "Hospital", "icon": Icons.local_hospital, "color": Colors.red},
    {"label": "School", "icon": Icons.school, "color": Colors.blue},
    {"label": "Fire Station", "icon": Icons.fire_truck, "color": Colors.orange},
    {"label": "Post Office", "icon": Icons.local_post_office, "color": Colors.blueGrey},
    {"label": "Ambulance", "icon": Icons.medical_services, "color": Colors.redAccent},
    {"label": "Vaccination Center", "icon": Icons.medication, "color": Colors.green},
    {"label": "Voting Booth", "icon": Icons.how_to_vote, "color": Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    fetchNearbyPlaces();
  }

  Future<void> fetchNearbyPlaces() async {
    setState(() => loading = true);
    try {
      final response = await ApiService.get('/admins/nearby');
      setState(() {
        nearbyList = response.data as List<dynamic>? ?? [];
        loading = false;
      });
    } catch (error) {
      setState(() => loading = false);
      _showSnackBar('Failed to load nearby places');
    }
  }

  Future<void> addOrUpdateNearby({int? id}) async {
    if (!_validateForm()) return;

    final payload = {
      "category": selectedCategory.toLowerCase(),
      "name": nameCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "description": descriptionCtrl.text.trim(),
      "contact_no": contactCtrl.text.trim(),
    };

    try {
      if (id == null) {
        await ApiService.post('/admins/nearby', payload);
        _showSnackBar('Place added successfully');
      } else {
        await ApiService.put('/admins/nearby/$id', payload);
        _showSnackBar('Place updated successfully');
      }
      Navigator.pop(context);
      await fetchNearbyPlaces();
    } catch (error) {
      _showSnackBar('Failed to save place');
    }
  }

  bool _validateForm() {
    if (nameCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter a name');
      return false;
    }
    if (addressCtrl.text.trim().isEmpty) {
      _showSnackBar('Please enter an address');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> deleteNearby(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: const Text('Are you sure you want to delete this place? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.delete('/admins/nearby/$id');
        _showSnackBar('Place deleted successfully');
        await fetchNearbyPlaces();
      } catch (error) {
        _showSnackBar('Failed to delete place');
      }
    }
  }

  void showNearbyDialog({Map<String, dynamic>? data}) {
    if (data != null) {
      String categoryFromApi = data['category'].toString();
      selectedCategory = categories.firstWhere(
        (c) => c["label"].toString().toLowerCase() == categoryFromApi.toLowerCase(),
        orElse: () => categories.first,
      )["label"] as String;
      nameCtrl.text = data['name'] ?? '';
      addressCtrl.text = data['address'] ?? '';
      descriptionCtrl.text = data['description'] ?? '';
      contactCtrl.text = data['contact_no'] ?? '';
    } else {
      selectedCategory = "Hospital";
      nameCtrl.clear();
      addressCtrl.clear();
      descriptionCtrl.clear();
      contactCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      data == null ? Icons.add_location : Icons.edit_location,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      data == null ? 'Add Nearby Place' : 'Edit Nearby Place',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Category Dropdown
                      _buildCategoryDropdown(),
                      const SizedBox(height: 16),

                      // Name Field
                      TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Name *',
                          prefixIcon: Icon(Icons.place),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Address Field
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Address *',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.next,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Contact Field
                      TextField(
                        controller: contactCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Description Field
                      TextField(
                        controller: descriptionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => addOrUpdateNearby(id: data?['id']),
                        child: Text(data == null ? 'Add Place' : 'Update Place'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    final selectedCategoryData = categories.firstWhere(
      (c) => c["label"] == selectedCategory,
      orElse: () => categories.first,
    );

    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category["label"] as String,
          child: Row(
            children: [
              Icon(
                category["icon"] as IconData,
                color: category["color"] as Color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(category["label"] as String),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => selectedCategory = value!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Nearby Places'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNearbyDialog(),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        child: const Icon(Icons.add_location_alt),
      ),
      body: loading
          ? _buildLoadingState()
          : nearbyList.isEmpty
              ? _buildEmptyState()
              : _buildNearbyList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading nearby places...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Nearby Places',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first nearby place by tapping the + button',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyList() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Nearby Places (${nearbyList.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.swap_vert,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: nearbyList.length,
            itemBuilder: (context, index) {
              final place = nearbyList[index];
              final category = categories.firstWhere(
                (c) => c["label"].toString().toLowerCase() == place['category'].toString().toLowerCase(),
                orElse: () => categories.first,
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category["color"].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category["icon"],
                      color: category["color"],
                      size: 22,
                    ),
                  ),
                  title: Text(
                    place['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        place['category']?.toString().toUpperCase() ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: category["color"],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (place['address'] != null && place['address'].isNotEmpty)
                        Text(
                          place['address'],
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => showNearbyDialog(data: place),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                        onPressed: () => deleteNearby(place['id']),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
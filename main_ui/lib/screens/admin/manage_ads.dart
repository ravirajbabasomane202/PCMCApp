// In screens/admin/manage_ads.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/utils/constants.dart';
import 'package:main_ui/services/api_service.dart'; // Assuming this handles auth headers

class ManageAdsScreen extends ConsumerStatefulWidget {
  const ManageAdsScreen({super.key});

  @override
  ConsumerState<ManageAdsScreen> createState() => _ManageAdsScreenState();
}

class _ManageAdsScreenState extends ConsumerState<ManageAdsScreen> {
  List<dynamic> ads = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final response = await ApiService.get(
          '/admins/ads'); // Ensure ApiService adds 'Authorization: Bearer <token>'
      if (mounted) {
        setState(() {
          ads = response.data ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      // Handle 401 specifically
      if (e.toString().contains('401')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized: Please log in again')),
        );
        // Redirect to login
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _createAd(
      Map<String, String> adData, PlatformFile? imageFile) async {
    try {
      await ApiService.postMultipart(
        '/admins/ads',
        data: adData,
        files: imageFile != null ? [imageFile] : [],
        fieldName: 'image_file',
      );
      _loadAds(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create ad: $e')),
      );
    }
  }

  Future<void> _updateAd(
      int adId, Map<String, String> adData, PlatformFile? imageFile) async {
    try {
      await ApiService.putMultipart(
        '/admins/ads/$adId',
        data: adData,
        file: imageFile,
        fileField: 'image_file',
      );
      _loadAds(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update ad: $e')),
      );
    }
  }

  Future<void> _deleteAd(int adId) async {
    try {
      await ApiService.delete('/admins/ads/$adId');
      _loadAds(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete ad: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Ads')),
      body: ListView.builder(
        itemCount: ads.length,
        itemBuilder: (context, index) {
          final ad = ads[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: ad['image_url'] != null &&
                      ad['image_url'].toString().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        '${Constants.baseUrl}/uploads/${ad['image_url']}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
                    )
                  : const Icon(Icons.image, size: 40),
              title: Text(ad['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad['description'] != null &&
                      ad['description'].toString().isNotEmpty)
                    Text(ad['description'],
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  if (ad['link_url'] != null &&
                      ad['link_url'].toString().isNotEmpty)
                    Text(
                      ad['link_url'],
                      style: const TextStyle(color: Colors.blueAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showAdDialog(ad: ad),
                    tooltip: 'Edit Ad',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: const Text('Delete Ad'),
                                content: const Text(
                                    'Are you sure you want to delete this ad?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel')),
                                  ElevatedButton(
                                      onPressed: () {
                                        _deleteAd(ad['id']);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete')),
                                ],
                              ));
                    },
                    tooltip: 'Delete Ad',
                  ),
                ],
              ),
              onTap: () async {
                final url = ad['link_url'];
                if (url != null && await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAdDialog(), // Implement dialog for form
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAdDialog({Map<String, dynamic>? ad}) {
    final bool isEditing = ad != null;
    PlatformFile? _selectedImageFile;
    final titleController = TextEditingController(text: ad?['title']);
    final descriptionController =
        TextEditingController(text: ad?['description']);
    final linkUrlController = TextEditingController(text: ad?['link_url']);
    bool isActive = ad?['is_active'] ?? true;
    DateTime? expiresAt = ad?['expires_at'] != null
        ? DateTime.parse(ad!['expires_at'])
        : null;



    showDialog( barrierDismissible: false,
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Ad' : 'Create Ad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 16),
                // --- Image Picker ---
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select Image'),
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null) {
                          setState(() {
                            _selectedImageFile = result.files.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_selectedImageFile?.name ?? (isEditing ? 'Keep current image' : 'No file selected'), overflow: TextOverflow.ellipsis,))
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: linkUrlController,
                  decoration: const InputDecoration(labelText: 'Link URL'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (val) => setState(() => isActive = val),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(expiresAt == null
                      ? 'Set Expiry Date'
                      : 'Expires: ${DateFormat.yMMMd().format(expiresAt!)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: expiresAt ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (pickedDate != null) {
                      setState(() => expiresAt = pickedDate);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final adData = <String, String>{
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'link_url': linkUrlController.text.trim(),
                  'is_active': isActive.toString(),
                  if (expiresAt != null)
                    'expires_at': expiresAt!.toIso8601String(),
                };

                if (adData['title']!.isNotEmpty) {
                  if (isEditing) {
                    _updateAd(ad!['id'], adData, _selectedImageFile);
                  } else {
                    _createAd(adData, _selectedImageFile);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(isEditing ? 'Update' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}

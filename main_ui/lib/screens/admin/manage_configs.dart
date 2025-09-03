import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api_service.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/custom_button.dart';

// Define a Config model
class Config {
  final String key;
  final String value;

  Config({required this.key, required this.value});

  factory Config.fromJson(Map<String, dynamic> json) {
    return Config(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

// AdminNotifier for managing configs
class AdminNotifier extends StateNotifier<AsyncValue<List<Config>>> {
  static final Dio _dio = ApiService.dio;
  AdminNotifier() : super(const AsyncValue.loading()) {
    getConfigs();
  }

  Future<void> getConfigs() async {
    try {
      state = const AsyncValue.loading();
      final response = await _dio.get('/admins/configs');
      final configs = (response.data as List).map((json) => Config.fromJson(json)).toList();
      state = AsyncValue.data(configs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addConfig(String key, String value) async {
    try {
      state = const AsyncValue.loading();
      await ApiService.post('/admins/configs', {'key': key, 'value': value});
      await getConfigs(); // Refresh configs after adding
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AsyncValue<List<Config>>>((ref) => AdminNotifier());

class ManageConfigs extends ConsumerStatefulWidget {
  const ManageConfigs({super.key});

  @override
  ConsumerState<ManageConfigs> createState() => _ManageConfigsState();
}

class _ManageConfigsState extends ConsumerState<ManageConfigs> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(adminProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: configsAsync.when(
        data: (configs) => configs.isEmpty
            ? EmptyState(
                icon: Icons.settings_outlined,
                title: l10n.noConfigs, // New localization key
                message: l10n.noConfigsMessage, // New localization key
                actionButton: CustomButton(
                  text: l10n.addConfig, // New localization key
                  onPressed: () => _showAddConfigDialog(context),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: configs.length,
                itemBuilder: (context, index) {
                  final config = configs[index];
                  return Card(
                    child: ListTile(
                      title: Text(config.key, style: Theme.of(context).textTheme.titleMedium),
                      subtitle: Text(config.value, style: Theme.of(context).textTheme.bodyMedium),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditConfigDialog(context, config),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyState(
          icon: Icons.error,
          title: l10n.error,
          message: error.toString(),
          actionButton: CustomButton(
            text: l10n.retry,
            onPressed: () => ref.read(adminProvider.notifier).getConfigs(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddConfigDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddConfigDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _keyController.clear();
    _valueController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addConfig), // New localization key
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: l10n.configKey, // New localization key
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.configValue, // New localization key
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CustomButton(
            text: l10n.submit,
            onPressed: () async {
              if (_keyController.text.trim().isEmpty || _valueController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.configCannotBeEmpty)), // New localization key
                );
                return;
              }
              try {
                await ref.read(adminProvider.notifier).addConfig(
                      _keyController.text.trim(),
                      _valueController.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.configAddedSuccess)), // New localization key
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.error}: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showEditConfigDialog(BuildContext context, Config config) {
    final l10n = AppLocalizations.of(context)!;
    _keyController.text = config.key;
    _valueController.text = config.value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editConfig), // New localization key
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: l10n.configKey,
                border: const OutlineInputBorder(),
              ),
              enabled: false, // Key remains non-editable
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: l10n.configValue,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          CustomButton(
            text: l10n.update,
            onPressed: () async {
              if (_valueController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.configValueCannotBeEmpty)), // New localization key
                );
                return;
              }
              try {
                await ref.read(adminProvider.notifier).addConfig(
                      _keyController.text.trim(),
                      _valueController.text.trim(),
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.configUpdatedSuccess)), // New localization key
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${l10n.error}: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
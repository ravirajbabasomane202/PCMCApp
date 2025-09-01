// lib/screens/field_staff/assigned_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/grievance_card.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/providers/user_provider.dart';

// Define a provider for fetching assigned grievances
final assignedGrievancesProvider = FutureProvider<List<Grievance>>((ref) async {
  final user = ref.watch(userNotifierProvider);
  if (user == null || user.role != 'field_staff') {
    return [];
  }
  final response = await ApiService.get('/grievances/assigned/${user.id}');
  return (response.data as List)
      .map((json) => Grievance.fromJson(json))
      .toList();
});

class AssignedList extends ConsumerWidget {
  const AssignedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final grievancesAsync = ref.watch(assignedGrievancesProvider);
    final theme = Theme.of(context);

    // State for the priority filter slider
    final priorityLevels = ['low', 'medium', 'high', 'urgent'];
    final ValueNotifier<double> priorityFilter = ValueNotifier<double>(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.assignedGrievances ?? 'Assigned Grievances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(), // Add navigation drawer
      body: Column(
        children: [
          // Slider for filtering by priority
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.filterByPriority,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ValueListenableBuilder<double>(
                  valueListenable: priorityFilter,
                  builder: (context, value, child) {
                    return Slider(
                      value: value,
                      min: 0,
                      max: priorityLevels.length - 1,
                      divisions: priorityLevels.length - 1,
                      label: priorityLevels[value.toInt()],
                      onChanged: (newValue) {
                        priorityFilter.value = newValue;
                      },
                      activeColor: theme.colorScheme.primary,
                      inactiveColor: theme.colorScheme.onSurface.withValues (alpha: 0.3),
                    );
                  },
                ),
              ],
            ),
          ),
          // Grievance list
          Expanded(
            child: grievancesAsync.when(
              data: (grievances) {
                // Filter grievances based on priority slider
                final filteredGrievances = grievances.where((grievance) {
                  final priorityIndex = priorityLevels.indexOf(grievance.priority?.toLowerCase() ?? 'medium');
                  return priorityIndex >= priorityFilter.value.toInt();
                }).toList();

                if (filteredGrievances.isEmpty) {
                  return EmptyState(
                    icon: Icons.assignment_turned_in,
                    title: l10n.noAssigned,
                    message: l10n.noAssignedMessage ?? 'No assigned grievances yet.',
                    actionButton: TextButton(
                      onPressed: () => ref.refresh(assignedGrievancesProvider),
                      child: Text(l10n.retry),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(assignedGrievancesProvider.future),
                  child: ListView.builder(
                    itemCount: filteredGrievances.length,
                    itemBuilder: (context, index) {
                      final grievance = filteredGrievances[index];
                      return GrievanceCard(grievance: grievance);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyState(
                icon: Icons.error_outline,
                title: l10n.error,
                message: l10n.failedToLoadGrievance,
                actionButton: TextButton(
                  onPressed: () => ref.refresh(assignedGrievancesProvider),
                  child: Text(l10n.retry),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/employer/update');
        },
        child: const Icon(Icons.update),
        tooltip: l10n.updateStatus,
      ),
    );
  }
}
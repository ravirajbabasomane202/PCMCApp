// lib/screens/member_head/view_grievances.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/widgets/empty_state.dart';
import 'package:main_ui/widgets/grievance_card.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/widgets/custom_button.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/providers/user_provider.dart';

// Define a provider for fetching grievances for member_head
final memberHeadGrievancesProvider = FutureProvider<List<Grievance>>((ref) async {
  final user = ref.watch(userNotifierProvider);
  if (user == null || user.role != 'member_head') {
    return [];
  }
  final apiService = await ApiService.get('/grievances/department/${user.departmentId}');
  return (apiService.data as List)
      .map((json) => Grievance.fromJson(json))
      .toList();
});

class ViewGrievances extends ConsumerWidget {
  const ViewGrievances({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final grievancesAsync = ref.watch(memberHeadGrievancesProvider);
    final theme = Theme.of(context);

    // State for the priority filter slider
    final priorityLevels = ['low', 'medium', 'high', 'urgent'];
    final ValueNotifier<double> priorityFilter = ValueNotifier<double>(0);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.viewgrievanceetails ?? 'View Grievances'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
            tooltip: l10n.notifications,
          ),
        ],
      ),
      drawer: const CustomNavigationDrawer(), // Add navigation drawer for profile, settings, logout
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
                    icon: Icons.list_alt,
                    title: l10n.noGrievances,
                    message: l10n.noGrievancesMessage,
                    actionButton: CustomButton(
                      text: l10n.retry,
                      onPressed: () => ref.refresh(memberHeadGrievancesProvider),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(memberHeadGrievancesProvider.future),
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
                actionButton: CustomButton(
                  text: l10n.retry,
                  onPressed: () => ref.refresh(memberHeadGrievancesProvider),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/member_head/assign');
        },
        child: const Icon(Icons.assignment),
        tooltip: l10n.assignGrievance,
      ),
    );
  }
}
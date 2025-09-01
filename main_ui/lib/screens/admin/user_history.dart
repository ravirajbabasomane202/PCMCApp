import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/grievance_model.dart';
import '../../providers/grievance_provider.dart';
import '../../widgets/grievance_card.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class UserHistoryScreen extends ConsumerWidget {
  final int? userId;
  const UserHistoryScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.userHistory)),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.userNotFound,
          message: l10n.userIdRequired,
        ),
      );
    }

    final history = ref.watch(citizenHistoryProvider(userId!));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userHistory)),
      body: history.when(
        data: (grievances) => grievances.isEmpty
            ? EmptyState(
                icon: Icons.history_toggle_off,
                title: l10n.noGrievancesFound,
                message: l10n.noGrievancesMessage,
              )
            : ListView.builder(
                itemCount: grievances.length,
                itemBuilder: (context, index) =>
                    GrievanceCard(grievance: grievances[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => EmptyState(
          icon: Icons.error,
          title: l10n.error,
          message: '${l10n.error}: $err',
        ),
      ),
    );
  }
}
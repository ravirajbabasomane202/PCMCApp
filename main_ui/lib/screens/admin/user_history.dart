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
    final theme = Theme.of(context);

    if (userId == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFf8fbff),
        appBar: AppBar(
          title: Text(l10n.userHistory),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black12,
          foregroundColor: theme.primaryColor,
          centerTitle: true,
        ),
        body: EmptyState(
          icon: Icons.error_outline,
          title: l10n.userNotFound,
          message: l10n.userIdRequired,
        ),
      );
    }

    final history = ref.watch(citizenHistoryProvider(userId!));

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(
          l10n.userHistory,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        foregroundColor: theme.primaryColor,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFf8fbff),
              Color(0xFFe8f1ff),
            ],
          ),
        ),
        child: history.when(
          data: (grievances) => grievances.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: EmptyState(
                    icon: Icons.history_toggle_off,
                    title: l10n.noGrievancesFound,
                    message: l10n.noGrievancesMessage,
                  ),
                )
              : RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: theme.primaryColor,
                  onRefresh: () async {
                    ref.refresh(citizenHistoryProvider(userId!));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: grievances.length,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GrievanceCard(grievance: grievances[index]),
                    ),
                  ),
                ),
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.loading,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: l10n.error,
              message: '${l10n.error}: $err',
            ),
          ),
        ),
      ),
    );
  }
}
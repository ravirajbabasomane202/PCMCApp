import 'dart:async'; // For debouncing
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/grievance_provider.dart';
import '../../widgets/grievance_card.dart';
import '../../widgets/empty_state.dart';
import '../../l10n/app_localizations.dart';

class UserHistoryScreen extends ConsumerStatefulWidget {
  final int? userId;
  const UserHistoryScreen({super.key, this.userId});

  @override
  _UserHistoryScreenState createState() => _UserHistoryScreenState();
}

class _UserHistoryScreenState extends ConsumerState<UserHistoryScreen> {
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
       
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (widget.userId == null) {
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

    final history = ref.watch(citizenHistoryProvider(widget.userId!));

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
      body: SingleChildScrollView( // Added to handle potential overflow
        child: Container(
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
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SizedBox(
                  height: 56.0, // Ensure sufficient height
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchByName ?? 'Search by name', // Fallback
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchText.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                 
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue), // Debug border
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: history.when(
                  data: (grievances) {
                    // Filter grievances based on search text
                    final filteredGrievances = grievances.where((grievance) {
                      final name = grievance.citizen?.name?.toLowerCase() ?? '';
                      final searchText = _searchText.toLowerCase();
                      // Debugging print to check data
                     
                      return name.contains(searchText);
                    }).toList();

                    if (filteredGrievances.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: EmptyState(
                          icon: _searchText.isEmpty ? Icons.history_toggle_off : Icons.search_off,
                          title: _searchText.isEmpty ? l10n.noGrievancesFound : l10n.noResultsFound,
                          message: _searchText.isEmpty ? l10n.noGrievancesMessage : l10n.noMatchingGrievances,
                        ),
                      );
                    }

                    return RefreshIndicator(
                      backgroundColor: Colors.white,
                      color: theme.primaryColor,
                      onRefresh: () async {
                        ref.refresh(citizenHistoryProvider(widget.userId!));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredGrievances.length,
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
                          child: GrievanceCard(grievance: filteredGrievances[index]),
                        ),
                      ),
                    );
                  },
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
            ],
          ),
        ),
      ),
    );
  }
}
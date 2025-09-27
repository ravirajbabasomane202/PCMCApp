import 'dart:async';
import 'package:flutter/material.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import '../../widgets/empty_state.dart';

class AllUsersHistoryScreen extends StatefulWidget {
  const AllUsersHistoryScreen({super.key});

  @override
  State<AllUsersHistoryScreen> createState() => _AllUsersHistoryScreenState();
}

class _AllUsersHistoryScreenState extends State<AllUsersHistoryScreen> {
  List<dynamic> usersHistory = [];
  bool isLoading = true;
  String? error;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchAllHistories();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  Future<void> fetchAllHistories() async {
    try {
      final response = await ApiService.dio.get('/admins/users/history');
      setState(() {
        usersHistory = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load histories: $e';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Helper method to get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Filter users based on search text
    final filteredUsersHistory = usersHistory.where((userData) {
      final user = User.fromJson(userData['user']);
      final name = user.name?.toLowerCase() ?? '';
      final email = user.email?.toLowerCase() ?? '';
      final searchText = _searchText.toLowerCase();
      return name.contains(searchText) || email.contains(searchText);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFf8fbff),
      appBar: AppBar(
        title: Text(l10n.allUsersHistory),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
      ),
      body: Container(
        color: const Color(0xFFf8fbff),
        child: Column(
          children: [
            // Search Field
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchByName ?? 'Search by name or email',
                    prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                    suffixIcon: _searchText.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.blueGrey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchText = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: fetchAllHistories,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filteredUsersHistory.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: EmptyState(
                                icon: _searchText.isEmpty ? Icons.history_toggle_off : Icons.search_off,
                                title: _searchText.isEmpty
                                    ? l10n.noGrievancesFound ?? 'No Histories Found'
                                    : l10n.noResultsFound ?? 'No Results Found',
                                message: _searchText.isEmpty
                                    ? l10n.noGrievancesMessage ?? 'No user histories available'
                                    : l10n.noMatchingGrievances ?? 'No matching users found',
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredUsersHistory.length,
                              itemBuilder: (context, index) {
                                final userData = filteredUsersHistory[index];
                                final user = User.fromJson(userData['user']);
                                final grievances = (userData['grievances'] as List)
                                    .map((g) => Grievance.fromJson(g))
                                    .toList();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: ExpansionTile(
                                      backgroundColor: const Color(0xFFecf2fe),
                                      collapsedBackgroundColor: const Color(0xFFecf2fe),
                                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      title: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: theme.primaryColor.withOpacity(0.2),
                                            child: Icon(
                                              Icons.person,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name ?? 'Unknown',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  user.email ?? 'No email',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Chip(
                                            label: Text(
                                              '${grievances.length}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            backgroundColor: theme.primaryColor,
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Container(
                                          color: Colors.white,
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Grievance History:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              ...grievances.map((g) => Container(
                                                margin: const EdgeInsets.only(bottom: 12),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[50],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey[200]!,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      _getStatusIcon(g.status ?? 'Unknown'),
                                                      color: _getStatusColor(g.status ?? 'Unknown'),
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            g.title,
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            g.description ?? 'No description',
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                decoration: BoxDecoration(
                                                                  color: _getStatusColor(g.status ?? 'Unknown').withOpacity(0.1),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Text(
                                                                  g.status ?? 'Unknown',
                                                                  style: TextStyle(
                                                                    color: _getStatusColor(g.status ?? 'Unknown'),
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                              const Spacer(),
                                                              Text(
                                                                '${g.createdAt!.day}/${g.createdAt!.month}/${g.createdAt!.year}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey[500],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
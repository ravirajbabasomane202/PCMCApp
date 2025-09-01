import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:main_ui/services/api_service.dart'; // Import your API service
import 'package:main_ui/models/user_model.dart'; // Adjust imports as needed
import 'package:main_ui/models/grievance_model.dart';

class AllUsersHistoryScreen extends StatefulWidget {
  const AllUsersHistoryScreen({super.key});

  @override
  State<AllUsersHistoryScreen> createState() => _AllUsersHistoryScreenState();
}

class _AllUsersHistoryScreenState extends State<AllUsersHistoryScreen> {
  List<dynamic> usersHistory = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAllHistories();
  }

  Future<void> fetchAllHistories() async {
    try {
      final response = await ApiService.dio.get('/admin/users/history');
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
  Widget build(BuildContext context) {
    return Scaffold( // Add Scaffold here
      appBar: AppBar(
        title: const Text('All Users History'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : ListView.builder(
                  itemCount: usersHistory.length,
                  itemBuilder: (context, index) {
                    final userData = usersHistory[index];
                    final user = User.fromJson(userData['user']); // Parse user
                    final grievances = (userData['grievances'] as List)
                        .map((g) => Grievance.fromJson(g))
                        .toList();

                    return ExpansionTile(
                      title: Text('${user.name} (${user.email})'),
                      children: grievances
                          .map((g) => ListTile(
                                title: Text(g.title),
                                subtitle: Text(g.status ?? 'Unknown'),
                              ))
                          .toList(),
                    );
                  },
                ),
    );
  }
}
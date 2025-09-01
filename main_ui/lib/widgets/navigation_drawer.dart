// lib/widgets/navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/services/auth_service.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/providers/user_provider.dart';

class CustomNavigationDrawer extends ConsumerWidget {
  const CustomNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider); // Uses userProvider (User?)

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Text(
              '${localizations.appTitle} - ${user?.name ?? localizations.guest}',
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(localizations.appTitle),
            onTap: () {
              Navigator.pop(context);
              final homeRoute = _getHomeRouteForRole(user?.role);
              if (homeRoute != null) {
                Navigator.pushNamed(context, homeRoute);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.invalidRole)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(localizations.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(localizations.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(localizations.logout ?? 'Logout'),
            onTap: () async {
              try {
                await AuthService.logout();
                ref.read(userNotifierProvider.notifier).setUser(null);// Clear user state
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.logoutFailed)),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String? _getHomeRouteForRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'CITIZEN':
        return '/citizen/home';
      case 'MEMBER_HEAD':
        return '/member_head/home';
      case 'FIELD_STAFF':
        return '/field_staff/home';
      case 'ADMIN':
        return '/admin/home';
      default:
        return null;
    }
  }
}
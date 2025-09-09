import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/models/user_model.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/providers/user_provider.dart';

class CustomNavigationDrawer extends ConsumerWidget {
  const CustomNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final user = ref.watch(userNotifierProvider);
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.primaryColor),
            child: Text(
              '${localizations.appTitle} - ${user?.name ?? user?.email ?? localizations.guest}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.home,
            title: localizations.appTitle ?? 'Home',
            onTap: () {
              Navigator.pop(context);
              final homeRoute = _getHomeRouteForRole(user?.role);
              if (homeRoute != null) {
                Navigator.pushNamed(context, homeRoute);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.invalidRole ?? 'Invalid Role')),
                );
              }
            },
          ),
          if (user?.role?.toUpperCase() == 'ADMIN') ...[
            _buildDrawerItem(
              context: context,
              icon: Icons.history,
              title: localizations.viewAuditLogs ?? 'View Audit Logs',
              route: '/admin/audit',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.report,
              title: localizations.complaintManagement ?? 'Complaint Management',
              route: '/admin/complaints',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.settings_applications,
              title: localizations.manageConfigs ?? 'Manage Configs',
              route: '/admin/configs',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.subject,
              title: localizations.manageSubjects ?? 'Manage Subjects',
              route: '/admin/subjects',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.people,
              title: localizations.manageUsers ?? 'Manage Users',
              route: '/admin/users',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.history_toggle_off,
              title: localizations.userHistory ?? 'User History',
              route: '/admin/all_users_history',
            ),
            _buildDrawerItem(
              context: context,
              icon: Icons.location_on,
              title: localizations.manageAreas ?? 'Manage Areas',
              route: '/admin/areas',
            ),
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.assessment,
            //   title: localizations.reports ?? 'Reports',
            //   route: '/admin/reports',
            // ),
          ],
          if (user?.role?.toUpperCase() == 'MEMBER_HEAD') ...[
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.view_list,
            //   title: localizations.viewgrievanceetails ?? 'View Grievances',
            //   route: '/member_head/view',
            // ),
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.assignment,
            //   title: localizations.assignGrievance ?? 'Assign Grievance',
            //   route: '/member_head/assign',
            // ),
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.cancel,
            //   title: localizations.rejectGrievance ?? 'Reject Grievance',
            //   route: '/member_head/reject',
            // ),
          ],
          if (user?.role?.toUpperCase() == 'FIELD_STAFF') ...[
            
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.update,
            //   title: localizations.updateStatus ?? 'Update Status',
            //   route: '/employer/update',
            // ),
            // _buildDrawerItem(
            //   context: context,
            //   icon: Icons.upload_file,
            //   title: localizations.uploadWorkproof ?? 'Upload Work Proof',
            //   route: '/employer/upload',
            // ),
          ],
          _buildDrawerItem(
            context: context,
            icon: Icons.person,
            title: localizations.profile ?? 'Profile',
            route: '/profile',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.settings,
            title: localizations.settings ?? 'Settings',
            route: '/settings',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.announcement,
            title: localizations.announcements ?? 'Announcements',
            route: '/announcements',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications,
            title: localizations.notifications ?? 'Notifications',
            route: '/notifications',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.privacy_tip,
            title: localizations.privacyPolicy ?? 'Privacy Policy',
            route: '/privacy-policy',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.help,
            title: localizations.faqs ?? 'FAQs',
            route: '/faqs',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.support,
            title: localizations.contactSupport ?? 'Contact Support',
            route: '/contact-support',
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.info,
            title: localizations.appVersion ?? 'App Version',
            route: '/app-version',
          ),
          const Divider(),
          _buildDrawerItem(
            context: context,
            icon: Icons.logout,
            title: localizations.logout ?? 'Logout',
            iconColor: Colors.red,
            onTap: () async {
              try {
                await ref.read(authProvider.notifier).logout();
                ref.read(userNotifierProvider.notifier).setUser(null);
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(localizations.logoutFailed ?? 'Logout Failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? route,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: onTap ??
          () {
            if (route != null) {
              Navigator.pop(context);
              Navigator.pushNamed(context, route);
            }
          },
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
import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/login_callback.dart';
import 'screens/citizen/submit_grievance.dart';
import 'screens/citizen/track_grievance.dart';
import 'screens/citizen/grievance_detail.dart';
import 'screens/member_head/view_grievances.dart';
import 'screens/member_head/assign_grievance.dart';
import 'screens/member_head/reject_grievance.dart';
import 'screens/field_staff/assigned_list.dart';
import 'screens/field_staff/update_status.dart';
import 'screens/field_staff/upload_workproof.dart';
import 'screens/admin/dashboard.dart';
import 'screens/admin/manage_users.dart';
import 'screens/admin/manage_subjects.dart';
import 'screens/admin/audit_logs.dart';
import 'screens/admin/complaint_management.dart';
import 'screens/admin/user_history.dart';
import 'screens/common/profile_screen.dart';
import 'screens/common/settings_screen.dart';
import 'screens/admin/manage_configs.dart';
import 'screens/admin/all_users_history.dart';
import 'screens/admin/ManageAreasScreen.dart';
import 'screens/common/announcements_screen.dart';
import 'screens/admin/reports_screen.dart';
import 'screens/common/notifications_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/common/view_privacy_policy_screen.dart';
import 'screens/common/faqs_screen.dart';
import 'screens/common/contact_support_screen.dart';
import 'screens/common/app_version_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/login': (context) => const LoginScreen(),
  '/login/callback': (context) => const LoginCallbackScreen(),
  '/admin/configs': (context) => const ManageConfigs(),
  '/citizen/track': (context) => const TrackGrievance(),
  '/citizen/submit': (context) => const SubmitGrievance(),
  '/citizen/detail': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as int?;
    if (args == null || args <= 0) {
      return const Scaffold(body: Center(child: Text('Invalid grievance ID')));
    }
    return GrievanceDetail(id: args);
  },
  '/member_head/view': (context) => const ViewGrievances(),
  '/member_head/assign': (context) => const AssignGrievance(),
  '/member_head/reject': (context) => const RejectGrievance(),
  '/employer/assigned': (context) => const AssignedList(),
  '/employer/update': (context) => const UpdateStatus(),
  '/employer/upload': (context) => const UploadWorkproof(),
  '/admin/dashboard': (context) => const Dashboard(),
  '/admin/users': (context) => const ManageUsers(),
  '/admin/subjects': (context) => const ManageSubjects(),
  '/admin/all_users_history': (context) => const AllUsersHistoryScreen(),
  '/admin/audit': (context) => const AuditLogs(),
  '/admin/complaints': (context) => const ComplaintManagement(),
  '/admin/user_history': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as int?;
    if (args == null) {
      return const Scaffold(body: Center(child: Text('User ID required')));
    }
    return UserHistoryScreen(userId: args); // Pass userId to screen
  },
  '/profile': (context) => const ProfileScreen(),
  '/settings': (context) => const SettingsScreen(),
  '/citizen/home': (context) => const TrackGrievance(),
  '/member_head/home': (context) => const ViewGrievances(),
  '/employer/home': (context) => const AssignedList(),
  '/field_staff/home': (context) => const AssignedList(), // Added for FIELD_STAFF role
  '/admin/home': (context) => const Dashboard(),
  '/admin/areas': (context) => const ManageAreasScreen(),
  '/announcements': (context) => const AnnouncementsScreen(),
  '/admin/reports': (context) => const ReportsScreen(),
  '/notifications': (context) => const NotificationsScreen(),
  '/auth/otp': (context) => const OtpVerificationScreen(),

  '/privacy-policy': (context) => const PrivacyPolicyScreen(),
  '/faqs': (context) => const FaqsScreen(),
  '/contact-support': (context) => const ContactSupportScreen(),
  '/app-version': (context) => const AppVersionScreen(),

};
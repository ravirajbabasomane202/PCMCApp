import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  /// App title displayed on home screen
  ///
  /// In en, this message translates to:
  /// **'Grievance System'**
  String get appTitle;

  /// Label for login button
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Label for register button
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Label for submit grievance button
  ///
  /// In en, this message translates to:
  /// **'Submit Grievance'**
  String get submitGrievance;

  /// Error message for failed login
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authenticationFailed;

  /// Generic error label
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// Label for name input field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Label for email input field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Label for password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Prompt to register
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get registerPrompt;

  /// Prompt to login
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get loginPrompt;

  /// Label for Google login button
  ///
  /// In en, this message translates to:
  /// **'Login with Google'**
  String get googleLogin;

  /// Error message for failed Google login
  ///
  /// In en, this message translates to:
  /// **'Google login failed'**
  String get googleLoginFailed;

  /// Label for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Label for dark mode toggle
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Label for language selector
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noComments.
  ///
  /// In en, this message translates to:
  /// **'No Comments Yet'**
  String get noComments;

  /// No description provided for @noCommentsMessage.
  ///
  /// In en, this message translates to:
  /// **'Be the first to add a comment!'**
  String get noCommentsMessage;

  /// No description provided for @addComment.
  ///
  /// In en, this message translates to:
  /// **'Add Comment'**
  String get addComment;

  /// No description provided for @yourComment.
  ///
  /// In en, this message translates to:
  /// **'Your Comment'**
  String get yourComment;

  /// No description provided for @commentCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Comment cannot be empty'**
  String get commentCannotBeEmpty;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @commentAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Comment added successfully'**
  String get commentAddedSuccess;

  /// No description provided for @failedToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment'**
  String get failedToAddComment;

  /// No description provided for @grievanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Grievance Details'**
  String get grievanceDetails;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @submitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get submitFeedback;

  /// No description provided for @selectRating.
  ///
  /// In en, this message translates to:
  /// **'Select Rating'**
  String get selectRating;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @pleaseProvideRating.
  ///
  /// In en, this message translates to:
  /// **'Please provide a rating'**
  String get pleaseProvideRating;

  /// No description provided for @feedbackSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Your feedback has been submitted'**
  String get feedbackSubmitted;

  /// No description provided for @failedToLoadGrievance.
  ///
  /// In en, this message translates to:
  /// **'Failed to load grievance'**
  String get failedToLoadGrievance;

  /// No description provided for @userHistory.
  ///
  /// In en, this message translates to:
  /// **'User History'**
  String get userHistory;

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @noGrievancesFound.
  ///
  /// In en, this message translates to:
  /// **'No grievances found'**
  String get noGrievancesFound;

  /// No description provided for @noGrievances.
  ///
  /// In en, this message translates to:
  /// **'No Grievances'**
  String get noGrievances;

  /// No description provided for @noGrievancesMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no grievances to display.'**
  String get noGrievancesMessage;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @filterByPriority.
  ///
  /// In en, this message translates to:
  /// **'Filter by Priority'**
  String get filterByPriority;

  /// No description provided for @filterByArea.
  ///
  /// In en, this message translates to:
  /// **'Filter by Area'**
  String get filterByArea;

  /// No description provided for @filterBySubject.
  ///
  /// In en, this message translates to:
  /// **'Filter by Subject'**
  String get filterBySubject;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @escalate.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get escalate;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @reassignGrievance.
  ///
  /// In en, this message translates to:
  /// **'Reassign Grievance'**
  String get reassignGrievance;

  /// No description provided for @selectAssignee.
  ///
  /// In en, this message translates to:
  /// **'Select Assignee'**
  String get selectAssignee;

  /// No description provided for @selectStatus.
  ///
  /// In en, this message translates to:
  /// **'Select Status'**
  String get selectStatus;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @noComplaints.
  ///
  /// In en, this message translates to:
  /// **'No Complaints'**
  String get noComplaints;

  /// No description provided for @noComplaintsMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no complaints to display.'**
  String get noComplaintsMessage;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get tryAgain;

  /// No description provided for @reassignComplaint.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassignComplaint;

  /// No description provided for @escalateComplaint.
  ///
  /// In en, this message translates to:
  /// **'Escalate'**
  String get escalateComplaint;

  /// Error message when user ID is not provided
  ///
  /// In en, this message translates to:
  /// **'User ID is required'**
  String get userIdRequired;

  /// No description provided for @noConfigs.
  ///
  /// In en, this message translates to:
  /// **'No Configurations'**
  String get noConfigs;

  /// No description provided for @noConfigsMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no configurations to display. Add one below.'**
  String get noConfigsMessage;

  /// No description provided for @addConfig.
  ///
  /// In en, this message translates to:
  /// **'Add Configuration'**
  String get addConfig;

  /// No description provided for @editConfig.
  ///
  /// In en, this message translates to:
  /// **'Edit Configuration'**
  String get editConfig;

  /// No description provided for @configKey.
  ///
  /// In en, this message translates to:
  /// **'Configuration Key'**
  String get configKey;

  /// No description provided for @configValue.
  ///
  /// In en, this message translates to:
  /// **'Configuration Value'**
  String get configValue;

  /// No description provided for @configCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Key and Value cannot be empty'**
  String get configCannotBeEmpty;

  /// No description provided for @configValueCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Value cannot be empty'**
  String get configValueCannotBeEmpty;

  /// No description provided for @configAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Configuration added successfully'**
  String get configAddedSuccess;

  /// No description provided for @configUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Configuration updated successfully'**
  String get configUpdatedSuccess;

  /// No description provided for @track_grievances.
  ///
  /// In en, this message translates to:
  /// **'Track Your Grievances'**
  String get track_grievances;

  /// No description provided for @no_grievances.
  ///
  /// In en, this message translates to:
  /// **'No Grievances Yet'**
  String get no_grievances;

  /// No description provided for @no_grievances_message.
  ///
  /// In en, this message translates to:
  /// **'Submit your first grievance to get started'**
  String get no_grievances_message;

  /// No description provided for @submit_grievance.
  ///
  /// In en, this message translates to:
  /// **'Submit Grievance'**
  String get submit_grievance;

  /// No description provided for @your_grievances.
  ///
  /// In en, this message translates to:
  /// **'Your Grievances'**
  String get your_grievances;

  /// No description provided for @please_login.
  ///
  /// In en, this message translates to:
  /// **'Please login'**
  String get please_login;

  /// No description provided for @addUser.
  ///
  /// In en, this message translates to:
  /// **'Add User'**
  String get addUser;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @userAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User added successfully'**
  String get userAddedSuccess;

  /// No description provided for @failedToAddUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to add user'**
  String get failedToAddUser;

  /// No description provided for @editUser.
  ///
  /// In en, this message translates to:
  /// **'Edit User'**
  String get editUser;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @userUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User updated successfully'**
  String get userUpdatedSuccess;

  /// No description provided for @failedToUpdateUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user'**
  String get failedToUpdateUser;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this user?'**
  String get deleteUserConfirmation;

  /// No description provided for @userDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully'**
  String get userDeletedSuccess;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @failedToDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete User'**
  String get failedToDeleteUser;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No Users'**
  String get noUsers;

  /// No description provided for @noUsersMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no users to display.,'**
  String get noUsersMessage;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Processing login...'**
  String get loading;

  /// No description provided for @viewgrievanceetails.
  ///
  /// In en, this message translates to:
  /// **'View Grievances'**
  String get viewgrievanceetails;

  /// No description provided for @assignGrievance.
  ///
  /// In en, this message translates to:
  /// **'Assign Grievance'**
  String get assignGrievance;

  /// No description provided for @rejectGrievance.
  ///
  /// In en, this message translates to:
  /// **'Reject Grievance'**
  String get rejectGrievance;

  /// No description provided for @rejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection Reason'**
  String get rejectionReason;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @assignedGrievances.
  ///
  /// In en, this message translates to:
  /// **'Assigned Grievances'**
  String get assignedGrievances;

  /// No description provided for @noAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Assigned Grievances'**
  String get noAssigned;

  /// No description provided for @noAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no grievances assigned to you.'**
  String get noAssignedMessage;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadWorkproof.
  ///
  /// In en, this message translates to:
  /// **'Upload Work Proof'**
  String get uploadWorkproof;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @invalidRole.
  ///
  /// In en, this message translates to:
  /// **'Invalid Role'**
  String get invalidRole;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout Failed'**
  String get logoutFailed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

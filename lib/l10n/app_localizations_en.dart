// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get emailEmptyInlineError => 'Email is required';

  @override
  String get invalidEmailInlineError => 'Enter a valid email';

  @override
  String get passwordEmptyInlineError => 'Password is required';

  @override
  String get loginSuccessFallbackMessage =>
      'Credentials verified. Enter the security code shown on the admin dashboard to complete login.';

  @override
  String get emailNotFoundInlineError =>
      'We couldn\'t find an account with this email.';

  @override
  String get emailNotFoundSnackbar => 'Please check your email and try again.';

  @override
  String get passwordIncorrectInlineError =>
      'The password you entered is incorrect.';

  @override
  String get passwordIncorrectSnackbar =>
      'Please check your password and try again.';

  @override
  String get genericInvalidCredentialsInlineError =>
      'The email or password you entered is incorrect.';

  @override
  String get genericInvalidCredentialsSnackbar =>
      'Unable to sign in. Please try again.';

  @override
  String get accountDisabledSnackbar =>
      'This account is not currently available.';

  @override
  String get genericFailureSnackbar =>
      'Unable to sign in at the moment. Please try again later.';

  @override
  String get offlineLoginSuccessSnackbar => 'Offline Login Successful';

  @override
  String loginExceptionSnackbar(Object error) {
    return 'Login failed: $error';
  }

  @override
  String get screenHeadingButtonLabel => 'Log in';

  @override
  String get subheading => 'Please enter your credentials to continue';

  @override
  String get accessRestrictionNotice =>
      'Access is limited to authorized staff and approved contractors. Accounts are created by an administrator. Public sign-up is not available.';

  @override
  String get emailFieldHint => 'Email';

  @override
  String get passwordFieldHint => 'Password';

  @override
  String get forgotPasswordLink => 'Forgot Password?';

  @override
  String get consentTextBeforeTermsLink => 'By logging in, you agree to our';

  @override
  String get termsLink => 'Terms & Conditions';

  @override
  String get consentConnectorWord => 'and';

  @override
  String get versionLabelPrefix => 'V';

  @override
  String get invalidCodeLengthInlineError => 'Enter the 6-digit security code';

  @override
  String get verifySuccessFallback => 'Login successful';

  @override
  String get sessionExpiredFallback =>
      'Login session expired or invalid. Please login again.';

  @override
  String get invalidCodeFallback => 'Invalid security code.';

  @override
  String verificationExceptionSnackbar(Object error) {
    return 'Verification failed: $error';
  }

  @override
  String get screenHeading => 'Enter Security Code';

  @override
  String get subheading2 =>
      'Ask your admin for the 6-digit security code shown on their dashboard.';

  @override
  String get codeFieldPlaceholder => '0.0';

  @override
  String get verifyButton => 'Verify';

  @override
  String get backLink => 'Back to login';

  @override
  String get successFallback => 'Success';

  @override
  String failureSnackbar(Object statusCode) {
    return 'Failed: $statusCode';
  }

  @override
  String exceptionSnackbar(Object error) {
    return 'Error: $error';
  }

  @override
  String get appbarTitle => 'Forgot Password';

  @override
  String get instructionText =>
      'Enter your email to receive a password reset link.';

  @override
  String get emailFieldHint2 => 'you@example.com';

  @override
  String get submitButton => 'Send Reset Link';

  @override
  String get apiResultFallback => 'Something went wrong';

  @override
  String get appbarTitleButtonLabel => 'Reset Password';

  @override
  String get otpFieldLabel => 'OTP';

  @override
  String get otpFieldHint => 'Enter OTP';

  @override
  String get otpRequiredValidation => 'OTP is required';

  @override
  String get newPasswordFieldLabel => 'New Password';

  @override
  String get newPasswordFieldHint => 'Enter new password';

  @override
  String get passwordLengthValidation =>
      'Password must be at least 8 characters';

  @override
  String get confirmPasswordFieldLabel => 'Confirm Password';

  @override
  String get confirmPasswordFieldHint => 'Re-enter password';

  @override
  String get confirmPasswordRequiredValidation =>
      'Confirm password is required';

  @override
  String get passwordsMismatchValidation => 'Passwords do not match';

  @override
  String get missingTokenSnackbar => 'No auth token found. Please login again.';

  @override
  String get appbarTitleButtonLabel2 => 'Change Password';

  @override
  String get oldPasswordFieldLabel => 'Old Password';

  @override
  String get oldPasswordRequiredValidation => 'Old password is required';

  @override
  String get newPasswordRequiredValidation => 'New password is required';

  @override
  String get confirmPasswordFieldLabel2 => 'Confirm New Password';

  @override
  String get accessibilityHintToggleOff => 'Double tap to disable';

  @override
  String get accessibilityHintToggleOn => 'Double tap to enable';

  @override
  String get heading => 'Before You Continue';

  @override
  String get subheading3 =>
      'Please review and confirm the following to use this app.';

  @override
  String get cardTitle => 'Age Confirmation';

  @override
  String get cardDescription =>
      'You must be at least 18 years old to use this app.';

  @override
  String get cardTitle2 => 'Your Privacy Matters';

  @override
  String get cardDescription2 =>
      'We only collect data required to provide our services.';

  @override
  String get cardLink => 'Privacy Policy';

  @override
  String get cardTitle3 => 'Allow Notifications (Optional)';

  @override
  String get cardDescription3 =>
      'Receive task updates and shift reminders. This is optional — the app works without notifications. You can change this anytime in device settings.';

  @override
  String get cardTitle4 => 'Location & Device Information';

  @override
  String get cardDescription4 =>
      'We collect your device identifier and, if you allow, your approximate location to improve security, prevent fraud, and deliver location-based services. Your location is not tracked continuously and is never shared or sold. You can change this permission anytime in your device settings.';

  @override
  String get continueButton => 'Continue';

  @override
  String get welcomeText => 'Welcome!';

  @override
  String get missingUpdateLinkSnackbar => 'Update link is not available.';

  @override
  String get invalidLinkSnackbar => 'Invalid update link.';

  @override
  String launchFailureSnackbar(Object error) {
    return 'Unable to open update link: $error';
  }

  @override
  String genericErrorSnackbar(Object error) {
    return 'Error opening update link: $error';
  }

  @override
  String get heading2 => 'Update Required';

  @override
  String get bodyText =>
      'A newer version of Deine Putzcrew is available and required to keep using the app.';

  @override
  String get reasonListItem => 'Bug fixes and stability improvements';

  @override
  String get reasonListItem2 => 'Important security updates';

  @override
  String get reasonListItem3 =>
      'Punch in/out will stay disabled until you update';

  @override
  String get updateButton => 'Update Now';

  @override
  String get footerNoteIos =>
      'You\'ll be redirected to TestFlight to install the update.';

  @override
  String get footerNoteAndroid =>
      'You\'ll be redirected to the Play Store to install the update.';

  @override
  String get pageTitleIos => 'Privacy Policy - iOS';

  @override
  String get pageTitleAndroid => 'Privacy Policy - Android';

  @override
  String effectiveDateLabel(Object date) {
    return 'Effective Date: $date';
  }

  @override
  String get introParagraph =>
      'This Privacy Policy explains how LivingSpark Global Tech Pvt Ltd (\"we\", \"our\", \"us\"), the developer and operator of DeinePutzCrew, collects, uses, stores, and protects personal data when you use the DeinePutzCrew iOS/Android application published on the Apple App Store/Google Play Store, and related services provided via deineputzcrew.de.';

  @override
  String get sectionHeader => '1. App Purpose';

  @override
  String get sectionHeader2 => '1.1 Account Access';

  @override
  String get sectionHeader3 => '2. Data We Collect';

  @override
  String get sectionHeader4 => '3. How We Use Your Data';

  @override
  String get sectionHeader5 => '4. Data Storage & Security';

  @override
  String get sectionHeader6 => '5. User Rights (EU / GDPR)';

  @override
  String get sectionHeader7 => '6. Contact Information';

  @override
  String footer(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get pageHeading => 'Welcome to DiveInPuits!';

  @override
  String get introParagraph2 =>
      'These Terms and Conditions govern your use of our application and services. By accessing or using our app, you agree to comply with these terms.';

  @override
  String get sectionHeader8 => '1. Account Responsibilities';

  @override
  String get sectionBody =>
      'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.';

  @override
  String get sectionHeader9 => '2. Usage of Services';

  @override
  String get sectionBody2 =>
      'You agree not to misuse our services, including engaging in fraudulent, abusive, or illegal activities within the app.';

  @override
  String get sectionHeader10 => '3. Limitation of Liability';

  @override
  String get sectionBody3 =>
      'We are not responsible for any indirect, incidental, or consequential damages arising from your use of our app.';

  @override
  String get sectionHeader11 => '4. Changes to Terms';

  @override
  String get sectionBody4 =>
      'We may update these Terms from time to time. Continued use of the app after updates means you accept the new Terms.';

  @override
  String get footer2 => 'Last updated: November 2025';

  @override
  String get notificationAlertDialogTitle => '🔔 Notification Alert';

  @override
  String notificationAlertBodyWithTask(Object taskId) {
    return 'You have an active notification.\n\nTask ID: $taskId\n\nPlease acknowledge to continue.';
  }

  @override
  String get notificationAlertBodyNoTask =>
      'You have an active notification.\n\nPlease acknowledge to continue.';

  @override
  String get notificationAlertAcknowledgeButton => 'Acknowledge';

  @override
  String get manualRefreshSnackbar => '🔄 Refreshing data...';

  @override
  String refreshFailureSnackbar(Object error) {
    return '⚠️ Failed to refresh: $error';
  }

  @override
  String get bottomNavLabel => 'Home';

  @override
  String get bottomNavLabel2 => 'Tasks';

  @override
  String get bottomNavLabel3 => 'Settings';

  @override
  String get autoCheckInOfflineSnackbar =>
      '✅ Auto Check-in completed (offline)';

  @override
  String get autoCheckOutOfflineSnackbar =>
      '📴 Auto Check-out saved offline. Will sync when online.';

  @override
  String get autoCheckInOfflineSnackbarVariant =>
      '📴 Auto Check-in saved offline. Will sync when online.';

  @override
  String autoCheckInSuccessSnackbar(Object taskName) {
    return '✅ Auto Check-in successful for $taskName';
  }

  @override
  String get remoteWipeSnackbar => '🧹 Local data cleared by server';

  @override
  String offlineSyncProgressSnackbar(Object count) {
    return '📤 Syncing $count offline actions...';
  }

  @override
  String offlineSyncSuccessSnackbar(Object count) {
    return '✅ Synced $count actions successfully!';
  }

  @override
  String get breakInOfflineSnackbar => '⏸ Break-In saved offline';

  @override
  String breakInFailureSnackbar(Object statusCode) {
    return '❌ Break-In failed ($statusCode)';
  }

  @override
  String get breakOutAuthErrorSnackbar =>
      'Authentication error. Please log in again.';

  @override
  String get breakOutOfflineSnackbar =>
      '▶️ Break-Out saved offline. Will sync later.';

  @override
  String get breakOutSuccessSnackbar => '✅ Break-Out successful.';

  @override
  String breakOutFailureSnackbar(Object statusCode) {
    return '❌ Break-Out failed ($statusCode).';
  }

  @override
  String get breakSelectTaskFirstSnackbar =>
      'Please select a task before starting a break.';

  @override
  String get breakButtonLabelOnBreak => 'End Break';

  @override
  String get breakButtonLabelNotOnBreak => 'Go for Break';

  @override
  String get clockOutBlockedByBreakSnackbar =>
      '⛔ You\'re on a break. Please end your break before clocking out.';

  @override
  String get clockOutNotClockedInSnackbar =>
      '⛔ Cannot clock out - You are not clocked in to any task';

  @override
  String get clockOutNoTaskFoundSnackbar => 'No punched-in task found.';

  @override
  String get clockOutButton => 'Clock Out';

  @override
  String get dashboardRetryButton => 'Retry';

  @override
  String get dashboardLoadingText => 'Loading dashboard...';

  @override
  String get taskSearchFieldHint => 'Search tasks...';

  @override
  String get offlineBannerHeading => '📴 Offline Mode';

  @override
  String get syncingBannerHeading => '📤 Syncing Data';

  @override
  String get offlineBannerSubtext =>
      'Check-ins/outs will be saved and synced when online';

  @override
  String syncPendingBannerSubtext(Object count) {
    return '$count action(s) pending sync';
  }

  @override
  String get syncNowTooltip => 'Sync now';

  @override
  String get taskListSectionTitle => 'Today\'s Tasks';

  @override
  String get viewAllTasksLink => 'View all';

  @override
  String get emptyTaskListText => 'No tasks available';

  @override
  String get priorityFilterChip => 'All';

  @override
  String get priorityFilterChip2 => 'Low';

  @override
  String get priorityFilterChip3 => 'Medium';

  @override
  String get priorityFilterChip4 => 'High';

  @override
  String get taskCardStatusBadge => 'Punched In';

  @override
  String get punchInAlreadyPunchedOutOfflineSnackbar =>
      '⛔ You already punched out from this task (offline). Cannot punch in again.';

  @override
  String get punchInLocationErrorSnackbar =>
      '⛔ Unable to get your location. Please enable location services.';

  @override
  String get punchInNotOnLocationSnackbar => '⛔ You are not on location';

  @override
  String get punchInInvalidTaskDateSnackbar => '⛔ Invalid task date format';

  @override
  String punchInTooEarly(
      Object date, Object hours, Object minutes, Object time) {
    return '⛔ Too early! Task starts at $time on $date (in ${hours}h ${minutes}m)';
  }

  @override
  String punchInTaskEndedSnackbar(Object date, Object time) {
    return '⛔ Task ended at $time on $date';
  }

  @override
  String get punchInOfflineSnackbar =>
      '📴 Punch-in saved offline. Will sync automatically.';

  @override
  String get punchInSuccessSnackbar => '✅ Punch-in successful';

  @override
  String get punchInOfflinePunchoutBlockSnackbar =>
      '⛔ This task already has an offline punch-out. Cannot punch in again.';

  @override
  String get taskAlreadyCompletedSnackbar => 'This task is already completed.';

  @override
  String alreadyPunchedIntoAnotherTaskSnackbar(Object taskName) {
    return 'You are already punched into \"$taskName\".';
  }

  @override
  String get loaderTextCheckingLocation => 'Checking your location...';

  @override
  String get loaderTextOpeningCamera => 'Opening camera...';

  @override
  String get loaderTextPunchingIn => 'Punching in...';

  @override
  String get loaderTextStartingBreak => 'Starting break...';

  @override
  String get loaderTextEndingBreak => 'Ending break...';

  @override
  String get appBarTitle => 'All Tasks';

  @override
  String get tabLabel => 'Pending';

  @override
  String get tabLabel2 => 'Completed';

  @override
  String get searchFieldHint => 'Search Task';

  @override
  String get appBarTitle2 => 'Task Details';

  @override
  String get taskLabel => 'Task';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get loggedTimeLabel => 'Logged:';

  @override
  String get attachmentsSectionTitle => 'Attachments';

  @override
  String get remarksFieldLabel => 'Remarks';

  @override
  String get remarksFieldHint => 'Enter Remark';

  @override
  String get addAttachmentSheetOption => 'Camera';

  @override
  String get addAttachmentButton => 'Add Attachment';

  @override
  String get markAsCompletedButton => 'Mark as Completed';

  @override
  String get punchOutMissingImageSnackbar => 'Please select at least one image';

  @override
  String get punchOutNotPunchedInSnackbar =>
      '⛔ Cannot punch out - You are not punched in to any task';

  @override
  String get punchOutTaskMismatchSnackbar =>
      '⛔ Cannot punch out - You are punched in to a different task';

  @override
  String get loaderTextGettingLocation => 'Getting your location...';

  @override
  String get loaderTextPunchingOut => 'Punching out...';

  @override
  String get punchOutOfflineSnackbar =>
      '📴 Punch-out saved offline. Will sync when online.';

  @override
  String get punchOutSuccessSnackbar => '✅ Punch-out successful';

  @override
  String get changeStatusPopupTitle => 'Change Status';

  @override
  String get statusOption => 'Work in progress';

  @override
  String get statusPopupSelectButton => 'Select';

  @override
  String get staticSubtextUnderEveryLoaderMessage =>
      'Please wait, don\'t close the app';

  @override
  String get genericErrorFallback => 'Something went wrong. Please try again.';

  @override
  String get dialogCancelButton => 'Cancel';

  @override
  String get logoutConfirmButton => 'Logout';

  @override
  String get deleteAccountDialogTitle => 'Delete Account';

  @override
  String get deleteAccountDialogBody =>
      'Are you sure you want to permanently delete your account? This action cannot be undone.';

  @override
  String get deleteAccountConfirmButton => 'Delete';

  @override
  String get deleteAccountSuccessSnackbar =>
      'Account deletion request submitted successfully.';

  @override
  String deleteAccountFailureSnackbar(Object details) {
    return 'Failed to delete account: $details';
  }

  @override
  String get sectionHeader12 => 'General';

  @override
  String get listItemChangePassword => 'Change password';

  @override
  String get noCamerasFoundError => 'No cameras found on this device.';

  @override
  String get noFrontCameraFound => 'No front camera found on this device.';

  @override
  String get noBackCameraFound => 'No back camera found on this device.';

  @override
  String get cameraPermissionDeniedError =>
      'Camera access is denied. Please enable it in your device Settings.';

  @override
  String genericCameraExceptionError(Object details) {
    return 'Camera error: $details';
  }

  @override
  String cameraInitFailureError(Object error) {
    return 'Failed to open camera: $error';
  }

  @override
  String get openSettingsButton => 'Open Settings';

  @override
  String get goBackButton => 'Go Back';

  @override
  String get appBarTitle3 => 'Complete Task';

  @override
  String get instructionText2 =>
      'Please add Remark and photos to mark the task as completed.';

  @override
  String get remarksFieldHint2 => 'Enter your task name';

  @override
  String attachmentsHeader(Object count) {
    return 'Attachments ($count)';
  }

  @override
  String submitSuccessSnackbar(Object count, Object remark) {
    return 'Task Completed with remark: $remark and $count images';
  }

  @override
  String get submitButton2 => 'Mark as Complete';

  @override
  String get channelNameGeneral => 'High Importance Notifications';

  @override
  String get channelDescriptionGeneral =>
      'This channel is used for important notifications.';

  @override
  String get channelNameAutoCheckIn => 'Auto Check-in Notifications';

  @override
  String get channelDescriptionAutoCheckInCreationTime =>
      'Critical notifications for automatic task check-ins with sound.';

  @override
  String get channelDescriptionAutoCheckInPerNotification =>
      'Critical notifications for automatic task check-ins';

  @override
  String get fallbackPushTitle => 'New Message';

  @override
  String get fallbackPushBody => 'You have a new notification';

  @override
  String get autoCheckInAlertTitle => '🚨 Auto Check-in Required';

  @override
  String autoCheckInAlertBodyWithLocation(Object location, Object time) {
    return '🎯 Time to check in at $location Task starts at $time';
  }

  @override
  String autoCheckInAlertBodyNoLocation(Object time) {
    return '🎯 Time to check in for your task Task starts at $time';
  }

  @override
  String get liveTrackingChannelName => 'Live Location Tracking';

  @override
  String get liveTrackingChannelDescription =>
      'Shown while you are punched in, so your location can be tracked for attendance.';

  @override
  String get liveTrackingPersistentNotificationTitle =>
      'Deineputzcrew — Punched In';

  @override
  String get liveTrackingPersistentNotificationBody =>
      'Your location is being tracked while you\'re on shift.';

  @override
  String get taskChannelName => 'Task Notifications';

  @override
  String get taskChannelDescription => 'Automatic task check-in notifications';

  @override
  String get autoCheckInSuccessNotificationTitleOnline =>
      '✅ Auto Check-in Successful';

  @override
  String get autoCheckInSuccessNotificationTitleOffline =>
      '✅ Auto Check-in (Offline)';

  @override
  String autoCheckInNotificationBody(Object taskName, Object time) {
    return 'Task: $taskName Time: $time';
  }

  @override
  String get reasonDropdownValue => 'Holiday';

  @override
  String get reasonDropdownValue2 => 'Rest / Personal';

  @override
  String get reasonDropdownValue3 => 'Sick';

  @override
  String get reasonDropdownValue4 => 'Other';

  @override
  String get appbarTitle2 => 'Time Off / Availability';

  @override
  String get adminProposalsSectionHeading => 'Requests from your admin';

  @override
  String get adminProposalsSubheading =>
      'Your admin proposed time off for you. Review and respond below.';

  @override
  String adminRequestCardRequestedByLine(Object name) {
    return 'Requested by: $name';
  }

  @override
  String get adminRequestCardDefaultAdminNameFallback => 'your admin';

  @override
  String adminRequestCardAdminNotePrefix(Object note) {
    return 'Admin note: $note';
  }

  @override
  String get adminRequestCardRejectButton => 'Reject';

  @override
  String get adminRequestCardApproveButton => 'Approve';

  @override
  String get rejectRequestDialogTitle => 'Reject request';

  @override
  String get rejectRequestDialogNoteFieldLabel => 'Note for admin (optional)';

  @override
  String get snackbarAfterApprove => '✅ Request approved';

  @override
  String get snackbarAfterReject => '❌ Request rejected';

  @override
  String get fallbackErrorRespondingToAdminRequest =>
      'Failed to respond to request';

  @override
  String get requestTimeOffSectionHeading => 'Request time off';

  @override
  String get subheadingUnderRequestTimeOff =>
      'Let your admin know you\'ll be on holiday, resting, or otherwise unavailable. They\'ll review and approve it.';

  @override
  String get startDateButtonPlaceholder => 'Start date';

  @override
  String get endDateButtonPlaceholder => 'End date';

  @override
  String get reasonDropdownFieldLabel => 'Reason';

  @override
  String get noteFieldLabel => 'Note (optional)';

  @override
  String get validationSnackbarMissingDates =>
      'Please select both a start and end date';

  @override
  String get submitButton3 => 'Submit request';

  @override
  String get submitSuccessSnackbar2 =>
      '✅ Time off requested — awaiting admin approval';

  @override
  String get submitFailureFallbackSnackbar => 'Failed to submit request';

  @override
  String get yourRequestsSectionHeading => 'Your requests';

  @override
  String get emptyStateText => 'No requests yet.';

  @override
  String get statusBadge => 'Approved';

  @override
  String get statusBadge2 => 'Rejected';

  @override
  String get languageRowLabel => 'Language';

  @override
  String get languageDropdownOption => 'English';

  @override
  String get languageDropdownOption2 => 'German';

  @override
  String get listItemNavigatesToTimeOffScreen => 'Time off / Availability';

  @override
  String get shiftResponseSnackbarAccepted => '✅ Shift accepted';

  @override
  String get shiftResponseSnackbarDeclined => '🚫 Shift declined';

  @override
  String get shiftResponseFallbackErrorSnackbar => 'Failed to respond to shift';

  @override
  String get needsResponseCardInfoLine => 'This shift needs your response';

  @override
  String get acceptButtonNeedsResponseCard => 'Accept';

  @override
  String get declineButtonNeedsResponseCard => 'Decline';

  @override
  String get statusChipAfterRespondingAccepted => '✅ Accepted';

  @override
  String get statusChipAfterRespondingDeclined => '🚫 Declined';

  @override
  String get debugTestNotificationChannelDescription =>
      'Test notification with sound';

  @override
  String debugTestNotificationTitle(Object number) {
    return '🔔 Sound Test #$number';
  }

  @override
  String get debugTestNotificationBody =>
      'Testing system default notification sound';
}

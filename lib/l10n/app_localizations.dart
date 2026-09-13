import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('de'),
    Locale('en')
  ];

  /// Login - email empty inline error
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailEmptyInlineError;

  /// Login - invalid email inline error
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmailInlineError;

  /// Login - password empty inline error
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordEmptyInlineError;

  /// Login - login success fallback message
  ///
  /// In en, this message translates to:
  /// **'Credentials verified. Enter the security code shown on the admin dashboard to complete login.'**
  String get loginSuccessFallbackMessage;

  /// Login - email not found inline error
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an account with this email.'**
  String get emailNotFoundInlineError;

  /// Login - email not found snackbar
  ///
  /// In en, this message translates to:
  /// **'Please check your email and try again.'**
  String get emailNotFoundSnackbar;

  /// Login - password incorrect inline error
  ///
  /// In en, this message translates to:
  /// **'The password you entered is incorrect.'**
  String get passwordIncorrectInlineError;

  /// Login - password incorrect snackbar
  ///
  /// In en, this message translates to:
  /// **'Please check your password and try again.'**
  String get passwordIncorrectSnackbar;

  /// Login - generic invalid credentials inline error
  ///
  /// In en, this message translates to:
  /// **'The email or password you entered is incorrect.'**
  String get genericInvalidCredentialsInlineError;

  /// Login - generic invalid credentials snackbar
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get genericInvalidCredentialsSnackbar;

  /// Login - account disabled snackbar
  ///
  /// In en, this message translates to:
  /// **'This account is not currently available.'**
  String get accountDisabledSnackbar;

  /// Login - generic failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in at the moment. Please try again later.'**
  String get genericFailureSnackbar;

  /// Login - offline login success snackbar
  ///
  /// In en, this message translates to:
  /// **'Offline Login Successful'**
  String get offlineLoginSuccessSnackbar;

  /// Login - login exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Login failed: {error}'**
  String loginExceptionSnackbar(Object error);

  /// Login - screen heading / button label
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get screenHeadingButtonLabel;

  /// Login - subheading
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials to continue'**
  String get subheading;

  /// Login - access-restriction notice
  ///
  /// In en, this message translates to:
  /// **'Access is limited to authorized staff and approved contractors. Accounts are created by an administrator. Public sign-up is not available.'**
  String get accessRestrictionNotice;

  /// Login - email field hint
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailFieldHint;

  /// Login - password field hint
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordFieldHint;

  /// Login - forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLink;

  /// Login - consent text before terms link
  ///
  /// In en, this message translates to:
  /// **'By logging in, you agree to our'**
  String get consentTextBeforeTermsLink;

  /// Login - terms link
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsLink;

  /// Login - consent connector word
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get consentConnectorWord;

  /// Login - version label prefix
  ///
  /// In en, this message translates to:
  /// **'V'**
  String get versionLabelPrefix;

  /// Security Code - invalid code length inline error
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit security code'**
  String get invalidCodeLengthInlineError;

  /// Security Code - verify success fallback
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get verifySuccessFallback;

  /// Security Code - session expired fallback
  ///
  /// In en, this message translates to:
  /// **'Login session expired or invalid. Please login again.'**
  String get sessionExpiredFallback;

  /// Security Code - invalid code fallback
  ///
  /// In en, this message translates to:
  /// **'Invalid security code.'**
  String get invalidCodeFallback;

  /// Security Code - verification exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String verificationExceptionSnackbar(Object error);

  /// Security Code - screen heading
  ///
  /// In en, this message translates to:
  /// **'Enter Security Code'**
  String get screenHeading;

  /// Security Code - subheading
  ///
  /// In en, this message translates to:
  /// **'Ask your admin for the 6-digit security code shown on their dashboard.'**
  String get subheading2;

  /// Security Code - code field placeholder
  ///
  /// In en, this message translates to:
  /// **'0.0'**
  String get codeFieldPlaceholder;

  /// Security Code - verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButton;

  /// Security Code - back link
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backLink;

  /// Forgot Password - success fallback
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get successFallback;

  /// Forgot Password - failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed: {statusCode}'**
  String failureSnackbar(Object statusCode);

  /// Forgot Password - exception snackbar
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String exceptionSnackbar(Object error);

  /// Forgot Password - AppBar title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get appbarTitle;

  /// Forgot Password - instruction text
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link.'**
  String get instructionText;

  /// Forgot Password - email field hint
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailFieldHint2;

  /// Forgot Password - submit button
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get submitButton;

  /// Reset Password - api result fallback
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get apiResultFallback;

  /// Reset Password - AppBar title / button label
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get appbarTitleButtonLabel;

  /// Reset Password - OTP field label
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get otpFieldLabel;

  /// Reset Password - OTP field hint
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get otpFieldHint;

  /// Reset Password - OTP required validation
  ///
  /// In en, this message translates to:
  /// **'OTP is required'**
  String get otpRequiredValidation;

  /// Reset Password - new password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordFieldLabel;

  /// Reset Password - new password field hint
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get newPasswordFieldHint;

  /// Reset Password - password length validation
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordLengthValidation;

  /// Reset Password - confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordFieldLabel;

  /// Reset Password - confirm password field hint
  ///
  /// In en, this message translates to:
  /// **'Re-enter password'**
  String get confirmPasswordFieldHint;

  /// Reset Password - confirm password required validation
  ///
  /// In en, this message translates to:
  /// **'Confirm password is required'**
  String get confirmPasswordRequiredValidation;

  /// Reset Password - passwords mismatch validation
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMismatchValidation;

  /// Change Password - missing token snackbar
  ///
  /// In en, this message translates to:
  /// **'No auth token found. Please login again.'**
  String get missingTokenSnackbar;

  /// Change Password - AppBar title / button label
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get appbarTitleButtonLabel2;

  /// Change Password - old password field label
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPasswordFieldLabel;

  /// Change Password - old password required validation
  ///
  /// In en, this message translates to:
  /// **'Old password is required'**
  String get oldPasswordRequiredValidation;

  /// Change Password - new password required validation
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequiredValidation;

  /// Change Password - confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPasswordFieldLabel2;

  /// Consent Screen - accessibility hint (toggle off)
  ///
  /// In en, this message translates to:
  /// **'Double tap to disable'**
  String get accessibilityHintToggleOff;

  /// Consent Screen - accessibility hint (toggle on)
  ///
  /// In en, this message translates to:
  /// **'Double tap to enable'**
  String get accessibilityHintToggleOn;

  /// Consent Screen - heading
  ///
  /// In en, this message translates to:
  /// **'Before You Continue'**
  String get heading;

  /// Consent Screen - subheading
  ///
  /// In en, this message translates to:
  /// **'Please review and confirm the following to use this app.'**
  String get subheading3;

  /// Consent Screen - card title
  ///
  /// In en, this message translates to:
  /// **'Age Confirmation'**
  String get cardTitle;

  /// Consent Screen - card description
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to use this app.'**
  String get cardDescription;

  /// Consent Screen - card title
  ///
  /// In en, this message translates to:
  /// **'Your Privacy Matters'**
  String get cardTitle2;

  /// Consent Screen - card description
  ///
  /// In en, this message translates to:
  /// **'We only collect data required to provide our services.'**
  String get cardDescription2;

  /// Consent Screen - card link
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get cardLink;

  /// Consent Screen - card title
  ///
  /// In en, this message translates to:
  /// **'Allow Notifications (Optional)'**
  String get cardTitle3;

  /// Consent Screen - card description
  ///
  /// In en, this message translates to:
  /// **'Receive task updates and shift reminders. This is optional — the app works without notifications. You can change this anytime in device settings.'**
  String get cardDescription3;

  /// Consent Screen - card title
  ///
  /// In en, this message translates to:
  /// **'Location & Device Information'**
  String get cardTitle4;

  /// Consent Screen - card description
  ///
  /// In en, this message translates to:
  /// **'We collect your device identifier and, if you allow, your approximate location to improve security, prevent fraud, and deliver location-based services. Your location is not tracked continuously and is never shared or sold. You can change this permission anytime in your device settings.'**
  String get cardDescription4;

  /// Consent Screen - continue button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Splash Screen - welcome text
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeText;

  /// Force Update - missing update link snackbar
  ///
  /// In en, this message translates to:
  /// **'Update link is not available.'**
  String get missingUpdateLinkSnackbar;

  /// Force Update - invalid link snackbar
  ///
  /// In en, this message translates to:
  /// **'Invalid update link.'**
  String get invalidLinkSnackbar;

  /// Force Update - launch failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Unable to open update link: {error}'**
  String launchFailureSnackbar(Object error);

  /// Force Update - generic error snackbar
  ///
  /// In en, this message translates to:
  /// **'Error opening update link: {error}'**
  String genericErrorSnackbar(Object error);

  /// Force Update - heading
  ///
  /// In en, this message translates to:
  /// **'Update Required'**
  String get heading2;

  /// Force Update - body text
  ///
  /// In en, this message translates to:
  /// **'A newer version of Deine Putzcrew is available and required to keep using the app.'**
  String get bodyText;

  /// Force Update - reason list item
  ///
  /// In en, this message translates to:
  /// **'Bug fixes and stability improvements'**
  String get reasonListItem;

  /// Force Update - reason list item
  ///
  /// In en, this message translates to:
  /// **'Important security updates'**
  String get reasonListItem2;

  /// Force Update - reason list item
  ///
  /// In en, this message translates to:
  /// **'Punch in/out will stay disabled until you update'**
  String get reasonListItem3;

  /// Force Update - update button
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateButton;

  /// Force Update - footer note iOS
  ///
  /// In en, this message translates to:
  /// **'You\'ll be redirected to TestFlight to install the update.'**
  String get footerNoteIos;

  /// Force Update - footer note Android
  ///
  /// In en, this message translates to:
  /// **'You\'ll be redirected to the Play Store to install the update.'**
  String get footerNoteAndroid;

  /// Privacy Policy - page title iOS
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy - iOS'**
  String get pageTitleIos;

  /// Privacy Policy - page title Android
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy - Android'**
  String get pageTitleAndroid;

  /// Privacy Policy - effective date label
  ///
  /// In en, this message translates to:
  /// **'Effective Date: {date}'**
  String effectiveDateLabel(Object date);

  /// Privacy Policy - intro paragraph
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains how LivingSpark Global Tech Pvt Ltd (\"we\", \"our\", \"us\"), the developer and operator of DeinePutzCrew, collects, uses, stores, and protects personal data when you use the DeinePutzCrew iOS/Android application published on the Apple App Store/Google Play Store, and related services provided via deineputzcrew.de.'**
  String get introParagraph;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'1. App Purpose'**
  String get sectionHeader;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'1.1 Account Access'**
  String get sectionHeader2;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'2. Data We Collect'**
  String get sectionHeader3;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Your Data'**
  String get sectionHeader4;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'4. Data Storage & Security'**
  String get sectionHeader5;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'5. User Rights (EU / GDPR)'**
  String get sectionHeader6;

  /// Privacy Policy - section header
  ///
  /// In en, this message translates to:
  /// **'6. Contact Information'**
  String get sectionHeader7;

  /// Privacy Policy - footer
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String footer(Object date);

  /// Terms & Conditions - page heading
  ///
  /// In en, this message translates to:
  /// **'Welcome to DiveInPuits!'**
  String get pageHeading;

  /// Terms & Conditions - intro paragraph
  ///
  /// In en, this message translates to:
  /// **'These Terms and Conditions govern your use of our application and services. By accessing or using our app, you agree to comply with these terms.'**
  String get introParagraph2;

  /// Terms & Conditions - section header
  ///
  /// In en, this message translates to:
  /// **'1. Account Responsibilities'**
  String get sectionHeader8;

  /// Terms & Conditions - section body
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.'**
  String get sectionBody;

  /// Terms & Conditions - section header
  ///
  /// In en, this message translates to:
  /// **'2. Usage of Services'**
  String get sectionHeader9;

  /// Terms & Conditions - section body
  ///
  /// In en, this message translates to:
  /// **'You agree not to misuse our services, including engaging in fraudulent, abusive, or illegal activities within the app.'**
  String get sectionBody2;

  /// Terms & Conditions - section header
  ///
  /// In en, this message translates to:
  /// **'3. Limitation of Liability'**
  String get sectionHeader10;

  /// Terms & Conditions - section body
  ///
  /// In en, this message translates to:
  /// **'We are not responsible for any indirect, incidental, or consequential damages arising from your use of our app.'**
  String get sectionBody3;

  /// Terms & Conditions - section header
  ///
  /// In en, this message translates to:
  /// **'4. Changes to Terms'**
  String get sectionHeader11;

  /// Terms & Conditions - section body
  ///
  /// In en, this message translates to:
  /// **'We may update these Terms from time to time. Continued use of the app after updates means you accept the new Terms.'**
  String get sectionBody4;

  /// Terms & Conditions - footer
  ///
  /// In en, this message translates to:
  /// **'Last updated: November 2025'**
  String get footer2;

  /// Dashboard - notification alert dialog title
  ///
  /// In en, this message translates to:
  /// **'🔔 Notification Alert'**
  String get notificationAlertDialogTitle;

  /// Dashboard - notification alert dialog body
  ///
  /// In en, this message translates to:
  /// **'You have an active notification.\n\nTask ID: {taskId}\n\nPlease acknowledge to continue.'**
  String notificationAlertBodyWithTask(Object taskId);

  /// Dashboard - notification alert dialog body
  ///
  /// In en, this message translates to:
  /// **'You have an active notification.\n\nPlease acknowledge to continue.'**
  String get notificationAlertBodyNoTask;

  /// Dashboard - notification alert acknowledge button
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get notificationAlertAcknowledgeButton;

  /// Dashboard - manual refresh snackbar
  ///
  /// In en, this message translates to:
  /// **'🔄 Refreshing data...'**
  String get manualRefreshSnackbar;

  /// Dashboard - refresh failure snackbar
  ///
  /// In en, this message translates to:
  /// **'⚠️ Failed to refresh: {error}'**
  String refreshFailureSnackbar(Object error);

  /// Dashboard - bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get bottomNavLabel;

  /// Dashboard - bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get bottomNavLabel2;

  /// Dashboard - bottom nav label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get bottomNavLabel3;

  /// Dashboard - auto check-in offline snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Auto Check-in completed (offline)'**
  String get autoCheckInOfflineSnackbar;

  /// Dashboard - auto check-out offline snackbar
  ///
  /// In en, this message translates to:
  /// **'📴 Auto Check-out saved offline. Will sync when online.'**
  String get autoCheckOutOfflineSnackbar;

  /// Dashboard - auto check-in offline snackbar (variant)
  ///
  /// In en, this message translates to:
  /// **'📴 Auto Check-in saved offline. Will sync when online.'**
  String get autoCheckInOfflineSnackbarVariant;

  /// Dashboard - auto check-in success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Auto Check-in successful for {taskName}'**
  String autoCheckInSuccessSnackbar(Object taskName);

  /// Dashboard - remote wipe snackbar
  ///
  /// In en, this message translates to:
  /// **'🧹 Local data cleared by server'**
  String get remoteWipeSnackbar;

  /// Dashboard - offline sync progress snackbar
  ///
  /// In en, this message translates to:
  /// **'📤 Syncing {count} offline actions...'**
  String offlineSyncProgressSnackbar(Object count);

  /// Dashboard - offline sync success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Synced {count} actions successfully!'**
  String offlineSyncSuccessSnackbar(Object count);

  /// Dashboard - break-in offline snackbar
  ///
  /// In en, this message translates to:
  /// **'⏸ Break-In saved offline'**
  String get breakInOfflineSnackbar;

  /// Dashboard - break-in failure snackbar
  ///
  /// In en, this message translates to:
  /// **'❌ Break-In failed ({statusCode})'**
  String breakInFailureSnackbar(Object statusCode);

  /// Dashboard - break-out auth error snackbar
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please log in again.'**
  String get breakOutAuthErrorSnackbar;

  /// Dashboard - break-out offline snackbar
  ///
  /// In en, this message translates to:
  /// **'▶️ Break-Out saved offline. Will sync later.'**
  String get breakOutOfflineSnackbar;

  /// Dashboard - break-out success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Break-Out successful.'**
  String get breakOutSuccessSnackbar;

  /// Dashboard - break-out failure snackbar
  ///
  /// In en, this message translates to:
  /// **'❌ Break-Out failed ({statusCode}).'**
  String breakOutFailureSnackbar(Object statusCode);

  /// Dashboard - break select-task-first snackbar
  ///
  /// In en, this message translates to:
  /// **'Please select a task before starting a break.'**
  String get breakSelectTaskFirstSnackbar;

  /// Dashboard - break button label (on break)
  ///
  /// In en, this message translates to:
  /// **'End Break'**
  String get breakButtonLabelOnBreak;

  /// Dashboard - break button label (not on break)
  ///
  /// In en, this message translates to:
  /// **'Go for Break'**
  String get breakButtonLabelNotOnBreak;

  /// Dashboard - clock-out blocked by break snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ You\'re on a break. Please end your break before clocking out.'**
  String get clockOutBlockedByBreakSnackbar;

  /// Dashboard - clock-out not-clocked-in snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Cannot clock out - You are not clocked in to any task'**
  String get clockOutNotClockedInSnackbar;

  /// Dashboard - clock-out no-task-found snackbar
  ///
  /// In en, this message translates to:
  /// **'No punched-in task found.'**
  String get clockOutNoTaskFoundSnackbar;

  /// Dashboard - clock out button
  ///
  /// In en, this message translates to:
  /// **'Clock Out'**
  String get clockOutButton;

  /// Dashboard - dashboard retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get dashboardRetryButton;

  /// Dashboard - dashboard loading text
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get dashboardLoadingText;

  /// Dashboard - task search field hint
  ///
  /// In en, this message translates to:
  /// **'Search tasks...'**
  String get taskSearchFieldHint;

  /// Dashboard - offline banner heading
  ///
  /// In en, this message translates to:
  /// **'📴 Offline Mode'**
  String get offlineBannerHeading;

  /// Dashboard - syncing banner heading
  ///
  /// In en, this message translates to:
  /// **'📤 Syncing Data'**
  String get syncingBannerHeading;

  /// Dashboard - offline banner subtext
  ///
  /// In en, this message translates to:
  /// **'Check-ins/outs will be saved and synced when online'**
  String get offlineBannerSubtext;

  /// Dashboard - sync pending banner subtext
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) pending sync'**
  String syncPendingBannerSubtext(Object count);

  /// Dashboard - sync now tooltip
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNowTooltip;

  /// Dashboard - task list section title
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get taskListSectionTitle;

  /// Dashboard - view all tasks link
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllTasksLink;

  /// Dashboard - empty task list text
  ///
  /// In en, this message translates to:
  /// **'No tasks available'**
  String get emptyTaskListText;

  /// Dashboard - priority filter chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get priorityFilterChip;

  /// Dashboard - priority filter chip
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityFilterChip2;

  /// Dashboard - priority filter chip
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityFilterChip3;

  /// Dashboard - priority filter chip
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityFilterChip4;

  /// Dashboard - task card status badge
  ///
  /// In en, this message translates to:
  /// **'Punched In'**
  String get taskCardStatusBadge;

  /// Dashboard - punch-in already-punched-out-offline snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ You already punched out from this task (offline). Cannot punch in again.'**
  String get punchInAlreadyPunchedOutOfflineSnackbar;

  /// Dashboard - punch-in location error snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Unable to get your location. Please enable location services.'**
  String get punchInLocationErrorSnackbar;

  /// Dashboard - punch-in not-on-location snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ You are not on location'**
  String get punchInNotOnLocationSnackbar;

  /// Dashboard - punch-in invalid task date snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Invalid task date format'**
  String get punchInInvalidTaskDateSnackbar;

  /// Dashboard - punch-in too-early snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Too early! Task starts at {time} on {date} (in {hours}h {minutes}m)'**
  String punchInTooEarly(
      Object date, Object hours, Object minutes, Object time);

  /// Dashboard - punch-in task-ended snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Task ended at {time} on {date}'**
  String punchInTaskEndedSnackbar(Object date, Object time);

  /// Dashboard - punch-in offline snackbar
  ///
  /// In en, this message translates to:
  /// **'📴 Punch-in saved offline. Will sync automatically.'**
  String get punchInOfflineSnackbar;

  /// Dashboard - punch-in success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Punch-in successful'**
  String get punchInSuccessSnackbar;

  /// Dashboard - punch-in offline-punchout-block snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ This task already has an offline punch-out. Cannot punch in again.'**
  String get punchInOfflinePunchoutBlockSnackbar;

  /// Dashboard - task already completed snackbar
  ///
  /// In en, this message translates to:
  /// **'This task is already completed.'**
  String get taskAlreadyCompletedSnackbar;

  /// Dashboard - already punched into another task snackbar
  ///
  /// In en, this message translates to:
  /// **'You are already punched into \"{taskName}\".'**
  String alreadyPunchedIntoAnotherTaskSnackbar(Object taskName);

  /// Dashboard - loader text - checking location
  ///
  /// In en, this message translates to:
  /// **'Checking your location...'**
  String get loaderTextCheckingLocation;

  /// Dashboard - loader text - opening camera
  ///
  /// In en, this message translates to:
  /// **'Opening camera...'**
  String get loaderTextOpeningCamera;

  /// Dashboard - loader text - punching in
  ///
  /// In en, this message translates to:
  /// **'Punching in...'**
  String get loaderTextPunchingIn;

  /// Dashboard - loader text - starting break
  ///
  /// In en, this message translates to:
  /// **'Starting break...'**
  String get loaderTextStartingBreak;

  /// Dashboard - loader text - ending break
  ///
  /// In en, this message translates to:
  /// **'Ending break...'**
  String get loaderTextEndingBreak;

  /// All Tasks - app bar title
  ///
  /// In en, this message translates to:
  /// **'All Tasks'**
  String get appBarTitle;

  /// All Tasks - tab label
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabLabel;

  /// All Tasks - tab label
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabLabel2;

  /// All Tasks - search field hint
  ///
  /// In en, this message translates to:
  /// **'Search Task'**
  String get searchFieldHint;

  /// Task Details - app bar title
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get appBarTitle2;

  /// Task Details - task label
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskLabel;

  /// Task Details - status field label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusFieldLabel;

  /// Task Details - logged time label
  ///
  /// In en, this message translates to:
  /// **'Logged:'**
  String get loggedTimeLabel;

  /// Task Details - attachments section title
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachmentsSectionTitle;

  /// Task Details - remarks field label
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get remarksFieldLabel;

  /// Task Details - remarks field hint
  ///
  /// In en, this message translates to:
  /// **'Enter Remark'**
  String get remarksFieldHint;

  /// Task Details - add attachment sheet option
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get addAttachmentSheetOption;

  /// Task Details - add attachment button
  ///
  /// In en, this message translates to:
  /// **'Add Attachment'**
  String get addAttachmentButton;

  /// Task Details - mark as completed button
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompletedButton;

  /// Task Details - punch-out missing image snackbar
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image'**
  String get punchOutMissingImageSnackbar;

  /// Task Details - punch-out not-punched-in snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Cannot punch out - You are not punched in to any task'**
  String get punchOutNotPunchedInSnackbar;

  /// Task Details - punch-out task-mismatch snackbar
  ///
  /// In en, this message translates to:
  /// **'⛔ Cannot punch out - You are punched in to a different task'**
  String get punchOutTaskMismatchSnackbar;

  /// Task Details - loader text - getting location
  ///
  /// In en, this message translates to:
  /// **'Getting your location...'**
  String get loaderTextGettingLocation;

  /// Task Details - loader text - punching out
  ///
  /// In en, this message translates to:
  /// **'Punching out...'**
  String get loaderTextPunchingOut;

  /// Task Details - punch-out offline snackbar
  ///
  /// In en, this message translates to:
  /// **'📴 Punch-out saved offline. Will sync when online.'**
  String get punchOutOfflineSnackbar;

  /// Task Details - punch-out success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Punch-out successful'**
  String get punchOutSuccessSnackbar;

  /// Task Details - change status popup title
  ///
  /// In en, this message translates to:
  /// **'Change Status'**
  String get changeStatusPopupTitle;

  /// Task Details - status option
  ///
  /// In en, this message translates to:
  /// **'Work in progress'**
  String get statusOption;

  /// Task Details - status popup select button
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get statusPopupSelectButton;

  /// Full-Screen Loader - static subtext under every loader message
  ///
  /// In en, this message translates to:
  /// **'Please wait, don\'t close the app'**
  String get staticSubtextUnderEveryLoaderMessage;

  /// Settings - generic error fallback
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericErrorFallback;

  /// Settings - dialog cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancelButton;

  /// Settings - logout confirm button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmButton;

  /// Settings - delete account dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountDialogTitle;

  /// Settings - delete account dialog body
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete your account? This action cannot be undone.'**
  String get deleteAccountDialogBody;

  /// Settings - delete account confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirmButton;

  /// Settings - delete account success snackbar
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted successfully.'**
  String get deleteAccountSuccessSnackbar;

  /// Settings - delete account failure snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account: {details}'**
  String deleteAccountFailureSnackbar(Object details);

  /// Settings - section header
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get sectionHeader12;

  /// Settings - list item - change password
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get listItemChangePassword;

  /// Camera (Front/Back - shared text) - no cameras found error
  ///
  /// In en, this message translates to:
  /// **'No cameras found on this device.'**
  String get noCamerasFoundError;

  /// Camera (Front/Back - shared text) - no matching camera found error
  ///
  /// In en, this message translates to:
  /// **'No front camera found on this device.'**
  String get noFrontCameraFound;

  /// Camera (Front/Back - shared text) - no matching camera found error
  ///
  /// In en, this message translates to:
  /// **'No back camera found on this device.'**
  String get noBackCameraFound;

  /// Camera (Front/Back - shared text) - camera permission denied error
  ///
  /// In en, this message translates to:
  /// **'Camera access is denied. Please enable it in your device Settings.'**
  String get cameraPermissionDeniedError;

  /// Camera (Front/Back - shared text) - generic camera exception error
  ///
  /// In en, this message translates to:
  /// **'Camera error: {details}'**
  String genericCameraExceptionError(Object details);

  /// Camera (Front/Back - shared text) - camera init failure error
  ///
  /// In en, this message translates to:
  /// **'Failed to open camera: {error}'**
  String cameraInitFailureError(Object error);

  /// Camera (Front/Back - shared text) - open settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsButton;

  /// Camera (Front/Back - shared text) - go back button
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBackButton;

  /// Complete Task (legacy/placeholder screen) - app bar title
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get appBarTitle3;

  /// Complete Task (legacy/placeholder screen) - instruction text
  ///
  /// In en, this message translates to:
  /// **'Please add Remark and photos to mark the task as completed.'**
  String get instructionText2;

  /// Complete Task (legacy/placeholder screen) - remarks field hint
  ///
  /// In en, this message translates to:
  /// **'Enter your task name'**
  String get remarksFieldHint2;

  /// Complete Task (legacy/placeholder screen) - attachments header
  ///
  /// In en, this message translates to:
  /// **'Attachments ({count})'**
  String attachmentsHeader(Object count);

  /// Complete Task (legacy/placeholder screen) - submit success snackbar
  ///
  /// In en, this message translates to:
  /// **'Task Completed with remark: {remark} and {count} images'**
  String submitSuccessSnackbar(Object count, Object remark);

  /// Complete Task (legacy/placeholder screen) - submit button
  ///
  /// In en, this message translates to:
  /// **'Mark as Complete'**
  String get submitButton2;

  /// System Notifications - channel name - general
  ///
  /// In en, this message translates to:
  /// **'High Importance Notifications'**
  String get channelNameGeneral;

  /// System Notifications - channel description - general
  ///
  /// In en, this message translates to:
  /// **'This channel is used for important notifications.'**
  String get channelDescriptionGeneral;

  /// System Notifications - channel name - auto check-in
  ///
  /// In en, this message translates to:
  /// **'Auto Check-in Notifications'**
  String get channelNameAutoCheckIn;

  /// System Notifications - channel description - auto check-in (creation time)
  ///
  /// In en, this message translates to:
  /// **'Critical notifications for automatic task check-ins with sound.'**
  String get channelDescriptionAutoCheckInCreationTime;

  /// System Notifications - channel description - auto check-in (per-notification)
  ///
  /// In en, this message translates to:
  /// **'Critical notifications for automatic task check-ins'**
  String get channelDescriptionAutoCheckInPerNotification;

  /// System Notifications - fallback push title
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get fallbackPushTitle;

  /// System Notifications - fallback push body
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get fallbackPushBody;

  /// System Notifications - auto check-in alert title
  ///
  /// In en, this message translates to:
  /// **'🚨 Auto Check-in Required'**
  String get autoCheckInAlertTitle;

  /// System Notifications - auto check-in alert body (with location)
  ///
  /// In en, this message translates to:
  /// **'🎯 Time to check in at {location} Task starts at {time}'**
  String autoCheckInAlertBodyWithLocation(Object location, Object time);

  /// System Notifications - auto check-in alert body (no location)
  ///
  /// In en, this message translates to:
  /// **'🎯 Time to check in for your task Task starts at {time}'**
  String autoCheckInAlertBodyNoLocation(Object time);

  /// System Notifications - live tracking channel name
  ///
  /// In en, this message translates to:
  /// **'Live Location Tracking'**
  String get liveTrackingChannelName;

  /// System Notifications - live tracking channel description
  ///
  /// In en, this message translates to:
  /// **'Shown while you are punched in, so your location can be tracked for attendance.'**
  String get liveTrackingChannelDescription;

  /// System Notifications - live tracking persistent notification title
  ///
  /// In en, this message translates to:
  /// **'Deineputzcrew — Punched In'**
  String get liveTrackingPersistentNotificationTitle;

  /// System Notifications - live tracking persistent notification body
  ///
  /// In en, this message translates to:
  /// **'Your location is being tracked while you\'re on shift.'**
  String get liveTrackingPersistentNotificationBody;

  /// System Notifications - task channel name
  ///
  /// In en, this message translates to:
  /// **'Task Notifications'**
  String get taskChannelName;

  /// System Notifications - task channel description
  ///
  /// In en, this message translates to:
  /// **'Automatic task check-in notifications'**
  String get taskChannelDescription;

  /// System Notifications - auto check-in success notification title (online)
  ///
  /// In en, this message translates to:
  /// **'✅ Auto Check-in Successful'**
  String get autoCheckInSuccessNotificationTitleOnline;

  /// System Notifications - auto check-in success notification title (offline)
  ///
  /// In en, this message translates to:
  /// **'✅ Auto Check-in (Offline)'**
  String get autoCheckInSuccessNotificationTitleOffline;

  /// System Notifications - auto check-in notification body
  ///
  /// In en, this message translates to:
  /// **'Task: {taskName} Time: {time}'**
  String autoCheckInNotificationBody(Object taskName, Object time);

  /// Availability / Time Off - reason dropdown value
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get reasonDropdownValue;

  /// Availability / Time Off - reason dropdown value
  ///
  /// In en, this message translates to:
  /// **'Rest / Personal'**
  String get reasonDropdownValue2;

  /// Availability / Time Off - reason dropdown value
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get reasonDropdownValue3;

  /// Availability / Time Off - reason dropdown value
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonDropdownValue4;

  /// Availability / Time Off - AppBar title
  ///
  /// In en, this message translates to:
  /// **'Time Off / Availability'**
  String get appbarTitle2;

  /// Availability / Time Off - admin proposals section heading
  ///
  /// In en, this message translates to:
  /// **'Requests from your admin'**
  String get adminProposalsSectionHeading;

  /// Availability / Time Off - admin proposals subheading
  ///
  /// In en, this message translates to:
  /// **'Your admin proposed time off for you. Review and respond below.'**
  String get adminProposalsSubheading;

  /// Availability / Time Off - admin request card - requested by line
  ///
  /// In en, this message translates to:
  /// **'Requested by: {name}'**
  String adminRequestCardRequestedByLine(Object name);

  /// Availability / Time Off - admin request card - default admin name fallback
  ///
  /// In en, this message translates to:
  /// **'your admin'**
  String get adminRequestCardDefaultAdminNameFallback;

  /// Availability / Time Off - admin request card - admin note prefix
  ///
  /// In en, this message translates to:
  /// **'Admin note: {note}'**
  String adminRequestCardAdminNotePrefix(Object note);

  /// Availability / Time Off - admin request card - reject button
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminRequestCardRejectButton;

  /// Availability / Time Off - admin request card - approve button
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminRequestCardApproveButton;

  /// Availability / Time Off - reject-request dialog title
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get rejectRequestDialogTitle;

  /// Availability / Time Off - reject-request dialog note field label
  ///
  /// In en, this message translates to:
  /// **'Note for admin (optional)'**
  String get rejectRequestDialogNoteFieldLabel;

  /// Availability / Time Off - snackbar after approve
  ///
  /// In en, this message translates to:
  /// **'✅ Request approved'**
  String get snackbarAfterApprove;

  /// Availability / Time Off - snackbar after reject
  ///
  /// In en, this message translates to:
  /// **'❌ Request rejected'**
  String get snackbarAfterReject;

  /// Availability / Time Off - fallback error responding to admin request
  ///
  /// In en, this message translates to:
  /// **'Failed to respond to request'**
  String get fallbackErrorRespondingToAdminRequest;

  /// Availability / Time Off - "Request time off" section heading
  ///
  /// In en, this message translates to:
  /// **'Request time off'**
  String get requestTimeOffSectionHeading;

  /// Availability / Time Off - subheading under Request time off
  ///
  /// In en, this message translates to:
  /// **'Let your admin know you\'ll be on holiday, resting, or otherwise unavailable. They\'ll review and approve it.'**
  String get subheadingUnderRequestTimeOff;

  /// Availability / Time Off - start date button placeholder
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDateButtonPlaceholder;

  /// Availability / Time Off - end date button placeholder
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get endDateButtonPlaceholder;

  /// Availability / Time Off - reason dropdown field label
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonDropdownFieldLabel;

  /// Availability / Time Off - note field label
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteFieldLabel;

  /// Availability / Time Off - validation snackbar - missing dates
  ///
  /// In en, this message translates to:
  /// **'Please select both a start and end date'**
  String get validationSnackbarMissingDates;

  /// Availability / Time Off - submit button
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitButton3;

  /// Availability / Time Off - submit success snackbar
  ///
  /// In en, this message translates to:
  /// **'✅ Time off requested — awaiting admin approval'**
  String get submitSuccessSnackbar2;

  /// Availability / Time Off - submit failure fallback snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get submitFailureFallbackSnackbar;

  /// Availability / Time Off - "Your requests" section heading
  ///
  /// In en, this message translates to:
  /// **'Your requests'**
  String get yourRequestsSectionHeading;

  /// Availability / Time Off - empty state text
  ///
  /// In en, this message translates to:
  /// **'No requests yet.'**
  String get emptyStateText;

  /// Availability / Time Off - status badge
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusBadge;

  /// Availability / Time Off - status badge
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusBadge2;

  /// Settings - language row label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageRowLabel;

  /// Settings - language dropdown option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageDropdownOption;

  /// Settings - language dropdown option
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get languageDropdownOption2;

  /// Settings - list item - navigates to Time Off screen
  ///
  /// In en, this message translates to:
  /// **'Time off / Availability'**
  String get listItemNavigatesToTimeOffScreen;

  /// Dashboard - shift-response snackbar (accepted)
  ///
  /// In en, this message translates to:
  /// **'✅ Shift accepted'**
  String get shiftResponseSnackbarAccepted;

  /// Dashboard - shift-response snackbar (declined)
  ///
  /// In en, this message translates to:
  /// **'🚫 Shift declined'**
  String get shiftResponseSnackbarDeclined;

  /// Dashboard - shift-response fallback error snackbar
  ///
  /// In en, this message translates to:
  /// **'Failed to respond to shift'**
  String get shiftResponseFallbackErrorSnackbar;

  /// Dashboard - "needs response" card info line
  ///
  /// In en, this message translates to:
  /// **'This shift needs your response'**
  String get needsResponseCardInfoLine;

  /// Dashboard - accept button (needs-response card)
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptButtonNeedsResponseCard;

  /// Dashboard - decline button (needs-response card)
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineButtonNeedsResponseCard;

  /// Dashboard - status chip after responding - accepted
  ///
  /// In en, this message translates to:
  /// **'✅ Accepted'**
  String get statusChipAfterRespondingAccepted;

  /// Dashboard - status chip after responding - declined
  ///
  /// In en, this message translates to:
  /// **'🚫 Declined'**
  String get statusChipAfterRespondingDeclined;

  /// System Notifications - debug/test notification channel description
  ///
  /// In en, this message translates to:
  /// **'Test notification with sound'**
  String get debugTestNotificationChannelDescription;

  /// System Notifications - debug/test notification title
  ///
  /// In en, this message translates to:
  /// **'🔔 Sound Test #{number}'**
  String debugTestNotificationTitle(Object number);

  /// System Notifications - debug/test notification body
  ///
  /// In en, this message translates to:
  /// **'Testing system default notification sound'**
  String get debugTestNotificationBody;
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
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

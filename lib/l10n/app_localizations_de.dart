// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get emailEmptyInlineError => 'E-Mail ist erforderlich';

  @override
  String get invalidEmailInlineError =>
      'Bitte eine gültige E-Mail-Adresse eingeben';

  @override
  String get passwordEmptyInlineError => 'Passwort ist erforderlich';

  @override
  String get loginSuccessFallbackMessage =>
      'Zugangsdaten bestätigt. Geben Sie den Sicherheitscode aus dem Admin-Dashboard ein, um die Anmeldung abzuschließen.';

  @override
  String get emailNotFoundInlineError =>
      'Wir konnten kein Konto mit dieser E-Mail-Adresse finden.';

  @override
  String get emailNotFoundSnackbar =>
      'Bitte überprüfen Sie Ihre E-Mail-Adresse und versuchen Sie es erneut.';

  @override
  String get passwordIncorrectInlineError =>
      'Das eingegebene Passwort ist falsch.';

  @override
  String get passwordIncorrectSnackbar =>
      'Bitte überprüfen Sie Ihr Passwort und versuchen Sie es erneut.';

  @override
  String get genericInvalidCredentialsInlineError =>
      'E-Mail-Adresse oder Passwort ist falsch.';

  @override
  String get genericInvalidCredentialsSnackbar =>
      'Anmeldung nicht möglich. Bitte versuchen Sie es erneut.';

  @override
  String get accountDisabledSnackbar =>
      'Dieses Konto ist derzeit nicht verfügbar.';

  @override
  String get genericFailureSnackbar =>
      'Anmeldung derzeit nicht möglich. Bitte versuchen Sie es später erneut.';

  @override
  String get offlineLoginSuccessSnackbar => 'Offline-Anmeldung erfolgreich';

  @override
  String loginExceptionSnackbar(Object error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get screenHeadingButtonLabel => 'Anmelden';

  @override
  String get subheading =>
      'Bitte geben Sie Ihre Zugangsdaten ein, um fortzufahren';

  @override
  String get accessRestrictionNotice =>
      'Der Zugang ist auf autorisierte Mitarbeitende und freigegebene Auftragnehmer beschränkt. Konten werden von einem Administrator angelegt. Eine öffentliche Registrierung ist nicht möglich.';

  @override
  String get emailFieldHint => 'E-Mail';

  @override
  String get passwordFieldHint => 'Passwort';

  @override
  String get forgotPasswordLink => 'Passwort vergessen?';

  @override
  String get consentTextBeforeTermsLink =>
      'Mit der Anmeldung stimmen Sie unseren';

  @override
  String get termsLink => 'Nutzungsbedingungen';

  @override
  String get consentConnectorWord => 'und';

  @override
  String get versionLabelPrefix => 'V';

  @override
  String get invalidCodeLengthInlineError =>
      'Geben Sie den 6-stelligen Sicherheitscode ein';

  @override
  String get verifySuccessFallback => 'Anmeldung erfolgreich';

  @override
  String get sessionExpiredFallback =>
      'Anmeldesitzung abgelaufen oder ungültig. Bitte melden Sie sich erneut an.';

  @override
  String get invalidCodeFallback => 'Ungültiger Sicherheitscode.';

  @override
  String verificationExceptionSnackbar(Object error) {
    return 'Verifizierung fehlgeschlagen: $error';
  }

  @override
  String get screenHeading => 'Sicherheitscode eingeben';

  @override
  String get subheading2 =>
      'Fragen Sie Ihren Admin nach dem 6-stelligen Sicherheitscode, der auf dem Dashboard angezeigt wird.';

  @override
  String get codeFieldPlaceholder => '0.0';

  @override
  String get verifyButton => 'Bestätigen';

  @override
  String get backLink => 'Zurück zur Anmeldung';

  @override
  String get successFallback => 'Erfolgreich';

  @override
  String failureSnackbar(Object statusCode) {
    return 'Fehlgeschlagen: $statusCode';
  }

  @override
  String exceptionSnackbar(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get appbarTitle => 'Passwort vergessen';

  @override
  String get instructionText =>
      'Geben Sie Ihre E-Mail-Adresse ein, um einen Link zum Zurücksetzen des Passworts zu erhalten.';

  @override
  String get emailFieldHint2 => 'name@beispiel.de';

  @override
  String get submitButton => 'Link senden';

  @override
  String get apiResultFallback => 'Etwas ist schiefgelaufen';

  @override
  String get appbarTitleButtonLabel => 'Passwort zurücksetzen';

  @override
  String get otpFieldLabel => 'Einmalcode';

  @override
  String get otpFieldHint => 'Einmalcode eingeben';

  @override
  String get otpRequiredValidation => 'Einmalcode ist erforderlich';

  @override
  String get newPasswordFieldLabel => 'Neues Passwort';

  @override
  String get newPasswordFieldHint => 'Neues Passwort eingeben';

  @override
  String get passwordLengthValidation =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get confirmPasswordFieldLabel => 'Passwort bestätigen';

  @override
  String get confirmPasswordFieldHint => 'Passwort erneut eingeben';

  @override
  String get confirmPasswordRequiredValidation =>
      'Passwortbestätigung ist erforderlich';

  @override
  String get passwordsMismatchValidation =>
      'Die Passwörter stimmen nicht überein';

  @override
  String get missingTokenSnackbar =>
      'Kein Anmelde-Token gefunden. Bitte melden Sie sich erneut an.';

  @override
  String get appbarTitleButtonLabel2 => 'Passwort ändern';

  @override
  String get oldPasswordFieldLabel => 'Altes Passwort';

  @override
  String get oldPasswordRequiredValidation => 'Altes Passwort ist erforderlich';

  @override
  String get newPasswordRequiredValidation => 'Neues Passwort ist erforderlich';

  @override
  String get confirmPasswordFieldLabel2 => 'Neues Passwort bestätigen';

  @override
  String get accessibilityHintToggleOff => 'Doppeltippen zum Deaktivieren';

  @override
  String get accessibilityHintToggleOn => 'Doppeltippen zum Aktivieren';

  @override
  String get heading => 'Bevor Sie fortfahren';

  @override
  String get subheading3 =>
      'Bitte lesen und bestätigen Sie Folgendes, um diese App zu nutzen.';

  @override
  String get cardTitle => 'Altersbestätigung';

  @override
  String get cardDescription =>
      'Sie müssen mindestens 18 Jahre alt sein, um diese App zu nutzen.';

  @override
  String get cardTitle2 => 'Ihre Privatsphäre ist uns wichtig';

  @override
  String get cardDescription2 =>
      'Wir erheben nur die Daten, die zur Erbringung unserer Leistungen erforderlich sind.';

  @override
  String get cardLink => 'Datenschutzerklärung';

  @override
  String get cardTitle3 => 'Benachrichtigungen erlauben (optional)';

  @override
  String get cardDescription3 =>
      'Erhalten Sie Aufgaben-Updates und Schicht-Erinnerungen. Dies ist optional – die App funktioniert auch ohne Benachrichtigungen. Sie können dies jederzeit in den Geräteeinstellungen ändern.';

  @override
  String get cardTitle4 => 'Standort- & Geräteinformationen';

  @override
  String get cardDescription4 =>
      'Wir erfassen Ihre Gerätekennung und – sofern Sie zustimmen – Ihren ungefähren Standort, um die Sicherheit zu verbessern, Betrug zu verhindern und standortbezogene Dienste bereitzustellen. Ihr Standort wird nicht dauerhaft erfasst und niemals weitergegeben oder verkauft. Sie können diese Berechtigung jederzeit in den Geräteeinstellungen ändern.';

  @override
  String get continueButton => 'Weiter';

  @override
  String get welcomeText => 'Willkommen!';

  @override
  String get missingUpdateLinkSnackbar => 'Update-Link ist nicht verfügbar.';

  @override
  String get invalidLinkSnackbar => 'Ungültiger Update-Link.';

  @override
  String launchFailureSnackbar(Object error) {
    return 'Update-Link konnte nicht geöffnet werden: $error';
  }

  @override
  String genericErrorSnackbar(Object error) {
    return 'Fehler beim Öffnen des Update-Links: $error';
  }

  @override
  String get heading2 => 'Update erforderlich';

  @override
  String get bodyText =>
      'Eine neuere Version von Deine Putzcrew ist verfügbar und erforderlich, um die App weiter zu nutzen.';

  @override
  String get reasonListItem => 'Fehlerbehebungen und Stabilitätsverbesserungen';

  @override
  String get reasonListItem2 => 'Wichtige Sicherheitsupdates';

  @override
  String get reasonListItem3 =>
      'Ein-/Ausstempeln bleibt deaktiviert, bis Sie das Update installieren';

  @override
  String get updateButton => 'Jetzt aktualisieren';

  @override
  String get footerNoteIos =>
      'Sie werden zu TestFlight weitergeleitet, um das Update zu installieren.';

  @override
  String get footerNoteAndroid =>
      'Sie werden zum Play Store weitergeleitet, um das Update zu installieren.';

  @override
  String get pageTitleIos => 'Datenschutzerklärung – iOS';

  @override
  String get pageTitleAndroid => 'Datenschutzerklärung – Android';

  @override
  String effectiveDateLabel(Object date) {
    return 'Gültig ab: $date';
  }

  @override
  String get introParagraph =>
      'Diese Datenschutzerklärung erläutert, wie LivingSpark Global Tech Pvt Ltd („wir“, „uns“, „unser“), Entwickler und Betreiber von DeinePutzCrew, personenbezogene Daten erhebt, verwendet, speichert und schützt, wenn Sie die im Apple App Store/Google Play Store veröffentlichte DeinePutzCrew iOS-/Android-App sowie zugehörige Dienste über deineputzcrew.de nutzen.';

  @override
  String get sectionHeader => '1. Zweck der App';

  @override
  String get sectionHeader2 => '1.1 Kontozugang';

  @override
  String get sectionHeader3 => '2. Erhobene Daten';

  @override
  String get sectionHeader4 => '3. Verwendung Ihrer Daten';

  @override
  String get sectionHeader5 => '4. Datenspeicherung & Sicherheit';

  @override
  String get sectionHeader6 => '5. Rechte der Nutzer (EU / DSGVO)';

  @override
  String get sectionHeader7 => '6. Kontakt';

  @override
  String footer(Object date) {
    return 'Zuletzt aktualisiert: $date';
  }

  @override
  String get pageHeading => 'Willkommen bei Deine Putzcrew!';

  @override
  String get introParagraph2 =>
      'Diese Nutzungsbedingungen regeln die Nutzung unserer App und Dienste. Durch den Zugriff auf oder die Nutzung unserer App erklären Sie sich mit diesen Bedingungen einverstanden.';

  @override
  String get sectionHeader8 => '1. Verantwortung für das Konto';

  @override
  String get sectionBody =>
      'Sie sind dafür verantwortlich, Ihre Zugangsdaten vertraulich zu behandeln. Sie verpflichten sich, uns unverzüglich über jede unbefugte Nutzung Ihres Kontos zu informieren.';

  @override
  String get sectionHeader9 => '2. Nutzung der Dienste';

  @override
  String get sectionBody2 =>
      'Sie verpflichten sich, unsere Dienste nicht zu missbrauchen, insbesondere keine betrügerischen, missbräuchlichen oder rechtswidrigen Handlungen innerhalb der App vorzunehmen.';

  @override
  String get sectionHeader10 => '3. Haftungsbeschränkung';

  @override
  String get sectionBody3 =>
      'Wir haften nicht für indirekte, zufällige oder Folgeschäden, die aus der Nutzung unserer App entstehen.';

  @override
  String get sectionHeader11 => '4. Änderungen der Bedingungen';

  @override
  String get sectionBody4 =>
      'Wir können diese Bedingungen von Zeit zu Zeit aktualisieren. Die weitere Nutzung der App nach einer Aktualisierung gilt als Zustimmung zu den neuen Bedingungen.';

  @override
  String get footer2 => 'Zuletzt aktualisiert: November 2025';

  @override
  String get notificationAlertDialogTitle => '🔔 Benachrichtigung';

  @override
  String notificationAlertBodyWithTask(Object taskId) {
    return 'Sie haben eine aktive Benachrichtigung.\n\nTask ID: $taskId\n\nBitte bestätigen, um fortzufahren.';
  }

  @override
  String get notificationAlertBodyNoTask =>
      'Sie haben eine aktive Benachrichtigung.\n\nBitte bestätigen, um fortzufahren.';

  @override
  String get notificationAlertAcknowledgeButton => 'Bestätigen';

  @override
  String get manualRefreshSnackbar => '🔄 Daten werden aktualisiert …';

  @override
  String refreshFailureSnackbar(Object error) {
    return '⚠️ Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get bottomNavLabel => 'Start';

  @override
  String get bottomNavLabel2 => 'Aufgaben';

  @override
  String get bottomNavLabel3 => 'Einstellungen';

  @override
  String get autoCheckInOfflineSnackbar =>
      '✅ Auto-Check-in abgeschlossen (offline)';

  @override
  String get autoCheckOutOfflineSnackbar =>
      '📴 Auto-Check-out offline gespeichert. Wird synchronisiert, sobald online.';

  @override
  String get autoCheckInOfflineSnackbarVariant =>
      '📴 Auto-Check-in offline gespeichert. Wird synchronisiert, sobald online.';

  @override
  String autoCheckInSuccessSnackbar(Object taskName) {
    return '✅ Auto-Check-in erfolgreich für $taskName';
  }

  @override
  String get remoteWipeSnackbar => '🧹 Lokale Daten vom Server gelöscht';

  @override
  String offlineSyncProgressSnackbar(Object count) {
    return '📤 $count Offline-Aktionen werden synchronisiert …';
  }

  @override
  String offlineSyncSuccessSnackbar(Object count) {
    return '✅ $count Aktionen erfolgreich synchronisiert!';
  }

  @override
  String get breakInOfflineSnackbar => '⏸ Pausenbeginn offline gespeichert';

  @override
  String breakInFailureSnackbar(Object statusCode) {
    return '❌ Pausenbeginn fehlgeschlagen ($statusCode)';
  }

  @override
  String get breakOutAuthErrorSnackbar =>
      'Authentifizierungsfehler. Bitte melden Sie sich erneut an.';

  @override
  String get breakOutOfflineSnackbar =>
      '▶️ Pausenende offline gespeichert. Wird später synchronisiert.';

  @override
  String get breakOutSuccessSnackbar => '✅ Pause beendet.';

  @override
  String breakOutFailureSnackbar(Object statusCode) {
    return '❌ Pausenende fehlgeschlagen ($statusCode).';
  }

  @override
  String get breakSelectTaskFirstSnackbar =>
      'Bitte wählen Sie eine Aufgabe aus, bevor Sie eine Pause beginnen.';

  @override
  String get breakButtonLabelOnBreak => 'Pause beenden';

  @override
  String get breakButtonLabelNotOnBreak => 'Pause machen';

  @override
  String get clockOutBlockedByBreakSnackbar =>
      '⛔ Sie sind in der Pause. Bitte beenden Sie die Pause, bevor Sie ausstempeln.';

  @override
  String get clockOutNotClockedInSnackbar =>
      '⛔ Ausstempeln nicht möglich – Sie sind bei keiner Aufgabe eingestempelt';

  @override
  String get clockOutNoTaskFoundSnackbar =>
      'Keine eingestempelte Aufgabe gefunden.';

  @override
  String get clockOutButton => 'Ausstempeln';

  @override
  String get dashboardRetryButton => 'Erneut versuchen';

  @override
  String get dashboardLoadingText => 'Dashboard wird geladen …';

  @override
  String get taskSearchFieldHint => 'Aufgaben suchen …';

  @override
  String get offlineBannerHeading => '📴 Offline-Modus';

  @override
  String get syncingBannerHeading => '📤 Daten werden synchronisiert';

  @override
  String get offlineBannerSubtext =>
      'Check-ins/-outs werden gespeichert und synchronisiert, sobald online';

  @override
  String syncPendingBannerSubtext(Object count) {
    return '$count Aktion(en) warten auf Synchronisierung';
  }

  @override
  String get syncNowTooltip => 'Jetzt synchronisieren';

  @override
  String get taskListSectionTitle => 'Heutige Aufgaben';

  @override
  String get viewAllTasksLink => 'Alle anzeigen';

  @override
  String get emptyTaskListText => 'Keine Aufgaben vorhanden';

  @override
  String get priorityFilterChip => 'Alle';

  @override
  String get priorityFilterChip2 => 'Niedrig';

  @override
  String get priorityFilterChip3 => 'Mittel';

  @override
  String get priorityFilterChip4 => 'Hoch';

  @override
  String get taskCardStatusBadge => 'Eingestempelt';

  @override
  String get punchInAlreadyPunchedOutOfflineSnackbar =>
      '⛔ Sie haben sich bei dieser Aufgabe bereits ausgestempelt (offline). Erneutes Einstempeln nicht möglich.';

  @override
  String get punchInLocationErrorSnackbar =>
      '⛔ Standort konnte nicht ermittelt werden. Bitte aktivieren Sie die Standortdienste.';

  @override
  String get punchInNotOnLocationSnackbar =>
      '⛔ Sie befinden sich nicht vor Ort';

  @override
  String get punchInInvalidTaskDateSnackbar =>
      '⛔ Ungültiges Datumsformat der Aufgabe';

  @override
  String punchInTooEarly(
      Object date, Object hours, Object minutes, Object time) {
    return '⛔ Zu früh! Die Aufgabe beginnt am $date um $time (in $hours Std. $minutes Min.)';
  }

  @override
  String punchInTaskEndedSnackbar(Object date, Object time) {
    return '⛔ Die Aufgabe endete am $date um $time';
  }

  @override
  String get punchInOfflineSnackbar =>
      '📴 Einstempeln offline gespeichert. Wird automatisch synchronisiert.';

  @override
  String get punchInSuccessSnackbar => '✅ Einstempeln erfolgreich';

  @override
  String get punchInOfflinePunchoutBlockSnackbar =>
      '⛔ Für diese Aufgabe liegt bereits ein Offline-Ausstempeln vor. Erneutes Einstempeln nicht möglich.';

  @override
  String get taskAlreadyCompletedSnackbar =>
      'Diese Aufgabe ist bereits abgeschlossen.';

  @override
  String alreadyPunchedIntoAnotherTaskSnackbar(Object taskName) {
    return 'Sie sind bereits bei „$taskName“ eingestempelt.';
  }

  @override
  String get loaderTextCheckingLocation => 'Standort wird geprüft …';

  @override
  String get loaderTextOpeningCamera => 'Kamera wird geöffnet …';

  @override
  String get loaderTextPunchingIn => 'Einstempeln …';

  @override
  String get loaderTextStartingBreak => 'Pause wird gestartet …';

  @override
  String get loaderTextEndingBreak => 'Pause wird beendet …';

  @override
  String get appBarTitle => 'Alle Aufgaben';

  @override
  String get tabLabel => 'Offen';

  @override
  String get tabLabel2 => 'Abgeschlossen';

  @override
  String get searchFieldHint => 'Aufgabe suchen';

  @override
  String get appBarTitle2 => 'Aufgabendetails';

  @override
  String get taskLabel => 'Aufgabe';

  @override
  String get statusFieldLabel => 'Status';

  @override
  String get loggedTimeLabel => 'Erfasst:';

  @override
  String get attachmentsSectionTitle => 'Anhänge';

  @override
  String get remarksFieldLabel => 'Bemerkungen';

  @override
  String get remarksFieldHint => 'Bemerkung eingeben';

  @override
  String get addAttachmentSheetOption => 'Kamera';

  @override
  String get addAttachmentButton => 'Anhang hinzufügen';

  @override
  String get markAsCompletedButton => 'Als abgeschlossen markieren';

  @override
  String get punchOutMissingImageSnackbar =>
      'Bitte wählen Sie mindestens ein Bild aus';

  @override
  String get punchOutNotPunchedInSnackbar =>
      '⛔ Ausstempeln nicht möglich – Sie sind bei keiner Aufgabe eingestempelt';

  @override
  String get punchOutTaskMismatchSnackbar =>
      '⛔ Ausstempeln nicht möglich – Sie sind bei einer anderen Aufgabe eingestempelt';

  @override
  String get loaderTextGettingLocation => 'Standort wird ermittelt …';

  @override
  String get loaderTextPunchingOut => 'Ausstempeln …';

  @override
  String get punchOutOfflineSnackbar =>
      '📴 Ausstempeln offline gespeichert. Wird synchronisiert, sobald online.';

  @override
  String get punchOutSuccessSnackbar => '✅ Ausstempeln erfolgreich';

  @override
  String get changeStatusPopupTitle => 'Status ändern';

  @override
  String get statusOption => 'In Bearbeitung';

  @override
  String get statusPopupSelectButton => 'Auswählen';

  @override
  String get staticSubtextUnderEveryLoaderMessage =>
      'Bitte warten, App nicht schließen';

  @override
  String get genericErrorFallback =>
      'Etwas ist schiefgelaufen. Bitte versuchen Sie es erneut.';

  @override
  String get dialogCancelButton => 'Abbrechen';

  @override
  String get logoutConfirmButton => 'Abmelden';

  @override
  String get deleteAccountDialogTitle => 'Konto löschen';

  @override
  String get deleteAccountDialogBody =>
      'Möchten Sie Ihr Konto wirklich dauerhaft löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountConfirmButton => 'Löschen';

  @override
  String get deleteAccountSuccessSnackbar =>
      'Antrag auf Kontolöschung erfolgreich übermittelt.';

  @override
  String deleteAccountFailureSnackbar(Object details) {
    return 'Konto konnte nicht gelöscht werden: $details';
  }

  @override
  String get sectionHeader12 => 'Allgemein';

  @override
  String get listItemChangePassword => 'Passwort ändern';

  @override
  String get noCamerasFoundError =>
      'Auf diesem Gerät wurde keine Kamera gefunden.';

  @override
  String get noFrontCameraFound =>
      'Keine Front-Kamera auf diesem Gerät gefunden.';

  @override
  String get noBackCameraFound =>
      'Keine Rück-Kamera auf diesem Gerät gefunden.';

  @override
  String get cameraPermissionDeniedError =>
      'Kamerazugriff verweigert. Bitte aktivieren Sie ihn in den Geräteeinstellungen.';

  @override
  String genericCameraExceptionError(Object details) {
    return 'Kamerafehler: $details';
  }

  @override
  String cameraInitFailureError(Object error) {
    return 'Kamera konnte nicht geöffnet werden: $error';
  }

  @override
  String get openSettingsButton => 'Einstellungen öffnen';

  @override
  String get goBackButton => 'Zurück';

  @override
  String get appBarTitle3 => 'Aufgabe abschließen';

  @override
  String get instructionText2 =>
      'Bitte fügen Sie eine Bemerkung und Fotos hinzu, um die Aufgabe als abgeschlossen zu markieren.';

  @override
  String get remarksFieldHint2 => 'Bemerkung eingeben';

  @override
  String attachmentsHeader(Object count) {
    return 'Anhänge ($count)';
  }

  @override
  String submitSuccessSnackbar(Object count, Object remark) {
    return 'Aufgabe abgeschlossen mit Bemerkung: $remark und $count Bildern';
  }

  @override
  String get submitButton2 => 'Als abgeschlossen markieren';

  @override
  String get channelNameGeneral => 'Wichtige Benachrichtigungen';

  @override
  String get channelDescriptionGeneral =>
      'Dieser Kanal wird für wichtige Benachrichtigungen verwendet.';

  @override
  String get channelNameAutoCheckIn => 'Auto-Check-in-Benachrichtigungen';

  @override
  String get channelDescriptionAutoCheckInCreationTime =>
      'Kritische Benachrichtigungen für automatische Aufgaben-Check-ins mit Ton.';

  @override
  String get channelDescriptionAutoCheckInPerNotification =>
      'Kritische Benachrichtigungen für automatische Aufgaben-Check-ins';

  @override
  String get fallbackPushTitle => 'Neue Nachricht';

  @override
  String get fallbackPushBody => 'Sie haben eine neue Benachrichtigung';

  @override
  String get autoCheckInAlertTitle => '🚨 Auto-Check-in erforderlich';

  @override
  String autoCheckInAlertBodyWithLocation(Object location, Object time) {
    return '🎯 Zeit zum Einchecken bei $location Aufgabe beginnt um $time';
  }

  @override
  String autoCheckInAlertBodyNoLocation(Object time) {
    return '🎯 Zeit zum Einchecken für Ihre Aufgabe Aufgabe beginnt um $time';
  }

  @override
  String get liveTrackingChannelName => 'Live-Standortverfolgung';

  @override
  String get liveTrackingChannelDescription =>
      'Wird angezeigt, solange Sie eingestempelt sind, damit Ihr Standort zur Anwesenheitserfassung verfolgt werden kann.';

  @override
  String get liveTrackingPersistentNotificationTitle =>
      'Deineputzcrew — Eingestempelt';

  @override
  String get liveTrackingPersistentNotificationBody =>
      'Ihr Standort wird während Ihrer Schicht erfasst.';

  @override
  String get taskChannelName => 'Aufgaben-Benachrichtigungen';

  @override
  String get taskChannelDescription =>
      'Automatische Aufgaben-Check-in-Benachrichtigungen';

  @override
  String get autoCheckInSuccessNotificationTitleOnline =>
      '✅ Auto-Check-in erfolgreich';

  @override
  String get autoCheckInSuccessNotificationTitleOffline =>
      '✅ Auto-Check-in (offline)';

  @override
  String autoCheckInNotificationBody(Object taskName, Object time) {
    return 'Aufgabe: $taskName Uhrzeit: $time';
  }

  @override
  String get reasonDropdownValue => 'Urlaub';

  @override
  String get reasonDropdownValue2 => 'Erholung / Privat';

  @override
  String get reasonDropdownValue3 => 'Krank';

  @override
  String get reasonDropdownValue4 => 'Sonstiges';

  @override
  String get appbarTitle2 => 'Abwesenheit / Verfügbarkeit';

  @override
  String get adminProposalsSectionHeading => 'Anfragen von deinem Admin';

  @override
  String get adminProposalsSubheading =>
      'Dein Admin hat eine Abwesenheit für dich vorgeschlagen. Prüfe sie und antworte unten.';

  @override
  String adminRequestCardRequestedByLine(Object name) {
    return 'Angefragt von: $name';
  }

  @override
  String get adminRequestCardDefaultAdminNameFallback => 'dein Admin';

  @override
  String adminRequestCardAdminNotePrefix(Object note) {
    return 'Hinweis vom Admin: $note';
  }

  @override
  String get adminRequestCardRejectButton => 'Ablehnen';

  @override
  String get adminRequestCardApproveButton => 'Genehmigen';

  @override
  String get rejectRequestDialogTitle => 'Anfrage ablehnen';

  @override
  String get rejectRequestDialogNoteFieldLabel =>
      'Hinweis für den Admin (optional)';

  @override
  String get snackbarAfterApprove => '✅ Anfrage genehmigt';

  @override
  String get snackbarAfterReject => '❌ Anfrage abgelehnt';

  @override
  String get fallbackErrorRespondingToAdminRequest =>
      'Antwort auf die Anfrage fehlgeschlagen';

  @override
  String get requestTimeOffSectionHeading => 'Abwesenheit beantragen';

  @override
  String get subheadingUnderRequestTimeOff =>
      'Teile deinem Admin mit, dass du im Urlaub bist, dich erholst oder anderweitig nicht verfügbar bist. Die Anfrage wird geprüft und genehmigt.';

  @override
  String get startDateButtonPlaceholder => 'Startdatum';

  @override
  String get endDateButtonPlaceholder => 'Enddatum';

  @override
  String get reasonDropdownFieldLabel => 'Grund';

  @override
  String get noteFieldLabel => 'Notiz (optional)';

  @override
  String get validationSnackbarMissingDates =>
      'Bitte wähle Start- und Enddatum aus';

  @override
  String get submitButton3 => 'Anfrage senden';

  @override
  String get submitSuccessSnackbar2 =>
      '✅ Abwesenheit beantragt — wartet auf Genehmigung durch den Admin';

  @override
  String get submitFailureFallbackSnackbar =>
      'Anfrage konnte nicht gesendet werden';

  @override
  String get yourRequestsSectionHeading => 'Deine Anfragen';

  @override
  String get emptyStateText => 'Noch keine Anfragen.';

  @override
  String get statusBadge => 'Genehmigt';

  @override
  String get statusBadge2 => 'Abgelehnt';

  @override
  String get languageRowLabel => 'Sprache';

  @override
  String get languageDropdownOption => 'Englisch';

  @override
  String get languageDropdownOption2 => 'Deutsch';

  @override
  String get listItemNavigatesToTimeOffScreen => 'Abwesenheit / Verfügbarkeit';

  @override
  String get shiftResponseSnackbarAccepted => '✅ Schicht angenommen';

  @override
  String get shiftResponseSnackbarDeclined => '🚫 Schicht abgelehnt';

  @override
  String get shiftResponseFallbackErrorSnackbar =>
      'Antwort auf die Schicht fehlgeschlagen';

  @override
  String get needsResponseCardInfoLine =>
      'Diese Schicht wartet auf deine Antwort';

  @override
  String get acceptButtonNeedsResponseCard => 'Annehmen';

  @override
  String get declineButtonNeedsResponseCard => 'Ablehnen';

  @override
  String get statusChipAfterRespondingAccepted => '✅ Angenommen';

  @override
  String get statusChipAfterRespondingDeclined => '🚫 Abgelehnt';

  @override
  String get debugTestNotificationChannelDescription =>
      'Testbenachrichtigung mit Ton';

  @override
  String debugTestNotificationTitle(Object number) {
    return '🔔 Tontest #$number';
  }

  @override
  String get debugTestNotificationBody =>
      'Test des Standard-Benachrichtigungstons des Systems';
}

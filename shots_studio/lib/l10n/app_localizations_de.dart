// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'Screenshots durchsuchen';

  @override
  String analyzed(int count, int total) {
    return 'Analysiert $count/$total';
  }

  @override
  String get developerModeDisabled => 'Erweiterte Einstellungen deaktiviert';

  @override
  String get collections => 'Sammlungen';

  @override
  String get screenshots => 'Screenshots';

  @override
  String get settings => 'Einstellungen';

  @override
  String get about => 'Über';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get createCollection => 'Sammlung erstellen';

  @override
  String get editCollection => 'Sammlung bearbeiten';

  @override
  String get deleteCollection => 'Sammlung löschen';

  @override
  String get collectionName => 'Sammlungsname';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Suchen';

  @override
  String get noResults => 'Keine Ergebnisse gefunden';

  @override
  String get loading => 'Laden...';

  @override
  String get error => 'Fehler';

  @override
  String get retry => 'Wiederholen';

  @override
  String get share => 'Teilen';

  @override
  String get copy => 'Kopieren';

  @override
  String get paste => 'Einfügen';

  @override
  String get selectAll => 'Alle auswählen';

  @override
  String get aiSettings => 'KI-Einstellungen';

  @override
  String get apiKey => 'API-Schlüssel';

  @override
  String get modelName => 'Modellname';

  @override
  String get autoProcessing => 'Automatische Verarbeitung';

  @override
  String get enabled => 'Aktiviert';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get theme => 'Design';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get systemTheme => 'System';

  @override
  String get language => 'Sprache';

  @override
  String get analytics => 'Analyse';

  @override
  String get betaTesting => 'Beta Testing';

  @override
  String get writeTagsToXMP => 'Tags in XMP schreiben';

  @override
  String get xmpMetadataWritten => 'XMP-Metadaten in Datei geschrieben';

  @override
  String get advancedSettings => 'Erweiterte Einstellungen';

  @override
  String get developerMode => 'Erweiterte Einstellungen';

  @override
  String get safeDelete => 'Sicheres Löschen';

  @override
  String get sourceCode => 'Quellcode';

  @override
  String get support => 'Support';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get privacyNotice => 'Datenschutzhinweis';

  @override
  String get analyticsAndTelemetry => 'Analytik und Telemetrie';

  @override
  String get performanceMenu => 'Leistungsmenü';

  @override
  String get serverMessages => 'Server-Nachrichten';

  @override
  String get maxParallelAI => 'Max parallele KI';

  @override
  String get enableScreenshotLimit => 'Screenshot-Limit aktivieren';

  @override
  String get tags => 'Tags';

  @override
  String get aiDetails => 'KI-Details';

  @override
  String get size => 'Größe';

  @override
  String get addDescription => 'Beschreibung hinzufügen';

  @override
  String get addTag => 'Tag hinzufügen';

  @override
  String get amoledMode => 'AMOLED-Modus';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get storage => 'Speicher';

  @override
  String get camera => 'Kamera';

  @override
  String get version => 'Version';

  @override
  String get buildNumber => 'Build-Nummer';

  @override
  String get ocrResults => 'OCR-Ergebnisse';

  @override
  String get extractedText => 'Extrahierter Text';

  @override
  String get noTextFound => 'Kein Text im Bild gefunden';

  @override
  String get processing => 'Verarbeitung...';

  @override
  String get selectImage => 'Bild auswählen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get fromGallery => 'Aus Galerie';

  @override
  String get imageSelected => 'Bild ausgewählt';

  @override
  String get noImageSelected => 'Kein Bild ausgewählt';

  @override
  String get apiKeyRequired => 'Erforderlich für KI-Funktionen';

  @override
  String get apiKeyValid => 'API-Schlüssel ist gültig';

  @override
  String get apiKeyValidationFailed =>
      'API-Schlüssel-Validierung fehlgeschlagen';

  @override
  String get apiKeyNotValidated =>
      'API-Schlüssel ist gesetzt (nicht validiert)';

  @override
  String get enterApiKey => 'Gemini API-Schlüssel eingeben';

  @override
  String get validateApiKey => 'API-Schlüssel validieren';

  @override
  String get valid => 'Gültig';

  @override
  String get autoProcessingDescription =>
      'Screenshots werden automatisch verarbeitet, wenn sie hinzugefügt werden';

  @override
  String get manualProcessingOnly => 'Nur manuelle Verarbeitung';

  @override
  String get amoledModeDescription =>
      'Dunkles Design optimiert für AMOLED-Bildschirme';

  @override
  String get defaultDarkTheme => 'Standard dunkles Design';

  @override
  String get getApiKey => 'API-Schlüssel erhalten';

  @override
  String get stopProcessing => 'Verarbeitung stoppen';

  @override
  String get processWithAI => 'Mit KI verarbeiten';

  @override
  String get createFirstCollection => 'Erstellen Sie Ihre erste Sammlung, um';

  @override
  String get organizeScreenshots => 'Ihre Screenshots zu organisieren';

  @override
  String get cancelSelection => 'Auswahl abbrechen';

  @override
  String get deselectAll => 'Alle abwählen';

  @override
  String get deleteSelected => 'Ausgewählte löschen';

  @override
  String get clearCorruptFiles => 'Beschädigte Dateien löschen';

  @override
  String get clearCorruptFilesConfirm => 'Beschädigte Dateien löschen?';

  @override
  String get clearCorruptFilesMessage =>
      'Sind Sie sicher, dass Sie alle beschädigten Dateien entfernen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get corruptFilesCleared => 'Beschädigte Dateien gelöscht';

  @override
  String get noCorruptFiles => 'Keine beschädigten Dateien gefunden';

  @override
  String get enableLocalAI => '🤖 Lokales KI-Modell aktivieren';

  @override
  String get localAIBenefits => 'Vorteile der lokalen KI:';

  @override
  String get localAIOffline =>
      '• Funktioniert vollständig offline - kein Internet erforderlich';

  @override
  String get localAIPrivacy => '• Ihre Daten bleiben privat auf Ihrem Gerät';

  @override
  String get localAINote => 'Hinweis:';

  @override
  String get localAIBattery => '• Verbraucht mehr Akku als Cloud-Modelle';

  @override
  String get localAIRAM => '• Benötigt mindestens 4GB verfügbaren RAM';

  @override
  String get localAIPrivacyNote =>
      'Das Modell wird Ihre Screenshots lokal verarbeiten für verbesserte Privatsphäre.';

  @override
  String get enableLocalAIButton => 'Lokale KI aktivieren';

  @override
  String get reminders => 'Erinnerungen';

  @override
  String get activeReminders => 'Aktiv';

  @override
  String get pastReminders => 'Vergangen';

  @override
  String get noActiveReminders =>
      'Keine aktiven Erinnerungen.\nErinnerungen in den Screenshot-Details setzen.';

  @override
  String get noPastReminders => 'Keine vergangenen Erinnerungen.';

  @override
  String get editReminder => 'Erinnerung bearbeiten';

  @override
  String get clearReminder => 'Erinnerung löschen';

  @override
  String get removePastReminder => 'Entfernen';

  @override
  String get pastReminderRemoved => 'Vergangene Erinnerung entfernt';

  @override
  String get supportTheProject => 'Projekt unterstützen';

  @override
  String get supportShotsStudio => 'Shots Studio unterstützen';

  @override
  String get supportDescription =>
      'Ihre Unterstützung hilft dabei, dieses Projekt am Leben zu erhalten und ermöglicht uns, tolle neue Funktionen hinzuzufügen';

  @override
  String get availableNow => 'Jetzt verfügbar';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get everyContributionMatters => 'Jeder Beitrag zählt';

  @override
  String get supportFooterDescription =>
      'Vielen Dank, dass Sie eine Unterstützung dieses Projekts in Betracht ziehen. Ihr Beitrag hilft uns dabei, Shots Studio zu pflegen und zu verbessern. Für spezielle Vereinbarungen oder internationale Überweisungen kontaktieren Sie uns bitte über GitHub.';

  @override
  String get contactOnGitHub => 'Auf GitHub kontaktieren';

  @override
  String get noSponsorshipOptions =>
      'Derzeit sind keine Sponsoring-Optionen verfügbar.';

  @override
  String get close => 'Schließen';

  @override
  String get quickCreateCollection => 'Schnell Sammlung erstellen';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return 'Neue Sammlung \"$collectionName\" mit $count Screenshot(s) aus Ihren Suchergebnissen erstellen?';
  }

  @override
  String get quickCreateWhatHappens => 'Was passiert:';

  @override
  String get quickCreateExplanation =>
      'Alle Screenshots aus Ihren Suchergebnissen werden zu dieser neuen Sammlung hinzugefügt. Sie können den Sammlungsnamen und die Einstellungen später anpassen.';

  @override
  String get dontShowAgain => 'Nicht mehr anzeigen';

  @override
  String get create => 'Erstellen';

  @override
  String get createCollectionFromSearchResults =>
      'Sammlung aus Suchergebnissen erstellen';

  @override
  String noScreenshotsFoundFor(String query) {
    return 'Keine Screenshots für \"$query\" gefunden';
  }

  @override
  String get dataManagement => 'Data Management';

  @override
  String get dataManagementDescription =>
      'Backup and restore your screenshots metadata, collections, and settings.';

  @override
  String get backup => 'Backup';

  @override
  String get restore => 'Restore';

  @override
  String get restoreData => 'Restore Data';

  @override
  String get restoreWarning =>
      'This will replace all your current data with the backup. Make sure you have a current backup before proceeding.\n\nImages that no longer exist on your device will be skipped.';
}

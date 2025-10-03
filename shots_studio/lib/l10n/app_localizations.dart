import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('ja'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Shots Studio'**
  String get appTitle;

  /// Tooltip for search button
  ///
  /// In en, this message translates to:
  /// **'Search Screenshots'**
  String get searchScreenshots;

  /// Shows progress of AI analysis
  ///
  /// In en, this message translates to:
  /// **'Analyzed {count}/{total}'**
  String analyzed(int count, int total);

  /// Message shown when developer mode is disabled
  ///
  /// In en, this message translates to:
  /// **'Advanced settings disabled'**
  String get developerModeDisabled;

  /// Collections section title
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get collections;

  /// Screenshots section title
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get screenshots;

  /// Settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Privacy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// Button text to create a new collection
  ///
  /// In en, this message translates to:
  /// **'Create Collection'**
  String get createCollection;

  /// Button text to edit collection
  ///
  /// In en, this message translates to:
  /// **'Edit Collection'**
  String get editCollection;

  /// Button text to delete collection
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get deleteCollection;

  /// Label for collection name input field
  ///
  /// In en, this message translates to:
  /// **'Collection Name'**
  String get collectionName;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Message when search returns no results
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Error message
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Share button text
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Paste button text
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Select all button text
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// AI Settings menu item
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiSettings;

  /// API Key label
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// Model name label
  ///
  /// In en, this message translates to:
  /// **'Model Name'**
  String get modelName;

  /// Auto processing setting
  ///
  /// In en, this message translates to:
  /// **'Auto Processing'**
  String get autoProcessing;

  /// Enabled status
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// Disabled status
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Analytics setting
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// Beta testing setting
  ///
  /// In en, this message translates to:
  /// **'Beta Testing'**
  String get betaTesting;

  /// XMP metadata writing setting
  ///
  /// In en, this message translates to:
  /// **'Write Tags to XMP'**
  String get writeTagsToXMP;

  /// Indicator showing XMP metadata has been written to the image file
  ///
  /// In en, this message translates to:
  /// **'XMP metadata written to file'**
  String get xmpMetadataWritten;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// Advanced settings mode setting
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get developerMode;

  /// No description provided for @safeDelete.
  ///
  /// In en, this message translates to:
  /// **'Safe Delete'**
  String get safeDelete;

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @privacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get privacyNotice;

  /// No description provided for @analyticsAndTelemetry.
  ///
  /// In en, this message translates to:
  /// **'Analytics and Telemetry'**
  String get analyticsAndTelemetry;

  /// No description provided for @performanceMenu.
  ///
  /// In en, this message translates to:
  /// **'Performance Menu'**
  String get performanceMenu;

  /// No description provided for @serverMessages.
  ///
  /// In en, this message translates to:
  /// **'Server Messages'**
  String get serverMessages;

  /// No description provided for @maxParallelAI.
  ///
  /// In en, this message translates to:
  /// **'Max Parallel AI'**
  String get maxParallelAI;

  /// No description provided for @enableScreenshotLimit.
  ///
  /// In en, this message translates to:
  /// **'Enable Screenshot Limit'**
  String get enableScreenshotLimit;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @aiDetails.
  ///
  /// In en, this message translates to:
  /// **'AI Details'**
  String get aiDetails;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @addDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a description'**
  String get addDescription;

  /// No description provided for @addTag.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get addTag;

  /// AMOLED mode setting
  ///
  /// In en, this message translates to:
  /// **'AMOLED Mode'**
  String get amoledMode;

  /// Notifications setting
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Permissions setting
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// Storage setting
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// Camera permission
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Build number label
  ///
  /// In en, this message translates to:
  /// **'Build Number'**
  String get buildNumber;

  /// OCR results dialog title
  ///
  /// In en, this message translates to:
  /// **'OCR Results'**
  String get ocrResults;

  /// Label for extracted text from OCR
  ///
  /// In en, this message translates to:
  /// **'Extracted Text'**
  String get extractedText;

  /// Message when OCR finds no text
  ///
  /// In en, this message translates to:
  /// **'No text found in image'**
  String get noTextFound;

  /// Processing message
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// Select image button text
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// Take photo button text
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// From gallery button text
  ///
  /// In en, this message translates to:
  /// **'From Gallery'**
  String get fromGallery;

  /// Message when image is selected
  ///
  /// In en, this message translates to:
  /// **'Image selected'**
  String get imageSelected;

  /// Message when no image is selected
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// Message when API key is required
  ///
  /// In en, this message translates to:
  /// **'Required for AI features'**
  String get apiKeyRequired;

  /// Message when API key is valid
  ///
  /// In en, this message translates to:
  /// **'API key is valid'**
  String get apiKeyValid;

  /// Message when API key validation fails
  ///
  /// In en, this message translates to:
  /// **'API key validation failed'**
  String get apiKeyValidationFailed;

  /// Message when API key is set but not validated
  ///
  /// In en, this message translates to:
  /// **'API key is set (not validated)'**
  String get apiKeyNotValidated;

  /// Placeholder text for API key field
  ///
  /// In en, this message translates to:
  /// **'Enter Gemini API Key'**
  String get enterApiKey;

  /// Button text to validate API key
  ///
  /// In en, this message translates to:
  /// **'Validate API Key'**
  String get validateApiKey;

  /// Valid status text
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// Description for auto processing when enabled
  ///
  /// In en, this message translates to:
  /// **'Screenshots will be automatically processed when added'**
  String get autoProcessingDescription;

  /// Description for auto processing when disabled
  ///
  /// In en, this message translates to:
  /// **'Manual processing only'**
  String get manualProcessingOnly;

  /// Description for AMOLED mode when enabled
  ///
  /// In en, this message translates to:
  /// **'Dark theme optimized for AMOLED screens'**
  String get amoledModeDescription;

  /// Description for AMOLED mode when disabled
  ///
  /// In en, this message translates to:
  /// **'Default dark theme'**
  String get defaultDarkTheme;

  /// Tooltip for API key help button
  ///
  /// In en, this message translates to:
  /// **'Get an API key'**
  String get getApiKey;

  /// Tooltip for stop processing button
  ///
  /// In en, this message translates to:
  /// **'Stop Processing'**
  String get stopProcessing;

  /// Tooltip for process with AI button
  ///
  /// In en, this message translates to:
  /// **'Process with AI'**
  String get processWithAI;

  /// First part of empty collections message
  ///
  /// In en, this message translates to:
  /// **'Create your first collection to'**
  String get createFirstCollection;

  /// Second part of empty collections message
  ///
  /// In en, this message translates to:
  /// **'organize your screenshots'**
  String get organizeScreenshots;

  /// Tooltip for cancel selection button
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get cancelSelection;

  /// Deselect all button text
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAll;

  /// Tooltip for delete selected button
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get deleteSelected;

  /// Button to clear all corrupt files
  ///
  /// In en, this message translates to:
  /// **'Clear Corrupt Files'**
  String get clearCorruptFiles;

  /// Title for confirm dialog to clear corrupt files
  ///
  /// In en, this message translates to:
  /// **'Clear Corrupt Files?'**
  String get clearCorruptFilesConfirm;

  /// Message for confirm dialog to clear corrupt files
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all corrupt files from this collection? This action cannot be undone.'**
  String get clearCorruptFilesMessage;

  /// Message shown when corrupt files are cleared
  ///
  /// In en, this message translates to:
  /// **'Corrupt files cleared'**
  String get corruptFilesCleared;

  /// Message shown when no corrupt files are found
  ///
  /// In en, this message translates to:
  /// **'No corrupt files found'**
  String get noCorruptFiles;

  /// Title for enable local AI dialog
  ///
  /// In en, this message translates to:
  /// **'🤖 Enable Local AI Model'**
  String get enableLocalAI;

  /// Header for What this means: section
  ///
  /// In en, this message translates to:
  /// **'What this means:'**
  String get localAIBenefits;

  /// Local AI benefit: offline functionality
  ///
  /// In en, this message translates to:
  /// **'• Works completely offline - no internet required'**
  String get localAIOffline;

  /// Local AI benefit: privacy
  ///
  /// In en, this message translates to:
  /// **'• Your data stays private on your device'**
  String get localAIPrivacy;

  /// Header for local AI notes section
  ///
  /// In en, this message translates to:
  /// **'Note:'**
  String get localAINote;

  /// Local AI note: battery usage
  ///
  /// In en, this message translates to:
  /// **'• Uses more battery than cloud models'**
  String get localAIBattery;

  /// Local AI note: RAM requirement
  ///
  /// In en, this message translates to:
  /// **'• Requires at least 4GB of available RAM'**
  String get localAIRAM;

  /// Local AI privacy explanation
  ///
  /// In en, this message translates to:
  /// **'The model will process your screenshots locally for enhanced privacy.'**
  String get localAIPrivacyNote;

  /// Button text to enable local AI
  ///
  /// In en, this message translates to:
  /// **'Enable Local AI'**
  String get enableLocalAIButton;

  /// Reminders screen title
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Active reminders tab title
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeReminders;

  /// Past reminders tab title
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastReminders;

  /// Message shown when there are no active reminders
  ///
  /// In en, this message translates to:
  /// **'No active reminders.\nSet reminders from screenshot details.'**
  String get noActiveReminders;

  /// Message shown when there are no past reminders
  ///
  /// In en, this message translates to:
  /// **'No past reminders.'**
  String get noPastReminders;

  /// Tooltip for edit reminder button
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// Tooltip for clear reminder button
  ///
  /// In en, this message translates to:
  /// **'Clear Reminder'**
  String get clearReminder;

  /// Tooltip for remove past reminder button
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePastReminder;

  /// Message shown when a past reminder is removed
  ///
  /// In en, this message translates to:
  /// **'Past reminder removed'**
  String get pastReminderRemoved;

  /// Title for sponsorship dialog and support button
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportTheProject;

  /// Main title in sponsorship dialog
  ///
  /// In en, this message translates to:
  /// **'Support Shots Studio'**
  String get supportShotsStudio;

  /// Description text in sponsorship dialog
  ///
  /// In en, this message translates to:
  /// **'Your support helps keep this project alive and enables us to add amazing new features'**
  String get supportDescription;

  /// Section title for available sponsorship options
  ///
  /// In en, this message translates to:
  /// **'Available now'**
  String get availableNow;

  /// Section title for upcoming sponsorship options
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Footer title in sponsorship dialog
  ///
  /// In en, this message translates to:
  /// **'Every contribution matters'**
  String get everyContributionMatters;

  /// Footer description in sponsorship dialog
  ///
  /// In en, this message translates to:
  /// **'Thank you for considering supporting this project. Your contribution helps us maintain and improve Shots Studio. For special arrangements or international wire transfers, please reach out via GitHub.'**
  String get supportFooterDescription;

  /// Button text to contact developer on GitHub
  ///
  /// In en, this message translates to:
  /// **'Contact on GitHub'**
  String get contactOnGitHub;

  /// Message when no sponsorship options are available
  ///
  /// In en, this message translates to:
  /// **'No sponsorship options are currently available.'**
  String get noSponsorshipOptions;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'ja',
    'pl',
    'pt',
    'ru',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

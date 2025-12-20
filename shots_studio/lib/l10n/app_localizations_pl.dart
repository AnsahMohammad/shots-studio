// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'Szukaj Zrzutów Ekranu';

  @override
  String analyzed(int count, int total) {
    return 'Przeanalizowano $count/$total';
  }

  @override
  String get developerModeDisabled => 'Ustawienia zaawansowane wyłączone';

  @override
  String get collections => 'Kolekcje';

  @override
  String get screenshots => 'Zrzuty Ekranu';

  @override
  String get settings => 'Ustawienia';

  @override
  String get about => 'O Aplikacji';

  @override
  String get privacy => 'Prywatność';

  @override
  String get createCollection => 'Utwórz Kolekcję';

  @override
  String get editCollection => 'Edytuj Kolekcję';

  @override
  String get deleteCollection => 'Usuń Kolekcję';

  @override
  String get collectionName => 'Nazwa Kolekcji';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get confirm => 'Potwierdź';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Szukaj';

  @override
  String get noResults => 'Nie znaleziono wyników';

  @override
  String get loading => 'Ładowanie...';

  @override
  String get error => 'Błąd';

  @override
  String get retry => 'Ponów';

  @override
  String get share => 'Udostępnij';

  @override
  String get copy => 'Kopiuj';

  @override
  String get paste => 'Wklej';

  @override
  String get selectAll => 'Zaznacz Wszystko';

  @override
  String get aiSettings => 'Ustawienia AI';

  @override
  String get apiKey => 'Klucz API';

  @override
  String get modelName => 'Nazwa Modelu';

  @override
  String get autoProcessing => 'Automatyczne Przetwarzanie';

  @override
  String get enabled => 'Włączone';

  @override
  String get disabled => 'Wyłączone';

  @override
  String get theme => 'Motyw';

  @override
  String get lightTheme => 'Jasny';

  @override
  String get darkTheme => 'Ciemny';

  @override
  String get systemTheme => 'Systemowy';

  @override
  String get language => 'Język';

  @override
  String get analytics => 'Analityka';

  @override
  String get betaTesting => 'Testy Beta';

  @override
  String get writeTagsToXMP => 'Zapisz tagi do XMP';

  @override
  String get xmpMetadataWritten => 'Metadane XMP zapisane do pliku';

  @override
  String get advancedSettings => 'Ustawienia Zaawansowane';

  @override
  String get developerMode => 'Ustawienia Zaawansowane';

  @override
  String get safeDelete => 'Bezpieczne Usuwanie';

  @override
  String get sourceCode => 'Kod Źródłowy';

  @override
  String get support => 'Wsparcie';

  @override
  String get checkForUpdates => 'Sprawdź Aktualizacje';

  @override
  String get privacyNotice => 'Informacja o Prywatności';

  @override
  String get analyticsAndTelemetry => 'Analityka i Telemetria';

  @override
  String get performanceMenu => 'Menu Wydajności';

  @override
  String get serverMessages => 'Wiadomości Serwera';

  @override
  String get maxParallelAI => 'Maksymalne Równoległe AI';

  @override
  String get enableScreenshotLimit => 'Włącz Limit Zrzutów';

  @override
  String get tags => 'Tagi';

  @override
  String get aiDetails => 'Szczegóły AI';

  @override
  String get size => 'Rozmiar';

  @override
  String get addDescription => 'Dodaj opis';

  @override
  String get addTag => 'Dodaj tag';

  @override
  String get amoledMode => 'Tryb AMOLED';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get permissions => 'Uprawnienia';

  @override
  String get storage => 'Pamięć';

  @override
  String get camera => 'Kamera';

  @override
  String get version => 'Wersja';

  @override
  String get buildNumber => 'Numer Kompilacji';

  @override
  String get ocrResults => 'Wyniki OCR';

  @override
  String get extractedText => 'Wyodrębniony Tekst';

  @override
  String get noTextFound => 'Nie znaleziono tekstu w obrazie';

  @override
  String get processing => 'Przetwarzanie...';

  @override
  String get selectImage => 'Wybierz Obraz';

  @override
  String get takePhoto => 'Zrób Zdjęcie';

  @override
  String get fromGallery => 'Z Galerii';

  @override
  String get imageSelected => 'Obraz wybrany';

  @override
  String get noImageSelected => 'Nie wybrano obrazu';

  @override
  String get apiKeyRequired => 'Wymagany do funkcji AI';

  @override
  String get apiKeyValid => 'Klucz API jest prawidłowy';

  @override
  String get apiKeyValidationFailed =>
      'Weryfikacja klucza API nie powiodła się';

  @override
  String get apiKeyNotValidated =>
      'Klucz API jest ustawiony (nie zweryfikowany)';

  @override
  String get enterApiKey => 'Wprowadź Klucz API Gemini';

  @override
  String get validateApiKey => 'Weryfikuj Klucz API';

  @override
  String get valid => 'Prawidłowy';

  @override
  String get autoProcessingDescription =>
      'Zrzuty ekranu będą automatycznie przetwarzane po dodaniu';

  @override
  String get manualProcessingOnly => 'Tylko ręczne przetwarzanie';

  @override
  String get amoledModeDescription =>
      'Ciemny motyw zoptymalizowany dla ekranów AMOLED';

  @override
  String get defaultDarkTheme => 'Domyślny ciemny motyw';

  @override
  String get getApiKey => 'Pobierz klucz API';

  @override
  String get stopProcessing => 'Zatrzymaj Przetwarzanie';

  @override
  String get processWithAI => 'Przetwarzaj z AI';

  @override
  String get createFirstCollection => 'Utwórz swoją pierwszą kolekcję, aby';

  @override
  String get organizeScreenshots => 'uporządkować swoje zrzuty ekranu';

  @override
  String get cancelSelection => 'Anuluj zaznaczenie';

  @override
  String get deselectAll => 'Odznacz Wszystko';

  @override
  String get deleteSelected => 'Usuń zaznaczone';

  @override
  String get clearCorruptFiles => 'Wyczyść Uszkodzone Pliki';

  @override
  String get clearCorruptFilesConfirm => 'Wyczyścić Uszkodzone Pliki?';

  @override
  String get clearCorruptFilesMessage =>
      'Czy na pewno chcesz usunąć wszystkie uszkodzone pliki z tej kolekcji? Ta akcja nie może zostać cofnięta.';

  @override
  String get corruptFilesCleared => 'Uszkodzone pliki zostały wyczyszczone';

  @override
  String get noCorruptFiles => 'Nie znaleziono uszkodzonych plików';

  @override
  String get enableLocalAI => '🤖 Włącz Lokalny Model AI';

  @override
  String get localAIBenefits => 'Co to oznacza:';

  @override
  String get localAIOffline =>
      '• Działa całkowicie offline - nie wymaga internetu';

  @override
  String get localAIPrivacy => '• Twoje dane pozostają prywatne na urządzeniu';

  @override
  String get localAINote => 'Uwaga:';

  @override
  String get localAIBattery => '• Zużywa więcej baterii niż modele chmurowe';

  @override
  String get localAIRAM => '• Wymaga co najmniej 4GB dostępnej pamięci RAM';

  @override
  String get localAIPrivacyNote =>
      'Model będzie przetwarzał twoje zrzuty ekranu lokalnie dla zwiększonej prywatności.';

  @override
  String get enableLocalAIButton => 'Włącz Lokalne AI';

  @override
  String get reminders => 'Przypomnienia';

  @override
  String get activeReminders => 'Aktywne';

  @override
  String get pastReminders => 'Przeszłe';

  @override
  String get noActiveReminders =>
      'Brak aktywnych przypomnień.\nUstaw przypomnienia ze szczegółów zrzutu ekranu.';

  @override
  String get noPastReminders => 'Brak przeszłych przypomnień.';

  @override
  String get editReminder => 'Edytuj Przypomnienie';

  @override
  String get clearReminder => 'Wyczyść Przypomnienie';

  @override
  String get removePastReminder => 'Usuń';

  @override
  String get pastReminderRemoved => 'Przeszłe przypomnienie zostało usunięte';

  @override
  String get supportTheProject => 'Wspieraj projekt';

  @override
  String get supportShotsStudio => 'Wspieraj Shots Studio';

  @override
  String get supportDescription =>
      'Twoje wsparcie pomaga utrzymać ten projekt przy życiu i umożliwia nam dodawanie niesamowitych nowych funkcji';

  @override
  String get availableNow => 'Dostępne teraz';

  @override
  String get comingSoon => 'Wkrótce';

  @override
  String get everyContributionMatters => 'Każdy wkład ma znaczenie';

  @override
  String get supportFooterDescription =>
      'Dziękujemy za rozważenie wsparcia tego projektu. Twój wkład pomaga nam utrzymywać i ulepszać Shots Studio. W przypadku specjalnych ustaleń lub międzynarodowych przelewów bankowych, skontaktuj się z nami przez GitHub.';

  @override
  String get contactOnGitHub => 'Kontakt na GitHub';

  @override
  String get noSponsorshipOptions =>
      'Obecnie nie ma dostępnych opcji sponsoringu.';

  @override
  String get close => 'Zamknij';

  @override
  String get quickCreateCollection => 'Szybkie Tworzenie Kolekcji';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return 'Chcesz utworzyć kolekcję o nazwie \"$collectionName\" z $count zrzutami ekranu?';
  }

  @override
  String get quickCreateWhatHappens => 'Co się stanie?';

  @override
  String get quickCreateExplanation =>
      'Natychmiast utworzymy nową kolekcję zawierającą wszystkie wyniki wyszukiwania.';

  @override
  String get dontShowAgain => 'Nie pokazuj ponownie';

  @override
  String get create => 'Utwórz';

  @override
  String get createCollectionFromSearchResults =>
      'Utwórz kolekcję z wyników wyszukiwania';

  @override
  String noScreenshotsFoundFor(String query) {
    return 'Nie znaleziono zrzutów ekranu dla \"$query\"';
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

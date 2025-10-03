// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'Поиск скриншотов';

  @override
  String analyzed(int count, int total) {
    return 'Проанализировано $count/$total';
  }

  @override
  String get developerModeDisabled => 'Расширенные настройки отключены';

  @override
  String get collections => 'Коллекции';

  @override
  String get screenshots => 'Скриншоты';

  @override
  String get settings => 'Настройки';

  @override
  String get about => 'О программе';

  @override
  String get privacy => 'Конфиденциальность';

  @override
  String get createCollection => 'Создать коллекцию';

  @override
  String get editCollection => 'Редактировать коллекцию';

  @override
  String get deleteCollection => 'Удалить коллекцию';

  @override
  String get collectionName => 'Название коллекции';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get ok => 'ОК';

  @override
  String get search => 'Поиск';

  @override
  String get noResults => 'Результаты не найдены';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get share => 'Поделиться';

  @override
  String get copy => 'Копировать';

  @override
  String get paste => 'Вставить';

  @override
  String get selectAll => 'Выбрать всё';

  @override
  String get aiSettings => 'Настройки ИИ';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get modelName => 'Модель ИИ';

  @override
  String get autoProcessing => 'Автообработка';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Отключено';

  @override
  String get theme => 'Тема';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Темная';

  @override
  String get systemTheme => 'Системная';

  @override
  String get language => 'Язык';

  @override
  String get analytics => 'Аналитика';

  @override
  String get betaTesting => 'Бета-тестирование';

  @override
  String get writeTagsToXMP => 'Записать теги в XMP';

  @override
  String get xmpMetadataWritten => 'XMP метаданные записаны в файл';

  @override
  String get advancedSettings => 'Расширенные настройки';

  @override
  String get developerMode => 'Расширенные настройки';

  @override
  String get safeDelete => 'Безопасное удаление';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get support => 'Поддержка';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get privacyNotice => 'Уведомление о конфиденциальности';

  @override
  String get analyticsAndTelemetry => 'Аналитика и телеметрия';

  @override
  String get performanceMenu => 'Меню производительности';

  @override
  String get serverMessages => 'Сообщения сервера';

  @override
  String get maxParallelAI => 'Максимум параллельных ИИ';

  @override
  String get enableScreenshotLimit => 'Включить лимит скриншотов';

  @override
  String get tags => 'Теги';

  @override
  String get aiDetails => 'Детали ИИ';

  @override
  String get size => 'Размер';

  @override
  String get addDescription => 'Добавить описание';

  @override
  String get addTag => 'Добавить тег';

  @override
  String get amoledMode => 'Режим AMOLED';

  @override
  String get notifications => 'Уведомления';

  @override
  String get permissions => 'Разрешения';

  @override
  String get storage => 'Хранилище';

  @override
  String get camera => 'Камера';

  @override
  String get version => 'Версия';

  @override
  String get buildNumber => 'Номер сборки';

  @override
  String get ocrResults => 'Результаты OCR';

  @override
  String get extractedText => 'Извлеченный текст';

  @override
  String get noTextFound => 'Текст в изображении не найден';

  @override
  String get processing => 'Обработка...';

  @override
  String get selectImage => 'Выбрать изображение';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get imageSelected => 'Изображение выбрано';

  @override
  String get noImageSelected => 'Изображение не выбрано';

  @override
  String get apiKeyRequired => 'Требуется для функций ИИ';

  @override
  String get apiKeyValid => 'API-ключ действителен';

  @override
  String get apiKeyValidationFailed => 'Проверка API-ключа не удалась';

  @override
  String get apiKeyNotValidated => 'API-ключ установлен (не проверен)';

  @override
  String get enterApiKey => 'Введите API-ключ Gemini';

  @override
  String get validateApiKey => 'Проверить API-ключ';

  @override
  String get valid => 'Действителен';

  @override
  String get autoProcessingDescription =>
      'Скриншоты будут автоматически обрабатываться при добавлении';

  @override
  String get manualProcessingOnly => 'Только ручная обработка';

  @override
  String get amoledModeDescription =>
      'Темная тема, оптимизированная для AMOLED-экранов';

  @override
  String get defaultDarkTheme => 'Стандартная темная тема';

  @override
  String get getApiKey => 'Получить API-ключ';

  @override
  String get stopProcessing => 'Остановить обработку';

  @override
  String get processWithAI => 'Обработать с ИИ';

  @override
  String get createFirstCollection => 'Создайте свою первую коллекцию, чтобы';

  @override
  String get organizeScreenshots => 'организовать ваши скриншоты';

  @override
  String get cancelSelection => 'Отменить выбор';

  @override
  String get deselectAll => 'Отменить выбор';

  @override
  String get deleteSelected => 'Удалить выбранные';

  @override
  String get clearCorruptFiles => 'Очистить поврежденные файлы';

  @override
  String get clearCorruptFilesConfirm => 'Очистить поврежденные файлы?';

  @override
  String get clearCorruptFilesMessage =>
      'Вы уверены, что хотите удалить все поврежденные файлы? Это действие нельзя отменить.';

  @override
  String get corruptFilesCleared => 'Поврежденные файлы очищены';

  @override
  String get noCorruptFiles => 'Поврежденные файлы не найдены';

  @override
  String get enableLocalAI => '🤖 Включить локальную модель ИИ';

  @override
  String get localAIBenefits => 'Преимущества локального ИИ:';

  @override
  String get localAIOffline =>
      '• Работает полностью офлайн - интернет не требуется';

  @override
  String get localAIPrivacy =>
      '• Ваши данные остаются приватными на вашем устройстве';

  @override
  String get localAINote => 'Примечание:';

  @override
  String get localAIBattery =>
      '• Использует больше батареи чем облачные модели';

  @override
  String get localAIRAM => '• Требует минимум 4ГБ доступной RAM';

  @override
  String get localAIPrivacyNote =>
      'Модель будет обрабатывать ваши скриншоты локально для повышенной приватности.';

  @override
  String get enableLocalAIButton => 'Включить локальный ИИ';

  @override
  String get reminders => 'Напоминания';

  @override
  String get activeReminders => 'Активные';

  @override
  String get pastReminders => 'Прошедшие';

  @override
  String get noActiveReminders =>
      'Нет активных напоминаний.\nУстановите напоминания в деталях скриншота.';

  @override
  String get noPastReminders => 'Нет прошедших напоминаний.';

  @override
  String get editReminder => 'Редактировать напоминание';

  @override
  String get clearReminder => 'Очистить напоминание';

  @override
  String get removePastReminder => 'Удалить';

  @override
  String get pastReminderRemoved => 'Прошедшее напоминание удалено';

  @override
  String get supportTheProject => 'Поддержать проект';

  @override
  String get supportShotsStudio => 'Поддержать Shots Studio';

  @override
  String get supportDescription =>
      'Ваша поддержка помогает сохранить этот проект живым и позволяет нам добавлять потрясающие новые функции';

  @override
  String get availableNow => 'Доступно сейчас';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get everyContributionMatters => 'Каждый вклад важен';

  @override
  String get supportFooterDescription =>
      'Спасибо за рассмотрение возможности поддержки этого проекта. Ваш вклад помогает нам поддерживать и улучшать Shots Studio. Для специальных договоренностей или международных банковских переводов, пожалуйста, свяжитесь с нами через GitHub.';

  @override
  String get contactOnGitHub => 'Связаться на GitHub';

  @override
  String get noSponsorshipOptions =>
      'В настоящее время варианты спонсорства недоступны.';

  @override
  String get close => 'Закрыть';
}

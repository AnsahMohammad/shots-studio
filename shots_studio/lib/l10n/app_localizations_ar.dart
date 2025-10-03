// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'استوديو اللقطات';

  @override
  String get searchScreenshots => 'البحث في لقطات الشاشة';

  @override
  String analyzed(int count, int total) {
    return 'تم تحليل $count/$total';
  }

  @override
  String get developerModeDisabled => 'تم تعطيل الإعدادات المتقدمة';

  @override
  String get collections => 'المجموعات';

  @override
  String get screenshots => 'لقطات الشاشة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get about => 'حول';

  @override
  String get privacy => 'الخصوصية';

  @override
  String get createCollection => 'إنشاء مجموعة';

  @override
  String get editCollection => 'تحرير المجموعة';

  @override
  String get deleteCollection => 'حذف المجموعة';

  @override
  String get collectionName => 'اسم المجموعة';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get confirm => 'تأكيد';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get ok => 'موافق';

  @override
  String get search => 'بحث';

  @override
  String get noResults => 'لم يتم العثور على نتائج';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get share => 'مشاركة';

  @override
  String get copy => 'نسخ';

  @override
  String get paste => 'لصق';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get aiSettings => 'إعدادات الذكاء الاصطناعي';

  @override
  String get apiKey => 'مفتاح API';

  @override
  String get modelName => 'اسم النموذج';

  @override
  String get autoProcessing => 'المعالجة التلقائية';

  @override
  String get enabled => 'مفعل';

  @override
  String get disabled => 'معطل';

  @override
  String get theme => 'السمة';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'داكن';

  @override
  String get systemTheme => 'النظام';

  @override
  String get language => 'اللغة';

  @override
  String get analytics => 'التحليلات';

  @override
  String get betaTesting => 'Beta Testing';

  @override
  String get writeTagsToXMP => 'كتابة العلامات في XMP';

  @override
  String get xmpMetadataWritten => 'تم كتابة بيانات XMP الوصفية في الملف';

  @override
  String get advancedSettings => 'الإعدادات المتقدمة';

  @override
  String get developerMode => 'الإعدادات المتقدمة';

  @override
  String get safeDelete => 'حذف آمن';

  @override
  String get sourceCode => 'الكود المصدري';

  @override
  String get support => 'الدعم';

  @override
  String get checkForUpdates => 'البحث عن تحديثات';

  @override
  String get privacyNotice => 'إشعار الخصوصية';

  @override
  String get analyticsAndTelemetry => 'التحليلات والقياس عن بُعد';

  @override
  String get performanceMenu => 'قائمة الأداء';

  @override
  String get serverMessages => 'رسائل الخادم';

  @override
  String get maxParallelAI => 'الحد الأقصى للذكاء الاصطناعي المتوازي';

  @override
  String get enableScreenshotLimit => 'تفعيل حد لقطات الشاشة';

  @override
  String get tags => 'العلامات';

  @override
  String get aiDetails => 'تفاصيل الذكاء الاصطناعي';

  @override
  String get size => 'الحجم';

  @override
  String get addDescription => 'إضافة وصف';

  @override
  String get addTag => 'إضافة علامة';

  @override
  String get amoledMode => 'وضع AMOLED';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get permissions => 'الأذونات';

  @override
  String get storage => 'التخزين';

  @override
  String get camera => 'الكاميرا';

  @override
  String get version => 'الإصدار';

  @override
  String get buildNumber => 'رقم البناء';

  @override
  String get ocrResults => 'نتائج OCR';

  @override
  String get extractedText => 'النص المستخرج';

  @override
  String get noTextFound => 'لم يتم العثور على نص في الصورة';

  @override
  String get processing => 'جاري المعالجة...';

  @override
  String get selectImage => 'اختر صورة';

  @override
  String get takePhoto => 'التقط صورة';

  @override
  String get fromGallery => 'من المعرض';

  @override
  String get imageSelected => 'تم اختيار الصورة';

  @override
  String get noImageSelected => 'لم يتم اختيار صورة';

  @override
  String get apiKeyRequired => 'مطلوب لميزات الذكاء الاصطناعي';

  @override
  String get apiKeyValid => 'مفتاح API صالح';

  @override
  String get apiKeyValidationFailed => 'فشل في التحقق من مفتاح API';

  @override
  String get apiKeyNotValidated => 'تم تعيين مفتاح API (غير محقق)';

  @override
  String get enterApiKey => 'أدخل مفتاح Gemini API';

  @override
  String get validateApiKey => 'التحقق من مفتاح API';

  @override
  String get valid => 'صالح';

  @override
  String get autoProcessingDescription =>
      'سيتم معالجة لقطات الشاشة تلقائياً عند إضافتها';

  @override
  String get manualProcessingOnly => 'معالجة يدوية فقط';

  @override
  String get amoledModeDescription => 'مظهر داكن محسن لشاشات AMOLED';

  @override
  String get defaultDarkTheme => 'المظهر الداكن الافتراضي';

  @override
  String get getApiKey => 'احصل على مفتاح API';

  @override
  String get stopProcessing => 'إيقاف المعالجة';

  @override
  String get processWithAI => 'معالجة بالذكاء الاصطناعي';

  @override
  String get createFirstCollection => 'أنشئ مجموعتك الأولى';

  @override
  String get organizeScreenshots => 'لتنظيم لقطات الشاشة';

  @override
  String get cancelSelection => 'إلغاء التحديد';

  @override
  String get deselectAll => 'إلغاء تحديد الكل';

  @override
  String get deleteSelected => 'حذف المحدد';

  @override
  String get clearCorruptFiles => 'مسح الملفات التالفة';

  @override
  String get clearCorruptFilesConfirm => 'مسح الملفات التالفة؟';

  @override
  String get clearCorruptFilesMessage =>
      'هل أنت متأكد من أنك تريد إزالة جميع الملفات التالفة؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get corruptFilesCleared => 'تم مسح الملفات التالفة';

  @override
  String get noCorruptFiles => 'لم يتم العثور على ملفات تالفة';

  @override
  String get enableLocalAI => '🤖 تفعيل نموذج الذكاء الاصطناعي المحلي';

  @override
  String get localAIBenefits => 'فوائد الذكاء الاصطناعي المحلي:';

  @override
  String get localAIOffline =>
      '• يعمل بشكل كامل دون اتصال بالإنترنت - لا يتطلب إنترنت';

  @override
  String get localAIPrivacy => '• تبقى بياناتك خاصة على جهازك';

  @override
  String get localAINote => 'ملاحظة:';

  @override
  String get localAIBattery => '• يستخدم بطارية أكثر من النماذج السحابية';

  @override
  String get localAIRAM =>
      '• يتطلب على الأقل 4 جيجابايت من ذاكرة الوصول العشوائي المتاحة';

  @override
  String get localAIPrivacyNote =>
      'سيقوم النموذج بمعالجة لقطات الشاشة محلياً لتعزيز الخصوصية.';

  @override
  String get enableLocalAIButton => 'تفعيل الذكاء الاصطناعي المحلي';

  @override
  String get reminders => 'التذكيرات';

  @override
  String get activeReminders => 'نشط';

  @override
  String get pastReminders => 'السابق';

  @override
  String get noActiveReminders =>
      'لا توجد تذكيرات نشطة.\nقم بتعيين التذكيرات من تفاصيل لقطة الشاشة.';

  @override
  String get noPastReminders => 'لا توجد تذكيرات سابقة.';

  @override
  String get editReminder => 'تحرير التذكير';

  @override
  String get clearReminder => 'مسح التذكير';

  @override
  String get removePastReminder => 'إزالة';

  @override
  String get pastReminderRemoved => 'تم إزالة التذكير السابق';

  @override
  String get supportTheProject => 'دعم المشروع';

  @override
  String get supportShotsStudio => 'دعم Shots Studio';

  @override
  String get supportDescription =>
      'دعمكم يساعد في الحفاظ على هذا المشروع حياً ويمكننا من إضافة ميزات جديدة رائعة';

  @override
  String get availableNow => 'متاح الآن';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get everyContributionMatters => 'كل مساهمة مهمة';

  @override
  String get supportFooterDescription =>
      'شكراً لكم على التفكير في دعم هذا المشروع. مساهمتكم تساعدنا في الحفاظ على Shots Studio وتحسينه. للترتيبات الخاصة أو التحويلات المصرفية الدولية، يرجى التواصل عبر GitHub.';

  @override
  String get contactOnGitHub => 'التواصل عبر GitHub';

  @override
  String get noSponsorshipOptions => 'لا توجد خيارات رعاية متاحة حالياً.';

  @override
  String get close => 'إغلاق';
}

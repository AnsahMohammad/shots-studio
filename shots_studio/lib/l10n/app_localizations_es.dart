// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'Buscar Capturas de Pantalla';

  @override
  String analyzed(int count, int total) {
    return 'Analizado $count/$total';
  }

  @override
  String get developerModeDisabled => 'Configuración avanzada deshabilitada';

  @override
  String get collections => 'Colecciones';

  @override
  String get screenshots => 'Capturas de Pantalla';

  @override
  String get settings => 'Configuración';

  @override
  String get about => 'Acerca de';

  @override
  String get privacy => 'Privacidad';

  @override
  String get createCollection => 'Crear Colección';

  @override
  String get editCollection => 'Editar Colección';

  @override
  String get deleteCollection => 'Eliminar Colección';

  @override
  String get collectionName => 'Nombre de la Colección';

  @override
  String get save => 'Guardar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get ok => 'OK';

  @override
  String get search => 'Buscar';

  @override
  String get noResults => 'No se encontraron resultados';

  @override
  String get loading => 'Cargando...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Reintentar';

  @override
  String get share => 'Compartir';

  @override
  String get copy => 'Copiar';

  @override
  String get paste => 'Pegar';

  @override
  String get selectAll => 'Seleccionar Todo';

  @override
  String get aiSettings => 'Configuración de IA';

  @override
  String get apiKey => 'Clave API';

  @override
  String get modelName => 'Nombre del Modelo';

  @override
  String get autoProcessing => 'Procesamiento Automático';

  @override
  String get enabled => 'Habilitado';

  @override
  String get disabled => 'Deshabilitado';

  @override
  String get theme => 'Tema';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get systemTheme => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get analytics => 'Análisis';

  @override
  String get betaTesting => 'Beta Testing';

  @override
  String get writeTagsToXMP => 'Escribir Etiquetas en XMP';

  @override
  String get xmpMetadataWritten => 'Metadatos XMP escritos en el archivo';

  @override
  String get advancedSettings => 'Configuración Avanzada';

  @override
  String get developerMode => 'Configuración Avanzada';

  @override
  String get safeDelete => 'Eliminación Segura';

  @override
  String get sourceCode => 'Código Fuente';

  @override
  String get support => 'Soporte';

  @override
  String get checkForUpdates => 'Buscar Actualizaciones';

  @override
  String get privacyNotice => 'Aviso de Privacidad';

  @override
  String get analyticsAndTelemetry => 'Análisis y Telemetría';

  @override
  String get performanceMenu => 'Menú de Rendimiento';

  @override
  String get serverMessages => 'Mensajes del Servidor';

  @override
  String get maxParallelAI => 'IA Paralela Máxima';

  @override
  String get enableScreenshotLimit => 'Habilitar Límite de Capturas';

  @override
  String get tags => 'Etiquetas';

  @override
  String get aiDetails => 'Detalles de IA';

  @override
  String get size => 'Tamaño';

  @override
  String get awaitingAiProcessing => 'Esperando procesamiento de IA...';

  @override
  String get addTag => 'Agregar etiqueta';

  @override
  String get amoledMode => 'Modo AMOLED';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get permissions => 'Permisos';

  @override
  String get storage => 'Almacenamiento';

  @override
  String get camera => 'Cámara';

  @override
  String get version => 'Versión';

  @override
  String get buildNumber => 'Número de Compilación';

  @override
  String get ocrResults => 'Resultados OCR';

  @override
  String get extractedText => 'Texto Extraído';

  @override
  String get noTextFound => 'No se encontró texto en la imagen';

  @override
  String get processing => 'Procesando...';

  @override
  String get selectImage => 'Seleccionar Imagen';

  @override
  String get takePhoto => 'Tomar Foto';

  @override
  String get fromGallery => 'Desde Galería';

  @override
  String get imageSelected => 'Imagen seleccionada';

  @override
  String get noImageSelected => 'Ninguna imagen seleccionada';

  @override
  String get apiKeyRequired => 'Requerido para funciones de IA';

  @override
  String get apiKeyValid => 'La clave API es válida';

  @override
  String get apiKeyValidationFailed => 'Validación de clave API falló';

  @override
  String get apiKeyNotValidated => 'Clave API configurada (no validada)';

  @override
  String get enterApiKey => 'Ingrese la clave API de Gemini';

  @override
  String get validateApiKey => 'Validar clave API';

  @override
  String get valid => 'Válido';

  @override
  String get autoProcessingDescription =>
      'Las capturas de pantalla se procesarán automáticamente cuando se agreguen';

  @override
  String get manualProcessingOnly => 'Solo procesamiento manual';

  @override
  String get amoledModeDescription =>
      'Tema oscuro optimizado para pantallas AMOLED';

  @override
  String get defaultDarkTheme => 'Tema oscuro predeterminado';

  @override
  String get getApiKey => 'Obtener una clave API';

  @override
  String get stopProcessing => 'Detener procesamiento';

  @override
  String get processWithAI => 'Procesar con IA';

  @override
  String get createFirstCollection => 'Crea tu primera colección para';

  @override
  String get organizeScreenshots => 'organizar tus capturas de pantalla';

  @override
  String get cancelSelection => 'Cancelar selección';

  @override
  String get deselectAll => 'Deseleccionar Todo';

  @override
  String get deleteSelected => 'Eliminar seleccionados';

  @override
  String get clearCorruptFiles => 'Limpiar Archivos Corruptos';

  @override
  String get clearCorruptFilesConfirm => '¿Limpiar Archivos Corruptos?';

  @override
  String get clearCorruptFilesMessage =>
      '¿Estás seguro de que quieres eliminar todos los archivos corruptos de esta colección? Esta acción no se puede deshacer.';

  @override
  String get corruptFilesCleared => 'Archivos corruptos eliminados';

  @override
  String get noCorruptFiles => 'No se encontraron archivos corruptos';

  @override
  String get enableLocalAI => '🤖 Habilitar Modelo de IA Local';

  @override
  String get localAIBenefits => 'Beneficios de la IA Local:';

  @override
  String get localAIOffline =>
      '• Funciona completamente sin conexión - no requiere internet';

  @override
  String get localAIPrivacy =>
      '• Tus datos permanecen privados en tu dispositivo';

  @override
  String get localAINote => 'Nota:';

  @override
  String get localAIBattery => '• Usa más batería que los modelos en la nube';

  @override
  String get localAIRAM => '• Requiere al menos 4GB de RAM disponible';

  @override
  String get localAIPrivacyNote =>
      'El modelo procesará tus capturas de pantalla localmente para mayor privacidad.';

  @override
  String get enableLocalAIButton => 'Habilitar IA Local';

  @override
  String get reminders => 'Recordatorios';

  @override
  String get activeReminders => 'Activos';

  @override
  String get pastReminders => 'Pasados';

  @override
  String get noActiveReminders =>
      'No hay recordatorios activos.\nEstablece recordatorios desde los detalles de la captura.';

  @override
  String get noPastReminders => 'No hay recordatorios pasados.';

  @override
  String get editReminder => 'Editar Recordatorio';

  @override
  String get clearReminder => 'Limpiar Recordatorio';

  @override
  String get removePastReminder => 'Eliminar';

  @override
  String get pastReminderRemoved => 'Recordatorio pasado eliminado';

  @override
  String get supportTheProject => 'Apoyar el proyecto';

  @override
  String get supportShotsStudio => 'Apoyar Shots Studio';

  @override
  String get supportDescription =>
      'Tu apoyo ayuda a mantener vivo este proyecto y nos permite agregar nuevas características increíbles';

  @override
  String get availableNow => 'Disponible ahora';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get everyContributionMatters => 'Cada contribución importa';

  @override
  String get supportFooterDescription =>
      'Gracias por considerar apoyar este proyecto. Tu contribución nos ayuda a mantener y mejorar Shots Studio. Para arreglos especiales o transferencias bancarias internacionales, contáctanos a través de GitHub.';

  @override
  String get contactOnGitHub => 'Contactar en GitHub';

  @override
  String get noSponsorshipOptions =>
      'No hay opciones de patrocinio disponibles actualmente.';

  @override
  String get close => 'Cerrar';

  @override
  String get quickCreateCollection => 'Creación Rápida de Colección';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return '¿Crear una nueva colección \"$collectionName\" con $count captura(s) de pantalla de los resultados de búsqueda?';
  }

  @override
  String get quickCreateWhatHappens => 'Qué sucede:';

  @override
  String get quickCreateExplanation =>
      'Todas las capturas de pantalla de los resultados de búsqueda se agregarán a esta nueva colección. Puedes personalizar el nombre de la colección y la configuración más tarde.';

  @override
  String get dontShowAgain => 'No mostrar esto de nuevo';

  @override
  String get create => 'Crear';

  @override
  String get createCollectionFromSearchResults =>
      'Crear colección desde resultados de búsqueda';

  @override
  String noScreenshotsFoundFor(String query) {
    return 'No se encontraron capturas de pantalla para \"$query\"';
  }

  @override
  String get dataManagement => 'Gestión de Datos';

  @override
  String get dataManagementDescription =>
      'Haga una copia de seguridad y restaure los metadatos de sus capturas, colecciones y configuración.';

  @override
  String get backup => 'Copia de Seguridad';

  @override
  String get restore => 'Restaurar';

  @override
  String get restoreData => 'Restaurar Datos';

  @override
  String get restoreWarning =>
      'Esto reemplazará todos sus datos actuales con la copia de seguridad. Asegúrese de tener una copia de seguridad actual antes de continuar.\n\nLas imágenes que ya no existan en su dispositivo se omitirán.';
}

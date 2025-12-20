// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '截图工作室';

  @override
  String get searchScreenshots => '搜索截图';

  @override
  String analyzed(int count, int total) {
    return '已分析 $count/$total';
  }

  @override
  String get developerModeDisabled => '高级设置已禁用';

  @override
  String get collections => '收藏';

  @override
  String get screenshots => '截图';

  @override
  String get settings => '设置';

  @override
  String get about => '关于';

  @override
  String get privacy => '隐私';

  @override
  String get createCollection => '创建收藏夹';

  @override
  String get editCollection => '编辑收藏夹';

  @override
  String get deleteCollection => '删除收藏夹';

  @override
  String get collectionName => '收藏夹名称';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get confirm => '确认';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get ok => '确定';

  @override
  String get search => '搜索';

  @override
  String get noResults => '未找到结果';

  @override
  String get loading => '加载中...';

  @override
  String get error => '错误';

  @override
  String get retry => '重试';

  @override
  String get share => '分享';

  @override
  String get copy => '复制';

  @override
  String get paste => '粘贴';

  @override
  String get selectAll => '全选';

  @override
  String get aiSettings => 'AI设置';

  @override
  String get apiKey => 'API密钥';

  @override
  String get modelName => '模型名称';

  @override
  String get autoProcessing => '自动处理';

  @override
  String get enabled => '已启用';

  @override
  String get disabled => '已禁用';

  @override
  String get theme => '主题';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get systemTheme => '系统';

  @override
  String get language => '语言';

  @override
  String get analytics => '分析';

  @override
  String get betaTesting => 'Beta Testing';

  @override
  String get writeTagsToXMP => '将标签写入XMP';

  @override
  String get xmpMetadataWritten => 'XMP元数据已写入文件';

  @override
  String get advancedSettings => '高级设置';

  @override
  String get developerMode => '高级设置';

  @override
  String get safeDelete => '安全删除';

  @override
  String get sourceCode => '源代码';

  @override
  String get support => '支持';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get privacyNotice => '隐私声明';

  @override
  String get analyticsAndTelemetry => '分析和遥测';

  @override
  String get performanceMenu => '性能菜单';

  @override
  String get serverMessages => '服务器消息';

  @override
  String get maxParallelAI => '最大并行AI';

  @override
  String get enableScreenshotLimit => '启用截图限制';

  @override
  String get tags => '标签';

  @override
  String get aiDetails => 'AI详情';

  @override
  String get size => '大小';

  @override
  String get addDescription => '添加描述';

  @override
  String get addTag => '添加标签';

  @override
  String get amoledMode => 'AMOLED模式';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '权限';

  @override
  String get storage => '存储';

  @override
  String get camera => '相机';

  @override
  String get version => '版本';

  @override
  String get buildNumber => '构建号';

  @override
  String get ocrResults => 'OCR结果';

  @override
  String get extractedText => '提取的文本';

  @override
  String get noTextFound => '图像中未找到文本';

  @override
  String get processing => '处理中...';

  @override
  String get selectImage => '选择图像';

  @override
  String get takePhoto => '拍照';

  @override
  String get fromGallery => '从图库选择';

  @override
  String get imageSelected => '已选择图像';

  @override
  String get noImageSelected => '未选择图像';

  @override
  String get apiKeyRequired => 'AI功能必需';

  @override
  String get apiKeyValid => 'API密钥有效';

  @override
  String get apiKeyValidationFailed => 'API密钥验证失败';

  @override
  String get apiKeyNotValidated => 'API密钥已设置（未验证）';

  @override
  String get enterApiKey => '输入Gemini API密钥';

  @override
  String get validateApiKey => '验证API密钥';

  @override
  String get valid => '有效';

  @override
  String get autoProcessingDescription => '添加截图时将自动处理';

  @override
  String get manualProcessingOnly => '仅手动处理';

  @override
  String get amoledModeDescription => '为AMOLED屏幕优化的深色主题';

  @override
  String get defaultDarkTheme => '默认深色主题';

  @override
  String get getApiKey => '获取API密钥';

  @override
  String get stopProcessing => '停止处理';

  @override
  String get processWithAI => '使用AI处理';

  @override
  String get createFirstCollection => '创建您的第一个收藏';

  @override
  String get organizeScreenshots => '来组织您的截图';

  @override
  String get cancelSelection => '取消选择';

  @override
  String get deselectAll => '取消全选';

  @override
  String get deleteSelected => '删除选中项';

  @override
  String get clearCorruptFiles => '清理损坏文件';

  @override
  String get clearCorruptFilesConfirm => '清理损坏文件？';

  @override
  String get clearCorruptFilesMessage => '您确定要删除所有损坏的文件吗？此操作无法撤销。';

  @override
  String get corruptFilesCleared => '损坏文件已清理';

  @override
  String get noCorruptFiles => '未找到损坏文件';

  @override
  String get enableLocalAI => '🤖 启用本地AI模型';

  @override
  String get localAIBenefits => '本地AI的优势：';

  @override
  String get localAIOffline => '• 完全离线工作 - 无需互联网连接';

  @override
  String get localAIPrivacy => '• 您的数据在设备上保持私密';

  @override
  String get localAINote => '注意：';

  @override
  String get localAIBattery => '• 比云端模型消耗更多电池';

  @override
  String get localAIRAM => '• 需要至少4GB可用内存';

  @override
  String get localAIPrivacyNote => '模型将在本地处理您的屏幕截图以增强隐私保护。';

  @override
  String get enableLocalAIButton => '启用本地AI';

  @override
  String get reminders => '提醒';

  @override
  String get activeReminders => '活跃';

  @override
  String get pastReminders => '过去';

  @override
  String get noActiveReminders => '没有活跃提醒。\n请从截图详情设置提醒。';

  @override
  String get noPastReminders => '没有过去的提醒。';

  @override
  String get editReminder => '编辑提醒';

  @override
  String get clearReminder => '清除提醒';

  @override
  String get removePastReminder => '移除';

  @override
  String get pastReminderRemoved => '过去的提醒已移除';

  @override
  String get supportTheProject => '支持项目';

  @override
  String get supportShotsStudio => '支持 Shots Studio';

  @override
  String get supportDescription => '您的支持有助于保持这个项目的活力，并使我们能够添加令人惊叹的新功能';

  @override
  String get availableNow => '现在可用';

  @override
  String get comingSoon => '即将推出';

  @override
  String get everyContributionMatters => '每一份贡献都很重要';

  @override
  String get supportFooterDescription =>
      '感谢您考虑支持这个项目。您的贡献帮助我们维护和改进 Shots Studio。如需特殊安排或国际电汇，请通过 GitHub 联系我们。';

  @override
  String get contactOnGitHub => '在 GitHub 上联系';

  @override
  String get noSponsorshipOptions => '目前没有可用的赞助选项。';

  @override
  String get close => '关闭';

  @override
  String get quickCreateCollection => '快速创建集合';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return '是否要创建名为 \"$collectionName\" 的集合，包含 $count 张截图？';
  }

  @override
  String get quickCreateWhatHappens => '会发生什么？';

  @override
  String get quickCreateExplanation => '我们将立即创建一个包含所有搜索结果的新集合。';

  @override
  String get dontShowAgain => '不再显示';

  @override
  String get create => '创建';

  @override
  String get createCollectionFromSearchResults => '从搜索结果创建集合';

  @override
  String noScreenshotsFoundFor(String query) {
    return '未找到与 \"$query\" 相关的截图';
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

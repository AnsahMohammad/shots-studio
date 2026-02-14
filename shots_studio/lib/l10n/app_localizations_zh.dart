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
  String get awaitingAiProcessing => '等待AI处理...';
  String get awaitingAiProcessing => '等待AI处理...';

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
  String get dataManagement => '数据管理';
  String get dataManagement => '数据管理';

  @override
  String get dataManagementDescription => '备份和恢复您的截图元数据、收藏夹和设置。';
  String get dataManagementDescription => '备份和恢复您的截图元数据、收藏夹和设置。';

  @override
  String get backup => '备份';
  String get backup => '备份';

  @override
  String get restore => '恢复';
  String get restore => '恢复';

  @override
  String get restoreData => '恢复数据';
  String get restoreData => '恢复数据';

  @override
  String get restoreWarning =>
      '这将用备份替换所有当前数据。请确保在继续之前拥有当前备份。\n\n设备上不再存在的图像将被跳过。';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

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
  String get awaitingAiProcessing => '等待AI处理...';

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
  String get dataManagement => '数据管理';

  @override
  String get dataManagementDescription => '备份和恢复您的截图元数据、收藏夹和设置。';

  @override
  String get backup => '备份';

  @override
  String get restore => '恢复';

  @override
  String get restoreData => '恢复数据';

  @override
  String get restoreWarning =>
      '这将用备份替换所有当前数据。请确保在继续之前拥有当前备份。\n\n设备上不再存在的图像将被跳过。';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '截圖工作室';

  @override
  String get searchScreenshots => '搜尋截圖';

  @override
  String analyzed(int count, int total) {
    return '已分析 $count/$total';
  }

  @override
  String get developerModeDisabled => '進階設定已停用';

  @override
  String get collections => '收藏';

  @override
  String get screenshots => '截圖';

  @override
  String get settings => '設定';

  @override
  String get about => '關於';

  @override
  String get privacy => '隱私';

  @override
  String get createCollection => '建立收藏夾';

  @override
  String get editCollection => '編輯收藏夾';

  @override
  String get deleteCollection => '刪除收藏夾';

  @override
  String get collectionName => '收藏夾名稱';

  @override
  String get save => '儲存';

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get confirm => '確認';

  @override
  String get yes => '是';

  @override
  String get no => '否';

  @override
  String get ok => '確定';

  @override
  String get search => '搜尋';

  @override
  String get noResults => '未找到結果';

  @override
  String get loading => '載入中...';

  @override
  String get error => '錯誤';

  @override
  String get retry => '重試';

  @override
  String get share => '分享';

  @override
  String get copy => '複製';

  @override
  String get paste => '貼上';

  @override
  String get selectAll => '全選';

  @override
  String get aiSettings => 'AI 設定';

  @override
  String get apiKey => 'API 金鑰';

  @override
  String get modelName => '模型名稱';

  @override
  String get autoProcessing => '自動處理';

  @override
  String get enabled => '已啟用';

  @override
  String get disabled => '已停用';

  @override
  String get theme => '主題';

  @override
  String get lightTheme => '淺色';

  @override
  String get darkTheme => '深色';

  @override
  String get systemTheme => '系統';

  @override
  String get language => '語言';

  @override
  String get analytics => '分析';

  @override
  String get betaTesting => 'Beta 測試';

  @override
  String get writeTagsToXMP => '將標籤寫入 XMP';

  @override
  String get xmpMetadataWritten => 'XMP 中繼資料已寫入檔案';

  @override
  String get advancedSettings => '進階設定';

  @override
  String get developerMode => '進階設定';

  @override
  String get safeDelete => '安全刪除';

  @override
  String get sourceCode => '原始碼';

  @override
  String get support => '支援';

  @override
  String get checkForUpdates => '檢查更新';

  @override
  String get privacyNotice => '隱私聲明';

  @override
  String get analyticsAndTelemetry => '分析與遙測';

  @override
  String get performanceMenu => '效能選單';

  @override
  String get serverMessages => '伺服器訊息';

  @override
  String get maxParallelAI => '最大平行 AI';

  @override
  String get enableScreenshotLimit => '啟用截圖限制';

  @override
  String get tags => '標籤';

  @override
  String get aiDetails => 'AI 詳情';

  @override
  String get size => '大小';

  @override
  String get awaitingAiProcessing => '等待 AI 處理...';

  @override
  String get addTag => '新增標籤';

  @override
  String get amoledMode => 'AMOLED 模式';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '權限';

  @override
  String get storage => '儲存空間';

  @override
  String get camera => '相機';

  @override
  String get version => '版本';

  @override
  String get buildNumber => '建置號碼';

  @override
  String get ocrResults => 'OCR 結果';

  @override
  String get extractedText => '提取的文字';

  @override
  String get noTextFound => '影像中未找到文字';

  @override
  String get processing => '處理中...';

  @override
  String get selectImage => '選擇影像';

  @override
  String get takePhoto => '拍照';

  @override
  String get fromGallery => '從圖庫選擇';

  @override
  String get imageSelected => '已選擇影像';

  @override
  String get noImageSelected => '未選擇影像';

  @override
  String get apiKeyRequired => 'AI 功能必需';

  @override
  String get apiKeyValid => 'API 金鑰有效';

  @override
  String get apiKeyValidationFailed => 'API 金鑰驗證失敗';

  @override
  String get apiKeyNotValidated => 'API 金鑰已設定（未驗證）';

  @override
  String get enterApiKey => '輸入 Gemini API 金鑰';

  @override
  String get validateApiKey => '驗證 API 金鑰';

  @override
  String get valid => '有效';

  @override
  String get autoProcessingDescription => '新增截圖時將自動處理';

  @override
  String get manualProcessingOnly => '僅手動處理';

  @override
  String get amoledModeDescription => '為 AMOLED 螢幕最佳化的深色主題';

  @override
  String get defaultDarkTheme => '預設深色主題';

  @override
  String get getApiKey => '獲取 API 金鑰';

  @override
  String get stopProcessing => '停止處理';

  @override
  String get processWithAI => '使用 AI 處理';

  @override
  String get createFirstCollection => '建立您的第一個收藏';

  @override
  String get organizeScreenshots => '來組織您的截圖';

  @override
  String get cancelSelection => '取消選擇';

  @override
  String get deselectAll => '取消全選';

  @override
  String get deleteSelected => '刪除選取項目';

  @override
  String get clearCorruptFiles => '清理損壞檔案';

  @override
  String get clearCorruptFilesConfirm => '清理損壞檔案？';

  @override
  String get clearCorruptFilesMessage => '您確定要刪除所有損壞的檔案嗎？此操作無法復原。';

  @override
  String get corruptFilesCleared => '損壞檔案已清理';

  @override
  String get noCorruptFiles => '未找到損壞檔案';

  @override
  String get enableLocalAI => '🤖 啟用本地 AI 模型';

  @override
  String get localAIBenefits => '本地 AI 的優勢：';

  @override
  String get localAIOffline => '• 完全離線工作 - 無需網際網路連線';

  @override
  String get localAIPrivacy => '• 您的資料在裝置上保持私密';

  @override
  String get localAINote => '注意：';

  @override
  String get localAIBattery => '• 比雲端模型消耗更多電力';

  @override
  String get localAIRAM => '• 需要至少 4GB 可用記憶體';

  @override
  String get localAIPrivacyNote => '模型將在本地處理您的螢幕截圖以增強隱私保護。';

  @override
  String get enableLocalAIButton => '啟用本地 AI';

  @override
  String get reminders => '提醒';

  @override
  String get activeReminders => '活躍';

  @override
  String get pastReminders => '過去';

  @override
  String get noActiveReminders => '沒有活躍提醒。\n請從截圖詳情設定提醒。';

  @override
  String get noPastReminders => '沒有過去的提醒。';

  @override
  String get editReminder => '編輯提醒';

  @override
  String get clearReminder => '清除提醒';

  @override
  String get removePastReminder => '移除';

  @override
  String get pastReminderRemoved => '過去的提醒已移除';

  @override
  String get supportTheProject => '支援專案';

  @override
  String get supportShotsStudio => '支援 Shots Studio';

  @override
  String get supportDescription => '您的支援有助於保持這個專案的活力，並使我們能夠新增令人驚嘆的新功能';

  @override
  String get availableNow => '現在可用';

  @override
  String get comingSoon => '即將推出';

  @override
  String get everyContributionMatters => '每一份貢獻都很重要';

  @override
  String get supportFooterDescription =>
      '感謝您考慮支援這個專案。您的貢獻幫助我們維護和改進 Shots Studio。如需特殊安排或國際電匯，請透過 GitHub 聯絡我們。';

  @override
  String get contactOnGitHub => '在 GitHub 上聯絡';

  @override
  String get noSponsorshipOptions => '目前沒有可用的贊助選項。';

  @override
  String get close => '關閉';

  @override
  String get quickCreateCollection => '快速建立集合';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return '是否要建立名為 \"$collectionName\" 的集合，包含 $count 張截圖？';
  }

  @override
  String get quickCreateWhatHappens => '會發生什麼？';

  @override
  String get quickCreateExplanation => '我們將立即建立一個包含所有搜尋結果的新集合。';

  @override
  String get dontShowAgain => '不再顯示';

  @override
  String get create => '建立';

  @override
  String get createCollectionFromSearchResults => '從搜尋結果建立集合';

  @override
  String noScreenshotsFoundFor(String query) {
    return '未找到與 \"$query\" 相關的截圖';
  }

  @override
  String get dataManagement => '資料管理';

  @override
  String get dataManagementDescription => '備份和復原您的截圖中繼資料、收藏夾和設定。';

  @override
  String get backup => '備份';

  @override
  String get restore => '復原';

  @override
  String get restoreData => '復原資料';

  @override
  String get restoreWarning =>
      '這將用備份替換所有目前資料。請確保在繼續之前擁有目前備份。\n\n裝置上不再存在的影像將被跳過。';
}

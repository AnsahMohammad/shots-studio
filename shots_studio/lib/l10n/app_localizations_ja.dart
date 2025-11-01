// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Shots Studio';

  @override
  String get searchScreenshots => 'スクリーンショットを検索';

  @override
  String analyzed(int count, int total) {
    return '分析済み $count/$total';
  }

  @override
  String get developerModeDisabled => '詳細設定が無効です';

  @override
  String get collections => 'コレクション';

  @override
  String get screenshots => 'スクリーンショット';

  @override
  String get settings => '設定';

  @override
  String get about => 'について';

  @override
  String get privacy => 'プライバシー';

  @override
  String get createCollection => 'コレクションを作成';

  @override
  String get editCollection => 'コレクションを編集';

  @override
  String get deleteCollection => 'コレクションを削除';

  @override
  String get collectionName => 'コレクション名';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get confirm => '確認';

  @override
  String get yes => 'はい';

  @override
  String get no => 'いいえ';

  @override
  String get ok => 'OK';

  @override
  String get search => '検索';

  @override
  String get noResults => '結果が見つかりません';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get share => '共有';

  @override
  String get copy => 'コピー';

  @override
  String get paste => '貼り付け';

  @override
  String get selectAll => 'すべて選択';

  @override
  String get aiSettings => 'AI設定';

  @override
  String get apiKey => 'APIキー';

  @override
  String get modelName => 'AIモデル';

  @override
  String get autoProcessing => '自動処理';

  @override
  String get enabled => '有効';

  @override
  String get disabled => '無効';

  @override
  String get theme => 'テーマ';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get systemTheme => 'システム';

  @override
  String get language => '言語';

  @override
  String get analytics => '分析';

  @override
  String get betaTesting => 'ベータテスト';

  @override
  String get writeTagsToXMP => 'タグをXMPに書き込む';

  @override
  String get xmpMetadataWritten => 'XMPメタデータがファイルに書き込まれました';

  @override
  String get advancedSettings => '詳細設定';

  @override
  String get developerMode => '詳細設定';

  @override
  String get safeDelete => '安全削除';

  @override
  String get sourceCode => 'ソースコード';

  @override
  String get support => 'サポート';

  @override
  String get checkForUpdates => 'アップデート確認';

  @override
  String get privacyNotice => 'プライバシー通知';

  @override
  String get analyticsAndTelemetry => '分析とテレメトリ';

  @override
  String get performanceMenu => 'パフォーマンスメニュー';

  @override
  String get serverMessages => 'サーバーメッセージ';

  @override
  String get maxParallelAI => '最大並列AI';

  @override
  String get enableScreenshotLimit => 'スクリーンショット制限を有効';

  @override
  String get tags => 'タグ';

  @override
  String get aiDetails => 'AI詳細';

  @override
  String get size => 'サイズ';

  @override
  String get addDescription => '説明を追加';

  @override
  String get addTag => 'タグを追加';

  @override
  String get amoledMode => 'AMOLEDモード';

  @override
  String get notifications => '通知';

  @override
  String get permissions => '権限';

  @override
  String get storage => 'ストレージ';

  @override
  String get camera => 'カメラ';

  @override
  String get version => 'バージョン';

  @override
  String get buildNumber => 'ビルド番号';

  @override
  String get ocrResults => 'OCR結果';

  @override
  String get extractedText => '抽出されたテキスト';

  @override
  String get noTextFound => '画像にテキストが見つかりません';

  @override
  String get processing => '処理中...';

  @override
  String get selectImage => '画像を選択';

  @override
  String get takePhoto => '写真を撮る';

  @override
  String get fromGallery => 'ギャラリーから';

  @override
  String get imageSelected => '画像が選択されました';

  @override
  String get noImageSelected => '画像が選択されていません';

  @override
  String get apiKeyRequired => 'AI機能に必要';

  @override
  String get apiKeyValid => 'APIキーは有効です';

  @override
  String get apiKeyValidationFailed => 'APIキーの検証に失敗しました';

  @override
  String get apiKeyNotValidated => 'APIキーが設定されています（未検証）';

  @override
  String get enterApiKey => 'Gemini APIキーを入力';

  @override
  String get validateApiKey => 'APIキーを検証';

  @override
  String get valid => '有効';

  @override
  String get autoProcessingDescription => '追加時にスクリーンショットが自動的に処理されます';

  @override
  String get manualProcessingOnly => '手動処理のみ';

  @override
  String get amoledModeDescription => 'AMOLEDスクリーン最適化ダークテーマ';

  @override
  String get defaultDarkTheme => 'デフォルトダークテーマ';

  @override
  String get getApiKey => 'APIキーを取得';

  @override
  String get stopProcessing => '処理を停止';

  @override
  String get processWithAI => 'AIで処理';

  @override
  String get createFirstCollection => '最初のコレクションを作成して';

  @override
  String get organizeScreenshots => 'スクリーンショットを整理';

  @override
  String get cancelSelection => '選択をキャンセル';

  @override
  String get deselectAll => 'すべて選択解除';

  @override
  String get deleteSelected => '選択項目を削除';

  @override
  String get clearCorruptFiles => '破損ファイルをクリア';

  @override
  String get clearCorruptFilesConfirm => '破損ファイルをクリアしますか？';

  @override
  String get clearCorruptFilesMessage =>
      'すべての破損ファイルを削除してもよろしいですか？この操作は取り消すことができません。';

  @override
  String get corruptFilesCleared => '破損ファイルをクリアしました';

  @override
  String get noCorruptFiles => '破損ファイルが見つかりません';

  @override
  String get enableLocalAI => '🤖 ローカルAIモデルを有効にする';

  @override
  String get localAIBenefits => 'ローカルAIの利点：';

  @override
  String get localAIOffline => '• 完全にオフラインで動作 - インターネット接続不要';

  @override
  String get localAIPrivacy => '• データはお使いのデバイス上でプライベートに保持されます';

  @override
  String get localAINote => '注意：';

  @override
  String get localAIBattery => '• クラウドモデルよりもバッテリーを多く消費します';

  @override
  String get localAIRAM => '• 最低4GBの利用可能なRAMが必要です';

  @override
  String get localAIPrivacyNote => 'モデルはプライバシー保護のためにスクリーンショットをローカルで処理します。';

  @override
  String get enableLocalAIButton => 'ローカルAIを有効にする';

  @override
  String get reminders => 'リマインダー';

  @override
  String get activeReminders => 'アクティブ';

  @override
  String get pastReminders => '過去';

  @override
  String get noActiveReminders =>
      'アクティブなリマインダーはありません。\nスクリーンショットの詳細からリマインダーを設定してください。';

  @override
  String get noPastReminders => '過去のリマインダーはありません。';

  @override
  String get editReminder => 'リマインダーを編集';

  @override
  String get clearReminder => 'リマインダーをクリア';

  @override
  String get removePastReminder => '削除';

  @override
  String get pastReminderRemoved => '過去のリマインダーが削除されました';

  @override
  String get supportTheProject => 'プロジェクトを支援';

  @override
  String get supportShotsStudio => 'Shots Studioを支援';

  @override
  String get supportDescription =>
      'あなたの支援により、このプロジェクトを維持し、素晴らしい新機能を追加することができます';

  @override
  String get availableNow => '利用可能';

  @override
  String get comingSoon => '近日公開';

  @override
  String get everyContributionMatters => 'すべての貢献が重要です';

  @override
  String get supportFooterDescription =>
      'このプロジェクトの支援をご検討いただき、ありがとうございます。あなたの貢献により、Shots Studioの維持と改善ができます。特別な取り決めや国際銀行振込については、GitHubからお問い合わせください。';

  @override
  String get contactOnGitHub => 'GitHubで連絡';

  @override
  String get noSponsorshipOptions => '現在、スポンサーシップオプションは利用できません。';

  @override
  String get close => '閉じる';

  @override
  String get quickCreateCollection => 'クイックコレクション作成';

  @override
  String quickCreateCollectionMessage(String collectionName, int count) {
    return '検索結果から$count件のスクリーンショットを含む新しいコレクション\"$collectionName\"を作成しますか？';
  }

  @override
  String get quickCreateWhatHappens => '実行内容：';

  @override
  String get quickCreateExplanation =>
      '検索結果のすべてのスクリーンショットがこの新しいコレクションに追加されます。コレクション名と設定は後でカスタマイズできます。';

  @override
  String get dontShowAgain => '今後表示しない';

  @override
  String get create => '作成';

  @override
  String get createCollectionFromSearchResults => '検索結果からコレクションを作成';

  @override
  String noScreenshotsFoundFor(String query) {
    return '\"$query\"に一致するスクリーンショットが見つかりません';
  }
}

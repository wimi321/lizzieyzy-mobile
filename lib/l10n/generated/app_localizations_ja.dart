// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'LizzieYZY Mobile';

  @override
  String get portraitGuardSemantics =>
      'スマートフォンでは縦向きで使用してください。タブレットは横向きでも使用できます';

  @override
  String get portraitGuardTitle => '縦向きで使用してください';

  @override
  String get portraitGuardBody => '碁盤、数値、操作を縦画面内にすべて表示します';

  @override
  String get kifuTab => '棋譜';

  @override
  String get kifuHomeTooltip => '棋譜一覧';

  @override
  String get scanTab => '盤面読取';

  @override
  String get photoScanTooltip => '碁盤を撮影して読み取る';

  @override
  String get homeSubtitle => 'LIZZIEYZY · 一局ずつ正確に検討';

  @override
  String get importKifuTooltip => '棋譜を読み込む';

  @override
  String get settingsTooltip => '設定';

  @override
  String get back => '戻る';

  @override
  String get recentKifu => '最近の棋譜';

  @override
  String get statusVerified => '検証済み';

  @override
  String get statusNeedsConfirmation => '要確認';

  @override
  String get statusCurrentPosition => '現在の局面';

  @override
  String get blackPlayerFallback => '黒番';

  @override
  String get whitePlayerFallback => '白番';

  @override
  String get completeKifu => '完全な棋譜';

  @override
  String get partialKifu => '部分棋譜';

  @override
  String get photoPosition => '写真の局面';

  @override
  String get justImported => '読み込み直後';

  @override
  String get photoScanSemantics => 'カメラを開いて碁盤を読み取る';

  @override
  String get photoScanTitle => '盤面を撮影';

  @override
  String get photoScanSubtitle => '実物の碁盤 · 手順番号付き棋譜画像';

  @override
  String get emptyKifuLibrary => '棋譜がありません。SGF / GIB を読み込むか、写真から局面を保存してください。';

  @override
  String get importFirstKifu => '最初の棋譜を読み込む';

  @override
  String inboundImported(String fileName) {
    return 'システム共有から $fileName を読み込みました';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return '$fileName を読み込みました · $warnings';
  }

  @override
  String inboundOpen(String fileName) {
    return '読み込んだ棋譜を開く：$fileName';
  }

  @override
  String get sharedKifuFallback => '共有された棋譜';

  @override
  String get inboundInvalidFile => '共有された棋譜が無効のため読み込めません。';

  @override
  String get inboundStorageFailure => '共有された棋譜を保存できません。空き容量を確認してください。';

  @override
  String get inboundPlatformFailure => 'システム共有から棋譜を読み取れません。再試行してください。';

  @override
  String get dismissNotice => '通知を閉じる';

  @override
  String playerPair(String blackPlayer, String whitePlayer) {
    return '$blackPlayer · $whitePlayer';
  }

  @override
  String moveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count手',
    );
    return '$_temp0';
  }

  @override
  String kifuCardDetail(String result, String moves, String playedAt) {
    return '$result · $moves · $playedAt';
  }

  @override
  String kifuCardSemantics(
    String blackPlayer,
    String whitePlayer,
    String result,
    String moves,
    String status,
  ) {
    return '$blackPlayer 対 $whitePlayer、$result、$moves、$status';
  }

  @override
  String get importKifuTitle => '棋譜を読み込む';

  @override
  String get importKifuSubtitle => 'SGF / GIB · 端末内で検証';

  @override
  String get chooseKifuTitle => 'SGF または GIB 棋譜を選択';

  @override
  String get chooseKifuBody =>
      '形式と囲碁ルールを先に検証します。不完全な記録は明示的に格下げし、完全な棋譜として扱いません。';

  @override
  String get chooseKifuFile => '棋譜ファイルを選択';

  @override
  String get validatingKifu => '棋譜を検証中…';

  @override
  String get importFailed => '読み込みに失敗しました';

  @override
  String get chooseAgain => '選び直す';

  @override
  String get saveKifuFailed => '保存できませんでした。空き容量を確認して再試行してください。';

  @override
  String get kifuReadFailed => '棋譜を読み取れませんでした。';

  @override
  String verifiedRecordDetail(String moves) {
    return '$moves · ルール検証済み';
  }

  @override
  String partialRecordDetail(String moves) {
    return '$moves · 手動確認が必要';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return '黒 $blackCount子 · 白 $whiteCount子';
  }

  @override
  String get warning => '警告';

  @override
  String get fileEncoding => 'ファイルエンコーディング';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return '旧形式の GIB エンコーディングを検出：$encoding';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
    );
    return '$_temp0';
  }

  @override
  String get addedToKifu => '棋譜に追加済み';

  @override
  String get addToKifu => '棋譜に追加';

  @override
  String get importAnother => '別の棋譜を読み込む';

  @override
  String get importErrorResourceLimit =>
      '棋譜が安全な処理上限を超えています。より小さいファイルを選択してください。';

  @override
  String get importErrorInvalidEncoding =>
      '棋譜の文字コードが無効または判別不能です。SGF は UTF-8 のみ対応しています。';

  @override
  String get importErrorUnsupportedFormat => '.sgf と .gib の棋譜のみ対応しています。';

  @override
  String get importErrorInvalidRecord => '棋譜形式または着手順が無効です。ファイルを確認してください。';

  @override
  String get importErrorUnknown => '棋譜を読み取れませんでした。ファイルが破損していないか確認してください。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '端末内を優先 · 設定を追跡可能';

  @override
  String get analysisServiceTitle => '解析サービス';

  @override
  String get analysisServiceUnconfigured => '未設定 · 棋譜は送信されません';

  @override
  String analysisServiceConfigured(String model) {
    return '$model · WSS';
  }

  @override
  String get appearanceTitle => '外観';

  @override
  String get languageTitle => '言語';

  @override
  String get privacyOpenSourceTitle => 'プライバシーとオープンソース';

  @override
  String get privacyOpenSourceDetail => 'データ境界 · ライセンス · セキュリティ報告';

  @override
  String get appVersionSemantics =>
      'LizzieYZY Mobile バージョン 0.1.0、オープンソースライセンス MPL 2.0';

  @override
  String get appVersionLabel => 'LizzieYZY Mobile · 0.1.0 · MPL-2.0';

  @override
  String get analysisShortcutConfigured => '解析サービス\n設定済み';

  @override
  String get analysisShortcutUnconfigured => '解析サービス\n未設定';

  @override
  String get privacyShortcut => 'プライバシー\nとOSS';

  @override
  String get appearanceSubtitle => 'システム設定と高コントラストに対応';

  @override
  String get languageSubtitle => 'アプリとシステム部品の表示言語';

  @override
  String get themeSystem => 'システムに従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get localeSystem => 'システムに従う';

  @override
  String get localeSimplifiedChinese => '简体中文';

  @override
  String get localeTraditionalChinese => '繁體中文';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeJapanese => '日本語';

  @override
  String get localeKorean => '한국어';

  @override
  String settingsTileSemantics(String title, String detail) {
    return '$title、$detail';
  }

  @override
  String get analysisServiceSubtitle => 'WSS · 認証情報はシステムの安全領域に保存';

  @override
  String get accessTokenOptional => 'アクセストークン（任意）';

  @override
  String get tokenSecureStorageHelper => 'Keychain / Keystore のみに保存';

  @override
  String get hideToken => 'トークンを隠す';

  @override
  String get showToken => 'トークンを表示';

  @override
  String get hideAccessToken => 'アクセストークンを隠す';

  @override
  String get showAccessToken => 'アクセストークンを表示';

  @override
  String get confirmEverySend => '送信のたびに確認';

  @override
  String get remoteAnalysisSendsFullKifu => 'リモート解析では完全な棋譜を送信します';

  @override
  String get settingsSaveFailedRetry => '保存できませんでした。再試行してください。';

  @override
  String get removeService => 'サービスを削除';

  @override
  String get saveConfiguration => '設定を保存';

  @override
  String get connectionTab => '接続';

  @override
  String get reviewTab => '検討';

  @override
  String get tokenLabel => 'トークン';

  @override
  String get confirmBeforeSend => '送信前に確認';

  @override
  String get settingsSaveFailed => '保存に失敗しました';

  @override
  String get saving => '保存中';

  @override
  String get save => '保存';

  @override
  String get analysisManifestFileType => 'LizzieYZY 解析サービスマニフェスト';

  @override
  String get manifestTooLarge => 'サービスマニフェストは 64 KB 以下にしてください。';

  @override
  String get manifestReadFailed => 'サービスマニフェストを読み取れませんでした。';

  @override
  String get removeAnalysisServiceTitle => '解析サービスを削除しますか？';

  @override
  String get removeAnalysisServiceBody => 'サービスのアドレスとシステム安全領域のアクセストークンが削除されます。';

  @override
  String get keep => '残す';

  @override
  String get remove => '削除';

  @override
  String get manifestNotImported => 'サービスマニフェスト未読込';

  @override
  String get manifestPurpose => 'マニフェストで接続先、モデルハッシュ、勝率視点を固定します';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '$host · $engineVersion';
  }

  @override
  String get notConfigured => '未設定';

  @override
  String get importAction => '読み込む';

  @override
  String get replace => '変更';

  @override
  String get removeAnalysisServiceTooltip => '解析サービスを削除';

  @override
  String get importManifestTooltip => 'サービスマニフェストを読み込む';

  @override
  String get replaceManifestTooltip => 'サービスマニフェストを変更';

  @override
  String get reviewDepth => '解析の深さ';

  @override
  String get analysisQuick => '高速';

  @override
  String get analysisStandard => '標準';

  @override
  String get analysisDeep => '詳細';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '$profile · 1手 $visitsString探索';
  }

  @override
  String get privacySubtitle => 'データの送信先を検証可能に';

  @override
  String get privacyLocalTab => '端末内';

  @override
  String get privacyRemoteTab => 'リモート';

  @override
  String get privacyOpenSourceTab => 'OSS';

  @override
  String get privacyLocalTitle => '初期設定では端末内のみで処理';

  @override
  String get privacyLocalFact1 => 'カメラ権限は盤面読取を開いたときだけ要求します。';

  @override
  String get privacyLocalFact2 => '写真、棋譜、修正結果はアプリの非公開領域に保存します。';

  @override
  String get privacyLocalFact3 => '広告、アカウント、交流機能、行動追跡 SDK はありません。';

  @override
  String get privacyRemoteTitle => 'リモート解析は自分で選択';

  @override
  String get privacyRemoteFact1 => '明示的にリモート検討を開始した場合だけ完全な棋譜を送信します。';

  @override
  String get privacyRemoteFact2 => '自分で読み込み、承認した WSS サービスだけが送信先です。';

  @override
  String get privacyRemoteFact3 => 'アクセストークンは Keychain / Keystore のみに保存します。';

  @override
  String get privacyOpenSourcePanelTitle => 'コードとモデルの境界を公開';

  @override
  String get privacyOpenSourceFact1 => 'アプリのソースコードは MPL-2.0 です。';

  @override
  String get privacyOpenSourceFact2 => 'モデル、データ、フォントにはライセンスと SHA-256 を記録します。';

  @override
  String get privacyOpenSourceFact3 =>
      'セキュリティ問題はリポジトリの SECURITY.md から非公開で報告してください。';

  @override
  String get privacyPreviousFact => '前の項目';

  @override
  String get privacyNextFact => '次の項目';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '$title。$facts';
  }

  @override
  String get licenses => 'ライセンス';

  @override
  String get viewThirdPartyLicenses => 'サードパーティライセンスを表示';

  @override
  String get privacyPromiseSemantics =>
      'プライバシー方針。必須アカウント、広告、コイン、自動アップロードはありません';

  @override
  String get privacyPromise => '必須アカウントなし · 広告なし · コインなし · 自動送信なし';

  @override
  String get closeCamera => 'カメラを閉じる';

  @override
  String get cameraViewfinderSemantics => 'カメラのファインダー。19路盤全体を枠内に収めてください';

  @override
  String get startingCamera => 'カメラを起動中…';

  @override
  String recognizingIntersections(int count) {
    return '$count個の交点を認識中…';
  }

  @override
  String get cameraTemporarilyUnavailable => 'カメラを一時的に使用できません';

  @override
  String get retry => '再試行';

  @override
  String get photoLibrary => '写真';

  @override
  String get capturePhoto => '撮影';

  @override
  String get captureHelp => '撮影のヒント';

  @override
  String get alignmentReady => '碁盤全体を枠内に · そのまま保持';

  @override
  String get alignmentRecognizing => '認識中 · この画面を閉じないでください';

  @override
  String get alignmentFallback => '写真から続行できます';

  @override
  String get alignmentPreparing => 'ファインダーを準備中';

  @override
  String get captureHelpTitle => '碁盤全体を撮影';

  @override
  String get captureHelpBody => '四隅を緑の枠内に収め、できるだけ碁盤の正面から撮影し、碁石の強い反射を避けてください。';

  @override
  String get gotIt => '了解';

  @override
  String get flashAutomatic => 'フラッシュ、自動';

  @override
  String get flashOff => 'フラッシュ、オフ';

  @override
  String get flashOn => 'フラッシュ、オン';

  @override
  String get cameraPermissionDenied =>
      'カメラへのアクセスが拒否されています。システム設定で許可するか、写真を使用してください。';

  @override
  String get cameraRestricted => 'この端末ではカメラが制限されています。写真を使用してください。';

  @override
  String get cameraUnavailable => 'カメラを使用できません。再試行するか写真を使用してください。';

  @override
  String get cameraCaptureFailed => '撮影できませんでした。端末を安定させて再試行してください。';

  @override
  String get photoLibraryPermissionDenied =>
      '写真へのアクセスが拒否されています。システム設定で許可してください。';

  @override
  String get photoLibraryUnavailable => '写真を開けませんでした。しばらくしてから再試行してください。';

  @override
  String get selectedImageUnreadable => '選択した画像を読み取れません。碁盤全体が鮮明な写真を選択してください。';

  @override
  String get recognitionIncompleteBoard =>
      '碁盤全体を認識できませんでした。四隅を枠内に収め、均一な明るさで再試行してください。';

  @override
  String get recognitionFailed => '認識に失敗しました。碁盤全体を鮮明に写して再試行してください。';

  @override
  String get useGuideFallback => 'ガイド枠で再認識';

  @override
  String get guideFallbackDetail => '同じ撮影フレームを使い、碁盤のガイド枠に合わせて再認識します。';

  @override
  String get guideFallbackRecognizing => 'ガイド枠で再認識中…';

  @override
  String get pageNotFound => 'ページが見つかりません';

  @override
  String get returnToKifu => '棋譜に戻る';

  @override
  String get cancelAction => 'キャンセル';

  @override
  String get closeAction => '閉じる';

  @override
  String get openAction => '開く';

  @override
  String get pauseAction => '一時停止';

  @override
  String get resumeAction => '再開';

  @override
  String get shareKifu => '棋譜を書き出す';

  @override
  String get shareOpened => 'システム共有を開きました';

  @override
  String get shareNoTarget => 'この端末に利用可能な共有先がありません';

  @override
  String get shareUnavailable => 'システム共有を開けませんでした。';

  @override
  String get preparing => '準備中';

  @override
  String get blackStoneShort => '黒';

  @override
  String get whiteStoneShort => '白';

  @override
  String get blackStoneLabel => '黒石';

  @override
  String get whiteStoneLabel => '白石';

  @override
  String get semanticSeparator => '、';

  @override
  String get emptyPoint => '空点';

  @override
  String get unclearPoint => '不明';

  @override
  String get passMove => 'パス';

  @override
  String pointsValue(String value) {
    return '$value目';
  }

  @override
  String pointLossValue(String value) {
    return '−$value目';
  }

  @override
  String visitsValue(String value) {
    return '$value探索';
  }

  @override
  String moveOrdinal(int move) {
    return '第$move手';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '有効な判断 $count手';
  }

  @override
  String boardDimension(int size) {
    return '$size路';
  }

  @override
  String coverageInterval(int coverage) {
    return '$coverage%区間';
  }

  @override
  String get winRateLabel => '勝率';

  @override
  String get scoreLeadLabel => '目差';

  @override
  String get blackScoreLeadLabel => '黒の目差';

  @override
  String get visitsLabel => '探索数';

  @override
  String get playedMoveLabel => '実戦';

  @override
  String get principalVariationLabel => '主変化';

  @override
  String get noneLabel => 'なし';

  @override
  String get analysisDefaultTitle => '標準解析';

  @override
  String get analysisContinuesInApp => 'このページを離れてもアプリ内で解析を続けます';

  @override
  String get analysisProgressLabel => '解析の進捗';

  @override
  String get analysisRunning => '解析中';

  @override
  String get analysisPaused => '一時停止中';

  @override
  String get analysisCompleted => '完了';

  @override
  String get analysisFailed => '解析失敗';

  @override
  String candidateSemantics(String label) {
    return '候補 $label';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return '候補 $label、$detail';
  }

  @override
  String get correctBoardTitle => '盤面を修正';

  @override
  String intersectionCoordinate(String coordinate) {
    return '交点 $coordinate';
  }

  @override
  String get confirmed => '確認済み';

  @override
  String pendingConfirmation(int count) {
    return '未確認 $countか所';
  }

  @override
  String get pendingLabel => '要確認';

  @override
  String markStone(String choice) {
    return '$choiceとして指定';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '$choiceの指定';
  }

  @override
  String get goBoardLabel => '囲碁盤';

  @override
  String get moveLeft => '左へ移動';

  @override
  String get moveRight => '右へ移動';

  @override
  String get moveUp => '上へ移動';

  @override
  String get moveDown => '下へ移動';

  @override
  String get noLastMove => '最終手の印なし';

  @override
  String lastMoveAt(String coordinate) {
    return '最終手 $coordinate';
  }

  @override
  String get noCandidatePoints => '候補点なし';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '$size路、黒石$blackCount子、白石$whiteCount子、$lastMove、$candidates。現在の交点 $coordinate';
  }

  @override
  String get boardNavigationHint => 'カスタム方向操作で交点を移動します';

  @override
  String get boardNavigationSelectHint => 'カスタム方向操作で交点を移動し、ダブルタップで選択します';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '$blackPlayer 対 $whitePlayer';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return '黒 $blackPlayer、白 $whitePlayer';
  }

  @override
  String get kifuReviewed => '検討済み';

  @override
  String get kifuAnalyzing => '解析中';

  @override
  String get kifuNotReviewed => '未検討';

  @override
  String get kifuNeedsAction => '対応が必要';

  @override
  String get timelineLabel => '手数';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '$label、全$total手中の第$current手';
  }

  @override
  String get previousMove => '前の手';

  @override
  String get nextMove => '次の手';

  @override
  String sliderMoveSemantics(int current, int total) {
    return '全$total手中の第$current手';
  }

  @override
  String get gamePerformanceEstimate => 'この対局の棋力推定';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '$title、$lowerRankから$upperRank、80%区間、$confidence、$decisions';
  }

  @override
  String get reviewKeyMoves => '重要手';

  @override
  String get reviewVariations => '変化';

  @override
  String get reviewTrend => '推移';

  @override
  String get reviewGame => '対局';

  @override
  String get reviewPanel => '検討パネル';

  @override
  String tabSemantics(String label) {
    return '$labelタブ';
  }

  @override
  String get selectFromPhotos => '写真から選択';

  @override
  String get scoreTrend => '目差の推移';

  @override
  String get noData => 'データなし';

  @override
  String blackLeads(String points) {
    return '黒が$points目リード';
  }

  @override
  String whiteLeads(String points) {
    return '白が$points目リード';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '$label、$direction';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '$label、$direction、現在第$move手';
  }

  @override
  String get partialRecordExpired => '部分棋譜を利用できません';

  @override
  String get partialTrustBoundary => '信頼境界 · 完全な対局ではありません';

  @override
  String partialBoardSemantics(int moves) {
    return '部分棋譜の有効な先頭$moves手。完全な検討は利用できません';
  }

  @override
  String partialUnproven(int move) {
    return '棋譜が第$move手から始まるか、検証できない配置を含むため、重要手と棋力は表示しません。';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return '第$move手が不正です：$reason';
  }

  @override
  String get ruleViolationWrongTurn => '手番が正しくありません';

  @override
  String get ruleViolationOutOfBounds => '盤外への着手です';

  @override
  String get ruleViolationOccupied => '交点にすでに石があります';

  @override
  String get ruleViolationSuicide => 'このルールでは自殺手を認めません';

  @override
  String get ruleViolationKo => 'コウの規則に違反しています';

  @override
  String get exportOriginalRecord => '元の棋譜を書き出す';

  @override
  String get saveCurrentPosition => '現在の局面を保存';

  @override
  String get ruleChinese => '中国ルール';

  @override
  String get ruleJapanese => '日本ルール';

  @override
  String get ruleKorean => '韓国ルール';

  @override
  String get ruleAga => 'AGAルール';

  @override
  String get ruleNewZealand => 'ニュージーランドルール';

  @override
  String get ruleTrompTaylor => 'Tromp-Taylorルール';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '$rules · $result · $moves';
  }

  @override
  String get resultUnknown => '結果不明';

  @override
  String get blackWins => '黒勝ち';

  @override
  String blackWinsBy(String points) {
    return '黒$points目勝ち';
  }

  @override
  String get whiteWins => '白勝ち';

  @override
  String whiteWinsBy(String points) {
    return '白$points目勝ち';
  }

  @override
  String get drawResult => '持碁';

  @override
  String get voidedResult => '無勝負';

  @override
  String get noAnalyzableKifu => '解析できる棋譜がありません';

  @override
  String get selectAnalyzableKifu => '棋譜画面から完全な棋譜または確認済みの局面を選択してください。';

  @override
  String get kifuNeedsConfirmation => '棋譜の確認が必要です';

  @override
  String get completeBeforeAnalysis => '棋譜を補完してルール検証を通してから全局検討を開始してください。';

  @override
  String get savePlayerToMoveFailed => '手番を保存できません。空き容量を確認して再試行してください。';

  @override
  String get cancelAnalysisTitle => '解析をキャンセルしますか？';

  @override
  String get cancelAnalysisBody => '現在のサービス要求は直ちに終了します。後で再開できます。';

  @override
  String get continueAnalysis => '解析を続ける';

  @override
  String get analyzeKifuTitle => '棋譜を解析';

  @override
  String get globalAnalysisRunning => '全局解析中';

  @override
  String get analysisQueuedTitle => 'デスクトップエンジンを待機中';

  @override
  String analysisQueuePosition(int position) {
    return '待ち順 $position · 現在の解析完了後に自動開始';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return '待ち順 #$position';
  }

  @override
  String get statusQueued => '待機中';

  @override
  String get connectingAnalysisService => '解析サービスに接続中';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '$completed / $total 局面';
  }

  @override
  String get reviewGenerated => '検討を作成しました';

  @override
  String get positionAnalysisComplete => '局面解析が完了しました';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '$completed局面 · $model';
  }

  @override
  String get analysisInvalidResult => '解析サービスから無効な結果が返されました。';

  @override
  String get analysisCancelled => '解析をキャンセルしました';

  @override
  String get incompleteResultsDiscarded => '未完了の結果は保存していません';

  @override
  String completedPositions(int count) {
    return '$count局面完了';
  }

  @override
  String get analysisServiceRequired => '解析サービスの設定が必要です';

  @override
  String get addWssServiceRetry => 'WSS KataGoサービスを追加して再試行してください。';

  @override
  String get cancelAnalysisSemantics => '解析をキャンセル。このページを離れてもアプリ内の処理は続きます';

  @override
  String get cancelQueuedAnalysisSemantics => 'この待機中の解析をキャンセル';

  @override
  String get openReview => '検討を開く';

  @override
  String get openKeyMoveReview => '重要手の検討を開く';

  @override
  String get viewCandidates => '候補を見る';

  @override
  String get viewPositionCandidates => '局面候補を見る';

  @override
  String get reanalyze => '再解析';

  @override
  String get sendBeforeConfirm => '送信前の確認';

  @override
  String sendPositionToHost(String host) {
    return '現在の盤面を $host に送信します。元の写真はアップロードしません。';
  }

  @override
  String sendRecordToHost(String host) {
    return '完全な棋譜を $host に送信してKataGo解析を行います。';
  }

  @override
  String get confirmAndStart => '確認して開始';

  @override
  String get viewPrivacyBoundary => 'プライバシー境界を確認';

  @override
  String get katagoUnconfigured => 'KataGoが未設定です';

  @override
  String get katagoConfigDetail =>
      '信頼できるWSS解析サービスのマニフェストを読み込んでください。アクセストークンはシステム安全領域だけに保存します。';

  @override
  String get configureAnalysisService => '解析サービスを設定';

  @override
  String get nextPlayerQuestion => '次はどちらの手番ですか？';

  @override
  String get photoNoTimingPlayerDetail =>
      '写真には着手時刻がありません。候補の勝率視点を確定するため手番を指定してください。';

  @override
  String get creatingAnalysisTask => '解析タスクを作成中';

  @override
  String get validatingConfigKifu => '設定と棋譜を検証中…';

  @override
  String get analysisDataDestinationSubtitle => 'データの送信先を明確に管理';

  @override
  String get analyzingPositionBoard => '解析中の現在局面';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '解析中の$size路盤、$completed局面完了';
  }

  @override
  String get statusNeedsConfiguration => '要設定';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusCancelled => 'キャンセル済み';

  @override
  String get analysisFailureCancel => '解析要求をキャンセルできませんでした。';

  @override
  String get analysisFailureProviderCreation => '解析サービスへの接続を作成できませんでした。';

  @override
  String get analysisFailureInvalidResult => '解析結果が検証に失敗しました。';

  @override
  String get analysisFailureProvider => '解析サービスでエラーが発生しました。';

  @override
  String get analysisFailureStreamEnded => '解析完了前に接続が終了しました。';

  @override
  String get analysisFailureRemote => '解析サービスが要求を完了できませんでした。';

  @override
  String get performanceSubtitle => '一局の棋力評価';

  @override
  String get performancePaneCore => '主要';

  @override
  String get performancePanePhases => '局面別';

  @override
  String get performancePaneSample => '標本';

  @override
  String get confidenceMedium => '信頼度：中';

  @override
  String get confidenceLow => '信頼度：低';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return 'この対局の棋力推定、$weakから$strong、$interval、$confidence、$decisions';
  }

  @override
  String get performanceBoundarySemantics =>
      'この結果は本局の内容だけを示し、長期棋力やサービス上の段級位ではありません';

  @override
  String get performanceBoundaryCompact => '本局のみ。長期棋力ではありません';

  @override
  String get performanceBoundaryFull =>
      'この範囲は本局の内容だけを示し、長期棋力やサービス上の段級位ではありません。';

  @override
  String get averagePointLoss => '平均損失目数';

  @override
  String get pointLossLabel => '損失目数';

  @override
  String get severeMistake => '重大なミス';

  @override
  String get phaseOpening => '序盤';

  @override
  String get phaseMiddleGame => '中盤';

  @override
  String get phaseEndgame => 'ヨセ';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '$phase · $loss · $moves';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '$phase、平均損失$loss、$moves';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '$board · $visits+探索 · $model';
  }

  @override
  String get checkCompleteNineteen => '完全な19路・置き石なしの棋譜';

  @override
  String get checkMinimumDecisions => '有効な判断が40手以上';

  @override
  String get checkStandardDeepAnalysis => '標準または詳細の全局解析';

  @override
  String get checkProductionCalibration => '本番用校正モデル';

  @override
  String get performanceUnavailableTitle => '棋力範囲は表示できません';

  @override
  String get performanceUnavailableBody =>
      '留保データで被覆率を検証済みの本番用校正モデルがありません。デモ用の値を段級位として表示しません。';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return '現在確認できる値：平均損失 $loss · Top 3 $topThree';
  }

  @override
  String get noCompleteReviewReturn => '完全な検討データなし · 戻る';

  @override
  String rankKyu(int value) {
    return '$value級';
  }

  @override
  String rankDan(int value) {
    return '$value段';
  }

  @override
  String get positionAnalysisTitle => '局面解析';

  @override
  String get positionAnalysisSubtitle => '現在局面 · 完全な手順なし';

  @override
  String positionBoardSemantics(String player, int count) {
    return '局面解析盤、$playerの手番、候補$count件';
  }

  @override
  String get staticPositionBoundarySemantics =>
      'この局面には完全な手順がないため、重要手と棋力評価は表示しません';

  @override
  String get staticPositionBoundaryBody => '現在の候補と形勢だけを解析し、重要手、手順軸、棋力は表示しません。';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return '候補$label、$move、$score';
  }

  @override
  String candidatePanelSemantics(
    String label,
    String move,
    String player,
    String winRate,
    String score,
    String visits,
    String pv,
  ) {
    return '候補$label、$move、$player勝率$winRate、黒の目差$score、$visits、主変化$pv';
  }

  @override
  String playerWinRate(String player) {
    return '$player勝率';
  }

  @override
  String get principalVariationNone => '主変化：なし';

  @override
  String principalVariationValue(String value) {
    return '主変化  $value';
  }

  @override
  String get noPlayableCandidate => 'サービスから着手可能な候補が返されませんでした。パスのみの可能性があります。';

  @override
  String get positionDataExpired => '局面データを利用できません';

  @override
  String get positionNotAnalyzed => 'この局面は未解析です';

  @override
  String get realKatagoOnly => '候補、勝率、目差、探索数には実際のKataGo結果だけを表示します。';

  @override
  String get startAnalysis => '解析開始';

  @override
  String get variationComparisonTitle => '変化を比較';

  @override
  String variationComparisonSubtitle(int move) {
    return '第$move手 · 実戦と候補';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return '第$move手の変化比較、候補$candidateを選択中';
  }

  @override
  String get noComparableCandidate => '比較できる候補がありません';

  @override
  String returnToMainLine(int move) {
    return '第$move手の本線に戻る';
  }

  @override
  String variationDetailsSemantics(
    String label,
    String move,
    String winRate,
    String score,
    String visits,
    String pv,
    String played,
    String loss,
  ) {
    return '候補$label、$move、勝率$winRate、黒の目差$score、$visits、主変化$pv、実戦$played、損失$loss';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return '実戦 $move · $loss';
  }

  @override
  String playedMoveValue(String move) {
    return '実戦 $move';
  }

  @override
  String get serviceNoPrincipalVariation => 'サービスから主変化が返されませんでした';

  @override
  String get realCandidateData => '実際の候補データ';

  @override
  String get noVariationReturn => '変化データなし · 戻る';

  @override
  String get bestCandidate => '最善候補';

  @override
  String get candidateVariation => '候補変化';

  @override
  String reviewBoardSemantics(int move, int count) {
    return '第$move手の検討盤、実際の候補$count件を表示';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '第$move手、$leaderが$points目リード、$leaderの勝率$winRate';
  }

  @override
  String positionMetricCompact(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '第$move手 · $leader $points目 · $winRate';
  }

  @override
  String positionMetricFull(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '現在第$move手    $leaderが$points目リード    $leader勝率 $winRate';
  }

  @override
  String get reviewTitle => '検討';

  @override
  String get completeAnalysisResults => '完全な解析結果';

  @override
  String get noCompletedReview => '完了した検討がありません';

  @override
  String get verifiedGlobalAnalysisOnly => '重要手の検討には、完全で検証済みの全局解析が必要です。';

  @override
  String get tabletLandscapeHint => '2列の検討を使うにはタブレットを横向きにしてください';

  @override
  String tabletBoardSemantics(int move, int count) {
    return 'タブレット検討盤、第$move手、候補$count件を表示';
  }

  @override
  String get noReviewDataReturn => '検討データなし · 棋譜に戻る';

  @override
  String get quickReview => '高速検討';

  @override
  String get standardReview => '標準検討';

  @override
  String get deepReview => '詳細検討';

  @override
  String regularMoveTitle(int move) {
    return '第$move手';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return '重要手 #$rank · 第$move手';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '$title、実戦から最善へ$comparison、$detail';
  }

  @override
  String get regularMoveBadge => '通常手';

  @override
  String get lossRankBadge => '損失順位';

  @override
  String get noCandidateData => '候補データなし';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '$winRate · $score · $visits';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return '最善候補$move、$detail';
  }

  @override
  String pvMoveCount(int moves) {
    return 'PV $moves手';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return '第$move手 · 黒の目差 $score · 黒勝率 $winRate';
  }

  @override
  String get globalScoreTrend => '全局の目差推移';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return '平均損失 $loss · Top 3 $topThree · 重大なミス $severe';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return '本局の数値、$detail。棋力範囲には校正済みモデルが必要です';
  }

  @override
  String get gameMetricsTitle => '本局の数値';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '$moves手 · 重要手$keyMoves件';
  }

  @override
  String get performanceNeedsCalibration => '棋力校正が必要';

  @override
  String get boardCorrectionExpired => '盤面修正データを利用できません';

  @override
  String get sequenceCorrectionExpired => '手順修正データを利用できません';

  @override
  String autoRectifiedSubtitle(String board) {
    return '自動補正 · $board';
  }

  @override
  String get viewOriginal => '元画像を表示';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return '実物盤の修正、黒$blackCount子、白$whiteCount子、未確認$pendingか所';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return '黒 $blackCount · 白 $whiteCount';
  }

  @override
  String get confirmCurrentPosition => '現在局面を確定';

  @override
  String confirmRemaining(int count) {
    return '残り$countか所を確認';
  }

  @override
  String get correctSequenceTitle => '手順を修正';

  @override
  String numberedDetectedMoves(int moves) {
    return '番号付き棋譜画像 · $moves手を認識';
  }

  @override
  String get sequenceValidatingSemantics => '番号付き棋譜の修正、完全な手順を検証中';

  @override
  String sequenceIssueSemantics(int move) {
    return '番号付き棋譜の修正、第$move手の確認が必要です。交点を選択してください';
  }

  @override
  String get reuseAfterCapture => '取り上げ後の同一点再使用';

  @override
  String get markPassMove => 'この手をパスにする';

  @override
  String selectMoveOnBoard(int move) {
    return '盤上で第$move手を選択';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return '第$move手を $coordinate に確定';
  }

  @override
  String get saveAsPositionFallback => '手順を復元できないため現在局面として保存';

  @override
  String get sequenceIssueNoFirst => '第1手を認識できませんでした。盤上の位置を選ぶかパスにしてください。';

  @override
  String get sequenceIssueMissing => '番号が欠けています。交点を選ぶと、その点の誤認識番号を置き換えます。';

  @override
  String get sequenceIssueOcr => 'OCRの信頼度が不足しています。位置を確認してください。';

  @override
  String get sequenceIssueColor => '石の色と手数の奇偶が一致しません。位置を確認してください。';

  @override
  String get sequenceIssueFinalMismatch => '復元した終局と認識盤面が一致しません。印の位置を確認してください。';

  @override
  String get sequenceIssueTooMany => '番号手順が安全な処理上限を超えています。';

  @override
  String get sequenceIssueDuplicate => '同じ手数が複数あります。番号を確認してください。';

  @override
  String get sequenceIssueIllegal => '手順が囲碁のルールに違反しています。印の位置を確認してください。';

  @override
  String get sequenceValidationFailed => '手順の検証に失敗しました。印を確認して再試行してください。';

  @override
  String get validatingGoRules => '囲碁ルールで検証中';

  @override
  String moveCannotConfirm(String move) {
    return '第$move手を確認できません';
  }

  @override
  String get checkingSequenceRules => '番号の連続性、取り、コウ、同一点の再使用を確認中です。';

  @override
  String get sequenceVerifiedTitle => '手順を検証しました';

  @override
  String get sequenceVerifiedSubtitle => '番号連続 · 囲碁ルール合格';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return '検証済みの$size路完全棋譜、全$moves手';
  }

  @override
  String get saveAndStartReview => '保存して検討を開始';

  @override
  String rescanWithReason(String reason) {
    return '$reason · 再読取';
  }

  @override
  String get originalImageUnavailable => '元画像を表示できません';

  @override
  String get scanResultTitle => '認識結果';

  @override
  String scanResultSubtitle(String board) {
    return '現在局面 · $board';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return '認識済みの$size路局面、黒$blackCount子、白$whiteCount子';
  }

  @override
  String get boardRecognitionComplete => '盤面認識が完了しました';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return '現在局面を認識しました：黒$blackCount子、白$whiteCount子。';
  }

  @override
  String get photoNoSequence =>
      '1枚の写真には着手時刻がないため完全な手順は復元できません。この局面では重要手の手順軸や棋力評価を表示しません。';

  @override
  String get nextPlayerLabel => '次の手番';

  @override
  String get chooseNextPlayerFirst => '次の手番を選択';

  @override
  String get analyzeCurrentPosition => '現在局面を解析';

  @override
  String get savePosition => '局面を保存';

  @override
  String get savePositionAnalysisFailed => '保存に失敗したため、現在局面の解析は開始していません。';

  @override
  String get scanResultExpired => '認識結果を利用できません';

  @override
  String get scanResultExpiredDetail => '盤面読取に戻り、もう一度撮影するか写真を選択してください。';

  @override
  String get returnToScan => '盤面読取に戻る';
}

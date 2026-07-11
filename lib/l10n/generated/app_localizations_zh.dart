// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'LizzieYZY Mobile';

  @override
  String get portraitGuardSemantics => '手机端请竖屏使用，平板横屏不受限制';

  @override
  String get portraitGuardTitle => '请竖屏使用';

  @override
  String get portraitGuardBody => '棋盘、数值与操作会在竖屏内完整呈现';

  @override
  String get kifuTab => '棋谱';

  @override
  String get kifuHomeTooltip => '棋谱首页';

  @override
  String get scanTab => '识谱';

  @override
  String get photoScanTooltip => '拍照识谱';

  @override
  String get homeSubtitle => 'LIZZIEYZY · 把每一盘复盘清楚';

  @override
  String get importKifuTooltip => '导入棋谱';

  @override
  String get settingsTooltip => '设置';

  @override
  String get back => '返回';

  @override
  String get recentKifu => '最近棋谱';

  @override
  String get statusVerified => '已校验';

  @override
  String get statusNeedsConfirmation => '需确认';

  @override
  String get statusCurrentPosition => '当前局面';

  @override
  String get blackPlayerFallback => '黑方';

  @override
  String get whitePlayerFallback => '白方';

  @override
  String get completeKifu => '完整棋谱';

  @override
  String get partialKifu => '片段棋谱';

  @override
  String get photoPosition => '照片局面';

  @override
  String get justImported => '刚刚导入';

  @override
  String get photoScanSemantics => '拍照识谱，打开相机识别棋盘';

  @override
  String get photoScanTitle => '拍照识谱';

  @override
  String get photoScanSubtitle => '实体棋盘 · 编号棋谱图';

  @override
  String get emptyKifuLibrary => '还没有棋谱。导入 SGF / GIB，或从照片保存当前局面。';

  @override
  String get importFirstKifu => '导入第一份棋谱';

  @override
  String inboundImported(String fileName) {
    return '已从系统分享导入 $fileName';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return '已导入 $fileName · $warnings';
  }

  @override
  String inboundOpen(String fileName) {
    return '打开已导入的棋谱：$fileName';
  }

  @override
  String get sharedKifuFallback => '分享的棋谱';

  @override
  String get inboundInvalidFile => '分享的棋谱无效，无法导入。';

  @override
  String get inboundStorageFailure => '保存分享的棋谱失败，请检查可用空间。';

  @override
  String get inboundPlatformFailure => '无法读取系统分享的棋谱，请重试。';

  @override
  String get dismissNotice => '关闭通知';

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
      zero: '0手',
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
    return '$blackPlayer 对 $whitePlayer，$result，$moves，$status';
  }

  @override
  String get importKifuTitle => '导入棋谱';

  @override
  String get importKifuSubtitle => 'SGF / GIB · 本地校验';

  @override
  String get chooseKifuTitle => '选择 SGF 或 GIB 棋谱';

  @override
  String get chooseKifuBody => '导入后先进行格式与围棋规则校验；有缺口的记录会明确降级，不会伪装成完整棋谱。';

  @override
  String get chooseKifuFile => '选择棋谱文件';

  @override
  String get validatingKifu => '正在校验棋谱…';

  @override
  String get importFailed => '导入失败';

  @override
  String get chooseAgain => '重新选择';

  @override
  String get saveKifuFailed => '保存失败，请检查可用空间后重试。';

  @override
  String get kifuReadFailed => '无法读取棋谱。';

  @override
  String verifiedRecordDetail(String moves) {
    return '$moves · 规则校验通过';
  }

  @override
  String partialRecordDetail(String moves) {
    return '$moves · 需要人工确认';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return '黑$blackCount子 · 白$whiteCount子';
  }

  @override
  String get warning => '警告';

  @override
  String get fileEncoding => '文件编码';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return '检测到旧版 GIB 编码：$encoding';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count项',
      zero: '0项',
    );
    return '$_temp0';
  }

  @override
  String get addedToKifu => '已加入棋谱';

  @override
  String get addToKifu => '加入棋谱';

  @override
  String get importAnother => '导入另一份';

  @override
  String get importErrorResourceLimit => '棋谱超过安全处理上限，请选择更小的文件。';

  @override
  String get importErrorInvalidEncoding => '棋谱文本编码无效或无法明确判断；SGF 仅支持 UTF-8。';

  @override
  String get importErrorUnsupportedFormat => '仅支持 .sgf 与 .gib 棋谱。';

  @override
  String get importErrorInvalidRecord => '棋谱格式或手顺无效，请检查文件。';

  @override
  String get importErrorUnknown => '无法读取该棋谱，请确认文件未损坏。';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '本机优先 · 配置可追溯';

  @override
  String get analysisServiceTitle => '分析服务';

  @override
  String get analysisServiceUnconfigured => '未配置 · 不会发送棋谱';

  @override
  String analysisServiceConfigured(String model) {
    return '$model · WSS';
  }

  @override
  String get appearanceTitle => '外观';

  @override
  String get languageTitle => '语言';

  @override
  String get privacyOpenSourceTitle => '隐私与开源';

  @override
  String get privacyOpenSourceDetail => '数据边界 · 许可证 · 安全报告';

  @override
  String get appVersionSemantics => 'LizzieYZY Mobile 版本 0.1.0，开源许可证 MPL 2.0';

  @override
  String get appVersionLabel => 'LizzieYZY Mobile · 0.1.0 · MPL-2.0';

  @override
  String get analysisShortcutConfigured => '分析服务\n已配置';

  @override
  String get analysisShortcutUnconfigured => '分析服务\n未配置';

  @override
  String get privacyShortcut => '隐私\n与开源';

  @override
  String get appearanceSubtitle => '跟随系统与高对比模式';

  @override
  String get languageSubtitle => '界面与系统控件语言';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get localeSystem => '跟随系统';

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
    return '$title，$detail';
  }

  @override
  String get analysisServiceSubtitle => 'WSS · 凭据存入系统安全区';

  @override
  String get accessTokenOptional => '访问令牌（可选）';

  @override
  String get tokenSecureStorageHelper => '只写入 Keychain / Keystore';

  @override
  String get hideToken => '隐藏令牌';

  @override
  String get showToken => '显示令牌';

  @override
  String get hideAccessToken => '隐藏访问令牌';

  @override
  String get showAccessToken => '显示访问令牌';

  @override
  String get confirmEverySend => '每次发送前确认';

  @override
  String get remoteAnalysisSendsFullKifu => '远端分析会发送完整棋谱';

  @override
  String get settingsSaveFailedRetry => '保存失败，请重试。';

  @override
  String get removeService => '移除服务';

  @override
  String get saveConfiguration => '保存配置';

  @override
  String get connectionTab => '连接';

  @override
  String get reviewTab => '复盘';

  @override
  String get tokenLabel => '令牌';

  @override
  String get confirmBeforeSend => '发送前确认';

  @override
  String get settingsSaveFailed => '保存失败';

  @override
  String get saving => '保存中';

  @override
  String get save => '保存';

  @override
  String get analysisManifestFileType => 'LizzieYZY 分析服务清单';

  @override
  String get manifestTooLarge => '服务清单不能超过 64 KB。';

  @override
  String get manifestReadFailed => '无法读取服务清单。';

  @override
  String get removeAnalysisServiceTitle => '移除分析服务？';

  @override
  String get removeAnalysisServiceBody => '服务地址和系统安全区中的访问令牌都会删除。';

  @override
  String get keep => '保留';

  @override
  String get remove => '移除';

  @override
  String get manifestNotImported => '尚未导入服务清单';

  @override
  String get manifestPurpose => '清单固定服务地址、模型哈希和胜率视角';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '$host · $engineVersion';
  }

  @override
  String get notConfigured => '未配置';

  @override
  String get importAction => '导入';

  @override
  String get replace => '更换';

  @override
  String get removeAnalysisServiceTooltip => '移除分析服务';

  @override
  String get importManifestTooltip => '导入服务清单';

  @override
  String get replaceManifestTooltip => '更换服务清单';

  @override
  String get reviewDepth => '复盘深度';

  @override
  String get analysisQuick => '快速';

  @override
  String get analysisStandard => '标准';

  @override
  String get analysisDeep => '深入';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '$profile · 每手$visitsString次访问';
  }

  @override
  String get privacySubtitle => '数据去向必须可验证';

  @override
  String get privacyLocalTab => '本机';

  @override
  String get privacyRemoteTab => '远端';

  @override
  String get privacyOpenSourceTab => '开源';

  @override
  String get privacyLocalTitle => '默认只在本机处理';

  @override
  String get privacyLocalFact1 => '相机权限只在进入识谱时申请。';

  @override
  String get privacyLocalFact2 => '照片、棋谱和校对结果保存在应用私有目录。';

  @override
  String get privacyLocalFact3 => '没有广告、账号、社交或行为跟踪 SDK。';

  @override
  String get privacyRemoteTitle => '远端分析由您决定';

  @override
  String get privacyRemoteFact1 => '只有主动开始远端复盘才发送完整棋谱。';

  @override
  String get privacyRemoteFact2 => '目标仅为您导入并批准的 WSS 服务。';

  @override
  String get privacyRemoteFact3 => '访问令牌只进入系统 Keychain / Keystore。';

  @override
  String get privacyOpenSourcePanelTitle => '代码与模型边界公开';

  @override
  String get privacyOpenSourceFact1 => '应用代码采用 MPL-2.0。';

  @override
  String get privacyOpenSourceFact2 => '模型、数据和字体必须记录许可与 SHA-256。';

  @override
  String get privacyOpenSourceFact3 => '安全问题通过仓库 SECURITY.md 私密报告。';

  @override
  String get privacyPreviousFact => '上一条';

  @override
  String get privacyNextFact => '下一条';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '$title，$facts';
  }

  @override
  String get licenses => '许可证';

  @override
  String get viewThirdPartyLicenses => '查看第三方许可证';

  @override
  String get privacyPromiseSemantics => '隐私承诺，没有强制账号，没有广告，没有金币，没有自动上传';

  @override
  String get privacyPromise => '无强制账号 · 无广告 · 无金币 · 不自动上传';

  @override
  String get closeCamera => '关闭相机';

  @override
  String get cameraViewfinderSemantics => '相机取景框，十九路棋盘需完整入框';

  @override
  String get startingCamera => '正在启动相机…';

  @override
  String recognizingIntersections(int count) {
    return '正在识别 $count 个交叉点…';
  }

  @override
  String get cameraTemporarilyUnavailable => '相机暂时不可用';

  @override
  String get retry => '重试';

  @override
  String get photoLibrary => '相册';

  @override
  String get capturePhoto => '拍照';

  @override
  String get captureHelp => '拍摄帮助';

  @override
  String get alignmentReady => '完整棋盘入框 · 保持稳定';

  @override
  String get alignmentRecognizing => '识别中 · 请勿离开';

  @override
  String get alignmentFallback => '可改用相册继续';

  @override
  String get alignmentPreparing => '正在准备取景';

  @override
  String get captureHelpTitle => '拍摄完整棋盘';

  @override
  String get captureHelpBody => '让四个角都在绿色框内，镜头尽量正对棋盘，并避开棋子上的强反光。';

  @override
  String get gotIt => '知道了';

  @override
  String get flashAutomatic => '闪光灯，自动';

  @override
  String get flashOff => '闪光灯，关闭';

  @override
  String get flashOn => '闪光灯，开启';

  @override
  String get cameraPermissionDenied => '未获得相机权限，请在系统设置中允许访问，或改用相册。';

  @override
  String get cameraRestricted => '此设备限制了相机访问，请改用相册。';

  @override
  String get cameraUnavailable => '相机暂时不可用，请重试或改用相册。';

  @override
  String get cameraCaptureFailed => '拍摄失败，请保持设备稳定后重试。';

  @override
  String get photoLibraryPermissionDenied => '无法访问相册，请在系统设置中允许照片访问。';

  @override
  String get photoLibraryUnavailable => '无法打开相册，请稍后重试。';

  @override
  String get selectedImageUnreadable => '无法读取所选图片，请换一张完整清晰的棋盘照片。';

  @override
  String get recognitionIncompleteBoard => '未能识别完整棋盘，请确保四角入框、光线均匀后重试。';

  @override
  String get recognitionFailed => '识别失败，请保持棋盘完整清晰后重试。';

  @override
  String get useGuideFallback => '改用导框识别';

  @override
  String get guideFallbackDetail => '使用同一组已拍画面，按棋盘导框重新识别。';

  @override
  String get guideFallbackRecognizing => '正在按导框重新识别…';

  @override
  String get pageNotFound => '页面不存在';

  @override
  String get returnToKifu => '返回棋谱';

  @override
  String get cancelAction => '取消';

  @override
  String get closeAction => '关闭';

  @override
  String get openAction => '打开';

  @override
  String get pauseAction => '暂停';

  @override
  String get resumeAction => '继续';

  @override
  String get shareKifu => '导出棋谱';

  @override
  String get shareOpened => '已打开系统分享';

  @override
  String get shareNoTarget => '当前设备没有可用的分享目标';

  @override
  String get shareUnavailable => '无法打开系统分享。';

  @override
  String get preparing => '准备中';

  @override
  String get blackStoneShort => '黑';

  @override
  String get whiteStoneShort => '白';

  @override
  String get blackStoneLabel => '黑棋';

  @override
  String get whiteStoneLabel => '白棋';

  @override
  String get semanticSeparator => '，';

  @override
  String get emptyPoint => '空';

  @override
  String get unclearPoint => '看不清';

  @override
  String get passMove => '停一手';

  @override
  String pointsValue(String value) {
    return '$value目';
  }

  @override
  String pointLossValue(String value) {
    return '-$value目';
  }

  @override
  String visitsValue(String value) {
    return '$value访问';
  }

  @override
  String moveOrdinal(int move) {
    return '第 $move 手';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '$count个有效决策';
  }

  @override
  String boardDimension(int size) {
    return '$size路';
  }

  @override
  String coverageInterval(int coverage) {
    return '$coverage% 区间';
  }

  @override
  String get winRateLabel => '胜率';

  @override
  String get scoreLeadLabel => '目差';

  @override
  String get blackScoreLeadLabel => '黑方目差';

  @override
  String get visitsLabel => '访问';

  @override
  String get playedMoveLabel => '实战';

  @override
  String get principalVariationLabel => '主变化';

  @override
  String get noneLabel => '无';

  @override
  String get analysisDefaultTitle => '标准分析';

  @override
  String get analysisContinuesInApp => '离开此页后，应用内任务继续运行';

  @override
  String get analysisProgressLabel => '分析进度';

  @override
  String get analysisRunning => '分析中';

  @override
  String get analysisPaused => '已暂停';

  @override
  String get analysisCompleted => '已完成';

  @override
  String get analysisFailed => '分析失败';

  @override
  String candidateSemantics(String label) {
    return '候选 $label';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return '候选 $label，$detail';
  }

  @override
  String get correctBoardTitle => '校对棋盘';

  @override
  String intersectionCoordinate(String coordinate) {
    return '交叉点 $coordinate';
  }

  @override
  String get confirmed => '已确认';

  @override
  String pendingConfirmation(int count) {
    return '待确认 $count';
  }

  @override
  String get pendingLabel => '待确认';

  @override
  String markStone(String choice) {
    return '标记为$choice';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '$choice棋子';
  }

  @override
  String get goBoardLabel => '围棋棋盘';

  @override
  String get moveLeft => '向左移动';

  @override
  String get moveRight => '向右移动';

  @override
  String get moveUp => '向上移动';

  @override
  String get moveDown => '向下移动';

  @override
  String get noLastMove => '没有最后一手标记';

  @override
  String lastMoveAt(String coordinate) {
    return '最后一手 $coordinate';
  }

  @override
  String get noCandidatePoints => '没有候选点';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '$size路，黑棋 $blackCount 子，白棋 $whiteCount 子，$lastMove，$candidates。当前 $coordinate';
  }

  @override
  String get boardNavigationHint => '使用自定义方向操作移动交叉点';

  @override
  String get boardNavigationSelectHint => '使用自定义方向操作移动交叉点，双击选择';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '$blackPlayer 对 $whitePlayer';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return '黑方 $blackPlayer，白方 $whitePlayer';
  }

  @override
  String get kifuReviewed => '已复盘';

  @override
  String get kifuAnalyzing => '分析中';

  @override
  String get kifuNotReviewed => '未复盘';

  @override
  String get kifuNeedsAction => '需要处理';

  @override
  String get timelineLabel => '手数';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '$label，第 $current 手，共 $total 手';
  }

  @override
  String get previousMove => '上一手';

  @override
  String get nextMove => '下一手';

  @override
  String sliderMoveSemantics(int current, int total) {
    return '第 $current 手，共 $total 手';
  }

  @override
  String get gamePerformanceEstimate => '本局发挥估计';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '$title，$lowerRank 到 $upperRank，80% 区间，$confidence，$decisions';
  }

  @override
  String get reviewKeyMoves => '关键手';

  @override
  String get reviewVariations => '变化';

  @override
  String get reviewTrend => '走势';

  @override
  String get reviewGame => '本局';

  @override
  String get reviewPanel => '复盘面板';

  @override
  String tabSemantics(String label) {
    return '$label标签页';
  }

  @override
  String get selectFromPhotos => '从相册选择';

  @override
  String get scoreTrend => '目差走势';

  @override
  String get noData => '暂无数据';

  @override
  String blackLeads(String points) {
    return '黑方领先 $points 目';
  }

  @override
  String whiteLeads(String points) {
    return '白方领先 $points 目';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '$label，$direction';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '$label，$direction，当前第 $move 手';
  }

  @override
  String get partialRecordExpired => '片段棋谱数据已失效';

  @override
  String get partialTrustBoundary => '信任边界 · 不作为完整对局';

  @override
  String partialBoardSemantics(int moves) {
    return '片段棋谱有效前缀局面，共$moves手，不能生成完整复盘';
  }

  @override
  String partialUnproven(int move) {
    return '记录从第$move手开始或包含无法证明的设置；不提供关键手与棋力。';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return '第$move手不合法：$reason';
  }

  @override
  String get ruleViolationWrongTurn => '行棋方顺序错误';

  @override
  String get ruleViolationOutOfBounds => '落子超出棋盘';

  @override
  String get ruleViolationOccupied => '交叉点已有棋子';

  @override
  String get ruleViolationSuicide => '规则不允许自杀棋';

  @override
  String get ruleViolationKo => '局面违反劫争规则';

  @override
  String get exportOriginalRecord => '导出原记录';

  @override
  String get saveCurrentPosition => '保存当前局面';

  @override
  String get ruleChinese => '中国规则';

  @override
  String get ruleJapanese => '日本规则';

  @override
  String get ruleKorean => '韩国规则';

  @override
  String get ruleAga => 'AGA规则';

  @override
  String get ruleNewZealand => '新西兰规则';

  @override
  String get ruleTrompTaylor => 'Tromp-Taylor规则';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '$rules · $result · $moves';
  }

  @override
  String get resultUnknown => '结果未知';

  @override
  String get blackWins => '黑胜';

  @override
  String blackWinsBy(String points) {
    return '黑胜$points目';
  }

  @override
  String get whiteWins => '白胜';

  @override
  String whiteWinsBy(String points) {
    return '白胜$points目';
  }

  @override
  String get drawResult => '和棋';

  @override
  String get voidedResult => '无胜负';

  @override
  String get noAnalyzableKifu => '没有可分析的棋谱';

  @override
  String get selectAnalyzableKifu => '请从棋谱首页选择完整棋谱或已确认的当前局面。';

  @override
  String get kifuNeedsConfirmation => '棋谱仍需确认';

  @override
  String get completeBeforeAnalysis => '补全并通过规则校验后，才能开始全局复盘。';

  @override
  String get savePlayerToMoveFailed => '无法保存行棋方，请检查可用空间后重试。';

  @override
  String get cancelAnalysisTitle => '取消分析？';

  @override
  String get cancelAnalysisBody => '当前服务请求会立即终止；之后可以重新开始。';

  @override
  String get continueAnalysis => '继续分析';

  @override
  String get analyzeKifuTitle => '分析棋谱';

  @override
  String get globalAnalysisRunning => '全局分析中';

  @override
  String get analysisQueuedTitle => '等待桌面引擎';

  @override
  String analysisQueuePosition(int position) {
    return '队列第 $position 位 · 当前分析结束后自动开始';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return '队列 #$position';
  }

  @override
  String get statusQueued => '排队中';

  @override
  String get connectingAnalysisService => '正在连接分析服务';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '$completed / $total 个局面';
  }

  @override
  String get reviewGenerated => '复盘已生成';

  @override
  String get positionAnalysisComplete => '局面分析完成';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '$completed 个局面 · $model';
  }

  @override
  String get analysisInvalidResult => '分析服务返回了无效结果。';

  @override
  String get analysisCancelled => '分析已取消';

  @override
  String get incompleteResultsDiscarded => '未保留不完整结果';

  @override
  String completedPositions(int count) {
    return '已完成 $count 个局面';
  }

  @override
  String get analysisServiceRequired => '需要配置分析服务';

  @override
  String get addWssServiceRetry => '添加 WSS KataGo 服务后重试。';

  @override
  String get cancelAnalysisSemantics => '取消分析。离开此页后，应用内任务继续运行';

  @override
  String get cancelQueuedAnalysisSemantics => '取消这项排队分析';

  @override
  String get openReview => '打开复盘';

  @override
  String get openKeyMoveReview => '打开关键手复盘';

  @override
  String get viewCandidates => '查看候选';

  @override
  String get viewPositionCandidates => '查看局面候选';

  @override
  String get reanalyze => '重新分析';

  @override
  String get sendBeforeConfirm => '发送前确认';

  @override
  String sendPositionToHost(String host) {
    return '将当前盘面发送到 $host；照片原图不会上传。';
  }

  @override
  String sendRecordToHost(String host) {
    return '将完整棋谱发送到 $host 进行 KataGo 分析。';
  }

  @override
  String get confirmAndStart => '确认并开始';

  @override
  String get viewPrivacyBoundary => '查看隐私边界';

  @override
  String get katagoUnconfigured => '尚未配置 KataGo';

  @override
  String get katagoConfigDetail => '导入可信的 WSS 分析服务清单；访问令牌只存入系统安全区。';

  @override
  String get configureAnalysisService => '配置分析服务';

  @override
  String get nextPlayerQuestion => '下一手轮到谁？';

  @override
  String get photoNoTimingPlayerDetail => '照片没有落子时间；必须确认行棋方，候选胜率才有明确含义。';

  @override
  String get creatingAnalysisTask => '正在建立分析任务';

  @override
  String get validatingConfigKifu => '正在验证配置与棋谱…';

  @override
  String get analysisDataDestinationSubtitle => '数据去向清晰可控';

  @override
  String get analyzingPositionBoard => '正在分析的当前局面棋盘';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '正在分析的$size路棋盘，已完成$completed个局面';
  }

  @override
  String get statusNeedsConfiguration => '待配置';

  @override
  String get statusFailed => '失败';

  @override
  String get statusCancelled => '已取消';

  @override
  String get analysisFailureCancel => '无法取消分析请求。';

  @override
  String get analysisFailureProviderCreation => '无法建立分析服务连接。';

  @override
  String get analysisFailureInvalidResult => '分析结果未通过校验。';

  @override
  String get analysisFailureProvider => '分析服务发生错误。';

  @override
  String get analysisFailureStreamEnded => '分析连接在完成前中断。';

  @override
  String get analysisFailureRemote => '分析服务未能完成请求。';

  @override
  String get performanceSubtitle => '单局棋力评估';

  @override
  String get performancePaneCore => '核心';

  @override
  String get performancePanePhases => '阶段';

  @override
  String get performancePaneSample => '样本';

  @override
  String get confidenceMedium => '中等置信度';

  @override
  String get confidenceLow => '低置信度';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return '本局发挥估计，$weak到$strong，$interval，$confidence，$decisions';
  }

  @override
  String get performanceBoundarySemantics => '此结果只表示本局发挥，不是长期棋力或平台段位';

  @override
  String get performanceBoundaryCompact => '仅本局，非长期棋力';

  @override
  String get performanceBoundaryFull => '仅代表这一盘的发挥区间，不是长期棋力或平台段位。';

  @override
  String get averagePointLoss => '平均目损';

  @override
  String get pointLossLabel => '目损';

  @override
  String get severeMistake => '严重失误';

  @override
  String get phaseOpening => '布局';

  @override
  String get phaseMiddleGame => '中盘';

  @override
  String get phaseEndgame => '官子';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '$phase · $loss · $moves';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '$phase，平均目损$loss，$moves';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '$board · $visits+访问 · $model';
  }

  @override
  String get checkCompleteNineteen => '完整19路非让子棋谱';

  @override
  String get checkMinimumDecisions => '至少40个有效决策';

  @override
  String get checkStandardDeepAnalysis => '标准或深度全局分析';

  @override
  String get checkProductionCalibration => '生产校准模型';

  @override
  String get performanceUnavailableTitle => '暂不显示棋力区间';

  @override
  String get performanceUnavailableBody => '没有通过留出集覆盖率验证的生产校准模型；不会用演示参数伪造级段。';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return '当前仍可验证：平均目损 $loss · Top-3 $topThree';
  }

  @override
  String get noCompleteReviewReturn => '没有完整复盘数据 · 返回';

  @override
  String rankKyu(int value) {
    return '$value级';
  }

  @override
  String rankDan(int value) {
    return '$value段';
  }

  @override
  String get positionAnalysisTitle => '局面分析';

  @override
  String get positionAnalysisSubtitle => '当前局面 · 无完整手顺';

  @override
  String positionBoardSemantics(String player, int count) {
    return '当前局面分析棋盘，$player行棋，$count个候选';
  }

  @override
  String get staticPositionBoundarySemantics => '当前局面不包含完整手顺，不提供关键手和棋力评估';

  @override
  String get staticPositionBoundaryBody => '只分析此刻的候选与形势；不显示关键手、时间轴或棋力。';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return '候选$label，$move，$score';
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
    return '候选$label，$move，$player胜率$winRate，黑方目差$score，$visits，主变化$pv';
  }

  @override
  String playerWinRate(String player) {
    return '$player胜率';
  }

  @override
  String get principalVariationNone => '主变化：无';

  @override
  String principalVariationValue(String value) {
    return '主变化  $value';
  }

  @override
  String get noPlayableCandidate => '服务未返回可下候选；可能只剩停一手。';

  @override
  String get positionDataExpired => '局面数据已失效';

  @override
  String get positionNotAnalyzed => '此局面尚未分析';

  @override
  String get realKatagoOnly => '候选、胜率、目差和访问数只显示真实 KataGo 结果。';

  @override
  String get startAnalysis => '开始分析';

  @override
  String get variationComparisonTitle => '变化比较';

  @override
  String variationComparisonSubtitle(int move) {
    return '第$move手 · 实战与候选';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return '第$move手变化比较，当前选择候选$candidate';
  }

  @override
  String get noComparableCandidate => '没有可比较的候选';

  @override
  String returnToMainLine(int move) {
    return '回到主线第$move手';
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
    return '候选$label，$move，胜率$winRate，黑方目差$score，$visits，主变化$pv，实战$played，目损$loss';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return '实战 $move · $loss';
  }

  @override
  String playedMoveValue(String move) {
    return '实战 $move';
  }

  @override
  String get serviceNoPrincipalVariation => '服务未提供主变化';

  @override
  String get realCandidateData => '真实候选数据';

  @override
  String get noVariationReturn => '没有变化数据 · 返回';

  @override
  String get bestCandidate => '最佳候选';

  @override
  String get candidateVariation => '候选变化';

  @override
  String reviewBoardSemantics(int move, int count) {
    return '第$move手复盘棋盘，显示$count个真实候选点';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '第$move手，$leader方领先$points目，$leader方胜率$winRate';
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
    return '当前第$move手    $leader方领先 $points目    $leader胜率 $winRate';
  }

  @override
  String get reviewTitle => '复盘';

  @override
  String get completeAnalysisResults => '完整分析结果';

  @override
  String get noCompletedReview => '没有已完成的复盘';

  @override
  String get verifiedGlobalAnalysisOnly => '只有完整且通过验证的全局分析，才会生成关键手复盘。';

  @override
  String get tabletLandscapeHint => '请横置平板以使用双栏复盘';

  @override
  String tabletBoardSemantics(int move, int count) {
    return '平板复盘棋盘，第$move手，显示$count个候选点';
  }

  @override
  String get noReviewDataReturn => '没有复盘数据 · 返回棋谱';

  @override
  String get quickReview => '快速复盘';

  @override
  String get standardReview => '标准复盘';

  @override
  String get deepReview => '深度复盘';

  @override
  String regularMoveTitle(int move) {
    return '第$move手';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return '关键手 #$rank · 第$move手';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '$title，实战到最佳$comparison，$detail';
  }

  @override
  String get regularMoveBadge => '普通手';

  @override
  String get lossRankBadge => '损失排序';

  @override
  String get noCandidateData => '没有候选数据';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '$winRate · $score · $visits';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return '最佳候选$move，$detail';
  }

  @override
  String pvMoveCount(int moves) {
    return 'PV $moves手';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return '第$move手 · 黑方目差 $score · 黑胜率 $winRate';
  }

  @override
  String get globalScoreTrend => '全局目差走势';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return '平均目损 $loss · Top-3 $topThree · 严重失误 $severe';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return '本局数值，$detail，棋力区间需要已校准模型';
  }

  @override
  String get gameMetricsTitle => '本局数值';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '$moves手 · $keyMoves个关键手';
  }

  @override
  String get performanceNeedsCalibration => '棋力需校准';

  @override
  String get boardCorrectionExpired => '棋盘校对数据已失效';

  @override
  String get sequenceCorrectionExpired => '手顺校对数据已失效';

  @override
  String autoRectifiedSubtitle(String board) {
    return '自动拉正 · $board';
  }

  @override
  String get viewOriginal => '查看原图';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return '实体棋盘识别校对，黑$blackCount子，白$whiteCount子，$pending处待确认';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return '黑 $blackCount · 白 $whiteCount';
  }

  @override
  String get confirmCurrentPosition => '确认当前局面';

  @override
  String confirmRemaining(int count) {
    return '请先确认 $count 处';
  }

  @override
  String get correctSequenceTitle => '校对手顺';

  @override
  String numberedDetectedMoves(int moves) {
    return '编号棋谱图 · 已识别 $moves 手';
  }

  @override
  String get sequenceValidatingSemantics => '编号棋谱校对，正在验证完整手顺';

  @override
  String sequenceIssueSemantics(int move) {
    return '编号棋谱校对，第$move手需要确认，请选择交叉点';
  }

  @override
  String get reuseAfterCapture => '提子后同点复用';

  @override
  String get markPassMove => '此手为停一手';

  @override
  String selectMoveOnBoard(int move) {
    return '在棋盘选择第$move手';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return '确认第$move手在 $coordinate';
  }

  @override
  String get saveAsPositionFallback => '无法恢复手顺，按当前局面保存';

  @override
  String get sequenceIssueNoFirst => '没有识别到第1手，请在棋盘选择位置或标记停一手。';

  @override
  String get sequenceIssueMissing => '编号缺失；选择对应交叉点会替换该点的误识别编号。';

  @override
  String get sequenceIssueOcr => 'OCR置信度不足，请核对位置。';

  @override
  String get sequenceIssueColor => '棋子颜色与手数奇偶不一致，请核对位置。';

  @override
  String get sequenceIssueFinalMismatch => '手顺终局与识别盘面不一致，请核对标记位置。';

  @override
  String get sequenceIssueTooMany => '编号手数超过安全处理上限。';

  @override
  String get sequenceIssueDuplicate => '同一手数出现了多个编号，请核对标记。';

  @override
  String get sequenceIssueIllegal => '手顺违反围棋规则，请核对标记位置。';

  @override
  String get sequenceValidationFailed => '手顺验证失败，请检查标记后重试。';

  @override
  String get validatingGoRules => '正在按围棋规则验证';

  @override
  String moveCannotConfirm(String move) {
    return '第$move手无法确认';
  }

  @override
  String get checkingSequenceRules => '正在检查编号连续性、提子、劫和同点复用。';

  @override
  String get sequenceVerifiedTitle => '手顺验证完成';

  @override
  String get sequenceVerifiedSubtitle => '编号连续 · 围棋规则通过';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return '已验证的$size路完整棋谱，共$moves手';
  }

  @override
  String get saveAndStartReview => '保存并开始复盘';

  @override
  String rescanWithReason(String reason) {
    return '$reason · 重新识谱';
  }

  @override
  String get originalImageUnavailable => '无法显示原图';

  @override
  String get scanResultTitle => '识别结果';

  @override
  String scanResultSubtitle(String board) {
    return '当前局面 · $board';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return '识别完成的$size路围棋局面，黑$blackCount子，白$whiteCount子';
  }

  @override
  String get boardRecognitionComplete => '棋盘识别完成';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return '已识别当前局面：黑$blackCount子，白$whiteCount子。';
  }

  @override
  String get photoNoSequence => '单张照片不包含落子时间，无法恢复完整手顺。此局面不会显示关键手时间轴或棋力评估。';

  @override
  String get nextPlayerLabel => '下一手';

  @override
  String get chooseNextPlayerFirst => '先选下一手';

  @override
  String get analyzeCurrentPosition => '分析当前局面';

  @override
  String get savePosition => '保存局面';

  @override
  String get savePositionAnalysisFailed => '保存失败，当前局面尚未开始分析。';

  @override
  String get scanResultExpired => '识别结果已失效';

  @override
  String get scanResultExpiredDetail => '请返回识谱页重新拍摄或选择照片。';

  @override
  String get returnToScan => '返回识谱';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'LizzieYZY Mobile';

  @override
  String get portraitGuardSemantics => '手機請直向使用，平板橫向不受限制';

  @override
  String get portraitGuardTitle => '請直向使用';

  @override
  String get portraitGuardBody => '棋盤、數值與操作會在直向畫面完整呈現';

  @override
  String get kifuTab => '棋譜';

  @override
  String get kifuHomeTooltip => '棋譜首頁';

  @override
  String get scanTab => '識譜';

  @override
  String get photoScanTooltip => '拍照識譜';

  @override
  String get homeSubtitle => 'LIZZIEYZY · 把每一盤複盤清楚';

  @override
  String get importKifuTooltip => '匯入棋譜';

  @override
  String get settingsTooltip => '設定';

  @override
  String get back => '返回';

  @override
  String get recentKifu => '最近棋譜';

  @override
  String get statusVerified => '已驗證';

  @override
  String get statusNeedsConfirmation => '待確認';

  @override
  String get statusCurrentPosition => '目前局面';

  @override
  String get blackPlayerFallback => '黑方';

  @override
  String get whitePlayerFallback => '白方';

  @override
  String get completeKifu => '完整棋譜';

  @override
  String get partialKifu => '片段棋譜';

  @override
  String get photoPosition => '照片局面';

  @override
  String get justImported => '剛剛匯入';

  @override
  String get photoScanSemantics => '拍照識譜，開啟相機辨識棋盤';

  @override
  String get photoScanTitle => '拍照識譜';

  @override
  String get photoScanSubtitle => '實體棋盤 · 編號棋譜圖';

  @override
  String get emptyKifuLibrary => '還沒有棋譜。請匯入 SGF / GIB，或從照片儲存目前局面。';

  @override
  String get importFirstKifu => '匯入第一份棋譜';

  @override
  String inboundImported(String fileName) {
    return '已從系統分享匯入 $fileName';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return '已匯入 $fileName · $warnings';
  }

  @override
  String inboundOpen(String fileName) {
    return '開啟已匯入的棋譜：$fileName';
  }

  @override
  String get sharedKifuFallback => '分享的棋譜';

  @override
  String get inboundInvalidFile => '分享的棋譜無效，無法匯入。';

  @override
  String get inboundStorageFailure => '儲存分享的棋譜失敗，請檢查可用空間。';

  @override
  String get inboundPlatformFailure => '無法讀取系統分享的棋譜，請重試。';

  @override
  String get dismissNotice => '關閉通知';

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
      zero: '0手',
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
    return '$blackPlayer 對 $whitePlayer，$result，$moves，$status';
  }

  @override
  String get importKifuTitle => '匯入棋譜';

  @override
  String get importKifuSubtitle => 'SGF / GIB · 本機驗證';

  @override
  String get chooseKifuTitle => '選擇 SGF 或 GIB 棋譜';

  @override
  String get chooseKifuBody => '匯入後會先驗證格式與圍棋規則；有缺漏的記錄會明確降級，不會偽裝成完整棋譜。';

  @override
  String get chooseKifuFile => '選擇棋譜檔案';

  @override
  String get validatingKifu => '正在驗證棋譜…';

  @override
  String get importFailed => '匯入失敗';

  @override
  String get chooseAgain => '重新選擇';

  @override
  String get saveKifuFailed => '儲存失敗，請檢查可用空間後再試一次。';

  @override
  String get kifuReadFailed => '無法讀取棋譜。';

  @override
  String verifiedRecordDetail(String moves) {
    return '$moves · 規則驗證通過';
  }

  @override
  String partialRecordDetail(String moves) {
    return '$moves · 需要人工確認';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return '黑$blackCount子 · 白$whiteCount子';
  }

  @override
  String get warning => '警告';

  @override
  String get fileEncoding => '檔案編碼';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return '偵測到舊版 GIB 編碼：$encoding';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count項',
      zero: '0項',
    );
    return '$_temp0';
  }

  @override
  String get addedToKifu => '已加入棋譜';

  @override
  String get addToKifu => '加入棋譜';

  @override
  String get importAnother => '匯入另一份';

  @override
  String get importErrorResourceLimit => '棋譜超過安全處理上限，請選擇較小的檔案。';

  @override
  String get importErrorInvalidEncoding => '棋譜文字編碼無效或無法明確判斷；SGF 僅支援 UTF-8。';

  @override
  String get importErrorUnsupportedFormat => '僅支援 .sgf 與 .gib 棋譜。';

  @override
  String get importErrorInvalidRecord => '棋譜格式或手順無效，請檢查檔案。';

  @override
  String get importErrorUnknown => '無法讀取此棋譜，請確認檔案未損壞。';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '本機優先 · 設定可追溯';

  @override
  String get analysisServiceTitle => '分析服務';

  @override
  String get analysisServiceUnconfigured => '未設定 · 不會傳送棋譜';

  @override
  String analysisServiceConfigured(String model) {
    return '$model · WSS';
  }

  @override
  String get appearanceTitle => '外觀';

  @override
  String get languageTitle => '語言';

  @override
  String get privacyOpenSourceTitle => '隱私與開源';

  @override
  String get privacyOpenSourceDetail => '資料邊界 · 授權條款 · 安全回報';

  @override
  String get appVersionSemantics => 'LizzieYZY Mobile 版本 0.1.0，開源授權 MPL 2.0';

  @override
  String get appVersionLabel => 'LizzieYZY Mobile · 0.1.0 · MPL-2.0';

  @override
  String get analysisShortcutConfigured => '分析服務\n已設定';

  @override
  String get analysisShortcutUnconfigured => '分析服務\n未設定';

  @override
  String get privacyShortcut => '隱私\n與開源';

  @override
  String get appearanceSubtitle => '跟隨系統與高對比模式';

  @override
  String get languageSubtitle => '介面與系統控制項語言';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get localeSystem => '跟隨系統';

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
    return '$title，$detail';
  }

  @override
  String get analysisServiceSubtitle => 'WSS · 憑證存入系統安全區';

  @override
  String get accessTokenOptional => '存取權杖（選填）';

  @override
  String get tokenSecureStorageHelper => '只寫入 Keychain / Keystore';

  @override
  String get hideToken => '隱藏權杖';

  @override
  String get showToken => '顯示權杖';

  @override
  String get hideAccessToken => '隱藏存取權杖';

  @override
  String get showAccessToken => '顯示存取權杖';

  @override
  String get confirmEverySend => '每次傳送前確認';

  @override
  String get remoteAnalysisSendsFullKifu => '遠端分析會傳送完整棋譜';

  @override
  String get settingsSaveFailedRetry => '儲存失敗，請再試一次。';

  @override
  String get removeService => '移除服務';

  @override
  String get saveConfiguration => '儲存設定';

  @override
  String get connectionTab => '連線';

  @override
  String get reviewTab => '複盤';

  @override
  String get tokenLabel => '權杖';

  @override
  String get confirmBeforeSend => '傳送前確認';

  @override
  String get settingsSaveFailed => '儲存失敗';

  @override
  String get saving => '儲存中';

  @override
  String get save => '儲存';

  @override
  String get analysisManifestFileType => 'LizzieYZY 分析服務清單';

  @override
  String get manifestTooLarge => '服務清單不可超過 64 KB。';

  @override
  String get manifestReadFailed => '無法讀取服務清單。';

  @override
  String get removeAnalysisServiceTitle => '移除分析服務？';

  @override
  String get removeAnalysisServiceBody => '服務位址與系統安全區中的存取權杖都會刪除。';

  @override
  String get keep => '保留';

  @override
  String get remove => '移除';

  @override
  String get manifestNotImported => '尚未匯入服務清單';

  @override
  String get manifestPurpose => '清單會固定服務位址、模型雜湊與勝率視角';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '$host · $engineVersion';
  }

  @override
  String get notConfigured => '未設定';

  @override
  String get importAction => '匯入';

  @override
  String get replace => '更換';

  @override
  String get removeAnalysisServiceTooltip => '移除分析服務';

  @override
  String get importManifestTooltip => '匯入服務清單';

  @override
  String get replaceManifestTooltip => '更換服務清單';

  @override
  String get reviewDepth => '複盤深度';

  @override
  String get analysisQuick => '快速';

  @override
  String get analysisStandard => '標準';

  @override
  String get analysisDeep => '深入';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '$profile · 每手$visitsString次訪問';
  }

  @override
  String get privacySubtitle => '資料去向必須可驗證';

  @override
  String get privacyLocalTab => '本機';

  @override
  String get privacyRemoteTab => '遠端';

  @override
  String get privacyOpenSourceTab => '開源';

  @override
  String get privacyLocalTitle => '預設只在本機處理';

  @override
  String get privacyLocalFact1 => '相機權限只在進入識譜時要求。';

  @override
  String get privacyLocalFact2 => '照片、棋譜與校對結果保存在 App 私有目錄。';

  @override
  String get privacyLocalFact3 => '沒有廣告、帳號、社交或行為追蹤 SDK。';

  @override
  String get privacyRemoteTitle => '遠端分析由您決定';

  @override
  String get privacyRemoteFact1 => '只有主動開始遠端複盤才會傳送完整棋譜。';

  @override
  String get privacyRemoteFact2 => '目標僅為您匯入並核准的 WSS 服務。';

  @override
  String get privacyRemoteFact3 => '存取權杖只會進入系統 Keychain / Keystore。';

  @override
  String get privacyOpenSourcePanelTitle => '程式碼與模型邊界公開';

  @override
  String get privacyOpenSourceFact1 => 'App 程式碼採用 MPL-2.0。';

  @override
  String get privacyOpenSourceFact2 => '模型、資料與字型必須記錄授權及 SHA-256。';

  @override
  String get privacyOpenSourceFact3 => '安全問題請依存放庫 SECURITY.md 私密回報。';

  @override
  String get privacyPreviousFact => '上一項';

  @override
  String get privacyNextFact => '下一項';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '$title，$facts';
  }

  @override
  String get licenses => '授權條款';

  @override
  String get viewThirdPartyLicenses => '查看第三方授權條款';

  @override
  String get privacyPromiseSemantics => '隱私承諾，沒有強制帳號，沒有廣告，沒有金幣，不會自動上傳';

  @override
  String get privacyPromise => '無強制帳號 · 無廣告 · 無金幣 · 不自動上傳';

  @override
  String get closeCamera => '關閉相機';

  @override
  String get cameraViewfinderSemantics => '相機取景框，十九路棋盤必須完整入框';

  @override
  String get startingCamera => '正在啟動相機…';

  @override
  String recognizingIntersections(int count) {
    return '正在辨識 $count 個交叉點…';
  }

  @override
  String get cameraTemporarilyUnavailable => '相機暫時無法使用';

  @override
  String get retry => '重試';

  @override
  String get photoLibrary => '相簿';

  @override
  String get capturePhoto => '拍照';

  @override
  String get captureHelp => '拍攝說明';

  @override
  String get alignmentReady => '完整棋盤入框 · 保持穩定';

  @override
  String get alignmentRecognizing => '辨識中 · 請勿離開';

  @override
  String get alignmentFallback => '可改用相簿繼續';

  @override
  String get alignmentPreparing => '正在準備取景';

  @override
  String get captureHelpTitle => '拍攝完整棋盤';

  @override
  String get captureHelpBody => '讓四個角都在綠色框內，鏡頭盡量正對棋盤，並避開棋子上的強烈反光。';

  @override
  String get gotIt => '知道了';

  @override
  String get flashAutomatic => '閃光燈，自動';

  @override
  String get flashOff => '閃光燈，關閉';

  @override
  String get flashOn => '閃光燈，開啟';

  @override
  String get cameraPermissionDenied => '未取得相機權限，請在系統設定允許存取，或改用相簿。';

  @override
  String get cameraRestricted => '此裝置限制相機存取，請改用相簿。';

  @override
  String get cameraUnavailable => '相機暫時無法使用，請重試或改用相簿。';

  @override
  String get cameraCaptureFailed => '拍攝失敗，請保持裝置穩定後重試。';

  @override
  String get photoLibraryPermissionDenied => '無法存取相簿，請在系統設定允許照片存取。';

  @override
  String get photoLibraryUnavailable => '無法開啟相簿，請稍後再試。';

  @override
  String get selectedImageUnreadable => '無法讀取所選圖片，請改用完整清晰的棋盤照片。';

  @override
  String get recognitionIncompleteBoard => '無法辨識完整棋盤，請確認四角入框、光線均勻後重試。';

  @override
  String get recognitionFailed => '辨識失敗，請保持棋盤完整清晰後重試。';

  @override
  String get useGuideFallback => '改用導框辨識';

  @override
  String get guideFallbackDetail => '使用同一組已拍畫面，依棋盤導框重新辨識。';

  @override
  String get guideFallbackRecognizing => '正在依導框重新辨識…';

  @override
  String get pageNotFound => '找不到頁面';

  @override
  String get returnToKifu => '返回棋譜';

  @override
  String get cancelAction => '取消';

  @override
  String get closeAction => '關閉';

  @override
  String get openAction => '開啟';

  @override
  String get pauseAction => '暫停';

  @override
  String get resumeAction => '繼續';

  @override
  String get shareKifu => '匯出棋譜';

  @override
  String get shareOpened => '已開啟系統分享';

  @override
  String get shareNoTarget => '此裝置沒有可用的分享目標';

  @override
  String get shareUnavailable => '無法開啟系統分享。';

  @override
  String get preparing => '準備中';

  @override
  String get blackStoneShort => '黑';

  @override
  String get whiteStoneShort => '白';

  @override
  String get blackStoneLabel => '黑棋';

  @override
  String get whiteStoneLabel => '白棋';

  @override
  String get semanticSeparator => '，';

  @override
  String get emptyPoint => '空';

  @override
  String get unclearPoint => '看不清';

  @override
  String get passMove => '停一手';

  @override
  String pointsValue(String value) {
    return '$value目';
  }

  @override
  String pointLossValue(String value) {
    return '-$value目';
  }

  @override
  String visitsValue(String value) {
    return '$value次訪問';
  }

  @override
  String moveOrdinal(int move) {
    return '第 $move 手';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '$count個有效決策';
  }

  @override
  String boardDimension(int size) {
    return '$size路';
  }

  @override
  String coverageInterval(int coverage) {
    return '$coverage% 區間';
  }

  @override
  String get winRateLabel => '勝率';

  @override
  String get scoreLeadLabel => '目差';

  @override
  String get blackScoreLeadLabel => '黑方目差';

  @override
  String get visitsLabel => '訪問';

  @override
  String get playedMoveLabel => '實戰';

  @override
  String get principalVariationLabel => '主要變化';

  @override
  String get noneLabel => '無';

  @override
  String get analysisDefaultTitle => '標準分析';

  @override
  String get analysisContinuesInApp => '離開此頁後，App 內的分析仍會繼續';

  @override
  String get analysisProgressLabel => '分析進度';

  @override
  String get analysisRunning => '分析中';

  @override
  String get analysisPaused => '已暫停';

  @override
  String get analysisCompleted => '已完成';

  @override
  String get analysisFailed => '分析失敗';

  @override
  String candidateSemantics(String label) {
    return '候選 $label';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return '候選 $label，$detail';
  }

  @override
  String get correctBoardTitle => '校對棋盤';

  @override
  String intersectionCoordinate(String coordinate) {
    return '交叉點 $coordinate';
  }

  @override
  String get confirmed => '已確認';

  @override
  String pendingConfirmation(int count) {
    return '待確認 $count';
  }

  @override
  String get pendingLabel => '待確認';

  @override
  String markStone(String choice) {
    return '標記為$choice';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '$choice棋子';
  }

  @override
  String get goBoardLabel => '圍棋棋盤';

  @override
  String get moveLeft => '向左移動';

  @override
  String get moveRight => '向右移動';

  @override
  String get moveUp => '向上移動';

  @override
  String get moveDown => '向下移動';

  @override
  String get noLastMove => '沒有最後一手標記';

  @override
  String lastMoveAt(String coordinate) {
    return '最後一手 $coordinate';
  }

  @override
  String get noCandidatePoints => '沒有候選點';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '$size路，黑棋 $blackCount 子，白棋 $whiteCount 子，$lastMove，$candidates。目前 $coordinate';
  }

  @override
  String get boardNavigationHint => '使用自訂方向操作移動交叉點';

  @override
  String get boardNavigationSelectHint => '使用自訂方向操作移動交叉點，點兩下選取';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '$blackPlayer 對 $whitePlayer';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return '黑方 $blackPlayer，白方 $whitePlayer';
  }

  @override
  String get kifuReviewed => '已複盤';

  @override
  String get kifuAnalyzing => '分析中';

  @override
  String get kifuNotReviewed => '未複盤';

  @override
  String get kifuNeedsAction => '需要處理';

  @override
  String get timelineLabel => '手數';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '$label，第 $current 手，共 $total 手';
  }

  @override
  String get previousMove => '上一手';

  @override
  String get nextMove => '下一手';

  @override
  String sliderMoveSemantics(int current, int total) {
    return '第 $current 手，共 $total 手';
  }

  @override
  String get gamePerformanceEstimate => '本局發揮估計';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '$title，$lowerRank 到 $upperRank，80% 區間，$confidence，$decisions';
  }

  @override
  String get reviewKeyMoves => '關鍵手';

  @override
  String get reviewVariations => '變化';

  @override
  String get reviewTrend => '走勢';

  @override
  String get reviewGame => '本局';

  @override
  String get reviewPanel => '複盤面板';

  @override
  String tabSemantics(String label) {
    return '$label分頁';
  }

  @override
  String get selectFromPhotos => '從相簿選取';

  @override
  String get scoreTrend => '目差走勢';

  @override
  String get noData => '暫無資料';

  @override
  String blackLeads(String points) {
    return '黑方領先 $points 目';
  }

  @override
  String whiteLeads(String points) {
    return '白方領先 $points 目';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '$label，$direction';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '$label，$direction，目前第 $move 手';
  }

  @override
  String get partialRecordExpired => '片段棋譜資料已失效';

  @override
  String get partialTrustBoundary => '信任邊界 · 不作為完整對局';

  @override
  String partialBoardSemantics(int moves) {
    return '片段棋譜的有效前段，共$moves手，無法產生完整複盤';
  }

  @override
  String partialUnproven(int move) {
    return '記錄從第$move手開始或包含無法證明的設定；不提供關鍵手與棋力。';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return '第$move手不合法：$reason';
  }

  @override
  String get ruleViolationWrongTurn => '行棋方順序錯誤';

  @override
  String get ruleViolationOutOfBounds => '落子超出棋盤';

  @override
  String get ruleViolationOccupied => '交叉點已有棋子';

  @override
  String get ruleViolationSuicide => '規則不允許自殺棋';

  @override
  String get ruleViolationKo => '局面違反劫爭規則';

  @override
  String get exportOriginalRecord => '匯出原始記錄';

  @override
  String get saveCurrentPosition => '儲存目前局面';

  @override
  String get ruleChinese => '中國規則';

  @override
  String get ruleJapanese => '日本規則';

  @override
  String get ruleKorean => '韓國規則';

  @override
  String get ruleAga => 'AGA 規則';

  @override
  String get ruleNewZealand => '紐西蘭規則';

  @override
  String get ruleTrompTaylor => 'Tromp-Taylor 規則';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '$rules · $result · $moves';
  }

  @override
  String get resultUnknown => '結果未知';

  @override
  String get blackWins => '黑勝';

  @override
  String blackWinsBy(String points) {
    return '黑勝$points目';
  }

  @override
  String get whiteWins => '白勝';

  @override
  String whiteWinsBy(String points) {
    return '白勝$points目';
  }

  @override
  String get drawResult => '和棋';

  @override
  String get voidedResult => '無勝負';

  @override
  String get noAnalyzableKifu => '沒有可分析的棋譜';

  @override
  String get selectAnalyzableKifu => '請從棋譜首頁選取完整棋譜或已確認的目前局面。';

  @override
  String get kifuNeedsConfirmation => '棋譜仍需確認';

  @override
  String get completeBeforeAnalysis => '補全並通過規則校驗後，才能開始全局複盤。';

  @override
  String get savePlayerToMoveFailed => '無法儲存行棋方，請檢查可用空間後重試。';

  @override
  String get cancelAnalysisTitle => '取消分析？';

  @override
  String get cancelAnalysisBody => '目前服務要求會立即終止；之後可以重新開始。';

  @override
  String get continueAnalysis => '繼續分析';

  @override
  String get analyzeKifuTitle => '分析棋譜';

  @override
  String get globalAnalysisRunning => '全局分析中';

  @override
  String get analysisQueuedTitle => '等待桌面引擎';

  @override
  String analysisQueuePosition(int position) {
    return '佇列第 $position 位 · 目前分析結束後自動開始';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return '佇列 #$position';
  }

  @override
  String get statusQueued => '排隊中';

  @override
  String get connectingAnalysisService => '正在連接分析服務';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '$completed / $total 個局面';
  }

  @override
  String get reviewGenerated => '複盤已產生';

  @override
  String get positionAnalysisComplete => '局面分析完成';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '$completed 個局面 · $model';
  }

  @override
  String get analysisInvalidResult => '分析服務傳回無效結果。';

  @override
  String get analysisCancelled => '分析已取消';

  @override
  String get incompleteResultsDiscarded => '未保留不完整結果';

  @override
  String completedPositions(int count) {
    return '已完成 $count 個局面';
  }

  @override
  String get analysisServiceRequired => '需要設定分析服務';

  @override
  String get addWssServiceRetry => '新增 WSS KataGo 服務後重試。';

  @override
  String get cancelAnalysisSemantics => '取消分析。離開此頁後，App 內的工作仍會繼續';

  @override
  String get cancelQueuedAnalysisSemantics => '取消這項排隊分析';

  @override
  String get openReview => '開啟複盤';

  @override
  String get openKeyMoveReview => '開啟關鍵手複盤';

  @override
  String get viewCandidates => '查看候選';

  @override
  String get viewPositionCandidates => '查看局面候選';

  @override
  String get reanalyze => '重新分析';

  @override
  String get sendBeforeConfirm => '傳送前確認';

  @override
  String sendPositionToHost(String host) {
    return '將目前盤面傳送到 $host；照片原圖不會上傳。';
  }

  @override
  String sendRecordToHost(String host) {
    return '將完整棋譜傳送到 $host 進行 KataGo 分析。';
  }

  @override
  String get confirmAndStart => '確認並開始';

  @override
  String get viewPrivacyBoundary => '查看隱私邊界';

  @override
  String get katagoUnconfigured => '尚未設定 KataGo';

  @override
  String get katagoConfigDetail => '匯入可信的 WSS 分析服務清單；存取權杖只會存入系統安全區。';

  @override
  String get configureAnalysisService => '設定分析服務';

  @override
  String get nextPlayerQuestion => '下一手輪到誰？';

  @override
  String get photoNoTimingPlayerDetail => '照片沒有落子時間；必須確認行棋方，候選勝率才有明確意義。';

  @override
  String get creatingAnalysisTask => '正在建立分析工作';

  @override
  String get validatingConfigKifu => '正在驗證設定與棋譜…';

  @override
  String get analysisDataDestinationSubtitle => '資料去向清晰可控';

  @override
  String get analyzingPositionBoard => '正在分析的目前局面棋盤';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '正在分析的$size路棋盤，已完成$completed個局面';
  }

  @override
  String get statusNeedsConfiguration => '待設定';

  @override
  String get statusFailed => '失敗';

  @override
  String get statusCancelled => '已取消';

  @override
  String get analysisFailureCancel => '無法取消分析要求。';

  @override
  String get analysisFailureProviderCreation => '無法建立分析服務連線。';

  @override
  String get analysisFailureInvalidResult => '分析結果未通過驗證。';

  @override
  String get analysisFailureProvider => '分析服務發生錯誤。';

  @override
  String get analysisFailureStreamEnded => '分析連線在完成前中斷。';

  @override
  String get analysisFailureRemote => '分析服務無法完成要求。';

  @override
  String get performanceSubtitle => '單局棋力評估';

  @override
  String get performancePaneCore => '核心';

  @override
  String get performancePanePhases => '階段';

  @override
  String get performancePaneSample => '樣本';

  @override
  String get confidenceMedium => '中等信賴度';

  @override
  String get confidenceLow => '低信賴度';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return '本局發揮估計，$weak到$strong，$interval，$confidence，$decisions';
  }

  @override
  String get performanceBoundarySemantics => '此結果只表示本局發揮，不是長期棋力或平台段位';

  @override
  String get performanceBoundaryCompact => '僅本局，非長期棋力';

  @override
  String get performanceBoundaryFull => '僅代表這一盤的發揮區間，不是長期棋力或平台段位。';

  @override
  String get averagePointLoss => '平均目損';

  @override
  String get pointLossLabel => '目損';

  @override
  String get severeMistake => '嚴重失誤';

  @override
  String get phaseOpening => '布局';

  @override
  String get phaseMiddleGame => '中盤';

  @override
  String get phaseEndgame => '官子';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '$phase · $loss · $moves';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '$phase，平均目損$loss，$moves';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '$board · $visits+次訪問 · $model';
  }

  @override
  String get checkCompleteNineteen => '完整19路非讓子棋譜';

  @override
  String get checkMinimumDecisions => '至少40個有效決策';

  @override
  String get checkStandardDeepAnalysis => '標準或深度全局分析';

  @override
  String get checkProductionCalibration => '正式校準模型';

  @override
  String get performanceUnavailableTitle => '暫不顯示棋力區間';

  @override
  String get performanceUnavailableBody => '沒有通過留出集覆蓋率驗證的正式校準模型；不會用示範參數偽造級段。';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return '目前仍可驗證：平均目損 $loss · Top-3 $topThree';
  }

  @override
  String get noCompleteReviewReturn => '沒有完整複盤資料 · 返回';

  @override
  String rankKyu(int value) {
    return '$value級';
  }

  @override
  String rankDan(int value) {
    return '$value段';
  }

  @override
  String get positionAnalysisTitle => '局面分析';

  @override
  String get positionAnalysisSubtitle => '目前局面 · 無完整手順';

  @override
  String positionBoardSemantics(String player, int count) {
    return '局面分析棋盤，$player行棋，$count個候選';
  }

  @override
  String get staticPositionBoundarySemantics => '目前局面不包含完整手順，不提供關鍵手和棋力評估';

  @override
  String get staticPositionBoundaryBody => '只分析此刻的候選與形勢；不顯示關鍵手、時間軸或棋力。';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return '候選$label，$move，$score';
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
    return '候選$label，$move，$player勝率$winRate，黑方目差$score，$visits，主要變化$pv';
  }

  @override
  String playerWinRate(String player) {
    return '$player勝率';
  }

  @override
  String get principalVariationNone => '主要變化：無';

  @override
  String principalVariationValue(String value) {
    return '主要變化  $value';
  }

  @override
  String get noPlayableCandidate => '服務未傳回可下候選；可能只剩停一手。';

  @override
  String get positionDataExpired => '局面資料已失效';

  @override
  String get positionNotAnalyzed => '此局面尚未分析';

  @override
  String get realKatagoOnly => '候選、勝率、目差和訪問數只顯示真實 KataGo 結果。';

  @override
  String get startAnalysis => '開始分析';

  @override
  String get variationComparisonTitle => '變化比較';

  @override
  String variationComparisonSubtitle(int move) {
    return '第$move手 · 實戰與候選';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return '第$move手變化比較，目前選取候選$candidate';
  }

  @override
  String get noComparableCandidate => '沒有可比較的候選';

  @override
  String returnToMainLine(int move) {
    return '回到主線第$move手';
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
    return '候選$label，$move，勝率$winRate，黑方目差$score，$visits，主要變化$pv，實戰$played，目損$loss';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return '實戰 $move · $loss';
  }

  @override
  String playedMoveValue(String move) {
    return '實戰 $move';
  }

  @override
  String get serviceNoPrincipalVariation => '服務未提供主要變化';

  @override
  String get realCandidateData => '真實候選資料';

  @override
  String get noVariationReturn => '沒有變化資料 · 返回';

  @override
  String get bestCandidate => '最佳候選';

  @override
  String get candidateVariation => '候選變化';

  @override
  String reviewBoardSemantics(int move, int count) {
    return '第$move手複盤棋盤，顯示$count個真實候選點';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '第$move手，$leader方領先$points目，$leader方勝率$winRate';
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
    return '目前第$move手    $leader方領先 $points目    $leader勝率 $winRate';
  }

  @override
  String get reviewTitle => '複盤';

  @override
  String get completeAnalysisResults => '完整分析結果';

  @override
  String get noCompletedReview => '沒有已完成的複盤';

  @override
  String get verifiedGlobalAnalysisOnly => '只有完整且通過驗證的全局分析，才會產生關鍵手複盤。';

  @override
  String get tabletLandscapeHint => '請將平板橫置以使用雙欄複盤';

  @override
  String tabletBoardSemantics(int move, int count) {
    return '平板複盤棋盤，第$move手，顯示$count個候選點';
  }

  @override
  String get noReviewDataReturn => '沒有複盤資料 · 返回棋譜';

  @override
  String get quickReview => '快速複盤';

  @override
  String get standardReview => '標準複盤';

  @override
  String get deepReview => '深度複盤';

  @override
  String regularMoveTitle(int move) {
    return '第$move手';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return '關鍵手 #$rank · 第$move手';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '$title，實戰到最佳$comparison，$detail';
  }

  @override
  String get regularMoveBadge => '普通手';

  @override
  String get lossRankBadge => '損失排序';

  @override
  String get noCandidateData => '沒有候選資料';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '$winRate · $score · $visits';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return '最佳候選$move，$detail';
  }

  @override
  String pvMoveCount(int moves) {
    return 'PV $moves手';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return '第$move手 · 黑方目差 $score · 黑勝率 $winRate';
  }

  @override
  String get globalScoreTrend => '全局目差走勢';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return '平均目損 $loss · Top-3 $topThree · 嚴重失誤 $severe';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return '本局數值，$detail，棋力區間需要已校準模型';
  }

  @override
  String get gameMetricsTitle => '本局數值';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '$moves手 · $keyMoves個關鍵手';
  }

  @override
  String get performanceNeedsCalibration => '棋力需校準';

  @override
  String get boardCorrectionExpired => '棋盤校對資料已失效';

  @override
  String get sequenceCorrectionExpired => '手順校對資料已失效';

  @override
  String autoRectifiedSubtitle(String board) {
    return '自動拉正 · $board';
  }

  @override
  String get viewOriginal => '查看原圖';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return '實體棋盤辨識校對，黑$blackCount子，白$whiteCount子，$pending處待確認';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return '黑 $blackCount · 白 $whiteCount';
  }

  @override
  String get confirmCurrentPosition => '確認目前局面';

  @override
  String confirmRemaining(int count) {
    return '請先確認 $count 處';
  }

  @override
  String get correctSequenceTitle => '校對手順';

  @override
  String numberedDetectedMoves(int moves) {
    return '編號棋譜圖 · 已辨識 $moves 手';
  }

  @override
  String get sequenceValidatingSemantics => '編號棋譜校對，正在驗證完整手順';

  @override
  String sequenceIssueSemantics(int move) {
    return '編號棋譜校對，第$move手需要確認，請選取交叉點';
  }

  @override
  String get reuseAfterCapture => '提子後同點重複使用';

  @override
  String get markPassMove => '此手為停一手';

  @override
  String selectMoveOnBoard(int move) {
    return '在棋盤選取第$move手';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return '確認第$move手在 $coordinate';
  }

  @override
  String get saveAsPositionFallback => '無法還原手順，依目前局面儲存';

  @override
  String get sequenceIssueNoFirst => '未辨識到第1手，請在棋盤選取位置或標記停一手。';

  @override
  String get sequenceIssueMissing => '編號缺失；選取對應交叉點會取代該點的誤辨識編號。';

  @override
  String get sequenceIssueOcr => 'OCR 信賴度不足，請核對位置。';

  @override
  String get sequenceIssueColor => '棋子顏色與手數奇偶不一致，請核對位置。';

  @override
  String get sequenceIssueFinalMismatch => '手順終局與辨識盤面不一致，請核對標記位置。';

  @override
  String get sequenceIssueTooMany => '編號手數超過安全處理上限。';

  @override
  String get sequenceIssueDuplicate => '同一手數出現多個編號，請核對標記。';

  @override
  String get sequenceIssueIllegal => '手順違反圍棋規則，請核對標記位置。';

  @override
  String get sequenceValidationFailed => '手順驗證失敗，請檢查標記後重試。';

  @override
  String get validatingGoRules => '正在依圍棋規則驗證';

  @override
  String moveCannotConfirm(String move) {
    return '第$move手無法確認';
  }

  @override
  String get checkingSequenceRules => '正在檢查編號連續性、提子、劫和同點重複使用。';

  @override
  String get sequenceVerifiedTitle => '手順驗證完成';

  @override
  String get sequenceVerifiedSubtitle => '編號連續 · 圍棋規則通過';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return '已驗證的$size路完整棋譜，共$moves手';
  }

  @override
  String get saveAndStartReview => '儲存並開始複盤';

  @override
  String rescanWithReason(String reason) {
    return '$reason · 重新識譜';
  }

  @override
  String get originalImageUnavailable => '無法顯示原圖';

  @override
  String get scanResultTitle => '辨識結果';

  @override
  String scanResultSubtitle(String board) {
    return '目前局面 · $board';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return '辨識完成的$size路圍棋局面，黑$blackCount子，白$whiteCount子';
  }

  @override
  String get boardRecognitionComplete => '棋盤辨識完成';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return '已辨識目前局面：黑$blackCount子，白$whiteCount子。';
  }

  @override
  String get photoNoSequence => '單張照片不包含落子時間，無法還原完整手順。此局面不會顯示關鍵手時間軸或棋力評估。';

  @override
  String get nextPlayerLabel => '下一手';

  @override
  String get chooseNextPlayerFirst => '先選下一手';

  @override
  String get analyzeCurrentPosition => '分析目前局面';

  @override
  String get savePosition => '儲存局面';

  @override
  String get savePositionAnalysisFailed => '儲存失敗，目前局面尚未開始分析。';

  @override
  String get scanResultExpired => '辨識結果已失效';

  @override
  String get scanResultExpiredDetail => '請返回識譜頁重新拍攝或選取照片。';

  @override
  String get returnToScan => '返回識譜';
}

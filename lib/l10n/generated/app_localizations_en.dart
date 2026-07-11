// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LizzieYZY Mobile';

  @override
  String get portraitGuardSemantics =>
      'Use portrait orientation on phones. Landscape remains available on tablets.';

  @override
  String get portraitGuardTitle => 'Turn your phone upright';

  @override
  String get portraitGuardBody =>
      'The board, metrics, and controls fit completely in portrait.';

  @override
  String get kifuTab => 'Games';

  @override
  String get kifuHomeTooltip => 'Game records';

  @override
  String get scanTab => 'Scan';

  @override
  String get photoScanTooltip => 'Scan a Go board';

  @override
  String get homeSubtitle => 'LIZZIEYZY · Review every game precisely';

  @override
  String get importKifuTooltip => 'Import game record';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get back => 'Back';

  @override
  String get recentKifu => 'Recent games';

  @override
  String get statusVerified => 'Verified';

  @override
  String get statusNeedsConfirmation => 'Needs review';

  @override
  String get statusCurrentPosition => 'Current position';

  @override
  String get blackPlayerFallback => 'Black';

  @override
  String get whitePlayerFallback => 'White';

  @override
  String get completeKifu => 'Complete game';

  @override
  String get partialKifu => 'Partial record';

  @override
  String get photoPosition => 'Photo position';

  @override
  String get justImported => 'Just imported';

  @override
  String get photoScanSemantics => 'Scan a Go board with the camera';

  @override
  String get photoScanTitle => 'Scan board';

  @override
  String get photoScanSubtitle => 'Physical board · Numbered diagram';

  @override
  String get emptyKifuLibrary =>
      'No games yet. Import an SGF or GIB file, or save a position from a photo.';

  @override
  String get importFirstKifu => 'Import your first game';

  @override
  String inboundImported(String fileName) {
    return 'Imported $fileName from system sharing';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return 'Imported $fileName · $warnings';
  }

  @override
  String inboundOpen(String fileName) {
    return 'Open imported game: $fileName';
  }

  @override
  String get sharedKifuFallback => 'Shared game record';

  @override
  String get inboundInvalidFile =>
      'The shared game record is invalid and could not be imported.';

  @override
  String get inboundStorageFailure =>
      'The shared game could not be saved. Check available storage.';

  @override
  String get inboundPlatformFailure =>
      'The game record could not be read from system sharing. Try again.';

  @override
  String get dismissNotice => 'Dismiss notification';

  @override
  String playerPair(String blackPlayer, String whitePlayer) {
    return '$blackPlayer · $whitePlayer';
  }

  @override
  String moveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
      zero: '0 moves',
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
    return '$blackPlayer versus $whitePlayer, $result, $moves, $status';
  }

  @override
  String get importKifuTitle => 'Import game';

  @override
  String get importKifuSubtitle => 'SGF / GIB · Local validation';

  @override
  String get chooseKifuTitle => 'Choose an SGF or GIB file';

  @override
  String get chooseKifuBody =>
      'The format and Go rules are validated first. Incomplete records are clearly downgraded and never presented as complete games.';

  @override
  String get chooseKifuFile => 'Choose game file';

  @override
  String get validatingKifu => 'Validating game…';

  @override
  String get importFailed => 'Import failed';

  @override
  String get chooseAgain => 'Choose again';

  @override
  String get saveKifuFailed =>
      'Could not save. Check available storage and try again.';

  @override
  String get kifuReadFailed => 'Could not read the game record.';

  @override
  String verifiedRecordDetail(String moves) {
    return '$moves · Rules validated';
  }

  @override
  String partialRecordDetail(String moves) {
    return '$moves · Manual confirmation required';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return 'Black $blackCount · White $whiteCount';
  }

  @override
  String get warning => 'Warnings';

  @override
  String get fileEncoding => 'File encoding';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return 'Legacy GIB encoding detected: $encoding';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'None',
    );
    return '$_temp0';
  }

  @override
  String get addedToKifu => 'Added to games';

  @override
  String get addToKifu => 'Add to games';

  @override
  String get importAnother => 'Import another';

  @override
  String get importErrorResourceLimit =>
      'This record exceeds the safe processing limit. Choose a smaller file.';

  @override
  String get importErrorInvalidEncoding =>
      'The text encoding is invalid or ambiguous. SGF supports UTF-8 only.';

  @override
  String get importErrorUnsupportedFormat =>
      'Only .sgf and .gib game records are supported.';

  @override
  String get importErrorInvalidRecord =>
      'The record format or move sequence is invalid. Check the file.';

  @override
  String get importErrorUnknown =>
      'Could not read this game record. Make sure the file is not damaged.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle => 'Local first · Auditable configuration';

  @override
  String get analysisServiceTitle => 'Analysis service';

  @override
  String get analysisServiceUnconfigured =>
      'Not configured · No games are sent';

  @override
  String analysisServiceConfigured(String model) {
    return '$model · WSS';
  }

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get languageTitle => 'Language';

  @override
  String get privacyOpenSourceTitle => 'Privacy & open source';

  @override
  String get privacyOpenSourceDetail =>
      'Data boundaries · Licenses · Security reports';

  @override
  String get appVersionSemantics =>
      'LizzieYZY Mobile version 0.1.0, open-source license MPL 2.0';

  @override
  String get appVersionLabel => 'LizzieYZY Mobile · 0.1.0 · MPL-2.0';

  @override
  String get analysisShortcutConfigured => 'Analysis\nConfigured';

  @override
  String get analysisShortcutUnconfigured => 'Analysis\nNot configured';

  @override
  String get privacyShortcut => 'Privacy &\nopen source';

  @override
  String get appearanceSubtitle => 'System theme and high contrast';

  @override
  String get languageSubtitle => 'App and system-control language';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get localeSystem => 'Follow system';

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
    return '$title, $detail';
  }

  @override
  String get analysisServiceSubtitle =>
      'WSS · Credentials in secure system storage';

  @override
  String get accessTokenOptional => 'Access token (optional)';

  @override
  String get tokenSecureStorageHelper => 'Stored only in Keychain / Keystore';

  @override
  String get hideToken => 'Hide token';

  @override
  String get showToken => 'Show token';

  @override
  String get hideAccessToken => 'Hide access token';

  @override
  String get showAccessToken => 'Show access token';

  @override
  String get confirmEverySend => 'Confirm before every upload';

  @override
  String get remoteAnalysisSendsFullKifu =>
      'Remote analysis sends the complete game record';

  @override
  String get settingsSaveFailedRetry => 'Could not save. Try again.';

  @override
  String get removeService => 'Remove service';

  @override
  String get saveConfiguration => 'Save configuration';

  @override
  String get connectionTab => 'Connection';

  @override
  String get reviewTab => 'Review';

  @override
  String get tokenLabel => 'Token';

  @override
  String get confirmBeforeSend => 'Confirm before sending';

  @override
  String get settingsSaveFailed => 'Save failed';

  @override
  String get saving => 'Saving';

  @override
  String get save => 'Save';

  @override
  String get analysisManifestFileType => 'LizzieYZY analysis service manifest';

  @override
  String get manifestTooLarge => 'The service manifest must not exceed 64 KB.';

  @override
  String get manifestReadFailed => 'Could not read the service manifest.';

  @override
  String get removeAnalysisServiceTitle => 'Remove analysis service?';

  @override
  String get removeAnalysisServiceBody =>
      'The service address and access token in secure system storage will be deleted.';

  @override
  String get keep => 'Keep';

  @override
  String get remove => 'Remove';

  @override
  String get manifestNotImported => 'No service manifest imported';

  @override
  String get manifestPurpose =>
      'The manifest pins the endpoint, model hash, and win-rate perspective';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '$host · $engineVersion';
  }

  @override
  String get notConfigured => 'Not configured';

  @override
  String get importAction => 'Import';

  @override
  String get replace => 'Replace';

  @override
  String get removeAnalysisServiceTooltip => 'Remove analysis service';

  @override
  String get importManifestTooltip => 'Import service manifest';

  @override
  String get replaceManifestTooltip => 'Replace service manifest';

  @override
  String get reviewDepth => 'Review depth';

  @override
  String get analysisQuick => 'Quick';

  @override
  String get analysisStandard => 'Standard';

  @override
  String get analysisDeep => 'Deep';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '$profile · $visitsString visits/move';
  }

  @override
  String get privacySubtitle => 'Every data destination must be verifiable';

  @override
  String get privacyLocalTab => 'On device';

  @override
  String get privacyRemoteTab => 'Remote';

  @override
  String get privacyOpenSourceTab => 'Open source';

  @override
  String get privacyLocalTitle => 'On-device by default';

  @override
  String get privacyLocalFact1 =>
      'Camera permission is requested only when you open board scanning.';

  @override
  String get privacyLocalFact2 =>
      'Photos, records, and corrections stay in the app\'s private directory.';

  @override
  String get privacyLocalFact3 =>
      'No ads, accounts, social features, or behavioral tracking SDKs.';

  @override
  String get privacyRemoteTitle => 'You control remote analysis';

  @override
  String get privacyRemoteFact1 =>
      'A complete record is sent only when you explicitly start remote review.';

  @override
  String get privacyRemoteFact2 =>
      'It is sent only to a WSS service you imported and approved.';

  @override
  String get privacyRemoteFact3 =>
      'Access tokens are stored only in Keychain / Keystore.';

  @override
  String get privacyOpenSourcePanelTitle =>
      'Code and model boundaries are public';

  @override
  String get privacyOpenSourceFact1 =>
      'The app source code is licensed under MPL-2.0.';

  @override
  String get privacyOpenSourceFact2 =>
      'Models, data, and fonts must declare licenses and SHA-256 hashes.';

  @override
  String get privacyOpenSourceFact3 =>
      'Report security issues privately through the repository SECURITY.md.';

  @override
  String get privacyPreviousFact => 'Previous item';

  @override
  String get privacyNextFact => 'Next item';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '$title. $facts';
  }

  @override
  String get licenses => 'Licenses';

  @override
  String get viewThirdPartyLicenses => 'View third-party licenses';

  @override
  String get privacyPromiseSemantics =>
      'Privacy commitment: no mandatory account, no ads, no coins, and no automatic uploads';

  @override
  String get privacyPromise =>
      'No required account · No ads · No coins · No automatic uploads';

  @override
  String get closeCamera => 'Close camera';

  @override
  String get cameraViewfinderSemantics =>
      'Camera viewfinder. Keep the entire 19×19 Go board inside the frame.';

  @override
  String get startingCamera => 'Starting camera…';

  @override
  String recognizingIntersections(int count) {
    return 'Recognizing $count intersections…';
  }

  @override
  String get cameraTemporarilyUnavailable => 'Camera temporarily unavailable';

  @override
  String get retry => 'Retry';

  @override
  String get photoLibrary => 'Photos';

  @override
  String get capturePhoto => 'Take photo';

  @override
  String get captureHelp => 'Photo help';

  @override
  String get alignmentReady => 'Entire board framed · Hold steady';

  @override
  String get alignmentRecognizing => 'Recognizing · Stay on this screen';

  @override
  String get alignmentFallback => 'You can continue from Photos';

  @override
  String get alignmentPreparing => 'Preparing viewfinder';

  @override
  String get captureHelpTitle => 'Photograph the entire board';

  @override
  String get captureHelpBody =>
      'Keep all four corners inside the green frame, hold the camera as square to the board as possible, and avoid strong glare on the stones.';

  @override
  String get gotIt => 'Got it';

  @override
  String get flashAutomatic => 'Flash, automatic';

  @override
  String get flashOff => 'Flash, off';

  @override
  String get flashOn => 'Flash, on';

  @override
  String get cameraPermissionDenied =>
      'Camera access is denied. Allow it in system settings or use Photos instead.';

  @override
  String get cameraRestricted =>
      'Camera access is restricted on this device. Use Photos instead.';

  @override
  String get cameraUnavailable =>
      'The camera is unavailable. Try again or use Photos.';

  @override
  String get cameraCaptureFailed =>
      'The photo could not be taken. Hold the device steady and try again.';

  @override
  String get photoLibraryPermissionDenied =>
      'Photo access is denied. Allow photo access in system settings.';

  @override
  String get photoLibraryUnavailable =>
      'Photos could not be opened. Try again later.';

  @override
  String get selectedImageUnreadable =>
      'The selected image could not be read. Choose a clear photo of the complete board.';

  @override
  String get recognitionIncompleteBoard =>
      'The complete board could not be recognized. Keep all four corners framed with even lighting and try again.';

  @override
  String get recognitionFailed =>
      'Recognition failed. Keep the complete board clear and try again.';

  @override
  String get useGuideFallback => 'Use board guide';

  @override
  String get guideFallbackDetail =>
      'Reprocess the same captured frame set using the board guide.';

  @override
  String get guideFallbackRecognizing => 'Recognizing with board guide…';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get returnToKifu => 'Back to records';

  @override
  String get cancelAction => 'Cancel';

  @override
  String get closeAction => 'Close';

  @override
  String get openAction => 'Open';

  @override
  String get pauseAction => 'Pause';

  @override
  String get resumeAction => 'Resume';

  @override
  String get shareKifu => 'Export record';

  @override
  String get shareOpened => 'System share opened';

  @override
  String get shareNoTarget =>
      'No sharing destination is available on this device';

  @override
  String get shareUnavailable => 'System share could not be opened.';

  @override
  String get preparing => 'Preparing';

  @override
  String get blackStoneShort => 'Black';

  @override
  String get whiteStoneShort => 'White';

  @override
  String get blackStoneLabel => 'Black stone';

  @override
  String get whiteStoneLabel => 'White stone';

  @override
  String get semanticSeparator => ', ';

  @override
  String get emptyPoint => 'Empty';

  @override
  String get unclearPoint => 'Unclear';

  @override
  String get passMove => 'Pass';

  @override
  String pointsValue(String value) {
    return '$value pts';
  }

  @override
  String pointLossValue(String value) {
    return '−$value pts';
  }

  @override
  String visitsValue(String value) {
    return '$value visits';
  }

  @override
  String moveOrdinal(int move) {
    return 'Move $move';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '$count effective decisions';
  }

  @override
  String boardDimension(int size) {
    return '$size×$size';
  }

  @override
  String coverageInterval(int coverage) {
    return '$coverage% interval';
  }

  @override
  String get winRateLabel => 'Win rate';

  @override
  String get scoreLeadLabel => 'Score lead';

  @override
  String get blackScoreLeadLabel => 'Black score lead';

  @override
  String get visitsLabel => 'Visits';

  @override
  String get playedMoveLabel => 'Played';

  @override
  String get principalVariationLabel => 'Main line';

  @override
  String get noneLabel => 'None';

  @override
  String get analysisDefaultTitle => 'Standard analysis';

  @override
  String get analysisContinuesInApp =>
      'Analysis continues in the app after you leave this page';

  @override
  String get analysisProgressLabel => 'Analysis progress';

  @override
  String get analysisRunning => 'Analyzing';

  @override
  String get analysisPaused => 'Paused';

  @override
  String get analysisCompleted => 'Complete';

  @override
  String get analysisFailed => 'Analysis failed';

  @override
  String candidateSemantics(String label) {
    return 'Candidate $label';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return 'Candidate $label, $detail';
  }

  @override
  String get correctBoardTitle => 'Correct board';

  @override
  String intersectionCoordinate(String coordinate) {
    return 'Intersection $coordinate';
  }

  @override
  String get confirmed => 'Confirmed';

  @override
  String pendingConfirmation(int count) {
    return '$count to confirm';
  }

  @override
  String get pendingLabel => 'To confirm';

  @override
  String markStone(String choice) {
    return 'Mark as $choice';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '$choice stone';
  }

  @override
  String get goBoardLabel => 'Go board';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String get noLastMove => 'No last-move marker';

  @override
  String lastMoveAt(String coordinate) {
    return 'Last move $coordinate';
  }

  @override
  String get noCandidatePoints => 'No candidate points';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '$size by $size, $blackCount black stones, $whiteCount white stones, $lastMove, $candidates. Current intersection $coordinate';
  }

  @override
  String get boardNavigationHint =>
      'Use the custom directional actions to move between intersections';

  @override
  String get boardNavigationSelectHint =>
      'Use the custom directional actions to move between intersections; double-tap to select';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '$blackPlayer vs $whitePlayer';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return 'Black $blackPlayer, White $whitePlayer';
  }

  @override
  String get kifuReviewed => 'Reviewed';

  @override
  String get kifuAnalyzing => 'Analyzing';

  @override
  String get kifuNotReviewed => 'Not reviewed';

  @override
  String get kifuNeedsAction => 'Needs attention';

  @override
  String get timelineLabel => 'Moves';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '$label, move $current of $total';
  }

  @override
  String get previousMove => 'Previous move';

  @override
  String get nextMove => 'Next move';

  @override
  String sliderMoveSemantics(int current, int total) {
    return 'Move $current of $total';
  }

  @override
  String get gamePerformanceEstimate => 'Game performance estimate';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '$title, $lowerRank to $upperRank, 80% interval, $confidence, $decisions';
  }

  @override
  String get reviewKeyMoves => 'Key moves';

  @override
  String get reviewVariations => 'Variations';

  @override
  String get reviewTrend => 'Trend';

  @override
  String get reviewGame => 'Game';

  @override
  String get reviewPanel => 'Review panel';

  @override
  String tabSemantics(String label) {
    return '$label tab';
  }

  @override
  String get selectFromPhotos => 'Choose from Photos';

  @override
  String get scoreTrend => 'Score-lead trend';

  @override
  String get noData => 'No data';

  @override
  String blackLeads(String points) {
    return 'Black leads by $points points';
  }

  @override
  String whiteLeads(String points) {
    return 'White leads by $points points';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '$label, $direction';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '$label, $direction, currently move $move';
  }

  @override
  String get partialRecordExpired => 'Partial record is no longer available';

  @override
  String get partialTrustBoundary => 'Trust boundary · Not a complete game';

  @override
  String partialBoardSemantics(int moves) {
    return 'Valid prefix of a partial record, $moves moves; full review is unavailable';
  }

  @override
  String partialUnproven(int move) {
    return 'The record starts at move $move or contains unverified setup; key moves and performance are unavailable.';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return 'Move $move is illegal: $reason';
  }

  @override
  String get ruleViolationWrongTurn => 'Wrong player to move';

  @override
  String get ruleViolationOutOfBounds => 'Move is outside the board';

  @override
  String get ruleViolationOccupied => 'The intersection is occupied';

  @override
  String get ruleViolationSuicide => 'Suicide is not allowed by these rules';

  @override
  String get ruleViolationKo => 'The position violates the ko rule';

  @override
  String get exportOriginalRecord => 'Export original';

  @override
  String get saveCurrentPosition => 'Save current position';

  @override
  String get ruleChinese => 'Chinese rules';

  @override
  String get ruleJapanese => 'Japanese rules';

  @override
  String get ruleKorean => 'Korean rules';

  @override
  String get ruleAga => 'AGA rules';

  @override
  String get ruleNewZealand => 'New Zealand rules';

  @override
  String get ruleTrompTaylor => 'Tromp-Taylor rules';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '$rules · $result · $moves';
  }

  @override
  String get resultUnknown => 'Unknown result';

  @override
  String get blackWins => 'Black wins';

  @override
  String blackWinsBy(String points) {
    return 'Black wins by $points points';
  }

  @override
  String get whiteWins => 'White wins';

  @override
  String whiteWinsBy(String points) {
    return 'White wins by $points points';
  }

  @override
  String get drawResult => 'Draw';

  @override
  String get voidedResult => 'No result';

  @override
  String get noAnalyzableKifu => 'No record to analyze';

  @override
  String get selectAnalyzableKifu =>
      'Choose a complete record or a confirmed position from the records screen.';

  @override
  String get kifuNeedsConfirmation => 'Record still needs confirmation';

  @override
  String get completeBeforeAnalysis =>
      'Complete and validate the record before starting a full review.';

  @override
  String get savePlayerToMoveFailed =>
      'Could not save the player to move. Check available storage and try again.';

  @override
  String get cancelAnalysisTitle => 'Cancel analysis?';

  @override
  String get cancelAnalysisBody =>
      'The current service request will stop immediately. You can start it again later.';

  @override
  String get continueAnalysis => 'Continue analysis';

  @override
  String get analyzeKifuTitle => 'Analyze record';

  @override
  String get globalAnalysisRunning => 'Analyzing full game';

  @override
  String get analysisQueuedTitle => 'Waiting for desktop engine';

  @override
  String analysisQueuePosition(int position) {
    return 'Queue position $position · starts automatically after the current analysis';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return 'Queue #$position';
  }

  @override
  String get statusQueued => 'Queued';

  @override
  String get connectingAnalysisService => 'Connecting to analysis service';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '$completed / $total positions';
  }

  @override
  String get reviewGenerated => 'Review ready';

  @override
  String get positionAnalysisComplete => 'Position analysis complete';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '$completed positions · $model';
  }

  @override
  String get analysisInvalidResult =>
      'The analysis service returned an invalid result.';

  @override
  String get analysisCancelled => 'Analysis cancelled';

  @override
  String get incompleteResultsDiscarded => 'Incomplete results were not kept';

  @override
  String completedPositions(int count) {
    return '$count positions complete';
  }

  @override
  String get analysisServiceRequired => 'Analysis service required';

  @override
  String get addWssServiceRetry => 'Add a WSS KataGo service and try again.';

  @override
  String get cancelAnalysisSemantics =>
      'Cancel analysis. The in-app task continues after you leave this page';

  @override
  String get cancelQueuedAnalysisSemantics => 'Cancel this queued analysis';

  @override
  String get openReview => 'Open review';

  @override
  String get openKeyMoveReview => 'Open key-move review';

  @override
  String get viewCandidates => 'View candidates';

  @override
  String get viewPositionCandidates => 'View position candidates';

  @override
  String get reanalyze => 'Analyze again';

  @override
  String get sendBeforeConfirm => 'Confirm before sending';

  @override
  String sendPositionToHost(String host) {
    return 'Send the current position to $host; the source photo is not uploaded.';
  }

  @override
  String sendRecordToHost(String host) {
    return 'Send the complete record to $host for KataGo analysis.';
  }

  @override
  String get confirmAndStart => 'Confirm and start';

  @override
  String get viewPrivacyBoundary => 'View privacy boundary';

  @override
  String get katagoUnconfigured => 'KataGo is not configured';

  @override
  String get katagoConfigDetail =>
      'Import a trusted WSS analysis-service manifest. The access token stays in secure system storage.';

  @override
  String get configureAnalysisService => 'Configure analysis service';

  @override
  String get nextPlayerQuestion => 'Who plays next?';

  @override
  String get photoNoTimingPlayerDetail =>
      'A photo has no move timing. Confirm the player to move so candidate win rates have a defined perspective.';

  @override
  String get creatingAnalysisTask => 'Creating analysis task';

  @override
  String get validatingConfigKifu => 'Validating configuration and record…';

  @override
  String get analysisDataDestinationSubtitle =>
      'Clear, controlled data destination';

  @override
  String get analyzingPositionBoard => 'Board for the position being analyzed';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '$size by $size board being analyzed; $completed positions complete';
  }

  @override
  String get statusNeedsConfiguration => 'Setup needed';

  @override
  String get statusFailed => 'Failed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get analysisFailureCancel =>
      'The analysis request could not be cancelled.';

  @override
  String get analysisFailureProviderCreation =>
      'The analysis-service connection could not be created.';

  @override
  String get analysisFailureInvalidResult =>
      'The analysis result failed validation.';

  @override
  String get analysisFailureProvider => 'The analysis service failed.';

  @override
  String get analysisFailureStreamEnded =>
      'The analysis connection ended before completion.';

  @override
  String get analysisFailureRemote =>
      'The analysis service could not complete the request.';

  @override
  String get performanceSubtitle => 'Single-game performance';

  @override
  String get performancePaneCore => 'Core';

  @override
  String get performancePanePhases => 'Phases';

  @override
  String get performancePaneSample => 'Sample';

  @override
  String get confidenceMedium => 'Medium confidence';

  @override
  String get confidenceLow => 'Low confidence';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return 'Game performance estimate, $weak to $strong, $interval, $confidence, $decisions';
  }

  @override
  String get performanceBoundarySemantics =>
      'This result describes this game only, not long-term strength or a platform rank';

  @override
  String get performanceBoundaryCompact =>
      'This game only, not long-term strength';

  @override
  String get performanceBoundaryFull =>
      'This range describes this game only, not long-term strength or a platform rank.';

  @override
  String get averagePointLoss => 'Average point loss';

  @override
  String get pointLossLabel => 'Point loss';

  @override
  String get severeMistake => 'Severe mistakes';

  @override
  String get phaseOpening => 'Opening';

  @override
  String get phaseMiddleGame => 'Middlegame';

  @override
  String get phaseEndgame => 'Endgame';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '$phase · $loss · $moves';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '$phase, average point loss $loss, $moves';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '$board · $visits+ visits · $model';
  }

  @override
  String get checkCompleteNineteen => 'Complete non-handicap 19×19 record';

  @override
  String get checkMinimumDecisions => 'At least 40 effective decisions';

  @override
  String get checkStandardDeepAnalysis => 'Standard or deep full-game analysis';

  @override
  String get checkProductionCalibration => 'Production calibration model';

  @override
  String get performanceUnavailableTitle => 'Performance range unavailable';

  @override
  String get performanceUnavailableBody =>
      'No production calibration model has passed holdout-set coverage validation. Demo parameters will never be presented as a rank.';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return 'Still verifiable: average point loss $loss · Top 3 $topThree';
  }

  @override
  String get noCompleteReviewReturn => 'No complete review data · Back';

  @override
  String rankKyu(int value) {
    return '$value kyu';
  }

  @override
  String rankDan(int value) {
    return '$value dan';
  }

  @override
  String get positionAnalysisTitle => 'Position analysis';

  @override
  String get positionAnalysisSubtitle =>
      'Current position · No complete sequence';

  @override
  String positionBoardSemantics(String player, int count) {
    return 'Position-analysis board, $player to play, $count candidates';
  }

  @override
  String get staticPositionBoundarySemantics =>
      'This position has no complete move sequence, so key moves and performance are unavailable';

  @override
  String get staticPositionBoundaryBody =>
      'Only candidates and the current evaluation are analyzed; key moves, timeline, and performance are not shown.';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return 'Candidate $label, $move, $score';
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
    return 'Candidate $label, $move, $player win rate $winRate, Black score lead $score, $visits, main line $pv';
  }

  @override
  String playerWinRate(String player) {
    return '$player win rate';
  }

  @override
  String get principalVariationNone => 'Main line: none';

  @override
  String principalVariationValue(String value) {
    return 'Main line  $value';
  }

  @override
  String get noPlayableCandidate =>
      'The service returned no playable candidate; only a pass may remain.';

  @override
  String get positionDataExpired => 'Position data is no longer available';

  @override
  String get positionNotAnalyzed => 'This position has not been analyzed';

  @override
  String get realKatagoOnly =>
      'Candidates, win rate, score lead, and visits show real KataGo results only.';

  @override
  String get startAnalysis => 'Start analysis';

  @override
  String get variationComparisonTitle => 'Compare variations';

  @override
  String variationComparisonSubtitle(int move) {
    return 'Move $move · Played vs candidates';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return 'Variation comparison at move $move; candidate $candidate selected';
  }

  @override
  String get noComparableCandidate => 'No candidate to compare';

  @override
  String returnToMainLine(int move) {
    return 'Return to main line at move $move';
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
    return 'Candidate $label, $move, win rate $winRate, Black score lead $score, $visits, main line $pv, played $played, point loss $loss';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return 'Played $move · $loss';
  }

  @override
  String playedMoveValue(String move) {
    return 'Played $move';
  }

  @override
  String get serviceNoPrincipalVariation =>
      'The service did not provide a main line';

  @override
  String get realCandidateData => 'Real candidate data';

  @override
  String get noVariationReturn => 'No variation data · Back';

  @override
  String get bestCandidate => 'Best candidate';

  @override
  String get candidateVariation => 'Candidate variation';

  @override
  String reviewBoardSemantics(int move, int count) {
    return 'Review board at move $move, showing $count real candidates';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return 'Move $move, $leader leads by $points points, $leader win rate $winRate';
  }

  @override
  String positionMetricCompact(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return 'Move $move · $leader +$points · $winRate';
  }

  @override
  String positionMetricFull(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return 'Move $move    $leader leads by $points points    $leader win rate $winRate';
  }

  @override
  String get reviewTitle => 'Review';

  @override
  String get completeAnalysisResults => 'Complete analysis results';

  @override
  String get noCompletedReview => 'No completed review';

  @override
  String get verifiedGlobalAnalysisOnly =>
      'A key-move review requires complete, validated full-game analysis.';

  @override
  String get tabletLandscapeHint =>
      'Rotate the tablet to landscape for the two-column review';

  @override
  String tabletBoardSemantics(int move, int count) {
    return 'Tablet review board at move $move, showing $count candidates';
  }

  @override
  String get noReviewDataReturn => 'No review data · Back to records';

  @override
  String get quickReview => 'Quick review';

  @override
  String get standardReview => 'Standard review';

  @override
  String get deepReview => 'Deep review';

  @override
  String regularMoveTitle(int move) {
    return 'Move $move';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return 'Key move #$rank · Move $move';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '$title, played to best $comparison, $detail';
  }

  @override
  String get regularMoveBadge => 'Regular move';

  @override
  String get lossRankBadge => 'Loss rank';

  @override
  String get noCandidateData => 'No candidate data';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '$winRate · $score · $visits';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return 'Best candidate $move, $detail';
  }

  @override
  String pvMoveCount(int moves) {
    return 'PV $moves moves';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return 'Move $move · Black score lead $score · Black win rate $winRate';
  }

  @override
  String get globalScoreTrend => 'Full-game score trend';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return 'Average point loss $loss · Top 3 $topThree · Severe mistakes $severe';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return 'Game metrics, $detail; performance range requires a calibrated model';
  }

  @override
  String get gameMetricsTitle => 'Game metrics';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '$moves moves · $keyMoves key moves';
  }

  @override
  String get performanceNeedsCalibration => 'Calibration required';

  @override
  String get boardCorrectionExpired =>
      'Board-correction data is no longer available';

  @override
  String get sequenceCorrectionExpired =>
      'Sequence-correction data is no longer available';

  @override
  String autoRectifiedSubtitle(String board) {
    return 'Auto-rectified · $board';
  }

  @override
  String get viewOriginal => 'View original';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return 'Physical-board correction, $blackCount black stones, $whiteCount white stones, $pending intersections to confirm';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return 'Black $blackCount · White $whiteCount';
  }

  @override
  String get confirmCurrentPosition => 'Confirm current position';

  @override
  String confirmRemaining(int count) {
    return 'Confirm $count remaining';
  }

  @override
  String get correctSequenceTitle => 'Correct sequence';

  @override
  String numberedDetectedMoves(int moves) {
    return 'Numbered diagram · $moves moves recognized';
  }

  @override
  String get sequenceValidatingSemantics =>
      'Numbered-diagram correction, validating the complete sequence';

  @override
  String sequenceIssueSemantics(int move) {
    return 'Numbered-diagram correction, move $move needs confirmation; choose an intersection';
  }

  @override
  String get reuseAfterCapture => 'Reuse point after capture';

  @override
  String get markPassMove => 'Mark this move as pass';

  @override
  String selectMoveOnBoard(int move) {
    return 'Choose move $move on the board';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return 'Confirm move $move at $coordinate';
  }

  @override
  String get saveAsPositionFallback =>
      'Sequence cannot be recovered; save current position';

  @override
  String get sequenceIssueNoFirst =>
      'Move 1 was not recognized. Choose its position or mark it as pass.';

  @override
  String get sequenceIssueMissing =>
      'A number is missing. Choosing its intersection replaces the incorrect number at that point.';

  @override
  String get sequenceIssueOcr => 'OCR confidence is low. Confirm the position.';

  @override
  String get sequenceIssueColor =>
      'Stone color does not match move-number parity. Confirm the position.';

  @override
  String get sequenceIssueFinalMismatch =>
      'The recovered sequence does not match the recognized final board. Check the marked position.';

  @override
  String get sequenceIssueTooMany =>
      'The numbered sequence exceeds the safe processing limit.';

  @override
  String get sequenceIssueDuplicate =>
      'The same move number appears more than once. Check the markers.';

  @override
  String get sequenceIssueIllegal =>
      'The sequence violates the Go rules. Check the marked position.';

  @override
  String get sequenceValidationFailed =>
      'Sequence validation failed. Check the markers and try again.';

  @override
  String get validatingGoRules => 'Validating with Go rules';

  @override
  String moveCannotConfirm(String move) {
    return 'Move $move cannot be confirmed';
  }

  @override
  String get checkingSequenceRules =>
      'Checking number continuity, captures, ko, and point reuse.';

  @override
  String get sequenceVerifiedTitle => 'Sequence verified';

  @override
  String get sequenceVerifiedSubtitle =>
      'Continuous numbering · Go rules passed';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return 'Verified complete $size by $size record with $moves moves';
  }

  @override
  String get saveAndStartReview => 'Save and start review';

  @override
  String rescanWithReason(String reason) {
    return '$reason · Scan again';
  }

  @override
  String get originalImageUnavailable => 'Original image cannot be displayed';

  @override
  String get scanResultTitle => 'Recognition result';

  @override
  String scanResultSubtitle(String board) {
    return 'Current position · $board';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return 'Recognized $size by $size Go position with $blackCount black stones and $whiteCount white stones';
  }

  @override
  String get boardRecognitionComplete => 'Board recognition complete';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return 'Current position recognized: $blackCount black stones and $whiteCount white stones.';
  }

  @override
  String get photoNoSequence =>
      'A single photo has no move timing, so a complete sequence cannot be recovered. This position has no key-move timeline or performance estimate.';

  @override
  String get nextPlayerLabel => 'Next player';

  @override
  String get chooseNextPlayerFirst => 'Choose next player';

  @override
  String get analyzeCurrentPosition => 'Analyze position';

  @override
  String get savePosition => 'Save position';

  @override
  String get savePositionAnalysisFailed =>
      'Save failed. Analysis of this position has not started.';

  @override
  String get scanResultExpired => 'Recognition result is no longer available';

  @override
  String get scanResultExpiredDetail =>
      'Return to board scanning and take or choose another photo.';

  @override
  String get returnToScan => 'Back to board scanning';
}

/// The translations for English (`en_XA`).
class AppLocalizationsEnXa extends AppLocalizationsEn {
  AppLocalizationsEnXa() : super('en_XA');

  @override
  String get appTitle => '⟦LizzieYZY Mobile⟧∼∼∼∼∼';

  @override
  String get portraitGuardSemantics =>
      '⟦Use portrait orientation on phones. Landscape remains available on tablets.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get portraitGuardTitle => '⟦Turn your phone upright⟧∼∼∼∼∼∼∼';

  @override
  String get portraitGuardBody =>
      '⟦The board, metrics, and controls fit completely in portrait.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get kifuTab => '⟦Games⟧∼∼';

  @override
  String get kifuHomeTooltip => '⟦Game records⟧∼∼∼∼';

  @override
  String get scanTab => '⟦Scan⟧∼∼';

  @override
  String get photoScanTooltip => '⟦Scan a Go board⟧∼∼∼∼∼';

  @override
  String get homeSubtitle =>
      '⟦LIZZIEYZY · Review every game precisely⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importKifuTooltip => '⟦Import game record⟧∼∼∼∼∼∼';

  @override
  String get settingsTooltip => '⟦Settings⟧∼∼∼';

  @override
  String get back => '⟦Back⟧∼∼';

  @override
  String get recentKifu => '⟦Recent games⟧∼∼∼∼';

  @override
  String get statusVerified => '⟦Verified⟧∼∼∼';

  @override
  String get statusNeedsConfirmation => '⟦Needs review⟧∼∼∼∼';

  @override
  String get statusCurrentPosition => '⟦Current position⟧∼∼∼∼∼';

  @override
  String get blackPlayerFallback => '⟦Black⟧∼∼';

  @override
  String get whitePlayerFallback => '⟦White⟧∼∼';

  @override
  String get completeKifu => '⟦Complete game⟧∼∼∼∼';

  @override
  String get partialKifu => '⟦Partial record⟧∼∼∼∼∼';

  @override
  String get photoPosition => '⟦Photo position⟧∼∼∼∼∼';

  @override
  String get justImported => '⟦Just imported⟧∼∼∼∼';

  @override
  String get photoScanSemantics =>
      '⟦Scan a Go board with the camera⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get photoScanTitle => '⟦Scan board⟧∼∼∼';

  @override
  String get photoScanSubtitle =>
      '⟦Physical board · Numbered diagram⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get emptyKifuLibrary =>
      '⟦No games yet. Import an SGF or GIB file, or save a position from a photo.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importFirstKifu => '⟦Import your first game⟧∼∼∼∼∼∼∼';

  @override
  String inboundImported(String fileName) {
    return '⟦Imported $fileName from system sharing⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return '⟦Imported $fileName · $warnings⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String inboundOpen(String fileName) {
    return '⟦Open imported game: $fileName⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get sharedKifuFallback => '⟦Shared game record⟧∼∼∼∼∼∼';

  @override
  String get inboundInvalidFile =>
      '⟦The shared game record is invalid and could not be imported.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get inboundStorageFailure =>
      '⟦The shared game could not be saved. Check available storage.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get inboundPlatformFailure =>
      '⟦The game record could not be read from system sharing. Try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get dismissNotice => '⟦Dismiss notification⟧∼∼∼∼∼∼';

  @override
  String playerPair(String blackPlayer, String whitePlayer) {
    return '⟦$blackPlayer · $whitePlayer⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String moveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count moves',
      one: '1 move',
      zero: '0 moves',
    );
    return '⟦$_temp0⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String kifuCardDetail(String result, String moves, String playedAt) {
    return '⟦$result · $moves · $playedAt⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String kifuCardSemantics(
    String blackPlayer,
    String whitePlayer,
    String result,
    String moves,
    String status,
  ) {
    return '⟦$blackPlayer versus $whitePlayer, $result, $moves, $status⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get importKifuTitle => '⟦Import game⟧∼∼∼∼';

  @override
  String get importKifuSubtitle => '⟦SGF / GIB · Local validation⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get chooseKifuTitle => '⟦Choose an SGF or GIB file⟧∼∼∼∼∼∼∼∼';

  @override
  String get chooseKifuBody =>
      '⟦The format and Go rules are validated first. Incomplete records are clearly downgraded and never presented as complete games.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get chooseKifuFile => '⟦Choose game file⟧∼∼∼∼∼';

  @override
  String get validatingKifu => '⟦Validating game…⟧∼∼∼∼∼';

  @override
  String get importFailed => '⟦Import failed⟧∼∼∼∼';

  @override
  String get chooseAgain => '⟦Choose again⟧∼∼∼∼';

  @override
  String get saveKifuFailed =>
      '⟦Could not save. Check available storage and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get kifuReadFailed => '⟦Could not read the game record.⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String verifiedRecordDetail(String moves) {
    return '⟦$moves · Rules validated⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String partialRecordDetail(String moves) {
    return '⟦$moves · Manual confirmation required⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return '⟦Black $blackCount · White $whiteCount⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get warning => '⟦Warnings⟧∼∼∼';

  @override
  String get fileEncoding => '⟦File encoding⟧∼∼∼∼';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return '⟦Legacy GIB encoding detected: $encoding⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
      zero: 'None',
    );
    return '⟦$_temp0⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get addedToKifu => '⟦Added to games⟧∼∼∼∼∼';

  @override
  String get addToKifu => '⟦Add to games⟧∼∼∼∼';

  @override
  String get importAnother => '⟦Import another⟧∼∼∼∼∼';

  @override
  String get importErrorResourceLimit =>
      '⟦This record exceeds the safe processing limit. Choose a smaller file.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importErrorInvalidEncoding =>
      '⟦The text encoding is invalid or ambiguous. SGF supports UTF-8 only.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importErrorUnsupportedFormat =>
      '⟦Only .sgf and .gib game records are supported.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importErrorInvalidRecord =>
      '⟦The record format or move sequence is invalid. Check the file.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get importErrorUnknown =>
      '⟦Could not read this game record. Make sure the file is not damaged.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get settingsTitle => '⟦Settings⟧∼∼∼';

  @override
  String get settingsSubtitle =>
      '⟦Local first · Auditable configuration⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisServiceTitle => '⟦Analysis service⟧∼∼∼∼∼';

  @override
  String get analysisServiceUnconfigured =>
      '⟦Not configured · No games are sent⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String analysisServiceConfigured(String model) {
    return '⟦$model · WSS⟧∼∼∼∼';
  }

  @override
  String get appearanceTitle => '⟦Appearance⟧∼∼∼';

  @override
  String get languageTitle => '⟦Language⟧∼∼∼';

  @override
  String get privacyOpenSourceTitle => '⟦Privacy & open source⟧∼∼∼∼∼∼∼';

  @override
  String get privacyOpenSourceDetail =>
      '⟦Data boundaries · Licenses · Security reports⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get appVersionSemantics =>
      '⟦LizzieYZY Mobile version 0.1.0, open-source license MPL 2.0⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get appVersionLabel =>
      '⟦LizzieYZY Mobile · 0.1.0 · MPL-2.0⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisShortcutConfigured => '⟦Analysis\nConfigured⟧∼∼∼∼∼∼';

  @override
  String get analysisShortcutUnconfigured =>
      '⟦Analysis\nNot configured⟧∼∼∼∼∼∼∼';

  @override
  String get privacyShortcut => '⟦Privacy &\nopen source⟧∼∼∼∼∼∼∼';

  @override
  String get appearanceSubtitle => '⟦System theme and high contrast⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get languageSubtitle => '⟦App and system-control language⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get themeSystem => '⟦Follow system⟧∼∼∼∼';

  @override
  String get themeLight => '⟦Light⟧∼∼';

  @override
  String get themeDark => '⟦Dark⟧∼∼';

  @override
  String get localeSystem => '⟦Follow system⟧∼∼∼∼';

  @override
  String get localeSimplifiedChinese => '⟦简体中文⟧∼∼';

  @override
  String get localeTraditionalChinese => '⟦繁體中文⟧∼∼';

  @override
  String get localeEnglish => '⟦English⟧∼∼∼';

  @override
  String get localeJapanese => '⟦日本語⟧∼';

  @override
  String get localeKorean => '⟦한국어⟧∼';

  @override
  String settingsTileSemantics(String title, String detail) {
    return '⟦$title, $detail⟧∼∼∼∼∼∼';
  }

  @override
  String get analysisServiceSubtitle =>
      '⟦WSS · Credentials in secure system storage⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get accessTokenOptional => '⟦Access token (optional)⟧∼∼∼∼∼∼∼';

  @override
  String get tokenSecureStorageHelper =>
      '⟦Stored only in Keychain / Keystore⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get hideToken => '⟦Hide token⟧∼∼∼';

  @override
  String get showToken => '⟦Show token⟧∼∼∼';

  @override
  String get hideAccessToken => '⟦Hide access token⟧∼∼∼∼∼∼';

  @override
  String get showAccessToken => '⟦Show access token⟧∼∼∼∼∼∼';

  @override
  String get confirmEverySend => '⟦Confirm before every upload⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get remoteAnalysisSendsFullKifu =>
      '⟦Remote analysis sends the complete game record⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get settingsSaveFailedRetry => '⟦Could not save. Try again.⟧∼∼∼∼∼∼∼∼';

  @override
  String get removeService => '⟦Remove service⟧∼∼∼∼∼';

  @override
  String get saveConfiguration => '⟦Save configuration⟧∼∼∼∼∼∼';

  @override
  String get connectionTab => '⟦Connection⟧∼∼∼';

  @override
  String get reviewTab => '⟦Review⟧∼∼';

  @override
  String get tokenLabel => '⟦Token⟧∼∼';

  @override
  String get confirmBeforeSend => '⟦Confirm before sending⟧∼∼∼∼∼∼∼';

  @override
  String get settingsSaveFailed => '⟦Save failed⟧∼∼∼∼';

  @override
  String get saving => '⟦Saving⟧∼∼';

  @override
  String get save => '⟦Save⟧∼∼';

  @override
  String get analysisManifestFileType =>
      '⟦LizzieYZY analysis service manifest⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get manifestTooLarge =>
      '⟦The service manifest must not exceed 64 KB.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get manifestReadFailed =>
      '⟦Could not read the service manifest.⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get removeAnalysisServiceTitle => '⟦Remove analysis service?⟧∼∼∼∼∼∼∼∼';

  @override
  String get removeAnalysisServiceBody =>
      '⟦The service address and access token in secure system storage will be deleted.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get keep => '⟦Keep⟧∼∼';

  @override
  String get remove => '⟦Remove⟧∼∼';

  @override
  String get manifestNotImported => '⟦No service manifest imported⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get manifestPurpose =>
      '⟦The manifest pins the endpoint, model hash, and win-rate perspective⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '⟦$host · $engineVersion⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get notConfigured => '⟦Not configured⟧∼∼∼∼∼';

  @override
  String get importAction => '⟦Import⟧∼∼';

  @override
  String get replace => '⟦Replace⟧∼∼∼';

  @override
  String get removeAnalysisServiceTooltip => '⟦Remove analysis service⟧∼∼∼∼∼∼∼';

  @override
  String get importManifestTooltip => '⟦Import service manifest⟧∼∼∼∼∼∼∼';

  @override
  String get replaceManifestTooltip => '⟦Replace service manifest⟧∼∼∼∼∼∼∼∼';

  @override
  String get reviewDepth => '⟦Review depth⟧∼∼∼∼';

  @override
  String get analysisQuick => '⟦Quick⟧∼∼';

  @override
  String get analysisStandard => '⟦Standard⟧∼∼∼';

  @override
  String get analysisDeep => '⟦Deep⟧∼∼';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '⟦$profile · $visitsString visits/move⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get privacySubtitle =>
      '⟦Every data destination must be verifiable⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyLocalTab => '⟦On device⟧∼∼∼';

  @override
  String get privacyRemoteTab => '⟦Remote⟧∼∼';

  @override
  String get privacyOpenSourceTab => '⟦Open source⟧∼∼∼∼';

  @override
  String get privacyLocalTitle => '⟦On-device by default⟧∼∼∼∼∼∼';

  @override
  String get privacyLocalFact1 =>
      '⟦Camera permission is requested only when you open board scanning.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyLocalFact2 =>
      '⟦Photos, records, and corrections stay in the app\'s private directory.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyLocalFact3 =>
      '⟦No ads, accounts, social features, or behavioral tracking SDKs.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyRemoteTitle => '⟦You control remote analysis⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyRemoteFact1 =>
      '⟦A complete record is sent only when you explicitly start remote review.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyRemoteFact2 =>
      '⟦It is sent only to a WSS service you imported and approved.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyRemoteFact3 =>
      '⟦Access tokens are stored only in Keychain / Keystore.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyOpenSourcePanelTitle =>
      '⟦Code and model boundaries are public⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyOpenSourceFact1 =>
      '⟦The app source code is licensed under MPL-2.0.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyOpenSourceFact2 =>
      '⟦Models, data, and fonts must declare licenses and SHA-256 hashes.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyOpenSourceFact3 =>
      '⟦Report security issues privately through the repository SECURITY.md.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyPreviousFact => '⟦Previous item⟧∼∼∼∼';

  @override
  String get privacyNextFact => '⟦Next item⟧∼∼∼';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '⟦$title. $facts⟧∼∼∼∼∼';
  }

  @override
  String get licenses => '⟦Licenses⟧∼∼∼';

  @override
  String get viewThirdPartyLicenses => '⟦View third-party licenses⟧∼∼∼∼∼∼∼∼';

  @override
  String get privacyPromiseSemantics =>
      '⟦Privacy commitment: no mandatory account, no ads, no coins, and no automatic uploads⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get privacyPromise =>
      '⟦No required account · No ads · No coins · No automatic uploads⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get closeCamera => '⟦Close camera⟧∼∼∼∼';

  @override
  String get cameraViewfinderSemantics =>
      '⟦Camera viewfinder. Keep the entire 19×19 Go board inside the frame.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get startingCamera => '⟦Starting camera…⟧∼∼∼∼∼';

  @override
  String recognizingIntersections(int count) {
    return '⟦Recognizing $count intersections…⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get cameraTemporarilyUnavailable =>
      '⟦Camera temporarily unavailable⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get retry => '⟦Retry⟧∼∼';

  @override
  String get photoLibrary => '⟦Photos⟧∼∼';

  @override
  String get capturePhoto => '⟦Take photo⟧∼∼∼';

  @override
  String get captureHelp => '⟦Photo help⟧∼∼∼';

  @override
  String get alignmentReady => '⟦Entire board framed · Hold steady⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get alignmentRecognizing =>
      '⟦Recognizing · Stay on this screen⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get alignmentFallback => '⟦You can continue from Photos⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get alignmentPreparing => '⟦Preparing viewfinder⟧∼∼∼∼∼∼';

  @override
  String get captureHelpTitle => '⟦Photograph the entire board⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get captureHelpBody =>
      '⟦Keep all four corners inside the green frame, hold the camera as square to the board as possible, and avoid strong glare on the stones.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get gotIt => '⟦Got it⟧∼∼';

  @override
  String get flashAutomatic => '⟦Flash, automatic⟧∼∼∼∼∼';

  @override
  String get flashOff => '⟦Flash, off⟧∼∼∼';

  @override
  String get flashOn => '⟦Flash, on⟧∼∼∼';

  @override
  String get cameraPermissionDenied =>
      '⟦Camera access is denied. Allow it in system settings or use Photos instead.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cameraRestricted =>
      '⟦Camera access is restricted on this device. Use Photos instead.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cameraUnavailable =>
      '⟦The camera is unavailable. Try again or use Photos.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cameraCaptureFailed =>
      '⟦The photo could not be taken. Hold the device steady and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get photoLibraryPermissionDenied =>
      '⟦Photo access is denied. Allow photo access in system settings.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get photoLibraryUnavailable =>
      '⟦Photos could not be opened. Try again later.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get selectedImageUnreadable =>
      '⟦The selected image could not be read. Choose a clear photo of the complete board.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get recognitionIncompleteBoard =>
      '⟦The complete board could not be recognized. Keep all four corners framed with even lighting and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get recognitionFailed =>
      '⟦Recognition failed. Keep the complete board clear and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get useGuideFallback => '⟦Use board guide⟧∼∼∼∼∼';

  @override
  String get guideFallbackDetail =>
      '⟦Reprocess the same captured frame set using the board guide.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get guideFallbackRecognizing =>
      '⟦Recognizing with board guide…⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get pageNotFound => '⟦Page not found⟧∼∼∼∼∼';

  @override
  String get returnToKifu => '⟦Back to records⟧∼∼∼∼∼';

  @override
  String get cancelAction => '⟦Cancel⟧∼∼';

  @override
  String get closeAction => '⟦Close⟧∼∼';

  @override
  String get openAction => '⟦Open⟧∼∼';

  @override
  String get pauseAction => '⟦Pause⟧∼∼';

  @override
  String get resumeAction => '⟦Resume⟧∼∼';

  @override
  String get shareKifu => '⟦Export record⟧∼∼∼∼';

  @override
  String get shareOpened => '⟦System share opened⟧∼∼∼∼∼∼';

  @override
  String get shareNoTarget =>
      '⟦No sharing destination is available on this device⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get shareUnavailable =>
      '⟦System share could not be opened.⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get preparing => '⟦Preparing⟧∼∼∼';

  @override
  String get blackStoneShort => '⟦Black⟧∼∼';

  @override
  String get whiteStoneShort => '⟦White⟧∼∼';

  @override
  String get blackStoneLabel => '⟦Black stone⟧∼∼∼∼';

  @override
  String get whiteStoneLabel => '⟦White stone⟧∼∼∼∼';

  @override
  String get semanticSeparator => '⟦, ⟧∼';

  @override
  String get emptyPoint => '⟦Empty⟧∼∼';

  @override
  String get unclearPoint => '⟦Unclear⟧∼∼∼';

  @override
  String get passMove => '⟦Pass⟧∼∼';

  @override
  String pointsValue(String value) {
    return '⟦$value pts⟧∼∼∼∼';
  }

  @override
  String pointLossValue(String value) {
    return '⟦−$value pts⟧∼∼∼∼';
  }

  @override
  String visitsValue(String value) {
    return '⟦$value visits⟧∼∼∼∼∼';
  }

  @override
  String moveOrdinal(int move) {
    return '⟦Move $move⟧∼∼∼∼';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '⟦$count effective decisions⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String boardDimension(int size) {
    return '⟦$size×$size⟧∼∼∼∼';
  }

  @override
  String coverageInterval(int coverage) {
    return '⟦$coverage% interval⟧∼∼∼∼∼∼';
  }

  @override
  String get winRateLabel => '⟦Win rate⟧∼∼∼';

  @override
  String get scoreLeadLabel => '⟦Score lead⟧∼∼∼';

  @override
  String get blackScoreLeadLabel => '⟦Black score lead⟧∼∼∼∼∼';

  @override
  String get visitsLabel => '⟦Visits⟧∼∼';

  @override
  String get playedMoveLabel => '⟦Played⟧∼∼';

  @override
  String get principalVariationLabel => '⟦Main line⟧∼∼∼';

  @override
  String get noneLabel => '⟦None⟧∼∼';

  @override
  String get analysisDefaultTitle => '⟦Standard analysis⟧∼∼∼∼∼∼';

  @override
  String get analysisContinuesInApp =>
      '⟦Analysis continues in the app after you leave this page⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisProgressLabel => '⟦Analysis progress⟧∼∼∼∼∼∼';

  @override
  String get analysisRunning => '⟦Analyzing⟧∼∼∼';

  @override
  String get analysisPaused => '⟦Paused⟧∼∼';

  @override
  String get analysisCompleted => '⟦Complete⟧∼∼∼';

  @override
  String get analysisFailed => '⟦Analysis failed⟧∼∼∼∼∼';

  @override
  String candidateSemantics(String label) {
    return '⟦Candidate $label⟧∼∼∼∼∼∼';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return '⟦Candidate $label, $detail⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get correctBoardTitle => '⟦Correct board⟧∼∼∼∼';

  @override
  String intersectionCoordinate(String coordinate) {
    return '⟦Intersection $coordinate⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get confirmed => '⟦Confirmed⟧∼∼∼';

  @override
  String pendingConfirmation(int count) {
    return '⟦$count to confirm⟧∼∼∼∼∼∼';
  }

  @override
  String get pendingLabel => '⟦To confirm⟧∼∼∼';

  @override
  String markStone(String choice) {
    return '⟦Mark as $choice⟧∼∼∼∼∼';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '⟦$choice stone⟧∼∼∼∼∼';
  }

  @override
  String get goBoardLabel => '⟦Go board⟧∼∼∼';

  @override
  String get moveLeft => '⟦Move left⟧∼∼∼';

  @override
  String get moveRight => '⟦Move right⟧∼∼∼';

  @override
  String get moveUp => '⟦Move up⟧∼∼∼';

  @override
  String get moveDown => '⟦Move down⟧∼∼∼';

  @override
  String get noLastMove => '⟦No last-move marker⟧∼∼∼∼∼∼';

  @override
  String lastMoveAt(String coordinate) {
    return '⟦Last move $coordinate⟧∼∼∼∼∼∼∼';
  }

  @override
  String get noCandidatePoints => '⟦No candidate points⟧∼∼∼∼∼∼';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '⟦$size by $size, $blackCount black stones, $whiteCount white stones, $lastMove, $candidates. Current intersection $coordinate⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get boardNavigationHint =>
      '⟦Use the custom directional actions to move between intersections⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get boardNavigationSelectHint =>
      '⟦Use the custom directional actions to move between intersections; double-tap to select⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '⟦$blackPlayer vs $whitePlayer⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return '⟦Black $blackPlayer, White $whitePlayer⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get kifuReviewed => '⟦Reviewed⟧∼∼∼';

  @override
  String get kifuAnalyzing => '⟦Analyzing⟧∼∼∼';

  @override
  String get kifuNotReviewed => '⟦Not reviewed⟧∼∼∼∼';

  @override
  String get kifuNeedsAction => '⟦Needs attention⟧∼∼∼∼∼';

  @override
  String get timelineLabel => '⟦Moves⟧∼∼';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '⟦$label, move $current of $total⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get previousMove => '⟦Previous move⟧∼∼∼∼';

  @override
  String get nextMove => '⟦Next move⟧∼∼∼';

  @override
  String sliderMoveSemantics(int current, int total) {
    return '⟦Move $current of $total⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get gamePerformanceEstimate => '⟦Game performance estimate⟧∼∼∼∼∼∼∼∼';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '⟦$title, $lowerRank to $upperRank, 80% interval, $confidence, $decisions⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get reviewKeyMoves => '⟦Key moves⟧∼∼∼';

  @override
  String get reviewVariations => '⟦Variations⟧∼∼∼';

  @override
  String get reviewTrend => '⟦Trend⟧∼∼';

  @override
  String get reviewGame => '⟦Game⟧∼∼';

  @override
  String get reviewPanel => '⟦Review panel⟧∼∼∼∼';

  @override
  String tabSemantics(String label) {
    return '⟦$label tab⟧∼∼∼∼';
  }

  @override
  String get selectFromPhotos => '⟦Choose from Photos⟧∼∼∼∼∼∼';

  @override
  String get scoreTrend => '⟦Score-lead trend⟧∼∼∼∼∼';

  @override
  String get noData => '⟦No data⟧∼∼∼';

  @override
  String blackLeads(String points) {
    return '⟦Black leads by $points points⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String whiteLeads(String points) {
    return '⟦White leads by $points points⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '⟦$label, $direction⟧∼∼∼∼∼∼';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '⟦$label, $direction, currently move $move⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get partialRecordExpired =>
      '⟦Partial record is no longer available⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get partialTrustBoundary =>
      '⟦Trust boundary · Not a complete game⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String partialBoardSemantics(int moves) {
    return '⟦Valid prefix of a partial record, $moves moves; full review is unavailable⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String partialUnproven(int move) {
    return '⟦The record starts at move $move or contains unverified setup; key moves and performance are unavailable.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return '⟦Move $move is illegal: $reason⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get ruleViolationWrongTurn => '⟦Wrong player to move⟧∼∼∼∼∼∼';

  @override
  String get ruleViolationOutOfBounds => '⟦Move is outside the board⟧∼∼∼∼∼∼∼∼';

  @override
  String get ruleViolationOccupied => '⟦The intersection is occupied⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get ruleViolationSuicide =>
      '⟦Suicide is not allowed by these rules⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get ruleViolationKo => '⟦The position violates the ko rule⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get exportOriginalRecord => '⟦Export original⟧∼∼∼∼∼';

  @override
  String get saveCurrentPosition => '⟦Save current position⟧∼∼∼∼∼∼∼';

  @override
  String get ruleChinese => '⟦Chinese rules⟧∼∼∼∼';

  @override
  String get ruleJapanese => '⟦Japanese rules⟧∼∼∼∼∼';

  @override
  String get ruleKorean => '⟦Korean rules⟧∼∼∼∼';

  @override
  String get ruleAga => '⟦AGA rules⟧∼∼∼';

  @override
  String get ruleNewZealand => '⟦New Zealand rules⟧∼∼∼∼∼∼';

  @override
  String get ruleTrompTaylor => '⟦Tromp-Taylor rules⟧∼∼∼∼∼∼';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '⟦$rules · $result · $moves⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get resultUnknown => '⟦Unknown result⟧∼∼∼∼∼';

  @override
  String get blackWins => '⟦Black wins⟧∼∼∼';

  @override
  String blackWinsBy(String points) {
    return '⟦Black wins by $points points⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get whiteWins => '⟦White wins⟧∼∼∼';

  @override
  String whiteWinsBy(String points) {
    return '⟦White wins by $points points⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get drawResult => '⟦Draw⟧∼∼';

  @override
  String get voidedResult => '⟦No result⟧∼∼∼';

  @override
  String get noAnalyzableKifu => '⟦No record to analyze⟧∼∼∼∼∼∼';

  @override
  String get selectAnalyzableKifu =>
      '⟦Choose a complete record or a confirmed position from the records screen.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get kifuNeedsConfirmation =>
      '⟦Record still needs confirmation⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get completeBeforeAnalysis =>
      '⟦Complete and validate the record before starting a full review.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get savePlayerToMoveFailed =>
      '⟦Could not save the player to move. Check available storage and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cancelAnalysisTitle => '⟦Cancel analysis?⟧∼∼∼∼∼';

  @override
  String get cancelAnalysisBody =>
      '⟦The current service request will stop immediately. You can start it again later.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get continueAnalysis => '⟦Continue analysis⟧∼∼∼∼∼∼';

  @override
  String get analyzeKifuTitle => '⟦Analyze record⟧∼∼∼∼∼';

  @override
  String get globalAnalysisRunning => '⟦Analyzing full game⟧∼∼∼∼∼∼';

  @override
  String get analysisQueuedTitle => '⟦Waiting for desktop engine⟧∼∼∼∼∼∼∼∼';

  @override
  String analysisQueuePosition(int position) {
    return '⟦Queue position $position · starts automatically after the current analysis⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return '⟦Queue #$position⟧∼∼∼∼∼∼';
  }

  @override
  String get statusQueued => '⟦Queued⟧∼∼';

  @override
  String get connectingAnalysisService =>
      '⟦Connecting to analysis service⟧∼∼∼∼∼∼∼∼∼';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '⟦$completed / $total positions⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get reviewGenerated => '⟦Review ready⟧∼∼∼∼';

  @override
  String get positionAnalysisComplete => '⟦Position analysis complete⟧∼∼∼∼∼∼∼∼';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '⟦$completed positions · $model⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get analysisInvalidResult =>
      '⟦The analysis service returned an invalid result.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisCancelled => '⟦Analysis cancelled⟧∼∼∼∼∼∼';

  @override
  String get incompleteResultsDiscarded =>
      '⟦Incomplete results were not kept⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String completedPositions(int count) {
    return '⟦$count positions complete⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get analysisServiceRequired => '⟦Analysis service required⟧∼∼∼∼∼∼∼∼';

  @override
  String get addWssServiceRetry =>
      '⟦Add a WSS KataGo service and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cancelAnalysisSemantics =>
      '⟦Cancel analysis. The in-app task continues after you leave this page⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get cancelQueuedAnalysisSemantics =>
      '⟦Cancel this queued analysis⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get openReview => '⟦Open review⟧∼∼∼∼';

  @override
  String get openKeyMoveReview => '⟦Open key-move review⟧∼∼∼∼∼∼';

  @override
  String get viewCandidates => '⟦View candidates⟧∼∼∼∼∼';

  @override
  String get viewPositionCandidates => '⟦View position candidates⟧∼∼∼∼∼∼∼∼';

  @override
  String get reanalyze => '⟦Analyze again⟧∼∼∼∼';

  @override
  String get sendBeforeConfirm => '⟦Confirm before sending⟧∼∼∼∼∼∼∼';

  @override
  String sendPositionToHost(String host) {
    return '⟦Send the current position to $host; the source photo is not uploaded.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String sendRecordToHost(String host) {
    return '⟦Send the complete record to $host for KataGo analysis.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get confirmAndStart => '⟦Confirm and start⟧∼∼∼∼∼∼';

  @override
  String get viewPrivacyBoundary => '⟦View privacy boundary⟧∼∼∼∼∼∼∼';

  @override
  String get katagoUnconfigured => '⟦KataGo is not configured⟧∼∼∼∼∼∼∼∼';

  @override
  String get katagoConfigDetail =>
      '⟦Import a trusted WSS analysis-service manifest. The access token stays in secure system storage.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get configureAnalysisService => '⟦Configure analysis service⟧∼∼∼∼∼∼∼∼';

  @override
  String get nextPlayerQuestion => '⟦Who plays next?⟧∼∼∼∼∼';

  @override
  String get photoNoTimingPlayerDetail =>
      '⟦A photo has no move timing. Confirm the player to move so candidate win rates have a defined perspective.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get creatingAnalysisTask => '⟦Creating analysis task⟧∼∼∼∼∼∼∼';

  @override
  String get validatingConfigKifu =>
      '⟦Validating configuration and record…⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisDataDestinationSubtitle =>
      '⟦Clear, controlled data destination⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analyzingPositionBoard =>
      '⟦Board for the position being analyzed⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '⟦$size by $size board being analyzed; $completed positions complete⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get statusNeedsConfiguration => '⟦Setup needed⟧∼∼∼∼';

  @override
  String get statusFailed => '⟦Failed⟧∼∼';

  @override
  String get statusCancelled => '⟦Cancelled⟧∼∼∼';

  @override
  String get analysisFailureCancel =>
      '⟦The analysis request could not be cancelled.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisFailureProviderCreation =>
      '⟦The analysis-service connection could not be created.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisFailureInvalidResult =>
      '⟦The analysis result failed validation.⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisFailureProvider =>
      '⟦The analysis service failed.⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisFailureStreamEnded =>
      '⟦The analysis connection ended before completion.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get analysisFailureRemote =>
      '⟦The analysis service could not complete the request.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get performanceSubtitle => '⟦Single-game performance⟧∼∼∼∼∼∼∼';

  @override
  String get performancePaneCore => '⟦Core⟧∼∼';

  @override
  String get performancePanePhases => '⟦Phases⟧∼∼';

  @override
  String get performancePaneSample => '⟦Sample⟧∼∼';

  @override
  String get confidenceMedium => '⟦Medium confidence⟧∼∼∼∼∼∼';

  @override
  String get confidenceLow => '⟦Low confidence⟧∼∼∼∼∼';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return '⟦Game performance estimate, $weak to $strong, $interval, $confidence, $decisions⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get performanceBoundarySemantics =>
      '⟦This result describes this game only, not long-term strength or a platform rank⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get performanceBoundaryCompact =>
      '⟦This game only, not long-term strength⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get performanceBoundaryFull =>
      '⟦This range describes this game only, not long-term strength or a platform rank.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get averagePointLoss => '⟦Average point loss⟧∼∼∼∼∼∼';

  @override
  String get pointLossLabel => '⟦Point loss⟧∼∼∼';

  @override
  String get severeMistake => '⟦Severe mistakes⟧∼∼∼∼∼';

  @override
  String get phaseOpening => '⟦Opening⟧∼∼∼';

  @override
  String get phaseMiddleGame => '⟦Middlegame⟧∼∼∼';

  @override
  String get phaseEndgame => '⟦Endgame⟧∼∼∼';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '⟦$phase · $loss · $moves⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '⟦$phase, average point loss $loss, $moves⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '⟦$board · $visits+ visits · $model⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get checkCompleteNineteen =>
      '⟦Complete non-handicap 19×19 record⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get checkMinimumDecisions =>
      '⟦At least 40 effective decisions⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get checkStandardDeepAnalysis =>
      '⟦Standard or deep full-game analysis⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get checkProductionCalibration =>
      '⟦Production calibration model⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get performanceUnavailableTitle =>
      '⟦Performance range unavailable⟧∼∼∼∼∼∼∼∼∼';

  @override
  String get performanceUnavailableBody =>
      '⟦No production calibration model has passed holdout-set coverage validation. Demo parameters will never be presented as a rank.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return '⟦Still verifiable: average point loss $loss · Top 3 $topThree⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get noCompleteReviewReturn =>
      '⟦No complete review data · Back⟧∼∼∼∼∼∼∼∼∼';

  @override
  String rankKyu(int value) {
    return '⟦$value kyu⟧∼∼∼∼';
  }

  @override
  String rankDan(int value) {
    return '⟦$value dan⟧∼∼∼∼';
  }

  @override
  String get positionAnalysisTitle => '⟦Position analysis⟧∼∼∼∼∼∼';

  @override
  String get positionAnalysisSubtitle =>
      '⟦Current position · No complete sequence⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String positionBoardSemantics(String player, int count) {
    return '⟦Position-analysis board, $player to play, $count candidates⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get staticPositionBoundarySemantics =>
      '⟦This position has no complete move sequence, so key moves and performance are unavailable⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get staticPositionBoundaryBody =>
      '⟦Only candidates and the current evaluation are analyzed; key moves, timeline, and performance are not shown.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return '⟦Candidate $label, $move, $score⟧∼∼∼∼∼∼∼∼∼∼∼';
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
    return '⟦Candidate $label, $move, $player win rate $winRate, Black score lead $score, $visits, main line $pv⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String playerWinRate(String player) {
    return '⟦$player win rate⟧∼∼∼∼∼∼';
  }

  @override
  String get principalVariationNone => '⟦Main line: none⟧∼∼∼∼∼';

  @override
  String principalVariationValue(String value) {
    return '⟦Main line  $value⟧∼∼∼∼∼∼';
  }

  @override
  String get noPlayableCandidate =>
      '⟦The service returned no playable candidate; only a pass may remain.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get positionDataExpired =>
      '⟦Position data is no longer available⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get positionNotAnalyzed =>
      '⟦This position has not been analyzed⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get realKatagoOnly =>
      '⟦Candidates, win rate, score lead, and visits show real KataGo results only.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get startAnalysis => '⟦Start analysis⟧∼∼∼∼∼';

  @override
  String get variationComparisonTitle => '⟦Compare variations⟧∼∼∼∼∼∼';

  @override
  String variationComparisonSubtitle(int move) {
    return '⟦Move $move · Played vs candidates⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return '⟦Variation comparison at move $move; candidate $candidate selected⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get noComparableCandidate => '⟦No candidate to compare⟧∼∼∼∼∼∼∼';

  @override
  String returnToMainLine(int move) {
    return '⟦Return to main line at move $move⟧∼∼∼∼∼∼∼∼∼∼∼';
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
    return '⟦Candidate $label, $move, win rate $winRate, Black score lead $score, $visits, main line $pv, played $played, point loss $loss⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return '⟦Played $move · $loss⟧∼∼∼∼∼∼∼';
  }

  @override
  String playedMoveValue(String move) {
    return '⟦Played $move⟧∼∼∼∼';
  }

  @override
  String get serviceNoPrincipalVariation =>
      '⟦The service did not provide a main line⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get realCandidateData => '⟦Real candidate data⟧∼∼∼∼∼∼';

  @override
  String get noVariationReturn => '⟦No variation data · Back⟧∼∼∼∼∼∼∼∼';

  @override
  String get bestCandidate => '⟦Best candidate⟧∼∼∼∼∼';

  @override
  String get candidateVariation => '⟦Candidate variation⟧∼∼∼∼∼∼';

  @override
  String reviewBoardSemantics(int move, int count) {
    return '⟦Review board at move $move, showing $count real candidates⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '⟦Move $move, $leader leads by $points points, $leader win rate $winRate⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String positionMetricCompact(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '⟦Move $move · $leader +$points · $winRate⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String positionMetricFull(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '⟦Move $move    $leader leads by $points points    $leader win rate $winRate⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get reviewTitle => '⟦Review⟧∼∼';

  @override
  String get completeAnalysisResults => '⟦Complete analysis results⟧∼∼∼∼∼∼∼∼';

  @override
  String get noCompletedReview => '⟦No completed review⟧∼∼∼∼∼∼';

  @override
  String get verifiedGlobalAnalysisOnly =>
      '⟦A key-move review requires complete, validated full-game analysis.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get tabletLandscapeHint =>
      '⟦Rotate the tablet to landscape for the two-column review⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String tabletBoardSemantics(int move, int count) {
    return '⟦Tablet review board at move $move, showing $count candidates⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get noReviewDataReturn =>
      '⟦No review data · Back to records⟧∼∼∼∼∼∼∼∼∼∼';

  @override
  String get quickReview => '⟦Quick review⟧∼∼∼∼';

  @override
  String get standardReview => '⟦Standard review⟧∼∼∼∼∼';

  @override
  String get deepReview => '⟦Deep review⟧∼∼∼∼';

  @override
  String regularMoveTitle(int move) {
    return '⟦Move $move⟧∼∼∼∼';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return '⟦Key move #$rank · Move $move⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '⟦$title, played to best $comparison, $detail⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get regularMoveBadge => '⟦Regular move⟧∼∼∼∼';

  @override
  String get lossRankBadge => '⟦Loss rank⟧∼∼∼';

  @override
  String get noCandidateData => '⟦No candidate data⟧∼∼∼∼∼∼';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '⟦$winRate · $score · $visits⟧∼∼∼∼∼∼∼∼∼';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return '⟦Best candidate $move, $detail⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String pvMoveCount(int moves) {
    return '⟦PV $moves moves⟧∼∼∼∼∼';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return '⟦Move $move · Black score lead $score · Black win rate $winRate⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get globalScoreTrend => '⟦Full-game score trend⟧∼∼∼∼∼∼∼';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return '⟦Average point loss $loss · Top 3 $topThree · Severe mistakes $severe⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return '⟦Game metrics, $detail; performance range requires a calibrated model⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get gameMetricsTitle => '⟦Game metrics⟧∼∼∼∼';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '⟦$moves moves · $keyMoves key moves⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get performanceNeedsCalibration => '⟦Calibration required⟧∼∼∼∼∼∼';

  @override
  String get boardCorrectionExpired =>
      '⟦Board-correction data is no longer available⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceCorrectionExpired =>
      '⟦Sequence-correction data is no longer available⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String autoRectifiedSubtitle(String board) {
    return '⟦Auto-rectified · $board⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get viewOriginal => '⟦View original⟧∼∼∼∼';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return '⟦Physical-board correction, $blackCount black stones, $whiteCount white stones, $pending intersections to confirm⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return '⟦Black $blackCount · White $whiteCount⟧∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get confirmCurrentPosition => '⟦Confirm current position⟧∼∼∼∼∼∼∼∼';

  @override
  String confirmRemaining(int count) {
    return '⟦Confirm $count remaining⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String get correctSequenceTitle => '⟦Correct sequence⟧∼∼∼∼∼';

  @override
  String numberedDetectedMoves(int moves) {
    return '⟦Numbered diagram · $moves moves recognized⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get sequenceValidatingSemantics =>
      '⟦Numbered-diagram correction, validating the complete sequence⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String sequenceIssueSemantics(int move) {
    return '⟦Numbered-diagram correction, move $move needs confirmation; choose an intersection⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get reuseAfterCapture => '⟦Reuse point after capture⟧∼∼∼∼∼∼∼∼';

  @override
  String get markPassMove => '⟦Mark this move as pass⟧∼∼∼∼∼∼∼';

  @override
  String selectMoveOnBoard(int move) {
    return '⟦Choose move $move on the board⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return '⟦Confirm move $move at $coordinate⟧∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get saveAsPositionFallback =>
      '⟦Sequence cannot be recovered; save current position⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueNoFirst =>
      '⟦Move 1 was not recognized. Choose its position or mark it as pass.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueMissing =>
      '⟦A number is missing. Choosing its intersection replaces the incorrect number at that point.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueOcr =>
      '⟦OCR confidence is low. Confirm the position.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueColor =>
      '⟦Stone color does not match move-number parity. Confirm the position.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueFinalMismatch =>
      '⟦The recovered sequence does not match the recognized final board. Check the marked position.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueTooMany =>
      '⟦The numbered sequence exceeds the safe processing limit.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueDuplicate =>
      '⟦The same move number appears more than once. Check the markers.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceIssueIllegal =>
      '⟦The sequence violates the Go rules. Check the marked position.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceValidationFailed =>
      '⟦Sequence validation failed. Check the markers and try again.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get validatingGoRules => '⟦Validating with Go rules⟧∼∼∼∼∼∼∼∼';

  @override
  String moveCannotConfirm(String move) {
    return '⟦Move $move cannot be confirmed⟧∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get checkingSequenceRules =>
      '⟦Checking number continuity, captures, ko, and point reuse.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get sequenceVerifiedTitle => '⟦Sequence verified⟧∼∼∼∼∼∼';

  @override
  String get sequenceVerifiedSubtitle =>
      '⟦Continuous numbering · Go rules passed⟧∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return '⟦Verified complete $size by $size record with $moves moves⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get saveAndStartReview => '⟦Save and start review⟧∼∼∼∼∼∼∼';

  @override
  String rescanWithReason(String reason) {
    return '⟦$reason · Scan again⟧∼∼∼∼∼∼∼';
  }

  @override
  String get originalImageUnavailable =>
      '⟦Original image cannot be displayed⟧∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get scanResultTitle => '⟦Recognition result⟧∼∼∼∼∼∼';

  @override
  String scanResultSubtitle(String board) {
    return '⟦Current position · $board⟧∼∼∼∼∼∼∼∼';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return '⟦Recognized $size by $size Go position with $blackCount black stones and $whiteCount white stones⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get boardRecognitionComplete => '⟦Board recognition complete⟧∼∼∼∼∼∼∼∼';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return '⟦Current position recognized: $blackCount black stones and $whiteCount white stones.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';
  }

  @override
  String get photoNoSequence =>
      '⟦A single photo has no move timing, so a complete sequence cannot be recovered. This position has no key-move timeline or performance estimate.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get nextPlayerLabel => '⟦Next player⟧∼∼∼∼';

  @override
  String get chooseNextPlayerFirst => '⟦Choose next player⟧∼∼∼∼∼∼';

  @override
  String get analyzeCurrentPosition => '⟦Analyze position⟧∼∼∼∼∼';

  @override
  String get savePosition => '⟦Save position⟧∼∼∼∼';

  @override
  String get savePositionAnalysisFailed =>
      '⟦Save failed. Analysis of this position has not started.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get scanResultExpired =>
      '⟦Recognition result is no longer available⟧∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get scanResultExpiredDetail =>
      '⟦Return to board scanning and take or choose another photo.⟧∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼∼';

  @override
  String get returnToScan => '⟦Back to board scanning⟧∼∼∼∼∼∼∼';
}

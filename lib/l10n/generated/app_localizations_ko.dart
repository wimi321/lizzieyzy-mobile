// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'LizzieYZY Mobile';

  @override
  String get portraitGuardSemantics =>
      '휴대전화에서는 세로 화면을 사용하세요. 태블릿은 가로 화면도 지원합니다';

  @override
  String get portraitGuardTitle => '세로 화면으로 돌려 주세요';

  @override
  String get portraitGuardBody => '바둑판, 수치, 조작을 세로 화면 안에 모두 표시합니다';

  @override
  String get kifuTab => '기보';

  @override
  String get kifuHomeTooltip => '기보 목록';

  @override
  String get scanTab => '판 인식';

  @override
  String get photoScanTooltip => '바둑판 촬영 인식';

  @override
  String get homeSubtitle => 'LIZZIEYZY · 한 판씩 정확하게 복기';

  @override
  String get importKifuTooltip => '기보 가져오기';

  @override
  String get settingsTooltip => '설정';

  @override
  String get back => '뒤로';

  @override
  String get recentKifu => '최근 기보';

  @override
  String get statusVerified => '검증됨';

  @override
  String get statusNeedsConfirmation => '확인 필요';

  @override
  String get statusCurrentPosition => '현재 국면';

  @override
  String get blackPlayerFallback => '흑';

  @override
  String get whitePlayerFallback => '백';

  @override
  String get completeKifu => '완전한 기보';

  @override
  String get partialKifu => '부분 기보';

  @override
  String get photoPosition => '사진 국면';

  @override
  String get justImported => '방금 가져옴';

  @override
  String get photoScanSemantics => '카메라를 열어 바둑판 인식';

  @override
  String get photoScanTitle => '바둑판 촬영';

  @override
  String get photoScanSubtitle => '실물 바둑판 · 수순 번호 기보 이미지';

  @override
  String get emptyKifuLibrary =>
      '기보가 없습니다. SGF / GIB를 가져오거나 사진에서 현재 국면을 저장하세요.';

  @override
  String get importFirstKifu => '첫 기보 가져오기';

  @override
  String inboundImported(String fileName) {
    return '시스템 공유에서 기보를 가져왔습니다: $fileName';
  }

  @override
  String inboundImportedWithWarnings(String fileName, String warnings) {
    return '$fileName 가져옴 · $warnings';
  }

  @override
  String inboundOpen(String fileName) {
    return '가져온 기보 열기: $fileName';
  }

  @override
  String get sharedKifuFallback => '공유된 기보';

  @override
  String get inboundInvalidFile => '공유된 기보가 올바르지 않아 가져오지 못했습니다.';

  @override
  String get inboundStorageFailure => '공유된 기보를 저장하지 못했습니다. 여유 공간을 확인하세요.';

  @override
  String get inboundPlatformFailure => '시스템 공유에서 기보를 읽지 못했습니다. 다시 시도하세요.';

  @override
  String get dismissNotice => '알림 닫기';

  @override
  String playerPair(String blackPlayer, String whitePlayer) {
    return '$blackPlayer · $whitePlayer';
  }

  @override
  String moveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count수',
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
    return '$blackPlayer 대 $whitePlayer, $result, $moves, $status';
  }

  @override
  String get importKifuTitle => '기보 가져오기';

  @override
  String get importKifuSubtitle => 'SGF / GIB · 기기 내 검증';

  @override
  String get chooseKifuTitle => 'SGF 또는 GIB 기보 선택';

  @override
  String get chooseKifuBody =>
      '먼저 형식과 바둑 규칙을 검증합니다. 누락된 기록은 명확히 구분하며 완전한 기보로 표시하지 않습니다.';

  @override
  String get chooseKifuFile => '기보 파일 선택';

  @override
  String get validatingKifu => '기보 검증 중…';

  @override
  String get importFailed => '가져오기 실패';

  @override
  String get chooseAgain => '다시 선택';

  @override
  String get saveKifuFailed => '저장하지 못했습니다. 여유 공간을 확인하고 다시 시도하세요.';

  @override
  String get kifuReadFailed => '기보를 읽지 못했습니다.';

  @override
  String verifiedRecordDetail(String moves) {
    return '$moves · 규칙 검증 완료';
  }

  @override
  String partialRecordDetail(String moves) {
    return '$moves · 수동 확인 필요';
  }

  @override
  String stoneCounts(int blackCount, int whiteCount) {
    return '흑 $blackCount개 · 백 $whiteCount개';
  }

  @override
  String get warning => '경고';

  @override
  String get fileEncoding => '파일 인코딩';

  @override
  String legacyGibEncodingDetected(String encoding) {
    return '레거시 GIB 인코딩 감지: $encoding';
  }

  @override
  String warningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개',
    );
    return '$_temp0';
  }

  @override
  String get addedToKifu => '기보에 추가됨';

  @override
  String get addToKifu => '기보에 추가';

  @override
  String get importAnother => '다른 기보 가져오기';

  @override
  String get importErrorResourceLimit => '기보가 안전 처리 한도를 초과합니다. 더 작은 파일을 선택하세요.';

  @override
  String get importErrorInvalidEncoding =>
      '기보 텍스트 인코딩이 잘못되었거나 모호합니다. SGF는 UTF-8만 지원합니다.';

  @override
  String get importErrorUnsupportedFormat => '.sgf 및 .gib 기보만 지원합니다.';

  @override
  String get importErrorInvalidRecord => '기보 형식 또는 수순이 올바르지 않습니다. 파일을 확인하세요.';

  @override
  String get importErrorUnknown => '기보를 읽지 못했습니다. 파일이 손상되지 않았는지 확인하세요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '기기 우선 · 추적 가능한 구성';

  @override
  String get analysisServiceTitle => '분석 서비스';

  @override
  String get analysisServiceUnconfigured => '설정 안 됨 · 기보를 보내지 않음';

  @override
  String analysisServiceConfigured(String model) {
    return '$model · WSS';
  }

  @override
  String get appearanceTitle => '화면 모드';

  @override
  String get languageTitle => '언어';

  @override
  String get privacyOpenSourceTitle => '개인정보 및 오픈 소스';

  @override
  String get privacyOpenSourceDetail => '데이터 경계 · 라이선스 · 보안 신고';

  @override
  String get appVersionSemantics =>
      'LizzieYZY Mobile 버전 0.1.0, 오픈 소스 라이선스 MPL 2.0';

  @override
  String get appVersionLabel => 'LizzieYZY Mobile · 0.1.0 · MPL-2.0';

  @override
  String get analysisShortcutConfigured => '분석 서비스\n설정됨';

  @override
  String get analysisShortcutUnconfigured => '분석 서비스\n미설정';

  @override
  String get privacyShortcut => '개인정보 및\n오픈 소스';

  @override
  String get appearanceSubtitle => '시스템 설정 및 고대비 모드';

  @override
  String get languageSubtitle => '앱과 시스템 컨트롤 언어';

  @override
  String get themeSystem => '시스템 설정';

  @override
  String get themeLight => '라이트';

  @override
  String get themeDark => '다크';

  @override
  String get localeSystem => '시스템 설정';

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
  String get analysisServiceSubtitle => 'WSS · 인증 정보는 시스템 보안 저장소에 보관';

  @override
  String get accessTokenOptional => '액세스 토큰(선택)';

  @override
  String get tokenSecureStorageHelper => 'Keychain / Keystore에만 저장';

  @override
  String get hideToken => '토큰 숨기기';

  @override
  String get showToken => '토큰 표시';

  @override
  String get hideAccessToken => '액세스 토큰 숨기기';

  @override
  String get showAccessToken => '액세스 토큰 표시';

  @override
  String get confirmEverySend => '보낼 때마다 확인';

  @override
  String get remoteAnalysisSendsFullKifu => '원격 분석은 전체 기보를 전송합니다';

  @override
  String get settingsSaveFailedRetry => '저장하지 못했습니다. 다시 시도하세요.';

  @override
  String get removeService => '서비스 제거';

  @override
  String get saveConfiguration => '구성 저장';

  @override
  String get connectionTab => '연결';

  @override
  String get reviewTab => '복기';

  @override
  String get tokenLabel => '토큰';

  @override
  String get confirmBeforeSend => '전송 전 확인';

  @override
  String get settingsSaveFailed => '저장 실패';

  @override
  String get saving => '저장 중';

  @override
  String get save => '저장';

  @override
  String get analysisManifestFileType => 'LizzieYZY 분석 서비스 매니페스트';

  @override
  String get manifestTooLarge => '서비스 매니페스트는 64 KB 이하여야 합니다.';

  @override
  String get manifestReadFailed => '서비스 매니페스트를 읽지 못했습니다.';

  @override
  String get removeAnalysisServiceTitle => '분석 서비스를 제거할까요?';

  @override
  String get removeAnalysisServiceBody => '서비스 주소와 시스템 보안 저장소의 액세스 토큰이 삭제됩니다.';

  @override
  String get keep => '유지';

  @override
  String get remove => '제거';

  @override
  String get manifestNotImported => '서비스 매니페스트를 가져오지 않음';

  @override
  String get manifestPurpose => '매니페스트가 서비스 주소, 모델 해시, 승률 시점을 고정합니다';

  @override
  String manifestConfiguredDetail(String host, String engineVersion) {
    return '$host · $engineVersion';
  }

  @override
  String get notConfigured => '설정 안 됨';

  @override
  String get importAction => '가져오기';

  @override
  String get replace => '교체';

  @override
  String get removeAnalysisServiceTooltip => '분석 서비스 제거';

  @override
  String get importManifestTooltip => '서비스 매니페스트 가져오기';

  @override
  String get replaceManifestTooltip => '서비스 매니페스트 교체';

  @override
  String get reviewDepth => '복기 깊이';

  @override
  String get analysisQuick => '빠르게';

  @override
  String get analysisStandard => '표준';

  @override
  String get analysisDeep => '깊게';

  @override
  String analysisProfileWithVisits(String profile, int visits) {
    final intl.NumberFormat visitsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String visitsString = visitsNumberFormat.format(visits);

    return '$profile · 수당 $visitsString회 탐색';
  }

  @override
  String get privacySubtitle => '데이터의 목적지를 검증할 수 있어야 합니다';

  @override
  String get privacyLocalTab => '기기';

  @override
  String get privacyRemoteTab => '원격';

  @override
  String get privacyOpenSourceTab => '오픈 소스';

  @override
  String get privacyLocalTitle => '기본적으로 기기에서만 처리';

  @override
  String get privacyLocalFact1 => '판 인식 화면을 열 때만 카메라 권한을 요청합니다.';

  @override
  String get privacyLocalFact2 => '사진, 기보, 교정 결과는 앱 전용 디렉터리에 보관합니다.';

  @override
  String get privacyLocalFact3 => '광고, 계정, 소셜 기능, 행동 추적 SDK가 없습니다.';

  @override
  String get privacyRemoteTitle => '원격 분석은 사용자가 결정';

  @override
  String get privacyRemoteFact1 => '원격 복기를 직접 시작할 때만 전체 기보를 전송합니다.';

  @override
  String get privacyRemoteFact2 => '직접 가져와 승인한 WSS 서비스에만 전송합니다.';

  @override
  String get privacyRemoteFact3 => '액세스 토큰은 Keychain / Keystore에만 저장합니다.';

  @override
  String get privacyOpenSourcePanelTitle => '코드와 모델 경계를 공개';

  @override
  String get privacyOpenSourceFact1 => '앱 소스 코드는 MPL-2.0을 따릅니다.';

  @override
  String get privacyOpenSourceFact2 => '모델, 데이터, 글꼴은 라이선스와 SHA-256을 기록해야 합니다.';

  @override
  String get privacyOpenSourceFact3 =>
      '보안 문제는 저장소의 SECURITY.md를 통해 비공개로 신고하세요.';

  @override
  String get privacyPreviousFact => '이전 항목';

  @override
  String get privacyNextFact => '다음 항목';

  @override
  String privacyPanelSemantics(String title, String facts) {
    return '$title. $facts';
  }

  @override
  String get licenses => '라이선스';

  @override
  String get viewThirdPartyLicenses => '서드 파티 라이선스 보기';

  @override
  String get privacyPromiseSemantics => '개인정보 보호 약속: 필수 계정, 광고, 코인, 자동 업로드 없음';

  @override
  String get privacyPromise => '필수 계정 없음 · 광고 없음 · 코인 없음 · 자동 업로드 없음';

  @override
  String get closeCamera => '카메라 닫기';

  @override
  String get cameraViewfinderSemantics => '카메라 촬영 영역. 19로 바둑판 전체를 프레임 안에 맞추세요';

  @override
  String get startingCamera => '카메라 시작 중…';

  @override
  String recognizingIntersections(int count) {
    return '교차점 $count개 인식 중…';
  }

  @override
  String get cameraTemporarilyUnavailable => '카메라를 잠시 사용할 수 없습니다';

  @override
  String get retry => '다시 시도';

  @override
  String get photoLibrary => '사진';

  @override
  String get capturePhoto => '촬영';

  @override
  String get captureHelp => '촬영 도움말';

  @override
  String get alignmentReady => '바둑판 전체가 프레임 안에 있음 · 움직이지 마세요';

  @override
  String get alignmentRecognizing => '인식 중 · 화면을 벗어나지 마세요';

  @override
  String get alignmentFallback => '사진에서 계속할 수 있습니다';

  @override
  String get alignmentPreparing => '촬영 화면 준비 중';

  @override
  String get captureHelpTitle => '바둑판 전체 촬영';

  @override
  String get captureHelpBody =>
      '네 모서리를 모두 초록색 프레임 안에 맞추고 카메라를 바둑판 정면에 두며 바둑돌의 강한 반사를 피하세요.';

  @override
  String get gotIt => '확인';

  @override
  String get flashAutomatic => '플래시, 자동';

  @override
  String get flashOff => '플래시, 끔';

  @override
  String get flashOn => '플래시, 켬';

  @override
  String get cameraPermissionDenied =>
      '카메라 접근이 거부되었습니다. 시스템 설정에서 허용하거나 사진을 사용하세요.';

  @override
  String get cameraRestricted => '이 기기에서 카메라 접근이 제한되었습니다. 사진을 사용하세요.';

  @override
  String get cameraUnavailable => '카메라를 사용할 수 없습니다. 다시 시도하거나 사진을 사용하세요.';

  @override
  String get cameraCaptureFailed => '촬영하지 못했습니다. 기기를 안정적으로 잡고 다시 시도하세요.';

  @override
  String get photoLibraryPermissionDenied =>
      '사진 접근이 거부되었습니다. 시스템 설정에서 사진 접근을 허용하세요.';

  @override
  String get photoLibraryUnavailable => '사진을 열지 못했습니다. 잠시 후 다시 시도하세요.';

  @override
  String get selectedImageUnreadable =>
      '선택한 이미지를 읽지 못했습니다. 바둑판 전체가 선명한 사진을 선택하세요.';

  @override
  String get recognitionIncompleteBoard =>
      '바둑판 전체를 인식하지 못했습니다. 네 모서리를 프레임에 맞추고 조명을 고르게 한 뒤 다시 시도하세요.';

  @override
  String get recognitionFailed => '인식에 실패했습니다. 바둑판 전체가 선명하게 보이도록 하고 다시 시도하세요.';

  @override
  String get useGuideFallback => '가이드로 다시 인식';

  @override
  String get guideFallbackDetail => '같은 촬영 프레임을 사용해 바둑판 가이드에 맞춰 다시 인식합니다.';

  @override
  String get guideFallbackRecognizing => '가이드로 다시 인식 중…';

  @override
  String get pageNotFound => '페이지를 찾을 수 없습니다';

  @override
  String get returnToKifu => '기보로 돌아가기';

  @override
  String get cancelAction => '취소';

  @override
  String get closeAction => '닫기';

  @override
  String get openAction => '열기';

  @override
  String get pauseAction => '일시 정지';

  @override
  String get resumeAction => '계속';

  @override
  String get shareKifu => '기보 내보내기';

  @override
  String get shareOpened => '시스템 공유를 열었습니다';

  @override
  String get shareNoTarget => '이 기기에 사용할 수 있는 공유 대상이 없습니다';

  @override
  String get shareUnavailable => '시스템 공유를 열 수 없습니다.';

  @override
  String get preparing => '준비 중';

  @override
  String get blackStoneShort => '흑';

  @override
  String get whiteStoneShort => '백';

  @override
  String get blackStoneLabel => '흑돌';

  @override
  String get whiteStoneLabel => '백돌';

  @override
  String get semanticSeparator => ', ';

  @override
  String get emptyPoint => '빈점';

  @override
  String get unclearPoint => '불명확';

  @override
  String get passMove => '통과';

  @override
  String pointsValue(String value) {
    return '$value집';
  }

  @override
  String pointLossValue(String value) {
    return '−$value집';
  }

  @override
  String visitsValue(String value) {
    return '$value회 탐색';
  }

  @override
  String moveOrdinal(int move) {
    return '제$move수';
  }

  @override
  String effectiveDecisionCount(int count) {
    return '유효 판단 $count수';
  }

  @override
  String boardDimension(int size) {
    return '$size로';
  }

  @override
  String coverageInterval(int coverage) {
    return '$coverage% 구간';
  }

  @override
  String get winRateLabel => '승률';

  @override
  String get scoreLeadLabel => '집 차이';

  @override
  String get blackScoreLeadLabel => '흑 기준 집 차이';

  @override
  String get visitsLabel => '탐색';

  @override
  String get playedMoveLabel => '실전';

  @override
  String get principalVariationLabel => '주요 변화';

  @override
  String get noneLabel => '없음';

  @override
  String get analysisDefaultTitle => '표준 분석';

  @override
  String get analysisContinuesInApp => '이 페이지를 나가도 앱 안에서 분석이 계속됩니다';

  @override
  String get analysisProgressLabel => '분석 진행률';

  @override
  String get analysisRunning => '분석 중';

  @override
  String get analysisPaused => '일시 정지됨';

  @override
  String get analysisCompleted => '완료';

  @override
  String get analysisFailed => '분석 실패';

  @override
  String candidateSemantics(String label) {
    return '후보 $label';
  }

  @override
  String candidateSemanticsWithDetail(String label, String detail) {
    return '후보 $label, $detail';
  }

  @override
  String get correctBoardTitle => '바둑판 교정';

  @override
  String intersectionCoordinate(String coordinate) {
    return '교차점 $coordinate';
  }

  @override
  String get confirmed => '확인됨';

  @override
  String pendingConfirmation(int count) {
    return '확인 대기 $count개';
  }

  @override
  String get pendingLabel => '확인 대기';

  @override
  String markStone(String choice) {
    return '$choice(으)로 표시';
  }

  @override
  String stoneChoiceSemantics(String choice) {
    return '$choice 돌';
  }

  @override
  String get goBoardLabel => '바둑판';

  @override
  String get moveLeft => '왼쪽으로 이동';

  @override
  String get moveRight => '오른쪽으로 이동';

  @override
  String get moveUp => '위로 이동';

  @override
  String get moveDown => '아래로 이동';

  @override
  String get noLastMove => '마지막 수 표시 없음';

  @override
  String lastMoveAt(String coordinate) {
    return '마지막 수 $coordinate';
  }

  @override
  String get noCandidatePoints => '후보 지점 없음';

  @override
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  ) {
    return '$size로, 흑돌 $blackCount개, 백돌 $whiteCount개, $lastMove, $candidates. 현재 교차점 $coordinate';
  }

  @override
  String get boardNavigationHint => '사용자 지정 방향 동작으로 교차점 사이를 이동하세요';

  @override
  String get boardNavigationSelectHint => '사용자 지정 방향 동작으로 이동하고 두 번 탭하여 선택하세요';

  @override
  String playerVersus(String blackPlayer, String whitePlayer) {
    return '$blackPlayer 대 $whitePlayer';
  }

  @override
  String playerColorsSemantics(String blackPlayer, String whitePlayer) {
    return '흑 $blackPlayer, 백 $whitePlayer';
  }

  @override
  String get kifuReviewed => '복기 완료';

  @override
  String get kifuAnalyzing => '분석 중';

  @override
  String get kifuNotReviewed => '미복기';

  @override
  String get kifuNeedsAction => '확인 필요';

  @override
  String get timelineLabel => '수순';

  @override
  String timelineSemantics(String label, int current, int total) {
    return '$label, 전체 $total수 중 제$current수';
  }

  @override
  String get previousMove => '이전 수';

  @override
  String get nextMove => '다음 수';

  @override
  String sliderMoveSemantics(int current, int total) {
    return '전체 $total수 중 제$current수';
  }

  @override
  String get gamePerformanceEstimate => '이번 판 경기력 추정';

  @override
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  ) {
    return '$title, $lowerRank부터 $upperRank, 80% 구간, $confidence, $decisions';
  }

  @override
  String get reviewKeyMoves => '핵심 수';

  @override
  String get reviewVariations => '변화';

  @override
  String get reviewTrend => '추이';

  @override
  String get reviewGame => '이번 판';

  @override
  String get reviewPanel => '복기 패널';

  @override
  String tabSemantics(String label) {
    return '$label 탭';
  }

  @override
  String get selectFromPhotos => '사진에서 선택';

  @override
  String get scoreTrend => '집 차이 추이';

  @override
  String get noData => '데이터 없음';

  @override
  String blackLeads(String points) {
    return '흑이 $points집 앞섬';
  }

  @override
  String whiteLeads(String points) {
    return '백이 $points집 앞섬';
  }

  @override
  String scoreChartSemantics(String label, String direction) {
    return '$label, $direction';
  }

  @override
  String scoreChartMoveSemantics(String label, String direction, int move) {
    return '$label, $direction, 현재 제$move수';
  }

  @override
  String get partialRecordExpired => '부분 기보를 더 이상 사용할 수 없습니다';

  @override
  String get partialTrustBoundary => '신뢰 경계 · 완전한 대국이 아님';

  @override
  String partialBoardSemantics(int moves) {
    return '부분 기보의 유효한 앞부분 $moves수. 전체 복기는 제공되지 않습니다';
  }

  @override
  String partialUnproven(int move) {
    return '기보가 제$move수부터 시작하거나 검증할 수 없는 배치를 포함하므로 핵심 수와 경기력을 제공하지 않습니다.';
  }

  @override
  String partialIllegalMove(int move, String reason) {
    return '제$move수는 둘 수 없습니다: $reason';
  }

  @override
  String get ruleViolationWrongTurn => '차례가 올바르지 않습니다';

  @override
  String get ruleViolationOutOfBounds => '바둑판 밖에 둔 수입니다';

  @override
  String get ruleViolationOccupied => '교차점에 이미 돌이 있습니다';

  @override
  String get ruleViolationSuicide => '이 규칙에서는 자충수를 허용하지 않습니다';

  @override
  String get ruleViolationKo => '패 규칙을 위반한 국면입니다';

  @override
  String get exportOriginalRecord => '원본 기보 내보내기';

  @override
  String get saveCurrentPosition => '현재 국면 저장';

  @override
  String get ruleChinese => '중국식 규칙';

  @override
  String get ruleJapanese => '일본식 규칙';

  @override
  String get ruleKorean => '한국식 규칙';

  @override
  String get ruleAga => 'AGA 규칙';

  @override
  String get ruleNewZealand => '뉴질랜드 규칙';

  @override
  String get ruleTrompTaylor => 'Tromp-Taylor 규칙';

  @override
  String reviewSubtitle(String rules, String result, String moves) {
    return '$rules · $result · $moves';
  }

  @override
  String get resultUnknown => '결과 미상';

  @override
  String get blackWins => '흑 승';

  @override
  String blackWinsBy(String points) {
    return '흑 $points집 승';
  }

  @override
  String get whiteWins => '백 승';

  @override
  String whiteWinsBy(String points) {
    return '백 $points집 승';
  }

  @override
  String get drawResult => '무승부';

  @override
  String get voidedResult => '무효 대국';

  @override
  String get noAnalyzableKifu => '분석할 기보가 없습니다';

  @override
  String get selectAnalyzableKifu => '기보 화면에서 완전한 기보 또는 확인된 현재 국면을 선택하세요.';

  @override
  String get kifuNeedsConfirmation => '기보 확인이 필요합니다';

  @override
  String get completeBeforeAnalysis => '기보를 보완하고 규칙 검증을 통과한 뒤 전체 복기를 시작하세요.';

  @override
  String get savePlayerToMoveFailed =>
      '다음 차례를 저장하지 못했습니다. 저장 공간을 확인하고 다시 시도하세요.';

  @override
  String get cancelAnalysisTitle => '분석을 취소할까요?';

  @override
  String get cancelAnalysisBody => '현재 서비스 요청이 즉시 중단됩니다. 나중에 다시 시작할 수 있습니다.';

  @override
  String get continueAnalysis => '분석 계속';

  @override
  String get analyzeKifuTitle => '기보 분석';

  @override
  String get globalAnalysisRunning => '전체 대국 분석 중';

  @override
  String get analysisQueuedTitle => '데스크톱 엔진 대기 중';

  @override
  String analysisQueuePosition(int position) {
    return '대기열 $position번째 · 현재 분석이 끝나면 자동 시작';
  }

  @override
  String analysisQueuePositionCompact(int position) {
    return '대기 #$position';
  }

  @override
  String get statusQueued => '대기 중';

  @override
  String get connectingAnalysisService => '분석 서비스 연결 중';

  @override
  String analyzedPositionProgress(int completed, int total) {
    return '$completed / $total 국면';
  }

  @override
  String get reviewGenerated => '복기가 준비되었습니다';

  @override
  String get positionAnalysisComplete => '국면 분석 완료';

  @override
  String analyzedPositionsWithModel(int completed, String model) {
    return '$completed개 국면 · $model';
  }

  @override
  String get analysisInvalidResult => '분석 서비스가 잘못된 결과를 반환했습니다.';

  @override
  String get analysisCancelled => '분석 취소됨';

  @override
  String get incompleteResultsDiscarded => '불완전한 결과는 보관하지 않았습니다';

  @override
  String completedPositions(int count) {
    return '$count개 국면 완료';
  }

  @override
  String get analysisServiceRequired => '분석 서비스 설정 필요';

  @override
  String get addWssServiceRetry => 'WSS KataGo 서비스를 추가하고 다시 시도하세요.';

  @override
  String get cancelAnalysisSemantics => '분석 취소. 이 페이지를 나가도 앱 안의 작업은 계속됩니다';

  @override
  String get cancelQueuedAnalysisSemantics => '이 대기 중인 분석 취소';

  @override
  String get openReview => '복기 열기';

  @override
  String get openKeyMoveReview => '핵심 수 복기 열기';

  @override
  String get viewCandidates => '후보 보기';

  @override
  String get viewPositionCandidates => '국면 후보 보기';

  @override
  String get reanalyze => '다시 분석';

  @override
  String get sendBeforeConfirm => '전송 전 확인';

  @override
  String sendPositionToHost(String host) {
    return '현재 국면을 $host에 전송합니다. 원본 사진은 업로드하지 않습니다.';
  }

  @override
  String sendRecordToHost(String host) {
    return '전체 기보를 $host에 전송해 KataGo 분석을 진행합니다.';
  }

  @override
  String get confirmAndStart => '확인 후 시작';

  @override
  String get viewPrivacyBoundary => '개인정보 경계 보기';

  @override
  String get katagoUnconfigured => 'KataGo가 설정되지 않았습니다';

  @override
  String get katagoConfigDetail =>
      '신뢰할 수 있는 WSS 분석 서비스 매니페스트를 가져오세요. 액세스 토큰은 시스템 보안 저장소에만 보관됩니다.';

  @override
  String get configureAnalysisService => '분석 서비스 설정';

  @override
  String get nextPlayerQuestion => '다음은 누구 차례인가요?';

  @override
  String get photoNoTimingPlayerDetail =>
      '사진에는 착수 시간이 없습니다. 후보 승률의 관점을 정하려면 다음 차례를 확인해야 합니다.';

  @override
  String get creatingAnalysisTask => '분석 작업 생성 중';

  @override
  String get validatingConfigKifu => '설정과 기보 확인 중…';

  @override
  String get analysisDataDestinationSubtitle => '데이터 목적지를 명확하게 제어';

  @override
  String get analyzingPositionBoard => '분석 중인 현재 국면 바둑판';

  @override
  String analyzingRecordBoard(int size, int completed) {
    return '분석 중인 $size로 바둑판, $completed개 국면 완료';
  }

  @override
  String get statusNeedsConfiguration => '설정 필요';

  @override
  String get statusFailed => '실패';

  @override
  String get statusCancelled => '취소됨';

  @override
  String get analysisFailureCancel => '분석 요청을 취소하지 못했습니다.';

  @override
  String get analysisFailureProviderCreation => '분석 서비스 연결을 만들지 못했습니다.';

  @override
  String get analysisFailureInvalidResult => '분석 결과가 검증을 통과하지 못했습니다.';

  @override
  String get analysisFailureProvider => '분석 서비스에 오류가 발생했습니다.';

  @override
  String get analysisFailureStreamEnded => '완료 전에 분석 연결이 종료되었습니다.';

  @override
  String get analysisFailureRemote => '분석 서비스가 요청을 완료하지 못했습니다.';

  @override
  String get performanceSubtitle => '단일 대국 경기력 평가';

  @override
  String get performancePaneCore => '핵심';

  @override
  String get performancePanePhases => '단계';

  @override
  String get performancePaneSample => '표본';

  @override
  String get confidenceMedium => '중간 신뢰도';

  @override
  String get confidenceLow => '낮은 신뢰도';

  @override
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  ) {
    return '이번 판 경기력 추정, $weak부터 $strong, $interval, $confidence, $decisions';
  }

  @override
  String get performanceBoundarySemantics =>
      '이 결과는 이번 한 판의 경기력만 나타내며 장기 기력이나 플랫폼 급수가 아닙니다';

  @override
  String get performanceBoundaryCompact => '이번 판만 해당, 장기 기력 아님';

  @override
  String get performanceBoundaryFull =>
      '이 범위는 이번 한 판의 경기력만 나타내며 장기 기력이나 플랫폼 급수가 아닙니다.';

  @override
  String get averagePointLoss => '평균 집 손실';

  @override
  String get pointLossLabel => '집 손실';

  @override
  String get severeMistake => '심각한 실수';

  @override
  String get phaseOpening => '포석';

  @override
  String get phaseMiddleGame => '중반';

  @override
  String get phaseEndgame => '끝내기';

  @override
  String phaseMetric(String phase, String loss, String moves) {
    return '$phase · $loss · $moves';
  }

  @override
  String phaseMetricSemantics(String phase, String loss, String moves) {
    return '$phase, 평균 집 손실 $loss, $moves';
  }

  @override
  String analysisSampleDetail(String board, int visits, String model) {
    return '$board · $visits+회 탐색 · $model';
  }

  @override
  String get checkCompleteNineteen => '완전한 19로 비접바둑 기보';

  @override
  String get checkMinimumDecisions => '유효 판단 40수 이상';

  @override
  String get checkStandardDeepAnalysis => '표준 또는 심층 전체 분석';

  @override
  String get checkProductionCalibration => '프로덕션 보정 모델';

  @override
  String get performanceUnavailableTitle => '기력 구간을 표시할 수 없습니다';

  @override
  String get performanceUnavailableBody =>
      '별도 검증 세트에서 포함률을 확인한 프로덕션 보정 모델이 없습니다. 데모 값을 급수처럼 표시하지 않습니다.';

  @override
  String verifiableMetrics(String loss, String topThree) {
    return '현재 검증 가능: 평균 집 손실 $loss · Top 3 $topThree';
  }

  @override
  String get noCompleteReviewReturn => '완전한 복기 데이터 없음 · 돌아가기';

  @override
  String rankKyu(int value) {
    return '$value급';
  }

  @override
  String rankDan(int value) {
    return '$value단';
  }

  @override
  String get positionAnalysisTitle => '국면 분석';

  @override
  String get positionAnalysisSubtitle => '현재 국면 · 완전한 수순 없음';

  @override
  String positionBoardSemantics(String player, int count) {
    return '국면 분석 바둑판, $player 차례, 후보 $count개';
  }

  @override
  String get staticPositionBoundarySemantics =>
      '이 국면에는 완전한 수순이 없어 핵심 수와 경기력을 제공하지 않습니다';

  @override
  String get staticPositionBoundaryBody =>
      '현재 후보와 형세만 분석하며 핵심 수, 수순 축, 경기력은 표시하지 않습니다.';

  @override
  String candidateChoiceSemantics(String label, String move, String score) {
    return '후보 $label, $move, $score';
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
    return '후보 $label, $move, $player 승률 $winRate, 흑 기준 집 차이 $score, $visits, 주요 변화 $pv';
  }

  @override
  String playerWinRate(String player) {
    return '$player 승률';
  }

  @override
  String get principalVariationNone => '주요 변화: 없음';

  @override
  String principalVariationValue(String value) {
    return '주요 변화  $value';
  }

  @override
  String get noPlayableCandidate =>
      '서비스가 둘 수 있는 후보를 반환하지 않았습니다. 통과만 남았을 수 있습니다.';

  @override
  String get positionDataExpired => '국면 데이터를 더 이상 사용할 수 없습니다';

  @override
  String get positionNotAnalyzed => '이 국면은 아직 분석되지 않았습니다';

  @override
  String get realKatagoOnly => '후보, 승률, 집 차이, 탐색 수에는 실제 KataGo 결과만 표시합니다.';

  @override
  String get startAnalysis => '분석 시작';

  @override
  String get variationComparisonTitle => '변화 비교';

  @override
  String variationComparisonSubtitle(int move) {
    return '제$move수 · 실전과 후보';
  }

  @override
  String variationBoardSemantics(int move, String candidate) {
    return '제$move수 변화 비교, 후보 $candidate 선택됨';
  }

  @override
  String get noComparableCandidate => '비교할 후보가 없습니다';

  @override
  String returnToMainLine(int move) {
    return '본선 제$move수로 돌아가기';
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
    return '후보 $label, $move, 승률 $winRate, 흑 기준 집 차이 $score, $visits, 주요 변화 $pv, 실전 $played, 집 손실 $loss';
  }

  @override
  String playedMoveWithLoss(String move, String loss) {
    return '실전 $move · $loss';
  }

  @override
  String playedMoveValue(String move) {
    return '실전 $move';
  }

  @override
  String get serviceNoPrincipalVariation => '서비스가 주요 변화를 제공하지 않았습니다';

  @override
  String get realCandidateData => '실제 후보 데이터';

  @override
  String get noVariationReturn => '변화 데이터 없음 · 돌아가기';

  @override
  String get bestCandidate => '최선 후보';

  @override
  String get candidateVariation => '후보 변화';

  @override
  String reviewBoardSemantics(int move, int count) {
    return '제$move수 복기 바둑판, 실제 후보 $count개 표시';
  }

  @override
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '제$move수, $leader이 $points집 앞섬, $leader 승률 $winRate';
  }

  @override
  String positionMetricCompact(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '제$move수 · $leader $points집 · $winRate';
  }

  @override
  String positionMetricFull(
    int move,
    String leader,
    String points,
    String winRate,
  ) {
    return '현재 제$move수    $leader이 $points집 앞섬    $leader 승률 $winRate';
  }

  @override
  String get reviewTitle => '복기';

  @override
  String get completeAnalysisResults => '완전한 분석 결과';

  @override
  String get noCompletedReview => '완료된 복기가 없습니다';

  @override
  String get verifiedGlobalAnalysisOnly => '핵심 수 복기는 완전하고 검증된 전체 대국 분석이 필요합니다.';

  @override
  String get tabletLandscapeHint => '2열 복기를 사용하려면 태블릿을 가로로 돌리세요';

  @override
  String tabletBoardSemantics(int move, int count) {
    return '태블릿 복기 바둑판, 제$move수, 후보 $count개 표시';
  }

  @override
  String get noReviewDataReturn => '복기 데이터 없음 · 기보로 돌아가기';

  @override
  String get quickReview => '빠른 복기';

  @override
  String get standardReview => '표준 복기';

  @override
  String get deepReview => '심층 복기';

  @override
  String regularMoveTitle(int move) {
    return '제$move수';
  }

  @override
  String rankedKeyMoveTitle(int rank, int move) {
    return '핵심 수 #$rank · 제$move수';
  }

  @override
  String keyMoveSemantics(String title, String comparison, String detail) {
    return '$title, 실전에서 최선까지 $comparison, $detail';
  }

  @override
  String get regularMoveBadge => '보통 수';

  @override
  String get lossRankBadge => '손실 순위';

  @override
  String get noCandidateData => '후보 데이터 없음';

  @override
  String candidateMetricDetail(String winRate, String score, String visits) {
    return '$winRate · $score · $visits';
  }

  @override
  String bestCandidateSemantics(String move, String detail) {
    return '최선 후보 $move, $detail';
  }

  @override
  String pvMoveCount(int moves) {
    return 'PV $moves수';
  }

  @override
  String trendCompactValue(int move, String score, String winRate) {
    return '제$move수 · 흑 기준 집 차이 $score · 흑 승률 $winRate';
  }

  @override
  String get globalScoreTrend => '전체 집 차이 추이';

  @override
  String gameMetricsDetail(String loss, String topThree, String severe) {
    return '평균 집 손실 $loss · Top 3 $topThree · 심각한 실수 $severe';
  }

  @override
  String gameMetricsSemantics(String detail) {
    return '이번 판 수치, $detail. 경기력 구간에는 보정된 모델이 필요합니다';
  }

  @override
  String get gameMetricsTitle => '이번 판 수치';

  @override
  String totalMovesKeyMoves(int moves, int keyMoves) {
    return '$moves수 · 핵심 수 $keyMoves개';
  }

  @override
  String get performanceNeedsCalibration => '기력 보정 필요';

  @override
  String get boardCorrectionExpired => '바둑판 교정 데이터를 더 이상 사용할 수 없습니다';

  @override
  String get sequenceCorrectionExpired => '수순 교정 데이터를 더 이상 사용할 수 없습니다';

  @override
  String autoRectifiedSubtitle(String board) {
    return '자동 보정 · $board';
  }

  @override
  String get viewOriginal => '원본 보기';

  @override
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending) {
    return '실물 바둑판 교정, 흑 $blackCount개, 백 $whiteCount개, 확인 대기 $pending곳';
  }

  @override
  String stoneCountsCompact(int blackCount, int whiteCount) {
    return '흑 $blackCount · 백 $whiteCount';
  }

  @override
  String get confirmCurrentPosition => '현재 국면 확인';

  @override
  String confirmRemaining(int count) {
    return '남은 $count곳 확인';
  }

  @override
  String get correctSequenceTitle => '수순 교정';

  @override
  String numberedDetectedMoves(int moves) {
    return '번호 기보 이미지 · $moves수 인식';
  }

  @override
  String get sequenceValidatingSemantics => '번호 기보 교정, 전체 수순 검증 중';

  @override
  String sequenceIssueSemantics(int move) {
    return '번호 기보 교정, 제$move수 확인 필요. 교차점을 선택하세요';
  }

  @override
  String get reuseAfterCapture => '따낸 뒤 같은 점 재사용';

  @override
  String get markPassMove => '이 수를 통과로 표시';

  @override
  String selectMoveOnBoard(int move) {
    return '바둑판에서 제$move수 선택';
  }

  @override
  String confirmMoveAt(int move, String coordinate) {
    return '제$move수를 $coordinate에 확인';
  }

  @override
  String get saveAsPositionFallback => '수순을 복원할 수 없어 현재 국면으로 저장';

  @override
  String get sequenceIssueNoFirst =>
      '제1수를 인식하지 못했습니다. 바둑판 위치를 선택하거나 통과로 표시하세요.';

  @override
  String get sequenceIssueMissing =>
      '번호가 빠졌습니다. 교차점을 선택하면 해당 점의 잘못 인식된 번호를 바꿉니다.';

  @override
  String get sequenceIssueOcr => 'OCR 신뢰도가 낮습니다. 위치를 확인하세요.';

  @override
  String get sequenceIssueColor => '돌 색과 수 번호의 홀짝이 맞지 않습니다. 위치를 확인하세요.';

  @override
  String get sequenceIssueFinalMismatch =>
      '복원한 최종 국면과 인식한 바둑판이 일치하지 않습니다. 표시 위치를 확인하세요.';

  @override
  String get sequenceIssueTooMany => '번호 수순이 안전 처리 한도를 넘었습니다.';

  @override
  String get sequenceIssueDuplicate => '같은 수 번호가 여러 번 나타납니다. 표시를 확인하세요.';

  @override
  String get sequenceIssueIllegal => '수순이 바둑 규칙을 위반합니다. 표시 위치를 확인하세요.';

  @override
  String get sequenceValidationFailed => '수순 검증에 실패했습니다. 표시를 확인하고 다시 시도하세요.';

  @override
  String get validatingGoRules => '바둑 규칙으로 검증 중';

  @override
  String moveCannotConfirm(String move) {
    return '제$move수를 확인할 수 없습니다';
  }

  @override
  String get checkingSequenceRules => '번호 연속성, 따냄, 패, 같은 점 재사용을 확인 중입니다.';

  @override
  String get sequenceVerifiedTitle => '수순 검증 완료';

  @override
  String get sequenceVerifiedSubtitle => '연속 번호 · 바둑 규칙 통과';

  @override
  String verifiedRecordSemantics(int size, int moves) {
    return '검증된 $size로 완전 기보, 총 $moves수';
  }

  @override
  String get saveAndStartReview => '저장하고 복기 시작';

  @override
  String rescanWithReason(String reason) {
    return '$reason · 다시 인식';
  }

  @override
  String get originalImageUnavailable => '원본 이미지를 표시할 수 없습니다';

  @override
  String get scanResultTitle => '인식 결과';

  @override
  String scanResultSubtitle(String board) {
    return '현재 국면 · $board';
  }

  @override
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount) {
    return '인식된 $size로 바둑 국면, 흑 $blackCount개, 백 $whiteCount개';
  }

  @override
  String get boardRecognitionComplete => '바둑판 인식 완료';

  @override
  String recognizedPositionCounts(int blackCount, int whiteCount) {
    return '현재 국면을 인식했습니다: 흑 $blackCount개, 백 $whiteCount개.';
  }

  @override
  String get photoNoSequence =>
      '한 장의 사진에는 착수 시간이 없어 전체 수순을 복원할 수 없습니다. 이 국면에는 핵심 수 타임라인이나 경기력 평가를 표시하지 않습니다.';

  @override
  String get nextPlayerLabel => '다음 차례';

  @override
  String get chooseNextPlayerFirst => '다음 차례 선택';

  @override
  String get analyzeCurrentPosition => '현재 국면 분석';

  @override
  String get savePosition => '국면 저장';

  @override
  String get savePositionAnalysisFailed => '저장에 실패해 현재 국면 분석을 시작하지 않았습니다.';

  @override
  String get scanResultExpired => '인식 결과를 더 이상 사용할 수 없습니다';

  @override
  String get scanResultExpiredDetail => '바둑판 인식으로 돌아가 다시 촬영하거나 사진을 선택하세요.';

  @override
  String get returnToScan => '바둑판 인식으로 돌아가기';
}

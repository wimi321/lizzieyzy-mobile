import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('en', 'XA'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'LizzieYZY Mobile'**
  String get appTitle;

  /// No description provided for @portraitGuardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'手机端请竖屏使用，平板横屏不受限制'**
  String get portraitGuardSemantics;

  /// No description provided for @portraitGuardTitle.
  ///
  /// In zh, this message translates to:
  /// **'请竖屏使用'**
  String get portraitGuardTitle;

  /// No description provided for @portraitGuardBody.
  ///
  /// In zh, this message translates to:
  /// **'棋盘、数值与操作会在竖屏内完整呈现'**
  String get portraitGuardBody;

  /// No description provided for @kifuTab.
  ///
  /// In zh, this message translates to:
  /// **'棋谱'**
  String get kifuTab;

  /// No description provided for @kifuHomeTooltip.
  ///
  /// In zh, this message translates to:
  /// **'棋谱首页'**
  String get kifuHomeTooltip;

  /// No description provided for @scanTab.
  ///
  /// In zh, this message translates to:
  /// **'识谱'**
  String get scanTab;

  /// No description provided for @photoScanTooltip.
  ///
  /// In zh, this message translates to:
  /// **'拍照识谱'**
  String get photoScanTooltip;

  /// No description provided for @homeSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'LIZZIEYZY · 把每一盘复盘清楚'**
  String get homeSubtitle;

  /// No description provided for @importKifuTooltip.
  ///
  /// In zh, this message translates to:
  /// **'导入棋谱'**
  String get importKifuTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTooltip;

  /// No description provided for @back.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get back;

  /// No description provided for @recentKifu.
  ///
  /// In zh, this message translates to:
  /// **'最近棋谱'**
  String get recentKifu;

  /// No description provided for @statusVerified.
  ///
  /// In zh, this message translates to:
  /// **'已校验'**
  String get statusVerified;

  /// No description provided for @statusNeedsConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'需确认'**
  String get statusNeedsConfirmation;

  /// No description provided for @statusCurrentPosition.
  ///
  /// In zh, this message translates to:
  /// **'当前局面'**
  String get statusCurrentPosition;

  /// No description provided for @blackPlayerFallback.
  ///
  /// In zh, this message translates to:
  /// **'黑方'**
  String get blackPlayerFallback;

  /// No description provided for @whitePlayerFallback.
  ///
  /// In zh, this message translates to:
  /// **'白方'**
  String get whitePlayerFallback;

  /// No description provided for @completeKifu.
  ///
  /// In zh, this message translates to:
  /// **'完整棋谱'**
  String get completeKifu;

  /// No description provided for @partialKifu.
  ///
  /// In zh, this message translates to:
  /// **'片段棋谱'**
  String get partialKifu;

  /// No description provided for @photoPosition.
  ///
  /// In zh, this message translates to:
  /// **'照片局面'**
  String get photoPosition;

  /// No description provided for @justImported.
  ///
  /// In zh, this message translates to:
  /// **'刚刚导入'**
  String get justImported;

  /// No description provided for @photoScanSemantics.
  ///
  /// In zh, this message translates to:
  /// **'拍照识谱，打开相机识别棋盘'**
  String get photoScanSemantics;

  /// No description provided for @photoScanTitle.
  ///
  /// In zh, this message translates to:
  /// **'拍照识谱'**
  String get photoScanTitle;

  /// No description provided for @photoScanSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'实体棋盘 · 编号棋谱图'**
  String get photoScanSubtitle;

  /// No description provided for @emptyKifuLibrary.
  ///
  /// In zh, this message translates to:
  /// **'还没有棋谱。导入 SGF / GIB，或从照片保存当前局面。'**
  String get emptyKifuLibrary;

  /// No description provided for @importFirstKifu.
  ///
  /// In zh, this message translates to:
  /// **'导入第一份棋谱'**
  String get importFirstKifu;

  /// No description provided for @inboundImported.
  ///
  /// In zh, this message translates to:
  /// **'已从系统分享导入 {fileName}'**
  String inboundImported(String fileName);

  /// No description provided for @inboundImportedWithWarnings.
  ///
  /// In zh, this message translates to:
  /// **'已导入 {fileName} · {warnings}'**
  String inboundImportedWithWarnings(String fileName, String warnings);

  /// No description provided for @inboundOpen.
  ///
  /// In zh, this message translates to:
  /// **'打开已导入的棋谱：{fileName}'**
  String inboundOpen(String fileName);

  /// No description provided for @sharedKifuFallback.
  ///
  /// In zh, this message translates to:
  /// **'分享的棋谱'**
  String get sharedKifuFallback;

  /// No description provided for @inboundInvalidFile.
  ///
  /// In zh, this message translates to:
  /// **'分享的棋谱无效，无法导入。'**
  String get inboundInvalidFile;

  /// No description provided for @inboundStorageFailure.
  ///
  /// In zh, this message translates to:
  /// **'保存分享的棋谱失败，请检查可用空间。'**
  String get inboundStorageFailure;

  /// No description provided for @inboundPlatformFailure.
  ///
  /// In zh, this message translates to:
  /// **'无法读取系统分享的棋谱，请重试。'**
  String get inboundPlatformFailure;

  /// No description provided for @dismissNotice.
  ///
  /// In zh, this message translates to:
  /// **'关闭通知'**
  String get dismissNotice;

  /// No description provided for @playerPair.
  ///
  /// In zh, this message translates to:
  /// **'{blackPlayer} · {whitePlayer}'**
  String playerPair(String blackPlayer, String whitePlayer);

  /// No description provided for @moveCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0 {0手} other {{count}手}}'**
  String moveCount(int count);

  /// No description provided for @kifuCardDetail.
  ///
  /// In zh, this message translates to:
  /// **'{result} · {moves} · {playedAt}'**
  String kifuCardDetail(String result, String moves, String playedAt);

  /// No description provided for @kifuCardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{blackPlayer} 对 {whitePlayer}，{result}，{moves}，{status}'**
  String kifuCardSemantics(
    String blackPlayer,
    String whitePlayer,
    String result,
    String moves,
    String status,
  );

  /// No description provided for @importKifuTitle.
  ///
  /// In zh, this message translates to:
  /// **'导入棋谱'**
  String get importKifuTitle;

  /// No description provided for @importKifuSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'SGF / GIB · 本地校验'**
  String get importKifuSubtitle;

  /// No description provided for @chooseKifuTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择 SGF 或 GIB 棋谱'**
  String get chooseKifuTitle;

  /// No description provided for @chooseKifuBody.
  ///
  /// In zh, this message translates to:
  /// **'导入后先进行格式与围棋规则校验；有缺口的记录会明确降级，不会伪装成完整棋谱。'**
  String get chooseKifuBody;

  /// No description provided for @chooseKifuFile.
  ///
  /// In zh, this message translates to:
  /// **'选择棋谱文件'**
  String get chooseKifuFile;

  /// No description provided for @validatingKifu.
  ///
  /// In zh, this message translates to:
  /// **'正在校验棋谱…'**
  String get validatingKifu;

  /// No description provided for @importFailed.
  ///
  /// In zh, this message translates to:
  /// **'导入失败'**
  String get importFailed;

  /// No description provided for @chooseAgain.
  ///
  /// In zh, this message translates to:
  /// **'重新选择'**
  String get chooseAgain;

  /// No description provided for @saveKifuFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请检查可用空间后重试。'**
  String get saveKifuFailed;

  /// No description provided for @kifuReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取棋谱。'**
  String get kifuReadFailed;

  /// No description provided for @verifiedRecordDetail.
  ///
  /// In zh, this message translates to:
  /// **'{moves} · 规则校验通过'**
  String verifiedRecordDetail(String moves);

  /// No description provided for @partialRecordDetail.
  ///
  /// In zh, this message translates to:
  /// **'{moves} · 需要人工确认'**
  String partialRecordDetail(String moves);

  /// No description provided for @stoneCounts.
  ///
  /// In zh, this message translates to:
  /// **'黑{blackCount}子 · 白{whiteCount}子'**
  String stoneCounts(int blackCount, int whiteCount);

  /// No description provided for @warning.
  ///
  /// In zh, this message translates to:
  /// **'警告'**
  String get warning;

  /// No description provided for @fileEncoding.
  ///
  /// In zh, this message translates to:
  /// **'文件编码'**
  String get fileEncoding;

  /// No description provided for @legacyGibEncodingDetected.
  ///
  /// In zh, this message translates to:
  /// **'检测到旧版 GIB 编码：{encoding}'**
  String legacyGibEncodingDetected(String encoding);

  /// No description provided for @warningCount.
  ///
  /// In zh, this message translates to:
  /// **'{count, plural, =0 {0项} other {{count}项}}'**
  String warningCount(int count);

  /// No description provided for @addedToKifu.
  ///
  /// In zh, this message translates to:
  /// **'已加入棋谱'**
  String get addedToKifu;

  /// No description provided for @addToKifu.
  ///
  /// In zh, this message translates to:
  /// **'加入棋谱'**
  String get addToKifu;

  /// No description provided for @importAnother.
  ///
  /// In zh, this message translates to:
  /// **'导入另一份'**
  String get importAnother;

  /// No description provided for @importErrorResourceLimit.
  ///
  /// In zh, this message translates to:
  /// **'棋谱超过安全处理上限，请选择更小的文件。'**
  String get importErrorResourceLimit;

  /// No description provided for @importErrorInvalidEncoding.
  ///
  /// In zh, this message translates to:
  /// **'棋谱文本编码无效或无法明确判断；SGF 仅支持 UTF-8。'**
  String get importErrorInvalidEncoding;

  /// No description provided for @importErrorUnsupportedFormat.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 .sgf 与 .gib 棋谱。'**
  String get importErrorUnsupportedFormat;

  /// No description provided for @importErrorInvalidRecord.
  ///
  /// In zh, this message translates to:
  /// **'棋谱格式或手顺无效，请检查文件。'**
  String get importErrorInvalidRecord;

  /// No description provided for @importErrorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'无法读取该棋谱，请确认文件未损坏。'**
  String get importErrorUnknown;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'本机优先 · 配置可追溯'**
  String get settingsSubtitle;

  /// No description provided for @analysisServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'分析服务'**
  String get analysisServiceTitle;

  /// No description provided for @analysisServiceUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置 · 不会发送棋谱'**
  String get analysisServiceUnconfigured;

  /// No description provided for @analysisServiceConfigured.
  ///
  /// In zh, this message translates to:
  /// **'{model} · WSS'**
  String analysisServiceConfigured(String model);

  /// No description provided for @appearanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearanceTitle;

  /// No description provided for @languageTitle.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get languageTitle;

  /// No description provided for @privacyOpenSourceTitle.
  ///
  /// In zh, this message translates to:
  /// **'隐私与开源'**
  String get privacyOpenSourceTitle;

  /// No description provided for @privacyOpenSourceDetail.
  ///
  /// In zh, this message translates to:
  /// **'数据边界 · 许可证 · 安全报告'**
  String get privacyOpenSourceDetail;

  /// No description provided for @appVersionSemantics.
  ///
  /// In zh, this message translates to:
  /// **'LizzieYZY Mobile 版本 0.1.0，开源许可证 MPL 2.0'**
  String get appVersionSemantics;

  /// No description provided for @appVersionLabel.
  ///
  /// In zh, this message translates to:
  /// **'LizzieYZY Mobile · 0.1.0 · MPL-2.0'**
  String get appVersionLabel;

  /// No description provided for @analysisShortcutConfigured.
  ///
  /// In zh, this message translates to:
  /// **'分析服务\n已配置'**
  String get analysisShortcutConfigured;

  /// No description provided for @analysisShortcutUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'分析服务\n未配置'**
  String get analysisShortcutUnconfigured;

  /// No description provided for @privacyShortcut.
  ///
  /// In zh, this message translates to:
  /// **'隐私\n与开源'**
  String get privacyShortcut;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统与高对比模式'**
  String get appearanceSubtitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'界面与系统控件语言'**
  String get languageSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @localeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get localeSystem;

  /// No description provided for @localeSimplifiedChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get localeSimplifiedChinese;

  /// No description provided for @localeTraditionalChinese.
  ///
  /// In zh, this message translates to:
  /// **'繁體中文'**
  String get localeTraditionalChinese;

  /// No description provided for @localeEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @localeJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本語'**
  String get localeJapanese;

  /// No description provided for @localeKorean.
  ///
  /// In zh, this message translates to:
  /// **'한국어'**
  String get localeKorean;

  /// No description provided for @settingsTileSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title}，{detail}'**
  String settingsTileSemantics(String title, String detail);

  /// No description provided for @analysisServiceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'WSS · 凭据存入系统安全区'**
  String get analysisServiceSubtitle;

  /// No description provided for @accessTokenOptional.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌（可选）'**
  String get accessTokenOptional;

  /// No description provided for @tokenSecureStorageHelper.
  ///
  /// In zh, this message translates to:
  /// **'只写入 Keychain / Keystore'**
  String get tokenSecureStorageHelper;

  /// No description provided for @hideToken.
  ///
  /// In zh, this message translates to:
  /// **'隐藏令牌'**
  String get hideToken;

  /// No description provided for @showToken.
  ///
  /// In zh, this message translates to:
  /// **'显示令牌'**
  String get showToken;

  /// No description provided for @hideAccessToken.
  ///
  /// In zh, this message translates to:
  /// **'隐藏访问令牌'**
  String get hideAccessToken;

  /// No description provided for @showAccessToken.
  ///
  /// In zh, this message translates to:
  /// **'显示访问令牌'**
  String get showAccessToken;

  /// No description provided for @confirmEverySend.
  ///
  /// In zh, this message translates to:
  /// **'每次发送前确认'**
  String get confirmEverySend;

  /// No description provided for @remoteAnalysisSendsFullKifu.
  ///
  /// In zh, this message translates to:
  /// **'远端分析会发送完整棋谱'**
  String get remoteAnalysisSendsFullKifu;

  /// No description provided for @settingsSaveFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，请重试。'**
  String get settingsSaveFailedRetry;

  /// No description provided for @removeService.
  ///
  /// In zh, this message translates to:
  /// **'移除服务'**
  String get removeService;

  /// No description provided for @saveConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'保存配置'**
  String get saveConfiguration;

  /// No description provided for @connectionTab.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get connectionTab;

  /// No description provided for @reviewTab.
  ///
  /// In zh, this message translates to:
  /// **'复盘'**
  String get reviewTab;

  /// No description provided for @tokenLabel.
  ///
  /// In zh, this message translates to:
  /// **'令牌'**
  String get tokenLabel;

  /// No description provided for @confirmBeforeSend.
  ///
  /// In zh, this message translates to:
  /// **'发送前确认'**
  String get confirmBeforeSend;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败'**
  String get settingsSaveFailed;

  /// No description provided for @saving.
  ///
  /// In zh, this message translates to:
  /// **'保存中'**
  String get saving;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @analysisManifestFileType.
  ///
  /// In zh, this message translates to:
  /// **'LizzieYZY 分析服务清单'**
  String get analysisManifestFileType;

  /// No description provided for @manifestTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'服务清单不能超过 64 KB。'**
  String get manifestTooLarge;

  /// No description provided for @manifestReadFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取服务清单。'**
  String get manifestReadFailed;

  /// No description provided for @removeAnalysisServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除分析服务？'**
  String get removeAnalysisServiceTitle;

  /// No description provided for @removeAnalysisServiceBody.
  ///
  /// In zh, this message translates to:
  /// **'服务地址和系统安全区中的访问令牌都会删除。'**
  String get removeAnalysisServiceBody;

  /// No description provided for @keep.
  ///
  /// In zh, this message translates to:
  /// **'保留'**
  String get keep;

  /// No description provided for @remove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @manifestNotImported.
  ///
  /// In zh, this message translates to:
  /// **'尚未导入服务清单'**
  String get manifestNotImported;

  /// No description provided for @manifestPurpose.
  ///
  /// In zh, this message translates to:
  /// **'清单固定服务地址、模型哈希和胜率视角'**
  String get manifestPurpose;

  /// No description provided for @manifestConfiguredDetail.
  ///
  /// In zh, this message translates to:
  /// **'{host} · {engineVersion}'**
  String manifestConfiguredDetail(String host, String engineVersion);

  /// No description provided for @notConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置'**
  String get notConfigured;

  /// No description provided for @importAction.
  ///
  /// In zh, this message translates to:
  /// **'导入'**
  String get importAction;

  /// No description provided for @replace.
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get replace;

  /// No description provided for @removeAnalysisServiceTooltip.
  ///
  /// In zh, this message translates to:
  /// **'移除分析服务'**
  String get removeAnalysisServiceTooltip;

  /// No description provided for @importManifestTooltip.
  ///
  /// In zh, this message translates to:
  /// **'导入服务清单'**
  String get importManifestTooltip;

  /// No description provided for @replaceManifestTooltip.
  ///
  /// In zh, this message translates to:
  /// **'更换服务清单'**
  String get replaceManifestTooltip;

  /// No description provided for @reviewDepth.
  ///
  /// In zh, this message translates to:
  /// **'复盘深度'**
  String get reviewDepth;

  /// No description provided for @analysisQuick.
  ///
  /// In zh, this message translates to:
  /// **'快速'**
  String get analysisQuick;

  /// No description provided for @analysisStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准'**
  String get analysisStandard;

  /// No description provided for @analysisDeep.
  ///
  /// In zh, this message translates to:
  /// **'深入'**
  String get analysisDeep;

  /// No description provided for @analysisProfileWithVisits.
  ///
  /// In zh, this message translates to:
  /// **'{profile} · 每手{visits}次访问'**
  String analysisProfileWithVisits(String profile, int visits);

  /// No description provided for @privacySubtitle.
  ///
  /// In zh, this message translates to:
  /// **'数据去向必须可验证'**
  String get privacySubtitle;

  /// No description provided for @privacyLocalTab.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get privacyLocalTab;

  /// No description provided for @privacyRemoteTab.
  ///
  /// In zh, this message translates to:
  /// **'远端'**
  String get privacyRemoteTab;

  /// No description provided for @privacyOpenSourceTab.
  ///
  /// In zh, this message translates to:
  /// **'开源'**
  String get privacyOpenSourceTab;

  /// No description provided for @privacyLocalTitle.
  ///
  /// In zh, this message translates to:
  /// **'默认只在本机处理'**
  String get privacyLocalTitle;

  /// No description provided for @privacyLocalFact1.
  ///
  /// In zh, this message translates to:
  /// **'相机权限只在进入识谱时申请。'**
  String get privacyLocalFact1;

  /// No description provided for @privacyLocalFact2.
  ///
  /// In zh, this message translates to:
  /// **'照片、棋谱和校对结果保存在应用私有目录。'**
  String get privacyLocalFact2;

  /// No description provided for @privacyLocalFact3.
  ///
  /// In zh, this message translates to:
  /// **'没有广告、账号、社交或行为跟踪 SDK。'**
  String get privacyLocalFact3;

  /// No description provided for @privacyRemoteTitle.
  ///
  /// In zh, this message translates to:
  /// **'远端分析由您决定'**
  String get privacyRemoteTitle;

  /// No description provided for @privacyRemoteFact1.
  ///
  /// In zh, this message translates to:
  /// **'只有主动开始远端复盘才发送完整棋谱。'**
  String get privacyRemoteFact1;

  /// No description provided for @privacyRemoteFact2.
  ///
  /// In zh, this message translates to:
  /// **'目标仅为您导入并批准的 WSS 服务。'**
  String get privacyRemoteFact2;

  /// No description provided for @privacyRemoteFact3.
  ///
  /// In zh, this message translates to:
  /// **'访问令牌只进入系统 Keychain / Keystore。'**
  String get privacyRemoteFact3;

  /// No description provided for @privacyOpenSourcePanelTitle.
  ///
  /// In zh, this message translates to:
  /// **'代码与模型边界公开'**
  String get privacyOpenSourcePanelTitle;

  /// No description provided for @privacyOpenSourceFact1.
  ///
  /// In zh, this message translates to:
  /// **'应用代码采用 MPL-2.0。'**
  String get privacyOpenSourceFact1;

  /// No description provided for @privacyOpenSourceFact2.
  ///
  /// In zh, this message translates to:
  /// **'模型、数据和字体必须记录许可与 SHA-256。'**
  String get privacyOpenSourceFact2;

  /// No description provided for @privacyOpenSourceFact3.
  ///
  /// In zh, this message translates to:
  /// **'安全问题通过仓库 SECURITY.md 私密报告。'**
  String get privacyOpenSourceFact3;

  /// No description provided for @privacyPreviousFact.
  ///
  /// In zh, this message translates to:
  /// **'上一条'**
  String get privacyPreviousFact;

  /// No description provided for @privacyNextFact.
  ///
  /// In zh, this message translates to:
  /// **'下一条'**
  String get privacyNextFact;

  /// No description provided for @privacyPanelSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title}，{facts}'**
  String privacyPanelSemantics(String title, String facts);

  /// No description provided for @licenses.
  ///
  /// In zh, this message translates to:
  /// **'许可证'**
  String get licenses;

  /// No description provided for @viewThirdPartyLicenses.
  ///
  /// In zh, this message translates to:
  /// **'查看第三方许可证'**
  String get viewThirdPartyLicenses;

  /// No description provided for @privacyPromiseSemantics.
  ///
  /// In zh, this message translates to:
  /// **'隐私承诺，没有强制账号，没有广告，没有金币，没有自动上传'**
  String get privacyPromiseSemantics;

  /// No description provided for @privacyPromise.
  ///
  /// In zh, this message translates to:
  /// **'无强制账号 · 无广告 · 无金币 · 不自动上传'**
  String get privacyPromise;

  /// No description provided for @closeCamera.
  ///
  /// In zh, this message translates to:
  /// **'关闭相机'**
  String get closeCamera;

  /// No description provided for @cameraViewfinderSemantics.
  ///
  /// In zh, this message translates to:
  /// **'相机取景框，十九路棋盘需完整入框'**
  String get cameraViewfinderSemantics;

  /// No description provided for @startingCamera.
  ///
  /// In zh, this message translates to:
  /// **'正在启动相机…'**
  String get startingCamera;

  /// No description provided for @recognizingIntersections.
  ///
  /// In zh, this message translates to:
  /// **'正在识别 {count} 个交叉点…'**
  String recognizingIntersections(int count);

  /// No description provided for @cameraTemporarilyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'相机暂时不可用'**
  String get cameraTemporarilyUnavailable;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @photoLibrary.
  ///
  /// In zh, this message translates to:
  /// **'相册'**
  String get photoLibrary;

  /// No description provided for @capturePhoto.
  ///
  /// In zh, this message translates to:
  /// **'拍照'**
  String get capturePhoto;

  /// No description provided for @captureHelp.
  ///
  /// In zh, this message translates to:
  /// **'拍摄帮助'**
  String get captureHelp;

  /// No description provided for @alignmentReady.
  ///
  /// In zh, this message translates to:
  /// **'完整棋盘入框 · 保持稳定'**
  String get alignmentReady;

  /// No description provided for @alignmentRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'识别中 · 请勿离开'**
  String get alignmentRecognizing;

  /// No description provided for @alignmentFallback.
  ///
  /// In zh, this message translates to:
  /// **'可改用相册继续'**
  String get alignmentFallback;

  /// No description provided for @alignmentPreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备取景'**
  String get alignmentPreparing;

  /// No description provided for @captureHelpTitle.
  ///
  /// In zh, this message translates to:
  /// **'拍摄完整棋盘'**
  String get captureHelpTitle;

  /// No description provided for @captureHelpBody.
  ///
  /// In zh, this message translates to:
  /// **'让四个角都在绿色框内，镜头尽量正对棋盘，并避开棋子上的强反光。'**
  String get captureHelpBody;

  /// No description provided for @gotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get gotIt;

  /// No description provided for @flashAutomatic.
  ///
  /// In zh, this message translates to:
  /// **'闪光灯，自动'**
  String get flashAutomatic;

  /// No description provided for @flashOff.
  ///
  /// In zh, this message translates to:
  /// **'闪光灯，关闭'**
  String get flashOff;

  /// No description provided for @flashOn.
  ///
  /// In zh, this message translates to:
  /// **'闪光灯，开启'**
  String get flashOn;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'未获得相机权限，请在系统设置中允许访问，或改用相册。'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraRestricted.
  ///
  /// In zh, this message translates to:
  /// **'此设备限制了相机访问，请改用相册。'**
  String get cameraRestricted;

  /// No description provided for @cameraUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'相机暂时不可用，请重试或改用相册。'**
  String get cameraUnavailable;

  /// No description provided for @cameraCaptureFailed.
  ///
  /// In zh, this message translates to:
  /// **'拍摄失败，请保持设备稳定后重试。'**
  String get cameraCaptureFailed;

  /// No description provided for @photoLibraryPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'无法访问相册，请在系统设置中允许照片访问。'**
  String get photoLibraryPermissionDenied;

  /// No description provided for @photoLibraryUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法打开相册，请稍后重试。'**
  String get photoLibraryUnavailable;

  /// No description provided for @selectedImageUnreadable.
  ///
  /// In zh, this message translates to:
  /// **'无法读取所选图片，请换一张完整清晰的棋盘照片。'**
  String get selectedImageUnreadable;

  /// No description provided for @recognitionIncompleteBoard.
  ///
  /// In zh, this message translates to:
  /// **'未能识别完整棋盘，请确保四角入框、光线均匀后重试。'**
  String get recognitionIncompleteBoard;

  /// No description provided for @recognitionFailed.
  ///
  /// In zh, this message translates to:
  /// **'识别失败，请保持棋盘完整清晰后重试。'**
  String get recognitionFailed;

  /// No description provided for @useGuideFallback.
  ///
  /// In zh, this message translates to:
  /// **'改用导框识别'**
  String get useGuideFallback;

  /// No description provided for @guideFallbackDetail.
  ///
  /// In zh, this message translates to:
  /// **'使用同一组已拍画面，按棋盘导框重新识别。'**
  String get guideFallbackDetail;

  /// No description provided for @guideFallbackRecognizing.
  ///
  /// In zh, this message translates to:
  /// **'正在按导框重新识别…'**
  String get guideFallbackRecognizing;

  /// No description provided for @pageNotFound.
  ///
  /// In zh, this message translates to:
  /// **'页面不存在'**
  String get pageNotFound;

  /// No description provided for @returnToKifu.
  ///
  /// In zh, this message translates to:
  /// **'返回棋谱'**
  String get returnToKifu;

  /// No description provided for @cancelAction.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancelAction;

  /// No description provided for @closeAction.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get closeAction;

  /// No description provided for @openAction.
  ///
  /// In zh, this message translates to:
  /// **'打开'**
  String get openAction;

  /// No description provided for @pauseAction.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get pauseAction;

  /// No description provided for @resumeAction.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get resumeAction;

  /// No description provided for @shareKifu.
  ///
  /// In zh, this message translates to:
  /// **'导出棋谱'**
  String get shareKifu;

  /// No description provided for @shareOpened.
  ///
  /// In zh, this message translates to:
  /// **'已打开系统分享'**
  String get shareOpened;

  /// No description provided for @shareNoTarget.
  ///
  /// In zh, this message translates to:
  /// **'当前设备没有可用的分享目标'**
  String get shareNoTarget;

  /// No description provided for @shareUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法打开系统分享。'**
  String get shareUnavailable;

  /// No description provided for @preparing.
  ///
  /// In zh, this message translates to:
  /// **'准备中'**
  String get preparing;

  /// No description provided for @blackStoneShort.
  ///
  /// In zh, this message translates to:
  /// **'黑'**
  String get blackStoneShort;

  /// No description provided for @whiteStoneShort.
  ///
  /// In zh, this message translates to:
  /// **'白'**
  String get whiteStoneShort;

  /// No description provided for @blackStoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'黑棋'**
  String get blackStoneLabel;

  /// No description provided for @whiteStoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'白棋'**
  String get whiteStoneLabel;

  /// No description provided for @semanticSeparator.
  ///
  /// In zh, this message translates to:
  /// **'，'**
  String get semanticSeparator;

  /// No description provided for @emptyPoint.
  ///
  /// In zh, this message translates to:
  /// **'空'**
  String get emptyPoint;

  /// No description provided for @unclearPoint.
  ///
  /// In zh, this message translates to:
  /// **'看不清'**
  String get unclearPoint;

  /// No description provided for @passMove.
  ///
  /// In zh, this message translates to:
  /// **'停一手'**
  String get passMove;

  /// No description provided for @pointsValue.
  ///
  /// In zh, this message translates to:
  /// **'{value}目'**
  String pointsValue(String value);

  /// No description provided for @pointLossValue.
  ///
  /// In zh, this message translates to:
  /// **'-{value}目'**
  String pointLossValue(String value);

  /// No description provided for @visitsValue.
  ///
  /// In zh, this message translates to:
  /// **'{value}访问'**
  String visitsValue(String value);

  /// No description provided for @moveOrdinal.
  ///
  /// In zh, this message translates to:
  /// **'第 {move} 手'**
  String moveOrdinal(int move);

  /// No description provided for @effectiveDecisionCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}个有效决策'**
  String effectiveDecisionCount(int count);

  /// No description provided for @boardDimension.
  ///
  /// In zh, this message translates to:
  /// **'{size}路'**
  String boardDimension(int size);

  /// No description provided for @coverageInterval.
  ///
  /// In zh, this message translates to:
  /// **'{coverage}% 区间'**
  String coverageInterval(int coverage);

  /// No description provided for @winRateLabel.
  ///
  /// In zh, this message translates to:
  /// **'胜率'**
  String get winRateLabel;

  /// No description provided for @scoreLeadLabel.
  ///
  /// In zh, this message translates to:
  /// **'目差'**
  String get scoreLeadLabel;

  /// No description provided for @blackScoreLeadLabel.
  ///
  /// In zh, this message translates to:
  /// **'黑方目差'**
  String get blackScoreLeadLabel;

  /// No description provided for @visitsLabel.
  ///
  /// In zh, this message translates to:
  /// **'访问'**
  String get visitsLabel;

  /// No description provided for @playedMoveLabel.
  ///
  /// In zh, this message translates to:
  /// **'实战'**
  String get playedMoveLabel;

  /// No description provided for @principalVariationLabel.
  ///
  /// In zh, this message translates to:
  /// **'主变化'**
  String get principalVariationLabel;

  /// No description provided for @noneLabel.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get noneLabel;

  /// No description provided for @analysisDefaultTitle.
  ///
  /// In zh, this message translates to:
  /// **'标准分析'**
  String get analysisDefaultTitle;

  /// No description provided for @analysisContinuesInApp.
  ///
  /// In zh, this message translates to:
  /// **'离开此页后，应用内任务继续运行'**
  String get analysisContinuesInApp;

  /// No description provided for @analysisProgressLabel.
  ///
  /// In zh, this message translates to:
  /// **'分析进度'**
  String get analysisProgressLabel;

  /// No description provided for @analysisRunning.
  ///
  /// In zh, this message translates to:
  /// **'分析中'**
  String get analysisRunning;

  /// No description provided for @analysisPaused.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get analysisPaused;

  /// No description provided for @analysisCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get analysisCompleted;

  /// No description provided for @analysisFailed.
  ///
  /// In zh, this message translates to:
  /// **'分析失败'**
  String get analysisFailed;

  /// No description provided for @candidateSemantics.
  ///
  /// In zh, this message translates to:
  /// **'候选 {label}'**
  String candidateSemantics(String label);

  /// No description provided for @candidateSemanticsWithDetail.
  ///
  /// In zh, this message translates to:
  /// **'候选 {label}，{detail}'**
  String candidateSemanticsWithDetail(String label, String detail);

  /// No description provided for @correctBoardTitle.
  ///
  /// In zh, this message translates to:
  /// **'校对棋盘'**
  String get correctBoardTitle;

  /// No description provided for @intersectionCoordinate.
  ///
  /// In zh, this message translates to:
  /// **'交叉点 {coordinate}'**
  String intersectionCoordinate(String coordinate);

  /// No description provided for @confirmed.
  ///
  /// In zh, this message translates to:
  /// **'已确认'**
  String get confirmed;

  /// No description provided for @pendingConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'待确认 {count}'**
  String pendingConfirmation(int count);

  /// No description provided for @pendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'待确认'**
  String get pendingLabel;

  /// No description provided for @markStone.
  ///
  /// In zh, this message translates to:
  /// **'标记为{choice}'**
  String markStone(String choice);

  /// No description provided for @stoneChoiceSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{choice}棋子'**
  String stoneChoiceSemantics(String choice);

  /// No description provided for @goBoardLabel.
  ///
  /// In zh, this message translates to:
  /// **'围棋棋盘'**
  String get goBoardLabel;

  /// No description provided for @moveLeft.
  ///
  /// In zh, this message translates to:
  /// **'向左移动'**
  String get moveLeft;

  /// No description provided for @moveRight.
  ///
  /// In zh, this message translates to:
  /// **'向右移动'**
  String get moveRight;

  /// No description provided for @moveUp.
  ///
  /// In zh, this message translates to:
  /// **'向上移动'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In zh, this message translates to:
  /// **'向下移动'**
  String get moveDown;

  /// No description provided for @noLastMove.
  ///
  /// In zh, this message translates to:
  /// **'没有最后一手标记'**
  String get noLastMove;

  /// No description provided for @lastMoveAt.
  ///
  /// In zh, this message translates to:
  /// **'最后一手 {coordinate}'**
  String lastMoveAt(String coordinate);

  /// No description provided for @noCandidatePoints.
  ///
  /// In zh, this message translates to:
  /// **'没有候选点'**
  String get noCandidatePoints;

  /// No description provided for @boardSemanticsValue.
  ///
  /// In zh, this message translates to:
  /// **'{size}路，黑棋 {blackCount} 子，白棋 {whiteCount} 子，{lastMove}，{candidates}。当前 {coordinate}'**
  String boardSemanticsValue(
    int size,
    int blackCount,
    int whiteCount,
    String lastMove,
    String candidates,
    String coordinate,
  );

  /// No description provided for @boardNavigationHint.
  ///
  /// In zh, this message translates to:
  /// **'使用自定义方向操作移动交叉点'**
  String get boardNavigationHint;

  /// No description provided for @boardNavigationSelectHint.
  ///
  /// In zh, this message translates to:
  /// **'使用自定义方向操作移动交叉点，双击选择'**
  String get boardNavigationSelectHint;

  /// No description provided for @playerVersus.
  ///
  /// In zh, this message translates to:
  /// **'{blackPlayer} 对 {whitePlayer}'**
  String playerVersus(String blackPlayer, String whitePlayer);

  /// No description provided for @playerColorsSemantics.
  ///
  /// In zh, this message translates to:
  /// **'黑方 {blackPlayer}，白方 {whitePlayer}'**
  String playerColorsSemantics(String blackPlayer, String whitePlayer);

  /// No description provided for @kifuReviewed.
  ///
  /// In zh, this message translates to:
  /// **'已复盘'**
  String get kifuReviewed;

  /// No description provided for @kifuAnalyzing.
  ///
  /// In zh, this message translates to:
  /// **'分析中'**
  String get kifuAnalyzing;

  /// No description provided for @kifuNotReviewed.
  ///
  /// In zh, this message translates to:
  /// **'未复盘'**
  String get kifuNotReviewed;

  /// No description provided for @kifuNeedsAction.
  ///
  /// In zh, this message translates to:
  /// **'需要处理'**
  String get kifuNeedsAction;

  /// No description provided for @timelineLabel.
  ///
  /// In zh, this message translates to:
  /// **'手数'**
  String get timelineLabel;

  /// No description provided for @timelineSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}，第 {current} 手，共 {total} 手'**
  String timelineSemantics(String label, int current, int total);

  /// No description provided for @previousMove.
  ///
  /// In zh, this message translates to:
  /// **'上一手'**
  String get previousMove;

  /// No description provided for @nextMove.
  ///
  /// In zh, this message translates to:
  /// **'下一手'**
  String get nextMove;

  /// No description provided for @sliderMoveSemantics.
  ///
  /// In zh, this message translates to:
  /// **'第 {current} 手，共 {total} 手'**
  String sliderMoveSemantics(int current, int total);

  /// No description provided for @gamePerformanceEstimate.
  ///
  /// In zh, this message translates to:
  /// **'本局发挥估计'**
  String get gamePerformanceEstimate;

  /// No description provided for @performanceBandSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title}，{lowerRank} 到 {upperRank}，80% 区间，{confidence}，{decisions}'**
  String performanceBandSemantics(
    String title,
    String lowerRank,
    String upperRank,
    String confidence,
    String decisions,
  );

  /// No description provided for @reviewKeyMoves.
  ///
  /// In zh, this message translates to:
  /// **'关键手'**
  String get reviewKeyMoves;

  /// No description provided for @reviewVariations.
  ///
  /// In zh, this message translates to:
  /// **'变化'**
  String get reviewVariations;

  /// No description provided for @reviewTrend.
  ///
  /// In zh, this message translates to:
  /// **'走势'**
  String get reviewTrend;

  /// No description provided for @reviewGame.
  ///
  /// In zh, this message translates to:
  /// **'本局'**
  String get reviewGame;

  /// No description provided for @reviewPanel.
  ///
  /// In zh, this message translates to:
  /// **'复盘面板'**
  String get reviewPanel;

  /// No description provided for @tabSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}标签页'**
  String tabSemantics(String label);

  /// No description provided for @selectFromPhotos.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get selectFromPhotos;

  /// No description provided for @scoreTrend.
  ///
  /// In zh, this message translates to:
  /// **'目差走势'**
  String get scoreTrend;

  /// No description provided for @noData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// No description provided for @blackLeads.
  ///
  /// In zh, this message translates to:
  /// **'黑方领先 {points} 目'**
  String blackLeads(String points);

  /// No description provided for @whiteLeads.
  ///
  /// In zh, this message translates to:
  /// **'白方领先 {points} 目'**
  String whiteLeads(String points);

  /// No description provided for @scoreChartSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}，{direction}'**
  String scoreChartSemantics(String label, String direction);

  /// No description provided for @scoreChartMoveSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{label}，{direction}，当前第 {move} 手'**
  String scoreChartMoveSemantics(String label, String direction, int move);

  /// No description provided for @partialRecordExpired.
  ///
  /// In zh, this message translates to:
  /// **'片段棋谱数据已失效'**
  String get partialRecordExpired;

  /// No description provided for @partialTrustBoundary.
  ///
  /// In zh, this message translates to:
  /// **'信任边界 · 不作为完整对局'**
  String get partialTrustBoundary;

  /// No description provided for @partialBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'片段棋谱有效前缀局面，共{moves}手，不能生成完整复盘'**
  String partialBoardSemantics(int moves);

  /// No description provided for @partialUnproven.
  ///
  /// In zh, this message translates to:
  /// **'记录从第{move}手开始或包含无法证明的设置；不提供关键手与棋力。'**
  String partialUnproven(int move);

  /// No description provided for @partialIllegalMove.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手不合法：{reason}'**
  String partialIllegalMove(int move, String reason);

  /// No description provided for @ruleViolationWrongTurn.
  ///
  /// In zh, this message translates to:
  /// **'行棋方顺序错误'**
  String get ruleViolationWrongTurn;

  /// No description provided for @ruleViolationOutOfBounds.
  ///
  /// In zh, this message translates to:
  /// **'落子超出棋盘'**
  String get ruleViolationOutOfBounds;

  /// No description provided for @ruleViolationOccupied.
  ///
  /// In zh, this message translates to:
  /// **'交叉点已有棋子'**
  String get ruleViolationOccupied;

  /// No description provided for @ruleViolationSuicide.
  ///
  /// In zh, this message translates to:
  /// **'规则不允许自杀棋'**
  String get ruleViolationSuicide;

  /// No description provided for @ruleViolationKo.
  ///
  /// In zh, this message translates to:
  /// **'局面违反劫争规则'**
  String get ruleViolationKo;

  /// No description provided for @exportOriginalRecord.
  ///
  /// In zh, this message translates to:
  /// **'导出原记录'**
  String get exportOriginalRecord;

  /// No description provided for @saveCurrentPosition.
  ///
  /// In zh, this message translates to:
  /// **'保存当前局面'**
  String get saveCurrentPosition;

  /// No description provided for @ruleChinese.
  ///
  /// In zh, this message translates to:
  /// **'中国规则'**
  String get ruleChinese;

  /// No description provided for @ruleJapanese.
  ///
  /// In zh, this message translates to:
  /// **'日本规则'**
  String get ruleJapanese;

  /// No description provided for @ruleKorean.
  ///
  /// In zh, this message translates to:
  /// **'韩国规则'**
  String get ruleKorean;

  /// No description provided for @ruleAga.
  ///
  /// In zh, this message translates to:
  /// **'AGA规则'**
  String get ruleAga;

  /// No description provided for @ruleNewZealand.
  ///
  /// In zh, this message translates to:
  /// **'新西兰规则'**
  String get ruleNewZealand;

  /// No description provided for @ruleTrompTaylor.
  ///
  /// In zh, this message translates to:
  /// **'Tromp-Taylor规则'**
  String get ruleTrompTaylor;

  /// No description provided for @reviewSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{rules} · {result} · {moves}'**
  String reviewSubtitle(String rules, String result, String moves);

  /// No description provided for @resultUnknown.
  ///
  /// In zh, this message translates to:
  /// **'结果未知'**
  String get resultUnknown;

  /// No description provided for @blackWins.
  ///
  /// In zh, this message translates to:
  /// **'黑胜'**
  String get blackWins;

  /// No description provided for @blackWinsBy.
  ///
  /// In zh, this message translates to:
  /// **'黑胜{points}目'**
  String blackWinsBy(String points);

  /// No description provided for @whiteWins.
  ///
  /// In zh, this message translates to:
  /// **'白胜'**
  String get whiteWins;

  /// No description provided for @whiteWinsBy.
  ///
  /// In zh, this message translates to:
  /// **'白胜{points}目'**
  String whiteWinsBy(String points);

  /// No description provided for @drawResult.
  ///
  /// In zh, this message translates to:
  /// **'和棋'**
  String get drawResult;

  /// No description provided for @voidedResult.
  ///
  /// In zh, this message translates to:
  /// **'无胜负'**
  String get voidedResult;

  /// No description provided for @noAnalyzableKifu.
  ///
  /// In zh, this message translates to:
  /// **'没有可分析的棋谱'**
  String get noAnalyzableKifu;

  /// No description provided for @selectAnalyzableKifu.
  ///
  /// In zh, this message translates to:
  /// **'请从棋谱首页选择完整棋谱或已确认的当前局面。'**
  String get selectAnalyzableKifu;

  /// No description provided for @kifuNeedsConfirmation.
  ///
  /// In zh, this message translates to:
  /// **'棋谱仍需确认'**
  String get kifuNeedsConfirmation;

  /// No description provided for @completeBeforeAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'补全并通过规则校验后，才能开始全局复盘。'**
  String get completeBeforeAnalysis;

  /// No description provided for @savePlayerToMoveFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法保存行棋方，请检查可用空间后重试。'**
  String get savePlayerToMoveFailed;

  /// No description provided for @cancelAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消分析？'**
  String get cancelAnalysisTitle;

  /// No description provided for @cancelAnalysisBody.
  ///
  /// In zh, this message translates to:
  /// **'当前服务请求会立即终止；之后可以重新开始。'**
  String get cancelAnalysisBody;

  /// No description provided for @continueAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'继续分析'**
  String get continueAnalysis;

  /// No description provided for @analyzeKifuTitle.
  ///
  /// In zh, this message translates to:
  /// **'分析棋谱'**
  String get analyzeKifuTitle;

  /// No description provided for @globalAnalysisRunning.
  ///
  /// In zh, this message translates to:
  /// **'全局分析中'**
  String get globalAnalysisRunning;

  /// No description provided for @analysisQueuedTitle.
  ///
  /// In zh, this message translates to:
  /// **'等待桌面引擎'**
  String get analysisQueuedTitle;

  /// No description provided for @analysisQueuePosition.
  ///
  /// In zh, this message translates to:
  /// **'队列第 {position} 位 · 当前分析结束后自动开始'**
  String analysisQueuePosition(int position);

  /// No description provided for @analysisQueuePositionCompact.
  ///
  /// In zh, this message translates to:
  /// **'队列 #{position}'**
  String analysisQueuePositionCompact(int position);

  /// No description provided for @statusQueued.
  ///
  /// In zh, this message translates to:
  /// **'排队中'**
  String get statusQueued;

  /// No description provided for @connectingAnalysisService.
  ///
  /// In zh, this message translates to:
  /// **'正在连接分析服务'**
  String get connectingAnalysisService;

  /// No description provided for @analyzedPositionProgress.
  ///
  /// In zh, this message translates to:
  /// **'{completed} / {total} 个局面'**
  String analyzedPositionProgress(int completed, int total);

  /// No description provided for @reviewGenerated.
  ///
  /// In zh, this message translates to:
  /// **'复盘已生成'**
  String get reviewGenerated;

  /// No description provided for @positionAnalysisComplete.
  ///
  /// In zh, this message translates to:
  /// **'局面分析完成'**
  String get positionAnalysisComplete;

  /// No description provided for @analyzedPositionsWithModel.
  ///
  /// In zh, this message translates to:
  /// **'{completed} 个局面 · {model}'**
  String analyzedPositionsWithModel(int completed, String model);

  /// No description provided for @analysisInvalidResult.
  ///
  /// In zh, this message translates to:
  /// **'分析服务返回了无效结果。'**
  String get analysisInvalidResult;

  /// No description provided for @analysisCancelled.
  ///
  /// In zh, this message translates to:
  /// **'分析已取消'**
  String get analysisCancelled;

  /// No description provided for @incompleteResultsDiscarded.
  ///
  /// In zh, this message translates to:
  /// **'未保留不完整结果'**
  String get incompleteResultsDiscarded;

  /// No description provided for @completedPositions.
  ///
  /// In zh, this message translates to:
  /// **'已完成 {count} 个局面'**
  String completedPositions(int count);

  /// No description provided for @analysisServiceRequired.
  ///
  /// In zh, this message translates to:
  /// **'需要配置分析服务'**
  String get analysisServiceRequired;

  /// No description provided for @addWssServiceRetry.
  ///
  /// In zh, this message translates to:
  /// **'添加 WSS KataGo 服务后重试。'**
  String get addWssServiceRetry;

  /// No description provided for @cancelAnalysisSemantics.
  ///
  /// In zh, this message translates to:
  /// **'取消分析。离开此页后，应用内任务继续运行'**
  String get cancelAnalysisSemantics;

  /// No description provided for @cancelQueuedAnalysisSemantics.
  ///
  /// In zh, this message translates to:
  /// **'取消这项排队分析'**
  String get cancelQueuedAnalysisSemantics;

  /// No description provided for @openReview.
  ///
  /// In zh, this message translates to:
  /// **'打开复盘'**
  String get openReview;

  /// No description provided for @openKeyMoveReview.
  ///
  /// In zh, this message translates to:
  /// **'打开关键手复盘'**
  String get openKeyMoveReview;

  /// No description provided for @viewCandidates.
  ///
  /// In zh, this message translates to:
  /// **'查看候选'**
  String get viewCandidates;

  /// No description provided for @viewPositionCandidates.
  ///
  /// In zh, this message translates to:
  /// **'查看局面候选'**
  String get viewPositionCandidates;

  /// No description provided for @reanalyze.
  ///
  /// In zh, this message translates to:
  /// **'重新分析'**
  String get reanalyze;

  /// No description provided for @sendBeforeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'发送前确认'**
  String get sendBeforeConfirm;

  /// No description provided for @sendPositionToHost.
  ///
  /// In zh, this message translates to:
  /// **'将当前盘面发送到 {host}；照片原图不会上传。'**
  String sendPositionToHost(String host);

  /// No description provided for @sendRecordToHost.
  ///
  /// In zh, this message translates to:
  /// **'将完整棋谱发送到 {host} 进行 KataGo 分析。'**
  String sendRecordToHost(String host);

  /// No description provided for @confirmAndStart.
  ///
  /// In zh, this message translates to:
  /// **'确认并开始'**
  String get confirmAndStart;

  /// No description provided for @viewPrivacyBoundary.
  ///
  /// In zh, this message translates to:
  /// **'查看隐私边界'**
  String get viewPrivacyBoundary;

  /// No description provided for @katagoUnconfigured.
  ///
  /// In zh, this message translates to:
  /// **'尚未配置 KataGo'**
  String get katagoUnconfigured;

  /// No description provided for @katagoConfigDetail.
  ///
  /// In zh, this message translates to:
  /// **'导入可信的 WSS 分析服务清单；访问令牌只存入系统安全区。'**
  String get katagoConfigDetail;

  /// No description provided for @configureAnalysisService.
  ///
  /// In zh, this message translates to:
  /// **'配置分析服务'**
  String get configureAnalysisService;

  /// No description provided for @nextPlayerQuestion.
  ///
  /// In zh, this message translates to:
  /// **'下一手轮到谁？'**
  String get nextPlayerQuestion;

  /// No description provided for @photoNoTimingPlayerDetail.
  ///
  /// In zh, this message translates to:
  /// **'照片没有落子时间；必须确认行棋方，候选胜率才有明确含义。'**
  String get photoNoTimingPlayerDetail;

  /// No description provided for @creatingAnalysisTask.
  ///
  /// In zh, this message translates to:
  /// **'正在建立分析任务'**
  String get creatingAnalysisTask;

  /// No description provided for @validatingConfigKifu.
  ///
  /// In zh, this message translates to:
  /// **'正在验证配置与棋谱…'**
  String get validatingConfigKifu;

  /// No description provided for @analysisDataDestinationSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'数据去向清晰可控'**
  String get analysisDataDestinationSubtitle;

  /// No description provided for @analyzingPositionBoard.
  ///
  /// In zh, this message translates to:
  /// **'正在分析的当前局面棋盘'**
  String get analyzingPositionBoard;

  /// No description provided for @analyzingRecordBoard.
  ///
  /// In zh, this message translates to:
  /// **'正在分析的{size}路棋盘，已完成{completed}个局面'**
  String analyzingRecordBoard(int size, int completed);

  /// No description provided for @statusNeedsConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'待配置'**
  String get statusNeedsConfiguration;

  /// No description provided for @statusFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get statusFailed;

  /// No description provided for @statusCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get statusCancelled;

  /// No description provided for @analysisFailureCancel.
  ///
  /// In zh, this message translates to:
  /// **'无法取消分析请求。'**
  String get analysisFailureCancel;

  /// No description provided for @analysisFailureProviderCreation.
  ///
  /// In zh, this message translates to:
  /// **'无法建立分析服务连接。'**
  String get analysisFailureProviderCreation;

  /// No description provided for @analysisFailureInvalidResult.
  ///
  /// In zh, this message translates to:
  /// **'分析结果未通过校验。'**
  String get analysisFailureInvalidResult;

  /// No description provided for @analysisFailureProvider.
  ///
  /// In zh, this message translates to:
  /// **'分析服务发生错误。'**
  String get analysisFailureProvider;

  /// No description provided for @analysisFailureStreamEnded.
  ///
  /// In zh, this message translates to:
  /// **'分析连接在完成前中断。'**
  String get analysisFailureStreamEnded;

  /// No description provided for @analysisFailureRemote.
  ///
  /// In zh, this message translates to:
  /// **'分析服务未能完成请求。'**
  String get analysisFailureRemote;

  /// No description provided for @performanceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'单局棋力评估'**
  String get performanceSubtitle;

  /// No description provided for @performancePaneCore.
  ///
  /// In zh, this message translates to:
  /// **'核心'**
  String get performancePaneCore;

  /// No description provided for @performancePanePhases.
  ///
  /// In zh, this message translates to:
  /// **'阶段'**
  String get performancePanePhases;

  /// No description provided for @performancePaneSample.
  ///
  /// In zh, this message translates to:
  /// **'样本'**
  String get performancePaneSample;

  /// No description provided for @confidenceMedium.
  ///
  /// In zh, this message translates to:
  /// **'中等置信度'**
  String get confidenceMedium;

  /// No description provided for @confidenceLow.
  ///
  /// In zh, this message translates to:
  /// **'低置信度'**
  String get confidenceLow;

  /// No description provided for @performanceOverviewSemantics.
  ///
  /// In zh, this message translates to:
  /// **'本局发挥估计，{weak}到{strong}，{interval}，{confidence}，{decisions}'**
  String performanceOverviewSemantics(
    String weak,
    String strong,
    String interval,
    String confidence,
    String decisions,
  );

  /// No description provided for @performanceBoundarySemantics.
  ///
  /// In zh, this message translates to:
  /// **'此结果只表示本局发挥，不是长期棋力或平台段位'**
  String get performanceBoundarySemantics;

  /// No description provided for @performanceBoundaryCompact.
  ///
  /// In zh, this message translates to:
  /// **'仅本局，非长期棋力'**
  String get performanceBoundaryCompact;

  /// No description provided for @performanceBoundaryFull.
  ///
  /// In zh, this message translates to:
  /// **'仅代表这一盘的发挥区间，不是长期棋力或平台段位。'**
  String get performanceBoundaryFull;

  /// No description provided for @averagePointLoss.
  ///
  /// In zh, this message translates to:
  /// **'平均目损'**
  String get averagePointLoss;

  /// No description provided for @pointLossLabel.
  ///
  /// In zh, this message translates to:
  /// **'目损'**
  String get pointLossLabel;

  /// No description provided for @severeMistake.
  ///
  /// In zh, this message translates to:
  /// **'严重失误'**
  String get severeMistake;

  /// No description provided for @phaseOpening.
  ///
  /// In zh, this message translates to:
  /// **'布局'**
  String get phaseOpening;

  /// No description provided for @phaseMiddleGame.
  ///
  /// In zh, this message translates to:
  /// **'中盘'**
  String get phaseMiddleGame;

  /// No description provided for @phaseEndgame.
  ///
  /// In zh, this message translates to:
  /// **'官子'**
  String get phaseEndgame;

  /// No description provided for @phaseMetric.
  ///
  /// In zh, this message translates to:
  /// **'{phase} · {loss} · {moves}'**
  String phaseMetric(String phase, String loss, String moves);

  /// No description provided for @phaseMetricSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{phase}，平均目损{loss}，{moves}'**
  String phaseMetricSemantics(String phase, String loss, String moves);

  /// No description provided for @analysisSampleDetail.
  ///
  /// In zh, this message translates to:
  /// **'{board} · {visits}+访问 · {model}'**
  String analysisSampleDetail(String board, int visits, String model);

  /// No description provided for @checkCompleteNineteen.
  ///
  /// In zh, this message translates to:
  /// **'完整19路非让子棋谱'**
  String get checkCompleteNineteen;

  /// No description provided for @checkMinimumDecisions.
  ///
  /// In zh, this message translates to:
  /// **'至少40个有效决策'**
  String get checkMinimumDecisions;

  /// No description provided for @checkStandardDeepAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'标准或深度全局分析'**
  String get checkStandardDeepAnalysis;

  /// No description provided for @checkProductionCalibration.
  ///
  /// In zh, this message translates to:
  /// **'生产校准模型'**
  String get checkProductionCalibration;

  /// No description provided for @performanceUnavailableTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂不显示棋力区间'**
  String get performanceUnavailableTitle;

  /// No description provided for @performanceUnavailableBody.
  ///
  /// In zh, this message translates to:
  /// **'没有通过留出集覆盖率验证的生产校准模型；不会用演示参数伪造级段。'**
  String get performanceUnavailableBody;

  /// No description provided for @verifiableMetrics.
  ///
  /// In zh, this message translates to:
  /// **'当前仍可验证：平均目损 {loss} · Top-3 {topThree}'**
  String verifiableMetrics(String loss, String topThree);

  /// No description provided for @noCompleteReviewReturn.
  ///
  /// In zh, this message translates to:
  /// **'没有完整复盘数据 · 返回'**
  String get noCompleteReviewReturn;

  /// No description provided for @rankKyu.
  ///
  /// In zh, this message translates to:
  /// **'{value}级'**
  String rankKyu(int value);

  /// No description provided for @rankDan.
  ///
  /// In zh, this message translates to:
  /// **'{value}段'**
  String rankDan(int value);

  /// No description provided for @positionAnalysisTitle.
  ///
  /// In zh, this message translates to:
  /// **'局面分析'**
  String get positionAnalysisTitle;

  /// No description provided for @positionAnalysisSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'当前局面 · 无完整手顺'**
  String get positionAnalysisSubtitle;

  /// No description provided for @positionBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'当前局面分析棋盘，{player}行棋，{count}个候选'**
  String positionBoardSemantics(String player, int count);

  /// No description provided for @staticPositionBoundarySemantics.
  ///
  /// In zh, this message translates to:
  /// **'当前局面不包含完整手顺，不提供关键手和棋力评估'**
  String get staticPositionBoundarySemantics;

  /// No description provided for @staticPositionBoundaryBody.
  ///
  /// In zh, this message translates to:
  /// **'只分析此刻的候选与形势；不显示关键手、时间轴或棋力。'**
  String get staticPositionBoundaryBody;

  /// No description provided for @candidateChoiceSemantics.
  ///
  /// In zh, this message translates to:
  /// **'候选{label}，{move}，{score}'**
  String candidateChoiceSemantics(String label, String move, String score);

  /// No description provided for @candidatePanelSemantics.
  ///
  /// In zh, this message translates to:
  /// **'候选{label}，{move}，{player}胜率{winRate}，黑方目差{score}，{visits}，主变化{pv}'**
  String candidatePanelSemantics(
    String label,
    String move,
    String player,
    String winRate,
    String score,
    String visits,
    String pv,
  );

  /// No description provided for @playerWinRate.
  ///
  /// In zh, this message translates to:
  /// **'{player}胜率'**
  String playerWinRate(String player);

  /// No description provided for @principalVariationNone.
  ///
  /// In zh, this message translates to:
  /// **'主变化：无'**
  String get principalVariationNone;

  /// No description provided for @principalVariationValue.
  ///
  /// In zh, this message translates to:
  /// **'主变化  {value}'**
  String principalVariationValue(String value);

  /// No description provided for @noPlayableCandidate.
  ///
  /// In zh, this message translates to:
  /// **'服务未返回可下候选；可能只剩停一手。'**
  String get noPlayableCandidate;

  /// No description provided for @positionDataExpired.
  ///
  /// In zh, this message translates to:
  /// **'局面数据已失效'**
  String get positionDataExpired;

  /// No description provided for @positionNotAnalyzed.
  ///
  /// In zh, this message translates to:
  /// **'此局面尚未分析'**
  String get positionNotAnalyzed;

  /// No description provided for @realKatagoOnly.
  ///
  /// In zh, this message translates to:
  /// **'候选、胜率、目差和访问数只显示真实 KataGo 结果。'**
  String get realKatagoOnly;

  /// No description provided for @startAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'开始分析'**
  String get startAnalysis;

  /// No description provided for @variationComparisonTitle.
  ///
  /// In zh, this message translates to:
  /// **'变化比较'**
  String get variationComparisonTitle;

  /// No description provided for @variationComparisonSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手 · 实战与候选'**
  String variationComparisonSubtitle(int move);

  /// No description provided for @variationBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手变化比较，当前选择候选{candidate}'**
  String variationBoardSemantics(int move, String candidate);

  /// No description provided for @noComparableCandidate.
  ///
  /// In zh, this message translates to:
  /// **'没有可比较的候选'**
  String get noComparableCandidate;

  /// No description provided for @returnToMainLine.
  ///
  /// In zh, this message translates to:
  /// **'回到主线第{move}手'**
  String returnToMainLine(int move);

  /// No description provided for @variationDetailsSemantics.
  ///
  /// In zh, this message translates to:
  /// **'候选{label}，{move}，胜率{winRate}，黑方目差{score}，{visits}，主变化{pv}，实战{played}，目损{loss}'**
  String variationDetailsSemantics(
    String label,
    String move,
    String winRate,
    String score,
    String visits,
    String pv,
    String played,
    String loss,
  );

  /// No description provided for @playedMoveWithLoss.
  ///
  /// In zh, this message translates to:
  /// **'实战 {move} · {loss}'**
  String playedMoveWithLoss(String move, String loss);

  /// No description provided for @playedMoveValue.
  ///
  /// In zh, this message translates to:
  /// **'实战 {move}'**
  String playedMoveValue(String move);

  /// No description provided for @serviceNoPrincipalVariation.
  ///
  /// In zh, this message translates to:
  /// **'服务未提供主变化'**
  String get serviceNoPrincipalVariation;

  /// No description provided for @realCandidateData.
  ///
  /// In zh, this message translates to:
  /// **'真实候选数据'**
  String get realCandidateData;

  /// No description provided for @noVariationReturn.
  ///
  /// In zh, this message translates to:
  /// **'没有变化数据 · 返回'**
  String get noVariationReturn;

  /// No description provided for @bestCandidate.
  ///
  /// In zh, this message translates to:
  /// **'最佳候选'**
  String get bestCandidate;

  /// No description provided for @candidateVariation.
  ///
  /// In zh, this message translates to:
  /// **'候选变化'**
  String get candidateVariation;

  /// No description provided for @reviewBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手复盘棋盘，显示{count}个真实候选点'**
  String reviewBoardSemantics(int move, int count);

  /// No description provided for @positionMetricSemantics.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手，{leader}方领先{points}目，{leader}方胜率{winRate}'**
  String positionMetricSemantics(
    int move,
    String leader,
    String points,
    String winRate,
  );

  /// No description provided for @positionMetricCompact.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手 · {leader} {points}目 · {winRate}'**
  String positionMetricCompact(
    int move,
    String leader,
    String points,
    String winRate,
  );

  /// No description provided for @positionMetricFull.
  ///
  /// In zh, this message translates to:
  /// **'当前第{move}手    {leader}方领先 {points}目    {leader}胜率 {winRate}'**
  String positionMetricFull(
    int move,
    String leader,
    String points,
    String winRate,
  );

  /// No description provided for @reviewTitle.
  ///
  /// In zh, this message translates to:
  /// **'复盘'**
  String get reviewTitle;

  /// No description provided for @completeAnalysisResults.
  ///
  /// In zh, this message translates to:
  /// **'完整分析结果'**
  String get completeAnalysisResults;

  /// No description provided for @noCompletedReview.
  ///
  /// In zh, this message translates to:
  /// **'没有已完成的复盘'**
  String get noCompletedReview;

  /// No description provided for @verifiedGlobalAnalysisOnly.
  ///
  /// In zh, this message translates to:
  /// **'只有完整且通过验证的全局分析，才会生成关键手复盘。'**
  String get verifiedGlobalAnalysisOnly;

  /// No description provided for @tabletLandscapeHint.
  ///
  /// In zh, this message translates to:
  /// **'请横置平板以使用双栏复盘'**
  String get tabletLandscapeHint;

  /// No description provided for @tabletBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'平板复盘棋盘，第{move}手，显示{count}个候选点'**
  String tabletBoardSemantics(int move, int count);

  /// No description provided for @noReviewDataReturn.
  ///
  /// In zh, this message translates to:
  /// **'没有复盘数据 · 返回棋谱'**
  String get noReviewDataReturn;

  /// No description provided for @quickReview.
  ///
  /// In zh, this message translates to:
  /// **'快速复盘'**
  String get quickReview;

  /// No description provided for @standardReview.
  ///
  /// In zh, this message translates to:
  /// **'标准复盘'**
  String get standardReview;

  /// No description provided for @deepReview.
  ///
  /// In zh, this message translates to:
  /// **'深度复盘'**
  String get deepReview;

  /// No description provided for @regularMoveTitle.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手'**
  String regularMoveTitle(int move);

  /// No description provided for @rankedKeyMoveTitle.
  ///
  /// In zh, this message translates to:
  /// **'关键手 #{rank} · 第{move}手'**
  String rankedKeyMoveTitle(int rank, int move);

  /// No description provided for @keyMoveSemantics.
  ///
  /// In zh, this message translates to:
  /// **'{title}，实战到最佳{comparison}，{detail}'**
  String keyMoveSemantics(String title, String comparison, String detail);

  /// No description provided for @regularMoveBadge.
  ///
  /// In zh, this message translates to:
  /// **'普通手'**
  String get regularMoveBadge;

  /// No description provided for @lossRankBadge.
  ///
  /// In zh, this message translates to:
  /// **'损失排序'**
  String get lossRankBadge;

  /// No description provided for @noCandidateData.
  ///
  /// In zh, this message translates to:
  /// **'没有候选数据'**
  String get noCandidateData;

  /// No description provided for @candidateMetricDetail.
  ///
  /// In zh, this message translates to:
  /// **'{winRate} · {score} · {visits}'**
  String candidateMetricDetail(String winRate, String score, String visits);

  /// No description provided for @bestCandidateSemantics.
  ///
  /// In zh, this message translates to:
  /// **'最佳候选{move}，{detail}'**
  String bestCandidateSemantics(String move, String detail);

  /// No description provided for @pvMoveCount.
  ///
  /// In zh, this message translates to:
  /// **'PV {moves}手'**
  String pvMoveCount(int moves);

  /// No description provided for @trendCompactValue.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手 · 黑方目差 {score} · 黑胜率 {winRate}'**
  String trendCompactValue(int move, String score, String winRate);

  /// No description provided for @globalScoreTrend.
  ///
  /// In zh, this message translates to:
  /// **'全局目差走势'**
  String get globalScoreTrend;

  /// No description provided for @gameMetricsDetail.
  ///
  /// In zh, this message translates to:
  /// **'平均目损 {loss} · Top-3 {topThree} · 严重失误 {severe}'**
  String gameMetricsDetail(String loss, String topThree, String severe);

  /// No description provided for @gameMetricsSemantics.
  ///
  /// In zh, this message translates to:
  /// **'本局数值，{detail}，棋力区间需要已校准模型'**
  String gameMetricsSemantics(String detail);

  /// No description provided for @gameMetricsTitle.
  ///
  /// In zh, this message translates to:
  /// **'本局数值'**
  String get gameMetricsTitle;

  /// No description provided for @totalMovesKeyMoves.
  ///
  /// In zh, this message translates to:
  /// **'{moves}手 · {keyMoves}个关键手'**
  String totalMovesKeyMoves(int moves, int keyMoves);

  /// No description provided for @performanceNeedsCalibration.
  ///
  /// In zh, this message translates to:
  /// **'棋力需校准'**
  String get performanceNeedsCalibration;

  /// No description provided for @boardCorrectionExpired.
  ///
  /// In zh, this message translates to:
  /// **'棋盘校对数据已失效'**
  String get boardCorrectionExpired;

  /// No description provided for @sequenceCorrectionExpired.
  ///
  /// In zh, this message translates to:
  /// **'手顺校对数据已失效'**
  String get sequenceCorrectionExpired;

  /// No description provided for @autoRectifiedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'自动拉正 · {board}'**
  String autoRectifiedSubtitle(String board);

  /// No description provided for @viewOriginal.
  ///
  /// In zh, this message translates to:
  /// **'查看原图'**
  String get viewOriginal;

  /// No description provided for @boardCorrectionSemantics.
  ///
  /// In zh, this message translates to:
  /// **'实体棋盘识别校对，黑{blackCount}子，白{whiteCount}子，{pending}处待确认'**
  String boardCorrectionSemantics(int blackCount, int whiteCount, int pending);

  /// No description provided for @stoneCountsCompact.
  ///
  /// In zh, this message translates to:
  /// **'黑 {blackCount} · 白 {whiteCount}'**
  String stoneCountsCompact(int blackCount, int whiteCount);

  /// No description provided for @confirmCurrentPosition.
  ///
  /// In zh, this message translates to:
  /// **'确认当前局面'**
  String get confirmCurrentPosition;

  /// No description provided for @confirmRemaining.
  ///
  /// In zh, this message translates to:
  /// **'请先确认 {count} 处'**
  String confirmRemaining(int count);

  /// No description provided for @correctSequenceTitle.
  ///
  /// In zh, this message translates to:
  /// **'校对手顺'**
  String get correctSequenceTitle;

  /// No description provided for @numberedDetectedMoves.
  ///
  /// In zh, this message translates to:
  /// **'编号棋谱图 · 已识别 {moves} 手'**
  String numberedDetectedMoves(int moves);

  /// No description provided for @sequenceValidatingSemantics.
  ///
  /// In zh, this message translates to:
  /// **'编号棋谱校对，正在验证完整手顺'**
  String get sequenceValidatingSemantics;

  /// No description provided for @sequenceIssueSemantics.
  ///
  /// In zh, this message translates to:
  /// **'编号棋谱校对，第{move}手需要确认，请选择交叉点'**
  String sequenceIssueSemantics(int move);

  /// No description provided for @reuseAfterCapture.
  ///
  /// In zh, this message translates to:
  /// **'提子后同点复用'**
  String get reuseAfterCapture;

  /// No description provided for @markPassMove.
  ///
  /// In zh, this message translates to:
  /// **'此手为停一手'**
  String get markPassMove;

  /// No description provided for @selectMoveOnBoard.
  ///
  /// In zh, this message translates to:
  /// **'在棋盘选择第{move}手'**
  String selectMoveOnBoard(int move);

  /// No description provided for @confirmMoveAt.
  ///
  /// In zh, this message translates to:
  /// **'确认第{move}手在 {coordinate}'**
  String confirmMoveAt(int move, String coordinate);

  /// No description provided for @saveAsPositionFallback.
  ///
  /// In zh, this message translates to:
  /// **'无法恢复手顺，按当前局面保存'**
  String get saveAsPositionFallback;

  /// No description provided for @sequenceIssueNoFirst.
  ///
  /// In zh, this message translates to:
  /// **'没有识别到第1手，请在棋盘选择位置或标记停一手。'**
  String get sequenceIssueNoFirst;

  /// No description provided for @sequenceIssueMissing.
  ///
  /// In zh, this message translates to:
  /// **'编号缺失；选择对应交叉点会替换该点的误识别编号。'**
  String get sequenceIssueMissing;

  /// No description provided for @sequenceIssueOcr.
  ///
  /// In zh, this message translates to:
  /// **'OCR置信度不足，请核对位置。'**
  String get sequenceIssueOcr;

  /// No description provided for @sequenceIssueColor.
  ///
  /// In zh, this message translates to:
  /// **'棋子颜色与手数奇偶不一致，请核对位置。'**
  String get sequenceIssueColor;

  /// No description provided for @sequenceIssueFinalMismatch.
  ///
  /// In zh, this message translates to:
  /// **'手顺终局与识别盘面不一致，请核对标记位置。'**
  String get sequenceIssueFinalMismatch;

  /// No description provided for @sequenceIssueTooMany.
  ///
  /// In zh, this message translates to:
  /// **'编号手数超过安全处理上限。'**
  String get sequenceIssueTooMany;

  /// No description provided for @sequenceIssueDuplicate.
  ///
  /// In zh, this message translates to:
  /// **'同一手数出现了多个编号，请核对标记。'**
  String get sequenceIssueDuplicate;

  /// No description provided for @sequenceIssueIllegal.
  ///
  /// In zh, this message translates to:
  /// **'手顺违反围棋规则，请核对标记位置。'**
  String get sequenceIssueIllegal;

  /// No description provided for @sequenceValidationFailed.
  ///
  /// In zh, this message translates to:
  /// **'手顺验证失败，请检查标记后重试。'**
  String get sequenceValidationFailed;

  /// No description provided for @validatingGoRules.
  ///
  /// In zh, this message translates to:
  /// **'正在按围棋规则验证'**
  String get validatingGoRules;

  /// No description provided for @moveCannotConfirm.
  ///
  /// In zh, this message translates to:
  /// **'第{move}手无法确认'**
  String moveCannotConfirm(String move);

  /// No description provided for @checkingSequenceRules.
  ///
  /// In zh, this message translates to:
  /// **'正在检查编号连续性、提子、劫和同点复用。'**
  String get checkingSequenceRules;

  /// No description provided for @sequenceVerifiedTitle.
  ///
  /// In zh, this message translates to:
  /// **'手顺验证完成'**
  String get sequenceVerifiedTitle;

  /// No description provided for @sequenceVerifiedSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'编号连续 · 围棋规则通过'**
  String get sequenceVerifiedSubtitle;

  /// No description provided for @verifiedRecordSemantics.
  ///
  /// In zh, this message translates to:
  /// **'已验证的{size}路完整棋谱，共{moves}手'**
  String verifiedRecordSemantics(int size, int moves);

  /// No description provided for @saveAndStartReview.
  ///
  /// In zh, this message translates to:
  /// **'保存并开始复盘'**
  String get saveAndStartReview;

  /// No description provided for @rescanWithReason.
  ///
  /// In zh, this message translates to:
  /// **'{reason} · 重新识谱'**
  String rescanWithReason(String reason);

  /// No description provided for @originalImageUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法显示原图'**
  String get originalImageUnavailable;

  /// No description provided for @scanResultTitle.
  ///
  /// In zh, this message translates to:
  /// **'识别结果'**
  String get scanResultTitle;

  /// No description provided for @scanResultSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'当前局面 · {board}'**
  String scanResultSubtitle(String board);

  /// No description provided for @scanResultBoardSemantics.
  ///
  /// In zh, this message translates to:
  /// **'识别完成的{size}路围棋局面，黑{blackCount}子，白{whiteCount}子'**
  String scanResultBoardSemantics(int size, int blackCount, int whiteCount);

  /// No description provided for @boardRecognitionComplete.
  ///
  /// In zh, this message translates to:
  /// **'棋盘识别完成'**
  String get boardRecognitionComplete;

  /// No description provided for @recognizedPositionCounts.
  ///
  /// In zh, this message translates to:
  /// **'已识别当前局面：黑{blackCount}子，白{whiteCount}子。'**
  String recognizedPositionCounts(int blackCount, int whiteCount);

  /// No description provided for @photoNoSequence.
  ///
  /// In zh, this message translates to:
  /// **'单张照片不包含落子时间，无法恢复完整手顺。此局面不会显示关键手时间轴或棋力评估。'**
  String get photoNoSequence;

  /// No description provided for @nextPlayerLabel.
  ///
  /// In zh, this message translates to:
  /// **'下一手'**
  String get nextPlayerLabel;

  /// No description provided for @chooseNextPlayerFirst.
  ///
  /// In zh, this message translates to:
  /// **'先选下一手'**
  String get chooseNextPlayerFirst;

  /// No description provided for @analyzeCurrentPosition.
  ///
  /// In zh, this message translates to:
  /// **'分析当前局面'**
  String get analyzeCurrentPosition;

  /// No description provided for @savePosition.
  ///
  /// In zh, this message translates to:
  /// **'保存局面'**
  String get savePosition;

  /// No description provided for @savePositionAnalysisFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败，当前局面尚未开始分析。'**
  String get savePositionAnalysisFailed;

  /// No description provided for @scanResultExpired.
  ///
  /// In zh, this message translates to:
  /// **'识别结果已失效'**
  String get scanResultExpired;

  /// No description provided for @scanResultExpiredDetail.
  ///
  /// In zh, this message translates to:
  /// **'请返回识谱页重新拍摄或选择照片。'**
  String get scanResultExpiredDetail;

  /// No description provided for @returnToScan.
  ///
  /// In zh, this message translates to:
  /// **'返回识谱'**
  String get returnToScan;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

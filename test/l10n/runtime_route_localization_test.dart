import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/import/presentation/partial_record_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/analysis_progress_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/game_performance_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/position_analysis_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_widgets.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/variation_comparison_screen.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/correction_screens.dart';
import 'package:lizzieyzy_mobile/features/scan/presentation/scan_result_screen.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

void main() {
  const locales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh', 'TW'),
    Locale('en', 'XA'),
  ];

  for (final locale in locales) {
    testWidgets(
      '${locale.toLanguageTag()} localizes every critical runtime route',
      (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(430, 932);
        addTearDown(() {
          tester.view
            ..resetDevicePixelRatio()
            ..resetPhysicalSize();
        });
        final l10n = lookupAppLocalizations(locale);
        final cases = <(Widget, String)>[
          (const PartialRecordScreen(), l10n.partialRecordExpired),
          (const AnalysisProgressScreen(), l10n.noAnalyzableKifu),
          (const KeyMoveReviewScreen(), l10n.noCompletedReview),
          (const PositionAnalysisScreen(), l10n.positionDataExpired),
          (const GamePerformanceScreen(), l10n.noCompleteReviewReturn),
          (const VariationComparisonScreen(), l10n.noVariationReturn),
          (
            const PhysicalBoardCorrectionScreen(),
            l10n.rescanWithReason(l10n.boardCorrectionExpired),
          ),
          (
            const NumberedKifuCorrectionScreen(),
            l10n.rescanWithReason(l10n.sequenceCorrectionExpired),
          ),
          (const ScanResultScreen(), l10n.scanResultExpired),
        ];

        for (final routeCase in cases) {
          await tester.pumpWidget(_localizedApp(locale, routeCase.$1));
          await tester.pumpAndSettle();
          expect(find.text(routeCase.$2), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      },
    );

    testWidgets(
      '${locale.toLanguageTag()} localizes all four review sections',
      (tester) async {
        final l10n = lookupAppLocalizations(locale);
        await tester.pumpWidget(
          _localizedApp(
            locale,
            Scaffold(
              body: ReviewSectionTabs(
                selected: ReviewSection.keyMoves,
                onSelected: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(l10n.reviewKeyMoves), findsOneWidget);
        expect(find.text(l10n.reviewVariations), findsOneWidget);
        expect(find.text(l10n.reviewTrend), findsOneWidget);
        expect(find.text(l10n.reviewGame), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Widget _localizedApp(Locale locale, Widget home) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  theme: LizzieTheme.light(),
  home: home,
);

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/key_move_review_screen.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/review_screen_data.dart';
import 'package:lizzieyzy_mobile/features/review/presentation/variation_comparison_screen.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../support/analysis_app_harness.dart';
import '../support/review_screen_fixture.dart';

void main() {
  Future<void> pumpAtScale(
    WidgetTester tester, {
    required Widget screen,
    required double textScale,
    Locale locale = const Locale('zh'),
  }) async {
    await configureTestView(
      tester,
      size: const Size(393, 852),
      textScale: textScale,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: LizzieTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoVerticalScrolling(WidgetTester tester) {
    final vertical = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where(
          (widget) =>
              widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up,
        );
    expect(vertical, isEmpty);
  }

  void expectParagraphsFullyPainted(Finder root) {
    final textElements = <Element>[
      ...root.evaluate().where((element) => element.widget is Text),
      ...find.descendant(of: root, matching: find.byType(Text)).evaluate(),
    ];
    final paragraphs = textElements
        .map((element) => element.renderObject)
        .whereType<RenderParagraph>();
    expect(paragraphs, isNotEmpty);
    for (final paragraph in paragraphs) {
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: 'Dynamic-type content must not truncate a keyed paragraph',
      );
    }
  }

  for (final scale in <double>[2, 3.2]) {
    testWidgets('review numerics remain complete at ${scale}x', (tester) async {
      await pumpAtScale(
        tester,
        screen: KeyMoveReviewScreen(data: reviewScreenFixture()),
        textScale: scale,
      );

      expectNoVerticalScrolling(tester);
      expectParagraphsFullyPainted(
        find.byKey(const Key('review-numeric-content')),
      );
      expect(tester.takeException(), isNull);

      for (final tab in <String>['变化', '本局', '关键手']) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expectParagraphsFullyPainted(
          find.byKey(const Key('review-numeric-content')),
        );
        expect(tester.takeException(), isNull);
      }

      await tester.tap(find.text('走势'));
      await tester.pumpAndSettle();
      expectParagraphsFullyPainted(
        find.byKey(const Key('review-trend-numeric-content')),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('variation metrics and PV remain complete at ${scale}x', (
      tester,
    ) async {
      final review = reviewScreenFixture();
      await pumpAtScale(
        tester,
        screen: VariationComparisonScreen(
          selection: ReviewMoveSelection(
            data: review,
            moveNumber: review.primaryMoment!.moveNumber,
          ),
        ),
        textScale: scale,
      );

      expectNoVerticalScrolling(tester);
      for (final key in <String>[
        'variation-primary-metrics',
        if (scale >= 2.5) 'variation-secondary-metrics',
        'variation-pv',
        'variation-played-loss',
      ]) {
        expectParagraphsFullyPainted(find.byKey(Key(key)));
      }
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: exception is FlutterError
            ? exception.toStringDeep()
            : exception?.toString(),
      );
    });
  }

  testWidgets('3.2x variation numerics remain complete in every locale', (
    tester,
  ) async {
    final review = reviewScreenFixture();
    for (final locale in AppLocalizations.supportedLocales) {
      await pumpAtScale(
        tester,
        screen: VariationComparisonScreen(
          selection: ReviewMoveSelection(
            data: review,
            moveNumber: review.primaryMoment!.moveNumber,
          ),
        ),
        textScale: 3.2,
        locale: locale,
      );

      for (final key in <String>[
        'variation-primary-metrics',
        'variation-secondary-metrics',
        'variation-pv',
        'variation-played-loss',
      ]) {
        expectParagraphsFullyPainted(find.byKey(Key(key)));
      }
      expectNoVerticalScrolling(tester);
      final exception = tester.takeException();
      expect(exception, isNull, reason: locale.toLanguageTag());
    }
  });
}

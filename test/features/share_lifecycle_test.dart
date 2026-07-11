import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

void main() {
  testWidgets('export cleanup runs at app startup and each later resume', (
    tester,
  ) async {
    final export = _MaintenanceExportService();
    await tester.pumpWidget(LizzieYzyApp(exportService: export));
    await tester.pump();
    expect(export.cleanupCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(export.cleanupCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(export.cleanupCalls, 2);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('export cleanup failure never escapes the lifecycle boundary', (
    tester,
  ) async {
    final export = _MaintenanceExportService(shouldFail: true);
    await tester.pumpWidget(LizzieYzyApp(exportService: export));
    await tester.pump();

    expect(export.cleanupCalls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _MaintenanceExportService
    implements KifuExportService, KifuExportArtifactMaintenance {
  _MaintenanceExportService({this.shouldFail = false});

  final bool shouldFail;
  int cleanupCalls = 0;

  @override
  Future<void> cleanupStaleArtifacts() async {
    cleanupCalls += 1;
    if (shouldFail) throw StateError('filesystem detail');
  }

  @override
  Future<KifuShareOutcome> share(
    KifuDocument document, {
    ShareAnchor? anchor,
  }) async => KifuShareOutcome.success;
}

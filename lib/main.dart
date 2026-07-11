import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/app/app.dart';
import 'package:lizzieyzy_mobile/application/inbound_kifu_controller.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/application/native_license_registry.dart';
import 'package:lizzieyzy_mobile/application/settings/settings.dart';
import 'package:lizzieyzy_mobile/infrastructure/persistence/persistence.dart';
import 'package:lizzieyzy_mobile/infrastructure/settings/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerNativeLicenseEntries();
  const initialRoute = String.fromEnvironment(
    'LIZZIEYZY_INITIAL_ROUTE',
    defaultValue: AppRoutes.root,
  );
  final settings = AppSettingsController(
    repository: PlatformAppSettingsRepository(),
  );
  final workspace = KifuWorkspaceController(repository: FileKifuRepository());
  await Future.wait(<Future<void>>[
    settings.initialize(),
    workspace.initialize(),
  ]);
  final inboundKifu = InboundKifuController(workspace: workspace);
  runApp(
    LizzieYzyApp(
      initialRoute: initialRoute,
      settingsController: settings,
      workspaceController: workspace,
      inboundKifuController: inboundKifu,
    ),
  );
  // External providers and iCloud files are untrusted I/O. The first frame is
  // never held behind an inbound document; success or a typed failure appears
  // in the already-mounted home notice.
  unawaited(inboundKifu.initialize());
}

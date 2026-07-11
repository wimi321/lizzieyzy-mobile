import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/kifu_workspace.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import 'app_routes.dart';

class LizzieYzyApp extends StatefulWidget {
  const LizzieYzyApp({
    super.key,
    this.initialRoute = AppRoutes.root,
    this.workspaceController,
  });

  final String initialRoute;
  final KifuWorkspaceController? workspaceController;

  @override
  State<LizzieYzyApp> createState() => _LizzieYzyAppState();
}

class _LizzieYzyAppState extends State<LizzieYzyApp> {
  late final KifuWorkspaceController _workspace =
      widget.workspaceController ?? KifuWorkspaceController();
  late final bool _ownsWorkspace = widget.workspaceController == null;

  @override
  void dispose() {
    if (_ownsWorkspace) _workspace.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KifuWorkspace(
      controller: _workspace,
      child: MaterialApp(
        title: 'LizzieYZY Mobile',
        debugShowCheckedModeBanner: false,
        theme: LizzieTheme.light(),
        darkTheme: LizzieTheme.dark(),
        themeMode: ThemeMode.light,
        initialRoute: widget.initialRoute,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        builder: (context, child) {
          final size = MediaQuery.sizeOf(context);
          final isLandscapePhone =
              size.width > size.height && size.shortestSide < 600;
          if (!isLandscapePhone) return child ?? const SizedBox.shrink();
          return const _PortraitPhoneGuard();
        },
      ),
    );
  }
}

class _PortraitPhoneGuard extends StatelessWidget {
  const _PortraitPhoneGuard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Semantics(
            liveRegion: true,
            label: '手机端请竖屏使用，平板横屏不受限制',
            child: Padding(
              padding: const EdgeInsets.all(GoSpacing.s6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.screen_rotation_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: GoSpacing.s4),
                  Text('请竖屏使用', style: theme.textTheme.titleLarge),
                  const SizedBox(height: GoSpacing.s2),
                  Text(
                    '棋盘、数值与操作会在竖屏内完整呈现',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

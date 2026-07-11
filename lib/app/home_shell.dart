import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../features/home/presentation/kifu_home_screen.dart';
import '../features/scan/presentation/camera_capture_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.scanController});

  /// Test seam for proving that camera permission is requested lazily.
  final ScanCaptureController? scanController;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _index = 0;
  var _scanMounted = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _index == 1
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            const KifuHomeScreen(embedded: true),
            if (_scanMounted)
              CameraCaptureScreen(
                embedded: true,
                controller: widget.scanController,
              )
            else
              const ColoredBox(color: GoCameraColors.background),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 64,
          selectedIndex: _index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => setState(() {
            _index = index;
            // Removing the camera subtree when leaving the tab releases the
            // controller, preview texture, and green privacy indicator.
            _scanMounted = index == 1;
          }),
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: const Icon(Icons.grid_view_outlined),
              selectedIcon: const Icon(Icons.grid_view_rounded),
              label: context.l10n.kifuTab,
              tooltip: context.l10n.kifuHomeTooltip,
            ),
            NavigationDestination(
              icon: const Icon(Icons.document_scanner_outlined),
              selectedIcon: const Icon(Icons.document_scanner_rounded),
              label: context.l10n.scanTab,
              tooltip: context.l10n.photoScanTooltip,
            ),
          ],
        ),
      ),
    );
  }
}

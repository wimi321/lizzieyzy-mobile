import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';

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
              const ColoredBox(color: Color(0xFF0B100D)),
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
          destinations: const <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: '棋谱',
              tooltip: '棋谱首页',
            ),
            NavigationDestination(
              icon: Icon(Icons.document_scanner_outlined),
              selectedIcon: Icon(Icons.document_scanner_rounded),
              label: '识谱',
              tooltip: '拍照识谱',
            ),
          ],
        ),
      ),
    );
  }
}

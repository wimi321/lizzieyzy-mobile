import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';

import '../../../app/app_routes.dart';

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({
    super.key,
    this.embedded = false,
    this.controller,
  });

  final bool embedded;
  final ScanCaptureController? controller;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  late final ScanCaptureController _controller =
      widget.controller ??
      ScanCaptureController(platform: PluginScanCapturePlatform());
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);
    unawaited(_controller.initialize());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_controller.resume());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_controller.suspend());
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_navigating || _controller.phase != ScanCapturePhase.ready) return;
    final payload = await _controller.captureCamera();
    await _openCorrection(payload);
  }

  Future<void> _pickImage() async {
    if (_navigating || _controller.phase == ScanCapturePhase.recognizing) {
      return;
    }
    final payload = await _controller.pickFromLibrary();
    await _openCorrection(payload);
  }

  Future<void> _retry() async {
    if (_controller.hasRetryableCapture) {
      final payload = await _controller.retryLastAttempt();
      await _openCorrection(payload);
    } else {
      await _controller.initialize();
    }
  }

  Future<void> _openCorrection(ScanCapturePayload? payload) async {
    if (!mounted || payload == null) return;
    _navigating = true;
    final shouldResumeCamera = _controller.phase == ScanCapturePhase.ready;
    try {
      if (shouldResumeCamera) await _controller.suspend();
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        AppRoutes.boardCorrection,
        arguments: payload,
      );
    } finally {
      if (mounted && shouldResumeCamera) await _controller.resume();
      _navigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final view = _CameraCaptureView(
      embedded: widget.embedded,
      controller: _controller,
      onCapture: _capture,
      onPickImage: _pickImage,
      onRetry: _retry,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: widget.embedded
          ? view
          : Scaffold(backgroundColor: const Color(0xFF0B100D), body: view),
    );
  }
}

class _CameraCaptureView extends StatelessWidget {
  const _CameraCaptureView({
    required this.embedded,
    required this.controller,
    required this.onCapture,
    required this.onPickImage,
    required this.onRetry,
  });

  final bool embedded;
  final ScanCaptureController controller;
  final VoidCallback onCapture;
  final VoidCallback onPickImage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ColoredBox(
      color: const Color(0xFF0B100D),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final frameSide = math.min(
              constraints.maxWidth - GoSpacing.s6,
              constraints.maxHeight * 0.58,
            );
            return Column(
              children: <Widget>[
                SizedBox(
                  height: 52,
                  child: Row(
                    children: <Widget>[
                      const SizedBox(width: GoSpacing.s2),
                      if (!embedded)
                        IconButton(
                          tooltip: '关闭相机',
                          onPressed: () => Navigator.maybePop(context),
                          color: Colors.white,
                          icon: const Icon(Icons.close_rounded),
                        )
                      else
                        const SizedBox(width: GoSizes.minimumTouchTarget),
                      const Expanded(
                        child: Text(
                          '拍照识谱',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _flashLabel(controller.flashMode),
                        onPressed: controller.phase == ScanCapturePhase.ready
                            ? controller.cycleFlash
                            : null,
                        color: Colors.white,
                        disabledColor: Colors.white38,
                        icon: Icon(_flashIcon(controller.flashMode)),
                      ),
                      const SizedBox(width: GoSpacing.s2),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Semantics(
                      image: true,
                      label: '相机取景框，十九路棋盘需完整入框',
                      child: SizedBox.square(
                        dimension: frameSide,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GoRadii.card),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(
                                color: const Color(0xFF090C0A),
                                child:
                                    controller.buildPreview() ??
                                    const CustomPaint(
                                      painter: _CameraBoardPainter(),
                                    ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0x6673CBAE),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    GoRadii.card,
                                  ),
                                ),
                              ),
                              const _CornerGuides(),
                              if (controller.phase ==
                                  ScanCapturePhase.initializing)
                                const _CameraStateOverlay(
                                  icon: Icons.camera_outlined,
                                  message: '正在启动相机…',
                                  progress: true,
                                ),
                              if (controller.phase ==
                                  ScanCapturePhase.recognizing)
                                const _CameraStateOverlay(
                                  icon: Icons.grid_on_rounded,
                                  message: '正在识别 361 个交叉点…',
                                  progress: true,
                                ),
                              if (controller.phase == ScanCapturePhase.failure)
                                _CameraStateOverlay(
                                  icon: Icons.camera_alt_outlined,
                                  message: controller.errorMessage ?? '相机暂时不可用',
                                  actionLabel: '重试',
                                  onAction: onRetry,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _AlignmentStatus(phase: controller.phase),
                const SizedBox(height: GoSpacing.s2),
                Padding(
                  padding: EdgeInsets.only(
                    left: GoSpacing.s6,
                    right: GoSpacing.s6,
                    bottom: media.padding.bottom > 0
                        ? GoSpacing.s1
                        : GoSpacing.s3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      _CameraAction(
                        icon: Icons.photo_library_outlined,
                        label: '相册',
                        onTap: controller.phase == ScanCapturePhase.recognizing
                            ? null
                            : onPickImage,
                      ),
                      Semantics(
                        button: true,
                        enabled: controller.phase == ScanCapturePhase.ready,
                        label: '拍照',
                        child: InkResponse(
                          onTap: controller.phase == ScanCapturePhase.ready
                              ? onCapture
                              : null,
                          radius: 44,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 160),
                            opacity: controller.phase == ScanCapturePhase.ready
                                ? 1
                                : 0.45,
                            child: Container(
                              width: 68,
                              height: 68,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _CameraAction(
                        icon: Icons.help_outline_rounded,
                        label: '拍摄帮助',
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (context) => const _CaptureHelpDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AlignmentStatus extends StatelessWidget {
  const _AlignmentStatus({required this.phase});

  final ScanCapturePhase phase;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (phase) {
      ScanCapturePhase.ready => (
        Icons.center_focus_strong_rounded,
        '完整棋盘入框 · 保持稳定',
        const Color(0xFF73CBAE),
      ),
      ScanCapturePhase.recognizing => (
        Icons.hourglass_top_rounded,
        '识别中 · 请勿离开',
        const Color(0xFFD8B77D),
      ),
      ScanCapturePhase.failure => (
        Icons.info_outline_rounded,
        '可改用相册继续',
        const Color(0xFFE2B35F),
      ),
      _ => (Icons.camera_outlined, '正在准备取景', const Color(0xFFB6C1BA)),
    };
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GoSpacing.s4,
          vertical: GoSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: const Color(0xE619221D),
          borderRadius: BorderRadius.circular(GoRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 18),
            const SizedBox(width: GoSpacing.s2),
            Flexible(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraStateOverlay extends StatelessWidget {
  const _CameraStateOverlay({
    required this.icon,
    required this.message,
    this.progress = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final bool progress;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xB30B100D),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GoSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                progress ? Icons.hourglass_top_rounded : icon,
                color: progress ? const Color(0xFF73CBAE) : Colors.white,
                size: 30,
              ),
              const SizedBox(height: GoSpacing.s3),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              if (actionLabel != null) ...<Widget>[
                const SizedBox(height: GoSpacing.s3),
                FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: SizedBox(
          width: 72,
          height: 68,
          child: Opacity(
            opacity: onTap == null ? 0.45 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureHelpDialog extends StatelessWidget {
  const _CaptureHelpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('拍摄完整棋盘'),
      content: const Text('让四个角都在绿色框内，镜头尽量正对棋盘，并避开棋子上的强反光。'),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('知道了'),
        ),
      ],
    );
  }
}

String _flashLabel(ScanFlashMode mode) => switch (mode) {
  ScanFlashMode.automatic => '闪光灯，自动',
  ScanFlashMode.off => '闪光灯，关闭',
  ScanFlashMode.on => '闪光灯，开启',
};

IconData _flashIcon(ScanFlashMode mode) => switch (mode) {
  ScanFlashMode.automatic => Icons.flash_auto_rounded,
  ScanFlashMode.off => Icons.flash_off_rounded,
  ScanFlashMode.on => Icons.flash_on_rounded,
};

class _CornerGuides extends StatelessWidget {
  const _CornerGuides();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _CornerPainter(color: const Color(0xFF73CBAE)),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const length = 30.0;
    final inset = size.shortestSide * 0.05;
    final paths = <Path>[
      Path()
        ..moveTo(inset, length)
        ..lineTo(inset, inset)
        ..lineTo(length, inset),
      Path()
        ..moveTo(size.width - length, inset)
        ..lineTo(size.width - inset, inset)
        ..lineTo(size.width - inset, length),
      Path()
        ..moveTo(inset, size.height - length)
        ..lineTo(inset, size.height - inset)
        ..lineTo(length, size.height - inset),
      Path()
        ..moveTo(size.width - length, size.height - inset)
        ..lineTo(size.width - inset, size.height - inset)
        ..lineTo(size.width - inset, size.height - length),
    ];
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CameraBoardPainter extends CustomPainter {
  const _CameraBoardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFF725B3E), Color(0xFFB18E5A)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final gridPaint = Paint()
      ..color = const Color(0xC83F3022)
      ..strokeWidth = 0.75;
    final inset = size.width * 0.065;
    final step = (size.width - inset * 2) / 18;
    for (var i = 0; i < 19; i++) {
      final offset = inset + step * i;
      canvas.drawLine(
        Offset(inset, offset),
        Offset(size.width - inset, offset),
        gridPaint,
      );
      canvas.drawLine(
        Offset(offset, inset),
        Offset(offset, size.height - inset),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

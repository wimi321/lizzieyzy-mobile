import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/design_system/design_system.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart' as domain;
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

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
  Future<void> _cameraTransition = Future<void>.value();
  bool? _lastRequestedCameraActive;
  bool _navigating = false;
  bool _usingGuideFallback = false;
  bool _disposed = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);
    _lifecycleState =
        WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;
    unawaited(
      _requestCameraActive(_lifecycleState == AppLifecycleState.resumed),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_navigating ||
            !mounted ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        unawaited(_requestCameraActive(true));
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_requestCameraActive(false));
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCameraActive(bool active) {
    if (_disposed) return Future<void>.value();
    if (_lastRequestedCameraActive == active) return _cameraTransition;
    _lastRequestedCameraActive = active;
    final operation = _cameraTransition.then((_) async {
      if (_disposed) return;
      if (active) {
        await _controller.resume();
      } else {
        await _controller.suspend();
      }
    });
    _cameraTransition = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
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

  Future<void> _retryWithGuide() async {
    if (_navigating || !_controller.canUseGuideFallback) return;
    setState(() => _usingGuideFallback = true);
    try {
      final payload = await _controller.retryWithGuide();
      await _openCorrection(payload);
    } finally {
      if (mounted) setState(() => _usingGuideFallback = false);
    }
  }

  Future<void> _openCorrection(ScanCapturePayload? payload) async {
    if (!mounted || payload == null) return;
    _navigating = true;
    final shouldResumeCamera = _controller.phase == ScanCapturePhase.ready;
    try {
      if (shouldResumeCamera) await _requestCameraActive(false);
      if (!mounted) return;
      await Navigator.pushNamed(
        context,
        payload.draft.kind == domain.ScanKind.numberedDiagram
            ? AppRoutes.numberedCorrection
            : AppRoutes.boardCorrection,
        arguments: payload,
      );
    } finally {
      _navigating = false;
      if (mounted &&
          shouldResumeCamera &&
          _lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        await _requestCameraActive(true);
      }
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
      onGuideFallback: _retryWithGuide,
      guideFallbackInProgress: _usingGuideFallback,
    );
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: widget.embedded
          ? view
          : Scaffold(backgroundColor: GoCameraColors.background, body: view),
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
    required this.onGuideFallback,
    required this.guideFallbackInProgress,
  });

  final bool embedded;
  final ScanCaptureController controller;
  final VoidCallback onCapture;
  final VoidCallback onPickImage;
  final VoidCallback onRetry;
  final VoidCallback onGuideFallback;
  final bool guideFallbackInProgress;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final l10n = context.l10n;
    return ColoredBox(
      color: GoCameraColors.background,
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
                          tooltip: l10n.closeCamera,
                          onPressed: () => Navigator.maybePop(context),
                          color: GoCameraColors.foreground,
                          icon: const Icon(Icons.close_rounded),
                        )
                      else
                        const SizedBox(width: GoSizes.minimumTouchTarget),
                      Expanded(
                        child: Text(
                          l10n.photoScanTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: GoCameraColors.foreground,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _flashLabel(l10n, controller.flashMode),
                        onPressed: controller.phase == ScanCapturePhase.ready
                            ? controller.cycleFlash
                            : null,
                        color: GoCameraColors.foreground,
                        disabledColor: GoCameraColors.foregroundDisabled,
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
                      label: l10n.cameraViewfinderSemantics,
                      child: SizedBox.square(
                        dimension: frameSide,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GoRadii.card),
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              ColoredBox(
                                color: GoCameraColors.previewFallback,
                                child:
                                    controller.buildPreview() ??
                                    const CustomPaint(
                                      painter: _CameraBoardPainter(),
                                    ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: GoCameraColors.guideGlow,
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
                                _CameraStateOverlay(
                                  icon: Icons.camera_outlined,
                                  message: l10n.startingCamera,
                                  progress: true,
                                ),
                              if (controller.phase ==
                                  ScanCapturePhase.recognizing)
                                _CameraStateOverlay(
                                  icon: Icons.grid_on_rounded,
                                  message: guideFallbackInProgress
                                      ? l10n.guideFallbackRecognizing
                                      : l10n.recognizingIntersections(361),
                                  progress: true,
                                ),
                              if (controller.phase == ScanCapturePhase.failure)
                                _CameraStateOverlay(
                                  icon: Icons.camera_alt_outlined,
                                  message: _failureMessage(
                                    l10n,
                                    controller.failureKind,
                                  ),
                                  detail: controller.canUseGuideFallback
                                      ? l10n.guideFallbackDetail
                                      : null,
                                  actionLabel: controller.canUseGuideFallback
                                      ? l10n.useGuideFallback
                                      : l10n.retry,
                                  onAction: controller.canUseGuideFallback
                                      ? onGuideFallback
                                      : onRetry,
                                  secondaryActionLabel:
                                      controller.canUseGuideFallback
                                      ? l10n.retry
                                      : null,
                                  onSecondaryAction:
                                      controller.canUseGuideFallback
                                      ? onRetry
                                      : null,
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
                        key: const Key('camera-photo-library-action'),
                        icon: Icons.photo_library_outlined,
                        label: l10n.photoLibrary,
                        onTap: controller.phase == ScanCapturePhase.recognizing
                            ? null
                            : onPickImage,
                      ),
                      Semantics(
                        button: true,
                        enabled: controller.phase == ScanCapturePhase.ready,
                        label: l10n.capturePhoto,
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
                                  color: GoCameraColors.foreground,
                                  width: 3,
                                ),
                              ),
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  color: GoCameraColors.foreground,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _CameraAction(
                        key: const Key('camera-help-action'),
                        icon: Icons.help_outline_rounded,
                        label: l10n.captureHelp,
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
    final l10n = context.l10n;
    final (icon, message, color) = switch (phase) {
      ScanCapturePhase.ready => (
        Icons.center_focus_strong_rounded,
        l10n.alignmentReady,
        GoCameraColors.guide,
      ),
      ScanCapturePhase.recognizing => (
        Icons.hourglass_top_rounded,
        l10n.alignmentRecognizing,
        GoCameraColors.recognizing,
      ),
      ScanCapturePhase.failure => (
        Icons.info_outline_rounded,
        l10n.alignmentFallback,
        GoCameraColors.warning,
      ),
      _ => (
        Icons.camera_outlined,
        l10n.alignmentPreparing,
        GoCameraColors.preparing,
      ),
    };
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    final messageForDisplay = extraLargeText
        ? _withoutPseudoExpansion(message)
        : message;
    final displayedMessage = extraLargeText
        ? messageForDisplay
              .split(RegExp(r'\s*[·•|｜]\s*'))
              .map((part) {
                final words = part.trim().split(RegExp(r'\s+'));
                return words.length > 2
                    ? words.sublist(words.length - 2).join(' ')
                    : part.trim();
              })
              .join('\n')
        : message;
    return Semantics(
      liveRegion: true,
      label: message,
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - GoSpacing.s6,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: GoSpacing.s4,
          vertical: GoSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: GoCameraColors.statusSurface,
          borderRadius: BorderRadius.circular(GoRadii.pill),
        ),
        child: extraLargeText
            ? Text(
                displayedMessage,
                key: const Key('camera-alignment-status'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: GoCameraColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: GoSpacing.s2),
                  Flexible(
                    child: Text(
                      displayedMessage,
                      key: const Key('camera-alignment-status'),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: GoCameraColors.foreground,
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
    this.detail,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final IconData icon;
  final String message;
  final bool progress;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final extraLargeText = MediaQuery.textScalerOf(context).scale(1) >= 2.5;
    final messageStyle = TextStyle(
      color: GoCameraColors.foreground,
      fontSize: extraLargeText ? 12 : 14,
      height: extraLargeText ? 1 : 1.35,
    );
    final messageForDisplay = extraLargeText
        ? _withoutPseudoExpansion(message)
        : message;
    final displayedMessage = extraLargeText && detail != null
        ? messageForDisplay.split(RegExp(r'[，,。.．]')).first.trim()
        : messageForDisplay;
    final actionLabels = <(String, VoidCallback?)>[
      if (actionLabel case final label?) (label, onAction),
      if (secondaryActionLabel case final label?) (label, onSecondaryAction),
    ];
    return ColoredBox(
      color: GoCameraColors.stateScrim,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(extraLargeText ? GoSpacing.s2 : GoSpacing.s5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!extraLargeText) ...<Widget>[
                Icon(
                  progress ? Icons.hourglass_top_rounded : icon,
                  color: progress
                      ? GoCameraColors.guide
                      : GoCameraColors.foreground,
                  size: 30,
                ),
                const SizedBox(height: GoSpacing.s3),
              ],
              Semantics(
                label: message,
                excludeSemantics: true,
                child: Text(
                  displayedMessage,
                  key: const Key('camera-state-message'),
                  textAlign: TextAlign.center,
                  maxLines: extraLargeText ? 2 : 3,
                  style: messageStyle,
                ),
              ),
              if (detail case final detail?) ...<Widget>[
                SizedBox(height: extraLargeText ? GoSpacing.s1 : GoSpacing.s2),
                Text(
                  extraLargeText ? _withoutPseudoExpansion(detail) : detail,
                  key: const Key('camera-state-detail'),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  style: messageStyle.copyWith(
                    color: GoCameraColors.foregroundMuted,
                  ),
                ),
              ],
              if (actionLabels.isNotEmpty) ...<Widget>[
                SizedBox(height: extraLargeText ? GoSpacing.s1 : GoSpacing.s3),
                Row(
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < actionLabels.length;
                      index++
                    ) ...<Widget>[
                      if (index > 0) const SizedBox(width: GoSpacing.s1),
                      Expanded(
                        child: FilledButton.tonal(
                          key: Key('camera-state-action-$index'),
                          onPressed: actionLabels[index].$2,
                          child: Text(
                            extraLargeText
                                ? _withoutPseudoExpansion(
                                    actionLabels[index].$1,
                                  )
                                : actionLabels[index].$1,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: extraLargeText
                                ? Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(height: 1)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final largeText = textScale >= 1.6;
    final extraLargeText = textScale >= 2.5;
    final compactLabel = _withoutPseudoExpansion(label);
    final displayedLabel = extraLargeText
        ? compactLabel.trim().split(RegExp(r'\s+')).last
        : label;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: extraLargeText
            ? 56
            : largeText
            ? 40
            : 32,
        child: SizedBox(
          width: extraLargeText
              ? 120
              : largeText
              ? 88
              : 72,
          height: extraLargeText
              ? 112
              : largeText
              ? 76
              : 68,
          child: Opacity(
            opacity: onTap == null ? 0.45 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!extraLargeText) ...<Widget>[
                  Icon(icon, color: GoCameraColors.foreground, size: 24),
                  const SizedBox(height: 2),
                ],
                Text(
                  displayedLabel,
                  key: const Key('camera-action-label'),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GoCameraColors.foreground,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _withoutPseudoExpansion(String value) {
  final match = RegExp(r'⟦([\s\S]*?)⟧').firstMatch(value);
  return match?.group(1) ?? value;
}

class _CaptureHelpDialog extends StatelessWidget {
  const _CaptureHelpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.captureHelpTitle),
      content: Text(context.l10n.captureHelpBody),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.gotIt),
        ),
      ],
    );
  }
}

String _flashLabel(AppLocalizations l10n, ScanFlashMode mode) => switch (mode) {
  ScanFlashMode.automatic => l10n.flashAutomatic,
  ScanFlashMode.off => l10n.flashOff,
  ScanFlashMode.on => l10n.flashOn,
};

String _failureMessage(AppLocalizations l10n, ScanCaptureFailureKind? kind) =>
    switch (kind) {
      ScanCaptureFailureKind.cameraPermissionDenied =>
        l10n.cameraPermissionDenied,
      ScanCaptureFailureKind.cameraRestricted => l10n.cameraRestricted,
      ScanCaptureFailureKind.cameraUnavailable => l10n.cameraUnavailable,
      ScanCaptureFailureKind.cameraCaptureFailed => l10n.cameraCaptureFailed,
      ScanCaptureFailureKind.photoLibraryPermissionDenied =>
        l10n.photoLibraryPermissionDenied,
      ScanCaptureFailureKind.photoLibraryUnavailable =>
        l10n.photoLibraryUnavailable,
      ScanCaptureFailureKind.selectedImageUnreadable =>
        l10n.selectedImageUnreadable,
      ScanCaptureFailureKind.recognitionIncompleteBoard =>
        l10n.recognitionIncompleteBoard,
      ScanCaptureFailureKind.recognitionFailed => l10n.recognitionFailed,
      null => l10n.cameraTemporarilyUnavailable,
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
        painter: const _CornerPainter(color: GoCameraColors.guide),
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
        colors: <Color>[
          GoCameraColors.previewWoodDark,
          GoCameraColors.previewWoodLight,
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, background);
    final gridPaint = Paint()
      ..color = GoCameraColors.previewGrid
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

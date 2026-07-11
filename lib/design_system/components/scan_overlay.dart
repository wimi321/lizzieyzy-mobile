import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/l10n/l10n.dart';

import '../tokens.dart';

/// Camera preview chrome for single-shot board recognition.
class ScanOverlay extends StatelessWidget {
  const ScanOverlay({
    required this.child,
    required this.status,
    super.key,
    this.aligned = false,
    this.onCapture,
    this.onGallery,
    this.onClose,
  });

  final Widget child;
  final String status;
  final bool aligned;
  final VoidCallback? onCapture;
  final VoidCallback? onGallery;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = context.goColors;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ExcludeSemantics(child: child),
          IgnorePointer(
            child: CustomPaint(
              painter: ScanOverlayPainter(
                scrimColor: semantic.scrim,
                frameColor: aligned ? semantic.candidatePrimary : Colors.white,
                aligned: aligned,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(GoSpacing.s4),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox.square(
                        dimension: GoSizes.comfortableTouchTarget,
                        child: onClose == null
                            ? null
                            : _CameraAction(
                                tooltip: context.l10n.closeAction,
                                icon: Icons.close_rounded,
                                onPressed: onClose,
                              ),
                      ),
                      const SizedBox(width: GoSpacing.s2),
                      Expanded(
                        child: Semantics(
                          liveRegion: true,
                          label: status,
                          excludeSemantics: true,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 40),
                            padding: const EdgeInsets.symmetric(
                              horizontal: GoSpacing.s3,
                              vertical: GoSpacing.s2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.68),
                              borderRadius: BorderRadius.circular(GoRadii.pill),
                              border: Border.all(
                                color: aligned
                                    ? semantic.candidatePrimary
                                    : Colors.white.withValues(alpha: 0.46),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  aligned
                                      ? Icons.check_circle_rounded
                                      : Icons.center_focus_weak_rounded,
                                  size: 18,
                                  color: aligned
                                      ? semantic.candidatePrimary
                                      : Colors.white,
                                ),
                                const SizedBox(width: GoSpacing.s2),
                                Flexible(
                                  child: Text(
                                    status,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GoSpacing.s2),
                      const SizedBox.square(
                        dimension: GoSizes.comfortableTouchTarget,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _CameraAction(
                        tooltip: context.l10n.selectFromPhotos,
                        icon: Icons.photo_library_outlined,
                        onPressed: onGallery,
                      ),
                      Semantics(
                        button: true,
                        enabled: onCapture != null,
                        label: context.l10n.photoScanTitle,
                        excludeSemantics: true,
                        child: SizedBox.square(
                          dimension: 80,
                          child: Material(
                            color: Colors.transparent,
                            child: InkResponse(
                              onTap: onCapture,
                              radius: 40,
                              child: Center(
                                child: Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: onCapture == null
                                        ? scheme.onSurface.withValues(
                                            alpha: 0.38,
                                          )
                                        : Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.32,
                                        ),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: GoSizes.comfortableTouchTarget),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraAction extends StatelessWidget {
  const _CameraAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(GoSizes.comfortableTouchTarget),
        backgroundColor: Colors.black.withValues(alpha: 0.62),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white38,
      ),
      icon: Icon(icon),
    );
  }
}

@visibleForTesting
class ScanOverlayPainter extends CustomPainter {
  const ScanOverlayPainter({
    required this.scrimColor,
    required this.frameColor,
    required this.aligned,
  });

  final Color scrimColor;
  final Color frameColor;
  final bool aligned;

  @override
  void paint(Canvas canvas, Size size) {
    final horizontalMargin = math.max(20, size.width * 0.06);
    final maxSquare = math.min(
      size.width - horizontalMargin * 2,
      size.height * 0.62,
    );
    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.47),
      width: maxSquare,
      height: maxSquare,
    );
    final scrim = Paint()..color = scrimColor;
    canvas
      ..drawRect(Rect.fromLTRB(0, 0, size.width, scanRect.top), scrim)
      ..drawRect(
        Rect.fromLTRB(0, scanRect.bottom, size.width, size.height),
        scrim,
      )
      ..drawRect(
        Rect.fromLTRB(0, scanRect.top, scanRect.left, scanRect.bottom),
        scrim,
      )
      ..drawRect(
        Rect.fromLTRB(
          scanRect.right,
          scanRect.top,
          size.width,
          scanRect.bottom,
        ),
        scrim,
      );

    final framePaint = Paint()
      ..color = frameColor
      ..strokeWidth = aligned ? 3 : 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final corner = scanRect.width * 0.11;
    final path = Path()
      ..moveTo(scanRect.left, scanRect.top + corner)
      ..lineTo(scanRect.left, scanRect.top)
      ..lineTo(scanRect.left + corner, scanRect.top)
      ..moveTo(scanRect.right - corner, scanRect.top)
      ..lineTo(scanRect.right, scanRect.top)
      ..lineTo(scanRect.right, scanRect.top + corner)
      ..moveTo(scanRect.right, scanRect.bottom - corner)
      ..lineTo(scanRect.right, scanRect.bottom)
      ..lineTo(scanRect.right - corner, scanRect.bottom)
      ..moveTo(scanRect.left + corner, scanRect.bottom)
      ..lineTo(scanRect.left, scanRect.bottom)
      ..lineTo(scanRect.left, scanRect.bottom - corner);
    canvas.drawPath(path, framePaint);

    final guidePaint = Paint()
      ..color = frameColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.75;
    for (var index = 1; index < 3; index++) {
      final fraction = index / 3;
      canvas
        ..drawLine(
          Offset(scanRect.left + scanRect.width * fraction, scanRect.top),
          Offset(scanRect.left + scanRect.width * fraction, scanRect.bottom),
          guidePaint,
        )
        ..drawLine(
          Offset(scanRect.left, scanRect.top + scanRect.height * fraction),
          Offset(scanRect.right, scanRect.top + scanRect.height * fraction),
          guidePaint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant ScanOverlayPainter oldDelegate) {
    return oldDelegate.scrimColor != scrimColor ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.aligned != aligned;
  }
}

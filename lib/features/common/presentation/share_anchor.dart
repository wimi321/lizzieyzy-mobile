import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/application/kifu_export_service.dart';

/// Resolves a non-empty global popover anchor for iPad share sheets.
///
/// Button contexts normally provide a laid-out [RenderBox]. The centered
/// fallback keeps the platform contract valid if the initiating render object
/// is replaced during a state update.
ShareAnchor resolveShareAnchor(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.hasSize) {
    final origin = renderObject.localToGlobal(Offset.zero);
    final size = renderObject.size;
    if (origin.dx.isFinite &&
        origin.dy.isFinite &&
        size.width.isFinite &&
        size.height.isFinite &&
        size.width > 0 &&
        size.height > 0) {
      return ShareAnchor(
        left: origin.dx,
        top: origin.dy,
        width: size.width,
        height: size.height,
      );
    }
  }
  final viewport = MediaQuery.sizeOf(context);
  return ShareAnchor(
    left: viewport.width / 2,
    top: viewport.height / 2,
    width: 1,
    height: 1,
  );
}

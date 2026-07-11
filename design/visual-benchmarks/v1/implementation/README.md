# Implementation evidence

These images are direct screenshots from the iOS Simulator. They prove that
the benchmark direction was rebuilt with Flutter widgets and `CustomPainter`;
the generated mockups are not embedded in the runtime application.

The generated references define visual intent. Flutter goldens under
`test/goldens/` protect deterministic layout. These simulator captures verify
the real system font, safe areas, device chrome, and final raster output.

Evidence currently covers the iPhone home, physical-board correction, analysis
progress, key-move review, dark variation comparison, and the iPad expanded
review. The iPad framebuffer is mechanically rotated 90 degrees to normalize
Simulator's landscape capture; no pixels, layout, labels, or colors are
otherwise edited.

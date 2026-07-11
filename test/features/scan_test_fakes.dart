import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lizzieyzy_mobile/application/scan/scan.dart';
import 'package:lizzieyzy_mobile/domain/domain.dart';

final class FakeScanCapturePlatform implements ScanCapturePlatform {
  FakeScanCapturePlatform({
    this.initializeError,
    this.captureError,
    this.libraryFrame,
    List<CapturedFrame>? cameraFrames,
  }) : cameraFrames = cameraFrames ?? fakeFrames(3);

  final Object? initializeError;
  final Object? captureError;
  final CapturedFrame? libraryFrame;
  final List<CapturedFrame> cameraFrames;

  int initializeCalls = 0;
  int suspendCalls = 0;
  int captureCalls = 0;
  int libraryCalls = 0;
  int disposeCalls = 0;
  bool ready = false;
  ScanFlashMode mode = ScanFlashMode.automatic;

  @override
  bool get isReady => ready;

  @override
  ScanFlashMode get flashMode => mode;

  @override
  Widget? buildPreview() => ready
      ? const ColoredBox(
          key: Key('fake-camera-preview'),
          color: Color(0xFF725B3E),
        )
      : null;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (initializeError case final error?) throw error;
    ready = true;
  }

  @override
  Future<void> resume() => initialize();

  @override
  Future<void> suspend() async {
    suspendCalls++;
    ready = false;
  }

  @override
  Future<List<CapturedFrame>> takeBurst({int preferredCount = 3}) async {
    captureCalls++;
    if (captureError case final error?) throw error;
    return cameraFrames;
  }

  @override
  Future<CapturedFrame?> pickFromLibrary() async {
    libraryCalls++;
    if (captureError case final error?) throw error;
    return libraryFrame ?? fakeFrame();
  }

  @override
  Future<void> cycleFlash() async {
    mode = switch (mode) {
      ScanFlashMode.automatic => ScanFlashMode.off,
      ScanFlashMode.off => ScanFlashMode.on,
      ScanFlashMode.on => ScanFlashMode.automatic,
    };
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
    ready = false;
  }
}

final class FakeBoardVision implements BoardVision {
  FakeBoardVision({ScanDraft? result, this.error})
    : result = result ?? fakeScanDraft();

  final ScanDraft result;
  final Object? error;
  int recognizeCalls = 0;
  FrameBundle? lastBundle;

  @override
  Future<ScanDraft> recognize(FrameBundle frames) async {
    recognizeCalls++;
    lastBundle = frames;
    if (error case final value?) throw value;
    return result;
  }
}

CapturedFrame fakeFrame([int seed = 1]) => CapturedFrame(
  encodedBytes: Uint8List.fromList(<int>[seed, seed + 1, seed + 2]),
  pixelWidth: 640,
  pixelHeight: 640,
  capturedAt: DateTime.utc(2026, 7, 11, 0, 0, seed),
);

List<CapturedFrame> fakeFrames(int count) => <CapturedFrame>[
  for (var index = 0; index < count; index++) fakeFrame(index + 1),
];

ScanDraft fakeScanDraft({
  ScanKind kind = ScanKind.physicalBoard,
  Map<BoardPoint, StoneColor>? stones,
  Set<BoardPoint>? uncertain,
}) {
  final resolvedStones =
      stones ??
      <BoardPoint, StoneColor>{
        const BoardPoint(3, 3): StoneColor.black,
        const BoardPoint(15, 15): StoneColor.white,
      };
  final resolvedUncertain = uncertain ?? <BoardPoint>{};
  return ScanDraft(
    kind: kind,
    boardSize: BoardSize.nineteen,
    boardBounds: const BoardQuadrilateral(
      topLeft: NormalizedPoint(0.05, 0.05),
      topRight: NormalizedPoint(0.95, 0.05),
      bottomRight: NormalizedPoint(0.95, 0.95),
      bottomLeft: NormalizedPoint(0.05, 0.95),
    ),
    intersections: <IntersectionPrediction>[
      for (var row = 0; row < 19; row++)
        for (var column = 0; column < 19; column++)
          _prediction(
            BoardPoint(column, row),
            resolvedStones[BoardPoint(column, row)],
            resolvedUncertain.contains(BoardPoint(column, row)),
          ),
    ],
    boardConfidence: 0.96,
  );
}

IntersectionPrediction _prediction(
  BoardPoint point,
  StoneColor? stone,
  bool uncertain,
) {
  if (uncertain) {
    return IntersectionPrediction(
      point: point,
      blackProbability: 0.44,
      whiteProbability: 0.31,
      emptyProbability: 0.25,
    );
  }
  return switch (stone) {
    StoneColor.black => IntersectionPrediction(
      point: point,
      blackProbability: 0.98,
      whiteProbability: 0.01,
      emptyProbability: 0.01,
    ),
    StoneColor.white => IntersectionPrediction(
      point: point,
      blackProbability: 0.01,
      whiteProbability: 0.98,
      emptyProbability: 0.01,
    ),
    null => IntersectionPrediction(
      point: point,
      blackProbability: 0.01,
      whiteProbability: 0.01,
      emptyProbability: 0.98,
    ),
  };
}

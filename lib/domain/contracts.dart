import 'analysis.dart';
import 'go_values.dart';
import 'kifu_document.dart';
import 'reports.dart';
import 'scan.dart';

abstract interface class BoardVision {
  Future<ScanDraft> recognize(FrameBundle frames);
}

abstract interface class SequenceSolver {
  Future<KifuDocument> solve(
    List<SequenceToken> tokens,
    GoRules rules, {
    required String documentId,
    required BoardSize boardSize,
    required KifuSource source,
    BoardPosition? initialPosition,
  });
}

abstract interface class AnalysisProvider {
  Future<AnalysisBundle> analyze(AnalysisRequest request);

  Stream<AnalysisEvent> stream(AnalysisRequest request);

  Future<void> cancel(String requestId);
}

abstract interface class ReviewBuilder {
  ReviewReport build(KifuDocument document, AnalysisBundle analysis);
}

abstract interface class GamePerformanceEstimator {
  /// The signature intentionally requires a verified record. A snapshot or a
  /// partial record cannot be passed without an explicit, unsafe cast.
  GamePerformanceReport estimate(
    VerifiedGameRecord record,
    AnalysisBundle analysis,
    ModelManifest manifest,
  );
}

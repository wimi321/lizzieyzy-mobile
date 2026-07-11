enum KifuResourceLimitKind {
  inputBytes,
  inputCharacters,
  gameTrees,
  nodes,
  variationDepth,
  properties,
  propertiesPerNode,
  propertyValues,
  propertyValuesPerProperty,
  moves,
  replayWork,
  propertyIdentifierCharacters,
  propertyValueCharacters,
  lineCharacters,
}

/// Typed, fail-closed error for an input that exceeds a processing budget.
///
/// It is also a [FormatException] so existing import surfaces continue to show
/// a safe validation failure instead of treating a resource rejection as an
/// application crash.
final class KifuResourceLimitException extends FormatException {
  KifuResourceLimitException({
    required this.kind,
    required this.limit,
    required this.actual,
  }) : super(
         'Kifu input exceeds the ${kind.name} limit '
         '($actual > $limit).',
       );

  final KifuResourceLimitKind kind;
  final int limit;
  final int actual;
}

final class KifuTextDecodingException extends FormatException {
  const KifuTextDecodingException()
    : super('The kifu file is not valid UTF-8 text.');
}

/// Shared parser and file-import budgets.
///
/// SGF maps these directly to collection/tree/node/property concepts. GIB is
/// linear, so physical lines consume the node budget and parsed tags/records
/// consume the property and property-value budgets.
final class KifuResourceLimits {
  const KifuResourceLimits({
    this.maxInputBytes = 16 * 1024 * 1024,
    this.maxInputCharacters = 16 * 1024 * 1024,
    this.maxGameTrees = 64,
    this.maxNodes = 50000,
    this.maxVariationDepth = 128,
    this.maxProperties = 250000,
    this.maxPropertiesPerNode = 256,
    this.maxPropertyValues = 500000,
    this.maxPropertyValuesPerProperty = 4096,
    this.maxMoves = 2000,
    this.maxReplayWork = 100000,
    this.maxPropertyIdentifierCharacters = 32,
    this.maxPropertyValueCharacters = 256 * 1024,
    this.maxLineCharacters = 64 * 1024,
  }) : assert(maxInputBytes > 0),
       assert(maxInputCharacters > 0),
       assert(maxGameTrees > 0),
       assert(maxNodes > 0),
       assert(maxVariationDepth > 0),
       assert(maxProperties > 0),
       assert(maxPropertiesPerNode > 0),
       assert(maxPropertyValues > 0),
       assert(maxPropertyValuesPerProperty > 0),
       assert(maxMoves > 0),
       assert(maxReplayWork > 0),
       assert(maxPropertyIdentifierCharacters > 0),
       assert(maxPropertyValueCharacters > 0),
       assert(maxLineCharacters > 0);

  final int maxInputBytes;
  final int maxInputCharacters;
  final int maxGameTrees;
  final int maxNodes;
  final int maxVariationDepth;
  final int maxProperties;
  final int maxPropertiesPerNode;
  final int maxPropertyValues;
  final int maxPropertyValuesPerProperty;

  /// Maximum number of moves replayed on any imported main line.
  final int maxMoves;

  /// Aggregate work budget for copying and validating SGF variations.
  ///
  /// This is intentionally separate from [maxNodes]: a shallow tree with a
  /// long shared prefix and many leaves can otherwise require quadratic work.
  final int maxReplayWork;
  final int maxPropertyIdentifierCharacters;
  final int maxPropertyValueCharacters;
  final int maxLineCharacters;

  void enforceInputBytes(int actual) =>
      _enforce(KifuResourceLimitKind.inputBytes, maxInputBytes, actual);

  void enforceInputCharacters(int actual) => _enforce(
    KifuResourceLimitKind.inputCharacters,
    maxInputCharacters,
    actual,
  );

  void enforceGameTrees(int actual) =>
      _enforce(KifuResourceLimitKind.gameTrees, maxGameTrees, actual);

  void enforceNodes(int actual) =>
      _enforce(KifuResourceLimitKind.nodes, maxNodes, actual);

  void enforceVariationDepth(int actual) =>
      _enforce(KifuResourceLimitKind.variationDepth, maxVariationDepth, actual);

  void enforceProperties(int actual) =>
      _enforce(KifuResourceLimitKind.properties, maxProperties, actual);

  void enforcePropertiesPerNode(int actual) => _enforce(
    KifuResourceLimitKind.propertiesPerNode,
    maxPropertiesPerNode,
    actual,
  );

  void enforcePropertyValues(int actual) =>
      _enforce(KifuResourceLimitKind.propertyValues, maxPropertyValues, actual);

  void enforcePropertyValuesPerProperty(int actual) => _enforce(
    KifuResourceLimitKind.propertyValuesPerProperty,
    maxPropertyValuesPerProperty,
    actual,
  );

  void enforceMoves(int actual) =>
      _enforce(KifuResourceLimitKind.moves, maxMoves, actual);

  void enforceReplayWork(int actual) =>
      _enforce(KifuResourceLimitKind.replayWork, maxReplayWork, actual);

  void enforcePropertyIdentifierCharacters(int actual) => _enforce(
    KifuResourceLimitKind.propertyIdentifierCharacters,
    maxPropertyIdentifierCharacters,
    actual,
  );

  void enforcePropertyValueCharacters(int actual) => _enforce(
    KifuResourceLimitKind.propertyValueCharacters,
    maxPropertyValueCharacters,
    actual,
  );

  void enforceLineCharacters(int actual) =>
      _enforce(KifuResourceLimitKind.lineCharacters, maxLineCharacters, actual);

  void _enforce(KifuResourceLimitKind kind, int limit, int actual) {
    if (actual > limit) {
      throw KifuResourceLimitException(
        kind: kind,
        limit: limit,
        actual: actual,
      );
    }
  }
}

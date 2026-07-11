import '../../domain/domain.dart';
import 'kifu_resource_limits.dart';

/// A syntax or mandatory-value failure with an exact source offset.
final class SgfFormatException extends FormatException {
  const SgfFormatException(super.message, [super.source, super.offset]);
}

/// Dependency-free SGF FF[4] collection parser.
///
/// It preserves every property, comment, node, and variation in the domain's
/// [SgfGameTree]. Go-specific semantic checks are performed by [SgfCodec].
final class SgfSyntaxParser {
  const SgfSyntaxParser({this.limits = const KifuResourceLimits()});

  final KifuResourceLimits limits;

  List<SgfGameTree> parseCollection(String source) {
    limits.enforceInputCharacters(source.length);
    return _SgfReader(source, limits).parse();
  }

  SgfGameTree parseSingleGame(String source) {
    final games = parseCollection(source);
    if (games.length != 1) {
      throw SgfFormatException(
        'Expected exactly one SGF game tree, found ${games.length}.',
        source,
        0,
      );
    }
    return games.single;
  }
}

final class _SgfReader {
  _SgfReader(this.source, this.limits);

  final String source;
  final KifuResourceLimits limits;
  int _offset = 0;
  int _nodeCount = 0;
  int _propertyCount = 0;
  int _propertyValueCount = 0;

  List<SgfGameTree> parse() {
    _skipWhitespace();
    if (_isAtEnd) _fail('The SGF source is empty.');

    final games = <SgfGameTree>[];
    while (!_isAtEnd) {
      limits.enforceGameTrees(games.length + 1);
      games.add(_parseGameTree(1));
      _skipWhitespace();
    }
    return List.unmodifiable(games);
  }

  SgfGameTree _parseGameTree(int depth) {
    limits.enforceVariationDepth(depth);
    _expect('(');
    _skipWhitespace();

    final sequence = <SgfNode>[];
    while (_peek == ';') {
      sequence.add(_parseNode());
      _skipWhitespace();
    }
    if (sequence.isEmpty) {
      _fail('A game tree must contain at least one node.');
    }

    final variations = <SgfGameTree>[];
    while (_peek == '(') {
      variations.add(_parseGameTree(depth + 1));
      _skipWhitespace();
    }
    _expect(')');
    return SgfGameTree(sequence: sequence, variations: variations);
  }

  SgfNode _parseNode() {
    _nodeCount++;
    limits.enforceNodes(_nodeCount);
    _expect(';');
    _skipWhitespace();
    final properties = <SgfProperty>[];
    final identifiers = <String>{};
    var nodePropertyCount = 0;

    while (_peek != null && _isUppercaseAscii(_peek!)) {
      nodePropertyCount++;
      _propertyCount++;
      limits
        ..enforcePropertiesPerNode(nodePropertyCount)
        ..enforceProperties(_propertyCount);
      final identifier = _parseIdentifier();
      if (!identifiers.add(identifier)) {
        _fail('Duplicate property $identifier in one SGF node.');
      }
      _skipWhitespace();
      if (_peek != '[') {
        _fail('Property $identifier must contain at least one value.');
      }
      final values = <String>[];
      while (_peek == '[') {
        _propertyValueCount++;
        limits
          ..enforcePropertyValuesPerProperty(values.length + 1)
          ..enforcePropertyValues(_propertyValueCount);
        values.add(_parsePropertyValue());
        _skipWhitespace();
      }
      properties.add(SgfProperty(identifier: identifier, values: values));
    }
    return SgfNode(properties: properties);
  }

  String _parseIdentifier() {
    final start = _offset;
    while (_peek != null && _isUppercaseAscii(_peek!)) {
      _offset++;
      limits.enforcePropertyIdentifierCharacters(_offset - start);
    }
    return source.substring(start, _offset);
  }

  String _parsePropertyValue() {
    _expect('[');
    final buffer = StringBuffer();
    var valueCharacters = 0;
    void consumeValueCharacters([int count = 1]) {
      valueCharacters += count;
      limits.enforcePropertyValueCharacters(valueCharacters);
    }

    while (!_isAtEnd) {
      final character = source[_offset++];
      if (character == ']') return buffer.toString();
      consumeValueCharacters();

      if (character == '\\') {
        if (_isAtEnd) {
          _fail('A property value cannot end with an escape character.');
        }
        final escaped = source[_offset++];
        consumeValueCharacters();
        if (escaped == '\r') {
          if (_peek == '\n') {
            _offset++;
            consumeValueCharacters();
          }
          continue;
        }
        if (escaped == '\n') continue;
        buffer.write(escaped);
        continue;
      }

      if (character == '\r') {
        if (_peek == '\n') {
          _offset++;
          consumeValueCharacters();
        }
        buffer.write('\n');
      } else {
        buffer.write(character);
      }
    }
    _fail('Unterminated SGF property value.');
  }

  void _skipWhitespace() {
    while (_peek != null &&
        (_peek == ' ' || _peek == '\t' || _peek == '\r' || _peek == '\n')) {
      _offset++;
    }
  }

  void _expect(String expected) {
    if (_peek != expected) {
      _fail(
        'Expected "$expected", found ${_peek == null ? 'end of input' : '"$_peek"'}.',
      );
    }
    _offset++;
  }

  bool _isUppercaseAscii(String character) {
    final code = character.codeUnitAt(0);
    return code >= 65 && code <= 90;
  }

  String? get _peek => _isAtEnd ? null : source[_offset];
  bool get _isAtEnd => _offset >= source.length;

  Never _fail(String message) =>
      throw SgfFormatException(message, source, _offset);
}

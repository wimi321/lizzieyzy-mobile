import '../../domain/domain.dart';

/// A syntax or mandatory-value failure with an exact source offset.
final class SgfFormatException extends FormatException {
  const SgfFormatException(super.message, [super.source, super.offset]);
}

/// Dependency-free SGF FF[4] collection parser.
///
/// It preserves every property, comment, node, and variation in the domain's
/// [SgfGameTree]. Go-specific semantic checks are performed by [SgfCodec].
final class SgfSyntaxParser {
  const SgfSyntaxParser();

  List<SgfGameTree> parseCollection(String source) =>
      _SgfReader(source).parse();

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
  _SgfReader(this.source);

  final String source;
  int _offset = 0;

  List<SgfGameTree> parse() {
    _skipWhitespace();
    if (_isAtEnd) _fail('The SGF source is empty.');

    final games = <SgfGameTree>[];
    while (!_isAtEnd) {
      games.add(_parseGameTree());
      _skipWhitespace();
    }
    return List.unmodifiable(games);
  }

  SgfGameTree _parseGameTree() {
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
      variations.add(_parseGameTree());
      _skipWhitespace();
    }
    _expect(')');
    return SgfGameTree(sequence: sequence, variations: variations);
  }

  SgfNode _parseNode() {
    _expect(';');
    _skipWhitespace();
    final properties = <SgfProperty>[];
    final identifiers = <String>{};

    while (_peek != null && _isUppercaseAscii(_peek!)) {
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
    }
    return source.substring(start, _offset);
  }

  String _parsePropertyValue() {
    _expect('[');
    final buffer = StringBuffer();
    while (!_isAtEnd) {
      final character = source[_offset++];
      if (character == ']') return buffer.toString();

      if (character == '\\') {
        if (_isAtEnd) {
          _fail('A property value cannot end with an escape character.');
        }
        final escaped = source[_offset++];
        if (escaped == '\r') {
          if (_peek == '\n') _offset++;
          continue;
        }
        if (escaped == '\n') continue;
        buffer.write(escaped);
        continue;
      }

      if (character == '\r') {
        if (_peek == '\n') _offset++;
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

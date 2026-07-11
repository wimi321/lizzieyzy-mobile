import 'go_values.dart';

final class SgfCoordinate {
  const SgfCoordinate(this.value);

  factory SgfCoordinate.fromPoint(BoardPoint point, BoardSize size) {
    if (!point.isOn(size)) {
      throw RangeError(
        'Point $point is outside a ${size.dimension} line board.',
      );
    }
    return SgfCoordinate(
      '${String.fromCharCode(97 + point.column)}${String.fromCharCode(97 + point.row)}',
    );
  }

  final String value;

  BoardPoint toPoint(BoardSize size) {
    if (!RegExp(r'^[a-z]{2}$').hasMatch(value)) {
      throw const FormatException(
        'An SGF coordinate must contain exactly two lowercase ASCII letters.',
      );
    }
    final point = BoardPoint(
      value.codeUnitAt(0) - 97,
      value.codeUnitAt(1) - 97,
    );
    if (!point.isOn(size)) {
      throw FormatException('SGF coordinate "$value" is outside the board.');
    }
    return point;
  }

  @override
  bool operator ==(Object other) =>
      other is SgfCoordinate && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class SgfProperty {
  SgfProperty({required this.identifier, required List<String> values})
    : values = List.unmodifiable(values) {
    if (!RegExp(r'^[A-Z]+$').hasMatch(identifier)) {
      throw FormatException(
        'SGF property identifiers must be uppercase ASCII letters.',
      );
    }
    if (values.isEmpty) {
      throw ArgumentError.value(
        values,
        'values',
        'An SGF property needs at least one value.',
      );
    }
  }

  final String identifier;
  final List<String> values;
}

final class SgfNode {
  SgfNode({Iterable<SgfProperty> properties = const []})
    : properties = Map.unmodifiable({
        for (final property in properties) property.identifier: property,
      }) {
    final supplied = properties.length;
    if (this.properties.length != supplied) {
      throw ArgumentError(
        'An SGF node cannot contain duplicate property identifiers.',
      );
    }
  }

  final Map<String, SgfProperty> properties;

  SgfProperty? operator [](String identifier) => properties[identifier];
}

/// SGF's recursive game-tree shape: a non-empty node sequence followed by zero
/// or more variations.
final class SgfGameTree {
  SgfGameTree({
    required List<SgfNode> sequence,
    List<SgfGameTree> variations = const [],
  }) : sequence = List.unmodifiable(sequence),
       variations = List.unmodifiable(variations) {
    if (sequence.isEmpty) {
      throw ArgumentError.value(
        sequence,
        'sequence',
        'An SGF game tree cannot be empty.',
      );
    }
  }

  final List<SgfNode> sequence;
  final List<SgfGameTree> variations;
}

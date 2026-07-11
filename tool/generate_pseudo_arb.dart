import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

const sourcePath = 'lib/l10n/app_en.arb';
const outputPath = 'lib/l10n/app_en_XA.arb';

/// Creates an obviously synthetic string and adds at least 30% extra Unicode
/// code points. ICU expressions remain untouched because padding is added
/// outside the original message.
String pseudoExpand(String source, {double minimumExpansion = 0.30}) {
  final padding = math.max(1, (source.runes.length * minimumExpansion).ceil());
  return '⟦$source⟧${'∼' * padding}';
}

Map<String, Object?> buildPseudoArb(Map<String, Object?> source) {
  return <String, Object?>{
    for (final entry in source.entries)
      if (entry.key == '@@locale')
        entry.key: 'en_XA'
      else if (entry.key.startsWith('@'))
        entry.key: entry.value
      else
        entry.key: pseudoExpand(entry.value! as String),
  };
}

void main() {
  final source =
      jsonDecode(File(sourcePath).readAsStringSync()) as Map<String, Object?>;
  const encoder = JsonEncoder.withIndent('  ');
  File(
    outputPath,
  ).writeAsStringSync('${encoder.convert(buildPseudoArb(source))}\n');
}

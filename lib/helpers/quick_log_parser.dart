typedef QuickLogEntry = ({String? name, int? kcal, int? protein});

const _number = r'(\d{1,3}(?:,\d{3})+|\d+)';
// Units in English and Bulgarian. `(?!\p{L})` is a word boundary that also
// works for Cyrillic, so "calzones" and "калцоне" are not read as units.
const _kcalUnit = r'(?:kcals?|cals?|calories?|ккал|калории|кал)(?!\p{L})';
const _gramUnit = r'(?:g(?:rams?)?|гр?(?:ама)?)';
const _proteinWord = r'(?:protein|протеин|белтъ(?:к|ци|чини))';
final _numberWithUnit = RegExp(
  '$_number\\s*$_kcalUnit',
  caseSensitive: false,
  unicode: true,
);
final _trailingNumber = RegExp('$_number\\s*\$');
final _protein = RegExp(
  '(\\d+)\\s*$_gramUnit\\s*(?:of\\s+)?$_proteinWord(?!\\p{L})'
  '|(?<!\\p{L})$_proteinWord\\s*(\\d+)\\s*$_gramUnit?(?!\\p{L})',
  caseSensitive: false,
  unicode: true,
);
final _edgeSeparators = RegExp(r'^[\s,:\-–]+|[\s,:\-–]+$');

/// Splits quick-log text like "chicken wrap 450" or "450 kcal chicken wrap"
/// into a meal name and calories, plus protein if written as "35g protein".
/// Units may be English or Bulgarian ("мусака 450 ккал 30г протеин").
/// A bare number only counts as calories when it ends the text, so
/// "2 eggs on toast" stays a name.
QuickLogEntry parseQuickLog(String input) {
  var text = input.trim();
  int? protein;
  final proteinMatch = _protein.firstMatch(text);
  if (proteinMatch != null) {
    protein = int.parse(proteinMatch.group(1) ?? proteinMatch.group(2)!);
    text = text.replaceRange(proteinMatch.start, proteinMatch.end, ' ').trim();
  }

  final match =
      _numberWithUnit.firstMatch(text) ?? _trailingNumber.firstMatch(text);
  if (match == null) {
    return (name: _cleanName(text), kcal: null, protein: protein);
  }

  final kcal = int.parse(match.group(1)!.replaceAll(',', ''));
  return (
    name: _cleanName(text.replaceRange(match.start, match.end, ' ')),
    kcal: kcal > 0 ? kcal : null,
    protein: protein,
  );
}

String? _cleanName(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(_edgeSeparators, '');
  if (cleaned.isEmpty) return null;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

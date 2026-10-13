typedef QuickLogEntry = ({String? name, int? kcal});

const _number = r'(\d{1,3}(?:,\d{3})+|\d+)';
final _numberWithUnit = RegExp(
  '$_number\\s*(?:kcals?|cals?|calories?)\\b',
  caseSensitive: false,
);
final _trailingNumber = RegExp('$_number\\s*\$');
final _edgeSeparators = RegExp(r'^[\s,:\-–]+|[\s,:\-–]+$');

/// Splits quick-log text like "chicken wrap 450" or "450 kcal chicken wrap"
/// into a meal name and calories. A bare number only counts as calories when
/// it ends the text, so "2 eggs on toast" stays a name.
QuickLogEntry parseQuickLog(String input) {
  final text = input.trim();
  final match =
      _numberWithUnit.firstMatch(text) ?? _trailingNumber.firstMatch(text);
  if (match == null) return (name: _cleanName(text), kcal: null);

  final kcal = int.parse(match.group(1)!.replaceAll(',', ''));
  return (
    name: _cleanName(text.replaceRange(match.start, match.end, ' ')),
    kcal: kcal > 0 ? kcal : null,
  );
}

String? _cleanName(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(_edgeSeparators, '');
  if (cleaned.isEmpty) return null;
  return cleaned[0].toUpperCase() + cleaned.substring(1);
}

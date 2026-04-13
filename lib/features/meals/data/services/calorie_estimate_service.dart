import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/api_keys.dart';
import '../repositories/ai_usage_repository.dart';

// ---------------------------------------------------------------------------
// Result / exception types
// ---------------------------------------------------------------------------

typedef CalorieEstimate = ({int kcal, String note});

class DailyLimitExceededException implements Exception {
  const DailyLimitExceededException();
}

/// Thrown when the Gemini API call or response parsing fails.
/// [message] carries the underlying error for diagnostics.
class CalorieEstimateException implements Exception {
  const CalorieEstimateException(this.message);
  final String message;
  @override
  String toString() => 'CalorieEstimateException: $message';
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class CalorieEstimateService {
  CalorieEstimateService(this._usageRepo);
  final AiUsageRepository _usageRepo;

  static const String _modelId = 'gemini-2.5-flash';

  static const String _promptTemplate =
      'You are a nutrition assistant. The user will describe a meal.\n'
      'Respond with ONLY a JSON object: '
      '{"kcal": <integer>, "note": "<one short sentence explaining the estimate>"}.\n'
      'Do not include any other text. '
      'Be concise and practical — estimate for a typical portion.\n\n'
      'Meal: {input}';

  Future<CalorieEstimate> estimate(String uid, String description) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Guard: check daily limit before calling the API.
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final model = GenerativeModel(
        model: _modelId,
        apiKey: ApiKeys.gemini,
      );

      final prompt =
          _promptTemplate.replaceFirst('{input}', description.trim());

      final response =
          await model.generateContent([Content.text(prompt)]);

      final raw = response.text?.trim() ?? '';

      if (raw.isEmpty) {
        throw const CalorieEstimateException('Empty response from model.');
      }

      // Strip markdown code fences the model sometimes adds.
      final jsonStr = raw
          .replaceAll(RegExp(r'```(?:json)?\s*'), '')
          .replaceAll('```', '')
          .trim();

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final kcal = (map['kcal'] as num).toInt();
      final note = map['note'] as String;

      // Increment only after a successful parse.
      await _usageRepo.increment(uid, today);

      return (kcal: kcal, note: note);
    } on DailyLimitExceededException {
      rethrow;
    } on CalorieEstimateException {
      rethrow;
    } catch (e, st) {
      debugPrint('CalorieEstimateService error: $e\n$st');
      throw CalorieEstimateException(e.toString());
    }
  }
}

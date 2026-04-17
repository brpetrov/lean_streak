import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/config/api_keys.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';

typedef CalorieEstimate = ({int kcal, String note});

class DailyLimitExceededException implements Exception {
  const DailyLimitExceededException();
}

class CalorieEstimateException implements Exception {
  const CalorieEstimateException(this.message);

  final String message;

  @override
  String toString() => 'CalorieEstimateException: $message';
}

class CalorieEstimateService {
  CalorieEstimateService(this._usageRepo);

  final AiUsageRepository _usageRepo;

  static const String _modelId = 'gemini-2.5-flash';
  static const int _maxServerRetries = 3;

  static const String _promptTemplate =
      'You are a nutrition assistant. The user will describe a meal.\n'
      'Respond with ONLY a JSON object: '
      '{"kcal": <integer>, "note": "<one short sentence explaining the estimate>"}.\n'
      'Do not include any other text. '
      'Be concise and practical, estimate for a typical portion.\n\n'
      'Meal: {input}';

  Future<CalorieEstimate> estimate(String uid, String description) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final model = GenerativeModel(model: _modelId, apiKey: ApiKeys.gemini);
      final prompt = _promptTemplate.replaceFirst(
        '{input}',
        description.trim(),
      );
      final response = await _generateWithRetries(model, prompt);
      final raw = response.text?.trim() ?? '';

      if (raw.isEmpty) {
        throw const CalorieEstimateException('Empty response from model.');
      }

      final jsonStr = raw
          .replaceAll(RegExp(r'```(?:json)?\s*'), '')
          .replaceAll('```', '')
          .trim();

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final kcal = (map['kcal'] as num).toInt();
      final note = map['note'] as String;

      await _usageRepo.increment(uid, today);
      return (kcal: kcal, note: note);
    } on DailyLimitExceededException {
      rethrow;
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService server error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService error: $error\n$st');
      throw CalorieEstimateException('Could not estimate calories right now.');
    }
  }

  Future<GenerateContentResponse> _generateWithRetries(
    GenerativeModel model,
    String prompt,
  ) async {
    for (var attempt = 1; attempt <= _maxServerRetries; attempt++) {
      try {
        return await model.generateContent([Content.text(prompt)]);
      } on ServerException catch (error) {
        if (!_isTransientServerError(error.message) ||
            attempt == _maxServerRetries) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      } on SocketException {
        if (attempt == _maxServerRetries) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 700 * attempt));
      }
    }

    throw const CalorieEstimateException('Could not reach the AI service.');
  }

  bool _isTransientServerError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('503') ||
        lower.contains('500') ||
        lower.contains('unavailable') ||
        lower.contains('high demand') ||
        lower.contains('overloaded') ||
        lower.contains('timed out');
  }

  String _friendlyServerError(String message) {
    if (_isTransientServerError(message)) {
      return 'The AI estimate service is busy right now. Try again in a few seconds.';
    }
    return 'Could not estimate calories right now.';
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

import 'package:lean_streak/core/config/api_keys.dart';
import 'package:lean_streak/repositories/ai_usage_repository.dart';

typedef CalorieEstimate = ({int kcal, int? protein, String note});
typedef VoiceMealParsed = ({String name, int kcal, int? protein});

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

  static const String _modelId = 'gemini-3.5-flash-lite';
  static const int _maxServerRetries = 3;
  static final _generationConfig = GenerationConfig(
    responseMimeType: 'application/json',
  );

  GenerativeModel get _model => GenerativeModel(
    model: _modelId,
    apiKey: ApiKeys.gemini,
    generationConfig: _generationConfig,
  );

  static const String _context =
      'You are a nutrition assistant. The user lives in the UK and often eats '
      'home-cooked Bulgarian food, so read dish names the Bulgarian way '
      '(e.g. musaka is the Bulgarian potato and minced meat bake).\n';

  // Listing each component before the total stops the model skipping the
  // oil, butter or gravy.
  static const String _promptTemplate =
      '$_context'
      'The user will describe a meal. List every component with its calories '
      'and protein, including cooking oil, butter, gravy, sauces, bread and '
      'drinks if mentioned. Use any amounts the user gives; otherwise assume a '
      'typical home portion. For home-cooked dishes, include the oil or fat '
      'they are usually cooked with. For branded or chain products use UK '
      'nutrition figures. Then add them up.\n'
      'Respond with ONLY a JSON object: {"items": [{"item": "<component>", '
      '"kcal": <integer>, "protein_g": <integer>}], "kcal": <integer total>, '
      '"protein_g": <integer total>, "note": "<one short sentence explaining '
      'the estimate>"}\n'
      'Do not include any other text.\n\n'
      'Meal: {input}';

  static const String _voicePromptTemplate =
      '$_context'
      'The user spoke a voice note about a meal. Extract a short meal name, '
      'the total calories and the total protein.\n'
      'List every component with its calories and protein. If the user stated '
      'a calorie or protein amount for something, use that exact number for '
      'it. Otherwise estimate it: use any amounts the user gives, assume a '
      'typical home portion if none, include the oil or fat home-cooked dishes '
      'are usually cooked with, and use UK nutrition figures for branded or '
      'chain products. Then add them up.\n'
      'If the user gave calories but no protein, still estimate the protein '
      'from the food. Only if nothing in the note says what the food was '
      '(e.g. "400 calories for lunch"), set protein_g to null.\n'
      'Respond with ONLY a JSON object: {"name": "<short meal name>", '
      '"items": [{"item": "<component>", "kcal": <integer>, "protein_g": '
      '<integer or null>}], "kcal": <integer total>, "protein_g": <integer '
      'total or null>}\n'
      'Do not include any other text.\n\n'
      'Transcript: {input}';

  static const String _proteinPromptTemplate =
      '$_context'
      'The user logged a meal by name with its calories. Assuming the '
      'calories are right, estimate how many grams of protein it contains.\n'
      'If the name gives no clue what the food was (e.g. "Lunch" or "Snack"), '
      'return null.\n'
      'Respond with ONLY a JSON object: {"protein_g": <integer or null>}\n'
      'Do not include any other text.\n\n'
      'Meal: {name}\nCalories: {kcal}';

  Future<CalorieEstimate> estimate(String uid, String description) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _usageRepo.watchCount(uid, today).first;
    if (count >= AiUsageRepository.dailyLimit) {
      throw const DailyLimitExceededException();
    }

    try {
      final prompt = _promptTemplate.replaceFirst(
        '{input}',
        description.trim(),
      );
      final response = await _generateWithRetries(_model, prompt);
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
      final protein = (map['protein_g'] as num?)?.round();
      final note = map['note'] as String;

      await _usageRepo.increment(uid, today);
      return (kcal: kcal, protein: protein, note: note);
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

  Future<VoiceMealParsed> parseVoice(String transcript) async {
    try {
      final prompt =
          _voicePromptTemplate.replaceFirst('{input}', transcript.trim());
      final response = await _generateWithRetries(_model, prompt);
      final raw = response.text?.trim() ?? '';

      if (raw.isEmpty) {
        throw const CalorieEstimateException('Empty response from model.');
      }

      final jsonStr = raw
          .replaceAll(RegExp(r'```(?:json)?\s*'), '')
          .replaceAll('```', '')
          .trim();

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final name = map['name'] as String;
      final kcal = (map['kcal'] as num).toInt();
      final protein = (map['protein_g'] as num?)?.round();

      return (name: name, kcal: kcal, protein: protein);
    } on CalorieEstimateException {
      rethrow;
    } on ServerException catch (error, st) {
      debugPrint('CalorieEstimateService voice parse error: $error\n$st');
      throw CalorieEstimateException(_friendlyServerError(error.message));
    } catch (error, st) {
      debugPrint('CalorieEstimateService voice parse error: $error\n$st');
      throw CalorieEstimateException(
        'Could not process voice input right now.',
      );
    }
  }

  /// Protein for a meal logged by name and calories, or null when the name
  /// says nothing about the food (e.g. "Lunch"). Like [parseVoice], this
  /// doesn't count towards the daily AI limit.
  Future<int?> estimateProtein(String name, int kcal) async {
    final prompt = _proteinPromptTemplate
        .replaceFirst('{name}', name.trim())
        .replaceFirst('{kcal}', '$kcal');
    final response = await _generateWithRetries(_model, prompt);
    final map = jsonDecode(response.text ?? '') as Map<String, dynamic>;
    return (map['protein_g'] as num?)?.round();
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

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:pawsense/core/services/ai/rule_based_fallback_service.dart';

enum GroqFallbackLevel {
  none,
  primaryRetry,
  fallbackModel,
  fallbackRetry,
  deterministicFallback,
}

enum GroqErrorType {
  none,
  timeout,
  rateLimited,
  server,
  network,
  badRequest,
  unauthorized,
  forbidden,
  invalidSchema,
  unknown,
}

class GroqGenerationResult {
  final bool success;
  final Map<String, dynamic> content;
  final String? modelUsed;
  final GroqFallbackLevel fallbackLevel;
  final int latencyMs;
  final GroqErrorType errorType;
  final bool cacheHit;
  final String traceId;

  const GroqGenerationResult({
    required this.success,
    required this.content,
    required this.modelUsed,
    required this.fallbackLevel,
    required this.latencyMs,
    required this.errorType,
    required this.cacheHit,
    required this.traceId,
  });
}

class _ModelHealthState {
  int failures = 0;
  DateTime? openedAt;

  bool get isOpen => openedAt != null;

  bool isCoolingDown(Duration cooldown) {
    if (openedAt == null) return false;
    return DateTime.now().difference(openedAt!) < cooldown;
  }

  void registerFailure(int threshold) {
    failures += 1;
    if (failures >= threshold) {
      openedAt = DateTime.now();
    }
  }

  void registerSuccess() {
    failures = 0;
    openedAt = null;
  }
}

class GroqOrchestrationService {
  GroqOrchestrationService._internal();
  static final GroqOrchestrationService instance =
      GroqOrchestrationService._internal();

  final RuleBasedFallbackService _ruleFallback =
      const RuleBasedFallbackService();

  final Map<String, _ModelHealthState> _healthByModel = {};
  final Map<String, _CacheEntry> _triageCache = {};
  final Map<String, _CacheEntry> _recommendationCache = {};

  DateTime _quotaDay = DateTime.now();
  int _callsToday = 0;

  static const Duration _triageCacheTtl = Duration(minutes: 20);
  static const Duration _recommendationCacheTtl = Duration(minutes: 20);
  static const Duration _breakerCooldown = Duration(seconds: 60);
  static const int _breakerFailureThreshold = 5;

  String _readEnv(String key) {
    final raw = dotenv.env[key] ?? '';
    var value = raw.trim();
    if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1).trim();
    }
    return value;
  }

  bool get _isEnabled {
    final enabled = _readEnv('GROQ_ENABLED').toLowerCase();
    if (enabled.isEmpty) return true;
    return enabled == '1' || enabled == 'true' || enabled == 'yes';
  }

  String get _apiKey => _readEnv('GROQ_API_KEY');

  String get _baseUrl {
    final configured = _readEnv('GROQ_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    return 'https://api.groq.com/openai/v1';
  }

  String get _triagePrimaryModel =>
      _readEnv('GROQ_PRIMARY_MODEL_TRIAGE').isNotEmpty
          ? _readEnv('GROQ_PRIMARY_MODEL_TRIAGE')
          : 'llama-3.1-8b-instant';

  String get _triageFallbackModel =>
      _readEnv('GROQ_FALLBACK_MODEL_TRIAGE').isNotEmpty
          ? _readEnv('GROQ_FALLBACK_MODEL_TRIAGE')
          : 'llama3-70b-8192';

  String get _recommendationPrimaryModel =>
      _readEnv('GROQ_PRIMARY_MODEL_RECO').isNotEmpty
          ? _readEnv('GROQ_PRIMARY_MODEL_RECO')
          : 'llama-3.1-8b-instant';

  String get _recommendationFallbackModel =>
      _readEnv('GROQ_FALLBACK_MODEL_RECO').isNotEmpty
          ? _readEnv('GROQ_FALLBACK_MODEL_RECO')
          : 'llama3-70b-8192';

  int get _timeoutMs => int.tryParse(_readEnv('GROQ_TIMEOUT_MS')) ?? 9000;

  int get _maxRetries => int.tryParse(_readEnv('GROQ_MAX_RETRIES')) ?? 1;

  int get _dailyCallCap =>
      int.tryParse(_readEnv('GROQ_DAILY_CALL_CAP')) ?? 2500;

  bool get isConfigured => _isEnabled && _apiKey.isNotEmpty;

  void validateConfiguration() {
    if (!_isEnabled) {
      debugPrint('ℹ️ GROQ integration is disabled via GROQ_ENABLED=false.');
      return;
    }

    if (_apiKey.isEmpty) {
      debugPrint(
          '⚠️ GROQ_API_KEY missing. AI features will use fallback mode.');
    }
  }

  Future<GroqGenerationResult> generateTriagePrior({
    required String petType,
    required List<String> symptoms,
    required Map<String, dynamic> intakeData,
    bool hasRedFlags = false,
    List<String>? cameraDetectableConditions,
  }) async {
    final traceId = _buildTraceId('triage');
    final allowedConditions =
        _normalizedAllowedConditionSet(cameraDetectableConditions);
    final cacheKey = _buildTriageCacheKey(
        petType, symptoms, intakeData, hasRedFlags, allowedConditions);
    final cached = _triageCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return GroqGenerationResult(
        success: true,
        content: _constrainTriageToAllowedConditions(
          payload: cached.payload,
          allowedConditions: allowedConditions,
        ),
        modelUsed: cached.modelUsed,
        fallbackLevel: cached.fallbackLevel,
        latencyMs: 0,
        errorType: GroqErrorType.none,
        cacheHit: true,
        traceId: traceId,
      );
    }

    if (!isConfigured || !_consumeDailyQuota()) {
      final fallback = _ruleFallback.triageFallback(
        petType: petType,
        symptoms: symptoms,
        hasRedFlags: hasRedFlags,
        allowedConditions: allowedConditions.toList(),
      );
      return _fallbackResult(
        _constrainTriageToAllowedConditions(
          payload: fallback,
          allowedConditions: allowedConditions,
        ),
        traceId,
        GroqErrorType.unknown,
      );
    }

    final payload = {
      'pet_type': petType,
      'symptoms': symptoms,
      'intake': intakeData,
      'red_flags': hasRedFlags,
      if (allowedConditions.isNotEmpty)
        'camera_detectable_conditions': allowedConditions.toList(),
    };

    final result = await _runWithChain(
      traceId: traceId,
      primaryModel: _triagePrimaryModel,
      fallbackModel: _triageFallbackModel,
      schemaValidator: _isValidTriageSchema,
      systemPrompt: _triageSystemPrompt,
      userPayload: payload,
      maxTokens: 500,
      temperature: 0.2,
      fallbackFactory: () => _ruleFallback.triageFallback(
        petType: petType,
        symptoms: symptoms,
        hasRedFlags: hasRedFlags,
        allowedConditions: allowedConditions.toList(),
      ),
    );

    final constrainedContent = _constrainTriageToAllowedConditions(
      payload: result.content,
      allowedConditions: allowedConditions,
    );

    final constrainedResult = GroqGenerationResult(
      success: result.success,
      content: constrainedContent,
      modelUsed: result.modelUsed,
      fallbackLevel: result.fallbackLevel,
      latencyMs: result.latencyMs,
      errorType: result.errorType,
      cacheHit: result.cacheHit,
      traceId: result.traceId,
    );

    if (constrainedResult.success) {
      _triageCache[cacheKey] = _CacheEntry(
        payload: constrainedResult.content,
        expiresAt: DateTime.now().add(_triageCacheTtl),
        modelUsed: constrainedResult.modelUsed,
        fallbackLevel: constrainedResult.fallbackLevel,
      );
    }

    return constrainedResult;
  }

  Future<GroqGenerationResult> generateRecommendationNarrative({
    required List<Map<String, dynamic>> fusedConditions,
    required Map<String, dynamic> diseaseContext,
    required bool hasRedFlags,
  }) async {
    final traceId = _buildTraceId('reco');

    if (hasRedFlags) {
      final emergency = _ruleFallback.recommendationFallback(
        fusedConditions: fusedConditions,
        hasRedFlags: true,
      );
      return _fallbackResult(
        emergency,
        traceId,
        GroqErrorType.none,
      );
    }

    final cacheKey = _buildRecommendationCacheKey(
      fusedConditions,
      diseaseContext,
      hasRedFlags,
    );
    final cached = _recommendationCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return GroqGenerationResult(
        success: true,
        content: cached.payload,
        modelUsed: cached.modelUsed,
        fallbackLevel: cached.fallbackLevel,
        latencyMs: 0,
        errorType: GroqErrorType.none,
        cacheHit: true,
        traceId: traceId,
      );
    }

    if (!isConfigured || !_consumeDailyQuota()) {
      final fallback = _ruleFallback.recommendationFallback(
        fusedConditions: fusedConditions,
        hasRedFlags: hasRedFlags,
      );
      return _fallbackResult(
        fallback,
        traceId,
        GroqErrorType.unknown,
      );
    }

    final payload = {
      'fused_conditions': fusedConditions,
      'disease_context': diseaseContext,
      'red_flags': hasRedFlags,
      'constraints': {
        'no_diagnosis_claims': true,
        'no_unverified_treatment': true,
      },
    };

    final result = await _runWithChain(
      traceId: traceId,
      primaryModel: _recommendationPrimaryModel,
      fallbackModel: _recommendationFallbackModel,
      schemaValidator: _isValidRecommendationSchema,
      systemPrompt: _recommendationSystemPrompt,
      userPayload: payload,
      maxTokens: 650,
      temperature: 0.25,
      fallbackFactory: () => _ruleFallback.recommendationFallback(
        fusedConditions: fusedConditions,
        hasRedFlags: false,
      ),
    );

    if (result.success) {
      _recommendationCache[cacheKey] = _CacheEntry(
        payload: result.content,
        expiresAt: DateTime.now().add(_recommendationCacheTtl),
        modelUsed: result.modelUsed,
        fallbackLevel: result.fallbackLevel,
      );
    }

    return result;
  }

  Future<GroqGenerationResult> generateGuidedChatQuestion({
    required String petType,
    required Map<String, dynamic> intakeData,
    required List<String> askedQuestionIds,
    required List<String> eligibleQuestionIds,
    required Map<String, dynamic> questionCatalog,
  }) async {
    final traceId = _buildTraceId('chatq');

    if (!isConfigured || !_consumeDailyQuota()) {
      return _fallbackResult(
        {
          'next_question_id':
              eligibleQuestionIds.isNotEmpty ? eligibleQuestionIds.first : '',
          'question_text': 'Let me ask one more question.',
          'helper_text': 'Please share the closest answer.',
          'should_finish': eligibleQuestionIds.isEmpty,
          'reason': 'deterministic_fallback',
        },
        traceId,
        GroqErrorType.unknown,
      );
    }

    final payload = {
      'pet_type': petType,
      'intake': intakeData,
      'asked_question_ids': askedQuestionIds,
      'eligible_question_ids': eligibleQuestionIds,
      'question_catalog': questionCatalog,
    };

    return _runWithChain(
      traceId: traceId,
      primaryModel: _triagePrimaryModel,
      fallbackModel: _triageFallbackModel,
      schemaValidator: _isValidGuidedQuestionSchema,
      systemPrompt: _guidedQuestionSystemPrompt,
      userPayload: payload,
      maxTokens: 280,
      temperature: 0.2,
      fallbackFactory: () => {
        'next_question_id':
            eligibleQuestionIds.isNotEmpty ? eligibleQuestionIds.first : '',
        'question_text': 'Let me ask one more question.',
        'helper_text': 'Please share the closest answer.',
        'should_finish': eligibleQuestionIds.isEmpty,
        'reason': 'deterministic_fallback',
      },
    );
  }

  Future<GroqGenerationResult> generateStructuredSymptomPrior({
    required Map<String, dynamic> petProfile,
    required Map<String, dynamic> intakeData,
    required List<String> cameraDetectableConditions,
  }) async {
    final traceId = _buildTraceId('symprior');

    final fallbackPayload = _deterministicStructuredSymptomPrior(
      petProfile: petProfile,
      intakeData: intakeData,
      cameraDetectableConditions: cameraDetectableConditions,
    );

    if (!isConfigured || !_consumeDailyQuota()) {
      return _fallbackResult(
        fallbackPayload,
        traceId,
        GroqErrorType.unknown,
      );
    }

    final payload = {
      'pet_profile': petProfile,
      'intake': intakeData,
      'camera_detectable_conditions': cameraDetectableConditions,
      'constraints': {
        'no_diagnosis_claims': true,
        'ranking_only': true,
      },
    };

    return _runWithChain(
      traceId: traceId,
      primaryModel: _triagePrimaryModel,
      fallbackModel: _triageFallbackModel,
      schemaValidator: _isValidStructuredSymptomPriorSchema,
      systemPrompt: _structuredSymptomPriorSystemPrompt,
      userPayload: payload,
      maxTokens: 700,
      temperature: 0.2,
      fallbackFactory: () => fallbackPayload,
    );
  }

  Future<GroqGenerationResult> _runWithChain({
    required String traceId,
    required String primaryModel,
    required String fallbackModel,
    required bool Function(Map<String, dynamic>) schemaValidator,
    required String systemPrompt,
    required Map<String, dynamic> userPayload,
    required int maxTokens,
    required double temperature,
    required Map<String, dynamic> Function() fallbackFactory,
  }) async {
    final started = DateTime.now();

    final chain = <_ChainNode>[
      _ChainNode(model: primaryModel, level: GroqFallbackLevel.none),
      if (_maxRetries > 0)
        _ChainNode(model: primaryModel, level: GroqFallbackLevel.primaryRetry),
      _ChainNode(model: fallbackModel, level: GroqFallbackLevel.fallbackModel),
      if (_maxRetries > 0)
        _ChainNode(
            model: fallbackModel, level: GroqFallbackLevel.fallbackRetry),
    ];

    GroqErrorType lastError = GroqErrorType.unknown;

    for (final node in chain) {
      if (_isBreakerOpen(node.model)) {
        continue;
      }

      final attemptResult = await _attemptGeneration(
        traceId: traceId,
        model: node.model,
        systemPrompt: systemPrompt,
        userPayload: userPayload,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      if (attemptResult.success && attemptResult.content != null) {
        final parsed = attemptResult.content!;
        if (!_passesSafetySanitizer(parsed) || !schemaValidator(parsed)) {
          lastError = GroqErrorType.invalidSchema;
          _registerFailure(node.model);
          continue;
        }

        _registerSuccess(node.model);

        return GroqGenerationResult(
          success: true,
          content: parsed,
          modelUsed: node.model,
          fallbackLevel: node.level,
          latencyMs: DateTime.now().difference(started).inMilliseconds,
          errorType: GroqErrorType.none,
          cacheHit: false,
          traceId: traceId,
        );
      }

      lastError = attemptResult.errorType;
      if (_isRetryable(lastError)) {
        _registerFailure(node.model);
        final retryDelay = _computeBackoffDelay(
          level: node.level,
          retryAfter: attemptResult.retryAfter,
        );
        if (retryDelay.inMilliseconds > 0) {
          await Future.delayed(retryDelay);
        }
        continue;
      }

      _registerFailure(node.model);
      break;
    }

    final fallback = fallbackFactory();
    return GroqGenerationResult(
      success: false,
      content: fallback,
      modelUsed: null,
      fallbackLevel: GroqFallbackLevel.deterministicFallback,
      latencyMs: DateTime.now().difference(started).inMilliseconds,
      errorType: lastError,
      cacheHit: false,
      traceId: traceId,
    );
  }

  Future<_AttemptResult> _attemptGeneration({
    required String traceId,
    required String model,
    required String systemPrompt,
    required Map<String, dynamic> userPayload,
    required int maxTokens,
    required double temperature,
  }) async {
    final uri = Uri.parse('$_baseUrl/chat/completions');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'model': model,
              'temperature': temperature,
              'max_tokens': maxTokens,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {
                  'role': 'user',
                  'content': json.encode({'trace_id': traceId, ...userPayload}),
                },
              ],
            }),
          )
          .timeout(Duration(milliseconds: _timeoutMs));

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final choices = body['choices'] as List<dynamic>?;
        if (choices == null || choices.isEmpty) {
          return const _AttemptResult(
            success: false,
            errorType: GroqErrorType.invalidSchema,
          );
        }

        final message = choices.first['message'] as Map<String, dynamic>?;
        final rawContent = message?['content']?.toString() ?? '';
        final normalizedContent = _normalizeJsonContent(rawContent);
        final parsed = json.decode(normalizedContent) as Map<String, dynamic>;

        return _AttemptResult(success: true, content: parsed);
      }

      if (response.statusCode == 429) {
        final retryAfterHeader = response.headers['retry-after'];
        final retryAfterSeconds = int.tryParse(retryAfterHeader ?? '');
        return _AttemptResult(
          success: false,
          errorType: GroqErrorType.rateLimited,
          retryAfter: retryAfterSeconds != null
              ? Duration(seconds: retryAfterSeconds)
              : null,
        );
      }

      if (response.statusCode == 408 || response.statusCode >= 500) {
        return const _AttemptResult(
          success: false,
          errorType: GroqErrorType.server,
        );
      }

      if (response.statusCode == 401) {
        return const _AttemptResult(
          success: false,
          errorType: GroqErrorType.unauthorized,
        );
      }

      if (response.statusCode == 403) {
        return const _AttemptResult(
          success: false,
          errorType: GroqErrorType.forbidden,
        );
      }

      return const _AttemptResult(
        success: false,
        errorType: GroqErrorType.badRequest,
      );
    } on TimeoutException {
      return const _AttemptResult(
          success: false, errorType: GroqErrorType.timeout);
    } catch (_) {
      return const _AttemptResult(
          success: false, errorType: GroqErrorType.network);
    }
  }

  bool _isRetryable(GroqErrorType type) {
    return type == GroqErrorType.timeout ||
        type == GroqErrorType.rateLimited ||
        type == GroqErrorType.server ||
        type == GroqErrorType.network;
  }

  Duration _computeBackoffDelay({
    required GroqFallbackLevel level,
    Duration? retryAfter,
  }) {
    if (retryAfter != null) {
      final capped = retryAfter.inSeconds > 6 ? 6 : retryAfter.inSeconds;
      return Duration(seconds: capped);
    }

    final base = switch (level) {
      GroqFallbackLevel.none => 300,
      GroqFallbackLevel.primaryRetry => 900,
      GroqFallbackLevel.fallbackModel => 300,
      GroqFallbackLevel.fallbackRetry => 900,
      GroqFallbackLevel.deterministicFallback => 0,
    };

    final jitter = Random().nextInt(160);
    return Duration(milliseconds: base + jitter);
  }

  bool _consumeDailyQuota() {
    final now = DateTime.now();
    if (_quotaDay.year != now.year ||
        _quotaDay.month != now.month ||
        _quotaDay.day != now.day) {
      _quotaDay = now;
      _callsToday = 0;
    }

    if (_callsToday >= _dailyCallCap) {
      return false;
    }

    _callsToday += 1;
    return true;
  }

  bool _isBreakerOpen(String model) {
    final state = _healthByModel[model];
    if (state == null) return false;
    if (!state.isOpen) return false;

    if (state.isCoolingDown(_breakerCooldown)) {
      return true;
    }

    state.registerSuccess();
    return false;
  }

  void _registerFailure(String model) {
    final state = _healthByModel.putIfAbsent(model, () => _ModelHealthState());
    state.registerFailure(_breakerFailureThreshold);
  }

  void _registerSuccess(String model) {
    final state = _healthByModel.putIfAbsent(model, () => _ModelHealthState());
    state.registerSuccess();
  }

  bool _isValidTriageSchema(Map<String, dynamic> payload) {
    return payload.containsKey('top_conditions') &&
        payload.containsKey('confidence_band') &&
        payload.containsKey('rationale') &&
        payload.containsKey('care_guidance') &&
        payload.containsKey('escalation_triggers') &&
        payload.containsKey('confidence_note');
  }

  bool _isValidRecommendationSchema(Map<String, dynamic> payload) {
    return payload.containsKey('summary') &&
        payload.containsKey('home_care') &&
        payload.containsKey('watchlist') &&
        payload.containsKey('escalation_triggers') &&
        payload.containsKey('confidence_note');
  }

  bool _isValidGuidedQuestionSchema(Map<String, dynamic> payload) {
    return payload.containsKey('next_question_id') &&
        payload.containsKey('question_text') &&
        payload.containsKey('helper_text') &&
        payload.containsKey('should_finish') &&
        payload.containsKey('reason');
  }

  bool _isValidStructuredSymptomPriorSchema(Map<String, dynamic> payload) {
    return payload.containsKey('symptoms') &&
        payload.containsKey('body_locations') &&
        payload.containsKey('duration') &&
        payload.containsKey('severity') &&
        payload.containsKey('exposure_factors') &&
        payload.containsKey('red_flags') &&
        payload.containsKey('triage_priors') &&
        payload.containsKey('summary');
  }

  Map<String, dynamic> _deterministicStructuredSymptomPrior({
    required Map<String, dynamic> petProfile,
    required Map<String, dynamic> intakeData,
    required List<String> cameraDetectableConditions,
  }) {
    final appearance = (intakeData['lesionAppearance'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final distribution =
        (intakeData['distributionAreas'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
    final redFlags = (intakeData['redFlags'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final symptoms = <String>[];
    if ((intakeData['itchSeverity']?.toString() ?? 'not_sure') != 'not_sure') {
      symptoms.add('itching');
    }
    if (appearance.contains('Hair loss patches')) symptoms.add('hair_loss');
    if (appearance.contains('Redness / rash')) symptoms.add('redness');
    if (appearance.contains('Scabs / crusts')) symptoms.add('crusting');
    if (appearance.contains('Moist or oozing skin')) symptoms.add('discharge');
    if (redFlags.any((f) => f.toLowerCase().contains('odor'))) {
      symptoms.add('odor');
    }

    final exposure = <String>[];
    final trigger = intakeData['triggerContext']?.toString() ?? 'not_sure';
    if (trigger == 'possible_allergen') exposure.add('possible_allergen');
    if (trigger == 'recent_grooming') exposure.add('recent_shampoo_change');
    if (trigger == 'recent_medication')
      exposure.add('recent_medication_change');

    final candidates = cameraDetectableConditions.isNotEmpty
        ? cameraDetectableConditions
        : <String>['dermatitis', 'mange', 'fungal_infection'];

    final priors = <Map<String, dynamic>>[];
    final scoreStep = candidates.length <= 1 ? 0.0 : 0.12;
    var score = 0.34;
    for (final condition in candidates.take(5)) {
      priors.add({
        'condition': condition,
        'score': score.clamp(0.08, 0.95),
      });
      score -= scoreStep;
    }

    return {
      'pet_profile': petProfile,
      'symptoms': symptoms.toSet().toList(),
      'body_locations': distribution
          .map((e) => e.toLowerCase().replaceAll(' ', '_'))
          .toSet()
          .toList(),
      'duration': intakeData['onsetDuration']?.toString() ?? '',
      'severity': intakeData['itchSeverity']?.toString() ?? 'not_sure',
      'exposure_factors': exposure,
      'red_flags': redFlags,
      'triage_priors': priors,
      'summary':
          'Symptom-informed condition ranking only. This is not a diagnosis.',
    };
  }

  bool _passesSafetySanitizer(Map<String, dynamic> payload) {
    final encoded = json.encode(payload).toLowerCase();
    const bannedPhrases = [
      'guaranteed cure',
      'definitive diagnosis',
      'certain diagnosis',
      '100% sure',
    ];

    return !bannedPhrases.any(encoded.contains);
  }

  String _normalizeJsonContent(String raw) {
    var content = raw.trim();
    if (content.startsWith('```')) {
      content = content.replaceAll('```json', '').replaceAll('```', '').trim();
    }
    return content;
  }

  String _buildTraceId(String prefix) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$now-${Random().nextInt(99999)}';
  }

  String _buildTriageCacheKey(
    String petType,
    List<String> symptoms,
    Map<String, dynamic> intake,
    bool redFlags,
    Set<String> allowedConditions,
  ) {
    final symptomKey = symptoms.map((e) => e.trim().toLowerCase()).toList()
      ..sort();
    final intakeKey = json.encode(intake);
    final allowed = allowedConditions.toList()..sort();
    return 'triage:${petType.toLowerCase()}:${symptomKey.join('|')}:$intakeKey:$redFlags:${allowed.join(',')}';
  }

  Set<String> _normalizedAllowedConditionSet(List<String>? allowedConditions) {
    return (allowedConditions ?? const <String>[])
        .map(_normalizeConditionLabel)
        .where((value) => value.isNotEmpty)
        .toSet();
  }

  String _normalizeConditionLabel(String raw) {
    final normalized =
        raw.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');

    const aliases = <String, String>{
      'allergic_dermatitis': 'dermatitis',
      'mange_or_mites': 'mange',
      'bacterial_infection': 'pyoderma',
    };

    return aliases[normalized] ?? normalized;
  }

  Map<String, dynamic> _constrainTriageToAllowedConditions({
    required Map<String, dynamic> payload,
    required Set<String> allowedConditions,
  }) {
    if (allowedConditions.isEmpty) {
      return payload;
    }

    final topConditionsRaw = payload['top_conditions'];
    if (topConditionsRaw is! List) {
      return payload;
    }

    final constrained = <Map<String, dynamic>>[];
    final seen = <String>{};

    for (final item in topConditionsRaw) {
      if (item is! Map) continue;
      final conditionRaw = item['condition']?.toString() ?? '';
      final normalized = _normalizeConditionLabel(conditionRaw);
      if (!allowedConditions.contains(normalized) ||
          seen.contains(normalized)) {
        continue;
      }

      final scoreValue = item['score'];
      final score =
          scoreValue is num ? scoreValue.toDouble().clamp(0.0, 1.0) : null;
      constrained.add({
        'condition': normalized,
        if (score != null) 'score': score,
        'source': item['source']?.toString() ?? 'llm',
      });
      seen.add(normalized);
    }

    if (constrained.isEmpty) {
      final defaults = allowedConditions.toList()..sort();
      var score = 0.34;
      for (final condition in defaults.take(3)) {
        constrained.add({
          'condition': condition,
          'score': score.clamp(0.08, 0.95),
          'source': 'allowed_fallback',
        });
        score -= 0.08;
      }
    }

    return {
      ...payload,
      'top_conditions': constrained.take(5).toList(),
    };
  }

  String _buildRecommendationCacheKey(
    List<Map<String, dynamic>> fused,
    Map<String, dynamic> context,
    bool redFlags,
  ) {
    return 'reco:${json.encode(fused)}:${json.encode(context)}:$redFlags';
  }

  GroqGenerationResult _fallbackResult(
    Map<String, dynamic> payload,
    String traceId,
    GroqErrorType errorType,
  ) {
    return GroqGenerationResult(
      success: false,
      content: payload,
      modelUsed: null,
      fallbackLevel: GroqFallbackLevel.deterministicFallback,
      latencyMs: 0,
      errorType: errorType,
      cacheHit: false,
      traceId: traceId,
    );
  }

  String get _triageSystemPrompt =>
      'You are a veterinary triage assistant. Return JSON only. '
      'Do not diagnose. Use conservative wording. '
      'Required keys: top_conditions, confidence_band, rationale, care_guidance, escalation_triggers, confidence_note.';

  String get _recommendationSystemPrompt =>
      'You are a veterinary care assistant. Return JSON only. '
      'Use only provided context. No diagnosis claims. No unsupported treatment claims. '
      'Required keys: summary, home_care, watchlist, escalation_triggers, confidence_note.';

  String get _guidedQuestionSystemPrompt =>
      'You are a pet skin chat assistant. Return JSON only. '
      'Decide the single best NEXT question to ask based on prior answers. '
      'Only choose next_question_id from eligible_question_ids. '
      'If there is enough information to guide camera scanning, set should_finish=true and next_question_id="". '
      'Use simple, owner-friendly language. '
      'Required keys: next_question_id, question_text, helper_text, should_finish, reason.';

  String get _structuredSymptomPriorSystemPrompt =>
      'You are a veterinary intake structuring assistant. Return JSON only. '
      'Convert owner answers into a structured symptom profile and symptom-informed condition ranking. '
      'Do not diagnose and do not claim certainty. '
      'Only include condition names from camera_detectable_conditions in triage_priors. '
      'triage_priors must be a ranked list of up to 5 items with keys: condition, score (0..1). '
      'Required keys: symptoms, body_locations, duration, severity, exposure_factors, red_flags, triage_priors, summary.';
}

class _ChainNode {
  final String model;
  final GroqFallbackLevel level;

  const _ChainNode({required this.model, required this.level});
}

class _AttemptResult {
  final bool success;
  final Map<String, dynamic>? content;
  final GroqErrorType errorType;
  final Duration? retryAfter;

  const _AttemptResult({
    required this.success,
    this.content,
    this.errorType = GroqErrorType.none,
    this.retryAfter,
  });
}

class _CacheEntry {
  final Map<String, dynamic> payload;
  final DateTime expiresAt;
  final String? modelUsed;
  final GroqFallbackLevel fallbackLevel;

  const _CacheEntry({
    required this.payload,
    required this.expiresAt,
    required this.modelUsed,
    required this.fallbackLevel,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

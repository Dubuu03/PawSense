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
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return 'https://api.groq.com/openai/v1';
  }

  String get _triagePrimaryModel =>
      _readEnv('GROQ_PRIMARY_MODEL_TRIAGE').isNotEmpty
      ? _readEnv('GROQ_PRIMARY_MODEL_TRIAGE')
      :
      'llama-3.1-8b-instant';

  String get _triageFallbackModel =>
      _readEnv('GROQ_FALLBACK_MODEL_TRIAGE').isNotEmpty
      ? _readEnv('GROQ_FALLBACK_MODEL_TRIAGE')
      :
      'llama3-70b-8192';

  String get _recommendationPrimaryModel =>
      _readEnv('GROQ_PRIMARY_MODEL_RECO').isNotEmpty
      ? _readEnv('GROQ_PRIMARY_MODEL_RECO')
      :
      'llama-3.1-8b-instant';

  String get _recommendationFallbackModel =>
      _readEnv('GROQ_FALLBACK_MODEL_RECO').isNotEmpty
      ? _readEnv('GROQ_FALLBACK_MODEL_RECO')
      :
      'llama3-70b-8192';

  int get _timeoutMs =>
      int.tryParse(_readEnv('GROQ_TIMEOUT_MS')) ?? 9000;

  int get _maxRetries =>
      int.tryParse(_readEnv('GROQ_MAX_RETRIES')) ?? 1;

  int get _dailyCallCap =>
      int.tryParse(_readEnv('GROQ_DAILY_CALL_CAP')) ?? 2500;

  bool get isConfigured => _isEnabled && _apiKey.isNotEmpty;

  void validateConfiguration() {
    if (!_isEnabled) {
      debugPrint('ℹ️ GROQ integration is disabled via GROQ_ENABLED=false.');
      return;
    }

    if (_apiKey.isEmpty) {
      debugPrint('⚠️ GROQ_API_KEY missing. AI features will use fallback mode.');
    }
  }

  Future<GroqGenerationResult> generateTriagePrior({
    required String petType,
    required List<String> symptoms,
    required Map<String, dynamic> intakeData,
    bool hasRedFlags = false,
  }) async {
    final traceId = _buildTraceId('triage');
    final cacheKey = _buildTriageCacheKey(petType, symptoms, intakeData, hasRedFlags);
    final cached = _triageCache[cacheKey];
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
      final fallback = _ruleFallback.triageFallback(
        petType: petType,
        symptoms: symptoms,
        hasRedFlags: hasRedFlags,
      );
      return _fallbackResult(
        fallback,
        traceId,
        GroqErrorType.unknown,
      );
    }

    final payload = {
      'pet_type': petType,
      'symptoms': symptoms,
      'intake': intakeData,
      'red_flags': hasRedFlags,
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
      ),
    );

    if (result.success) {
      _triageCache[cacheKey] = _CacheEntry(
        payload: result.content,
        expiresAt: DateTime.now().add(_triageCacheTtl),
        modelUsed: result.modelUsed,
        fallbackLevel: result.fallbackLevel,
      );
    }

    return result;
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
        _ChainNode(model: fallbackModel, level: GroqFallbackLevel.fallbackRetry),
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
      return const _AttemptResult(success: false, errorType: GroqErrorType.timeout);
    } catch (_) {
      return const _AttemptResult(success: false, errorType: GroqErrorType.network);
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
      content = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
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
  ) {
    final symptomKey = symptoms.map((e) => e.trim().toLowerCase()).toList()..sort();
    final intakeKey = json.encode(intake);
    return 'triage:${petType.toLowerCase()}:${symptomKey.join('|')}:$intakeKey:$redFlags';
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

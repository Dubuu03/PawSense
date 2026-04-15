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
  modelUnavailable,
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
  final Map<String, DateTime> _rateLimitedUntilByModel = {};
  final Map<String, DateTime> _unavailableUntilByModel = {};
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
          : 'llama-3.3-70b-versatile';

  List<String> get _triageBackupModels => _parseModelList(
        _readEnv('GROQ_BACKUP_MODELS_TRIAGE'),
        fallback: const <String>[
          'meta-llama/llama-4-scout-17b-16e-instruct',
          'qwen/qwen3-32b',
          'openai/gpt-oss-20b',
        ],
      );

  String get _recommendationPrimaryModel =>
      _readEnv('GROQ_PRIMARY_MODEL_RECO').isNotEmpty
          ? _readEnv('GROQ_PRIMARY_MODEL_RECO')
          : 'llama-3.1-8b-instant';

  String get _recommendationFallbackModel =>
      _readEnv('GROQ_FALLBACK_MODEL_RECO').isNotEmpty
          ? _readEnv('GROQ_FALLBACK_MODEL_RECO')
          : 'llama-3.3-70b-versatile';

  List<String> get _recommendationBackupModels => _parseModelList(
        _readEnv('GROQ_BACKUP_MODELS_RECO'),
        fallback: const <String>[
          'meta-llama/llama-4-scout-17b-16e-instruct',
          'openai/gpt-oss-20b',
          'qwen/qwen3-32b',
        ],
      );

  int get _timeoutMs => int.tryParse(_readEnv('GROQ_TIMEOUT_MS')) ?? 9000;

  int get _maxRetries => int.tryParse(_readEnv('GROQ_MAX_RETRIES')) ?? 1;

  int get _rateLimitCooldownMs =>
      int.tryParse(_readEnv('GROQ_RATE_LIMIT_COOLDOWN_MS')) ?? 15000;

  int get _modelUnavailableCooldownMin =>
      int.tryParse(_readEnv('GROQ_MODEL_UNAVAILABLE_COOLDOWN_MIN')) ?? 360;

  int get _dailyCallCap =>
      int.tryParse(_readEnv('GROQ_DAILY_CALL_CAP')) ?? 2500;

  List<String> _parseModelList(String raw,
      {List<String> fallback = const <String>[]}) {
    if (raw.trim().isEmpty) {
      return fallback;
    }

    final output = <String>[];
    final seen = <String>{};
    for (final part in raw.split(',')) {
      final model = part.trim();
      if (model.isEmpty) continue;
      if (seen.contains(model)) continue;
      seen.add(model);
      output.add(model);
    }

    return output.isEmpty ? fallback : output;
  }

  List<dynamic> _coerceDynamicList(dynamic raw) {
    if (raw is List) {
      return raw;
    }
    if (raw is Map) {
      return raw.values.toList(growable: false);
    }
    return <dynamic>[];
  }

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
      backupModels: _triageBackupModels,
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
      backupModels: _recommendationBackupModels,
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
    String preferredQuestionId = '',
  }) async {
    final traceId = _buildTraceId('chatq');
    final latestUserAnswer = _extractLatestUserAnswer(intakeData);
    final latestAnswerFocus = _extractLatestAnswerFocus(intakeData);
    final recentConversationContext =
        _extractRecentConversationContext(intakeData);
    final lastAnsweredQuestionId = latestAnswerFocus['question_id'] ?? '';
    final normalizedPreferredQuestionId = preferredQuestionId.trim();
    var fallbackQuestionId =
        eligibleQuestionIds.isNotEmpty ? eligibleQuestionIds.first : '';
    if (normalizedPreferredQuestionId.isNotEmpty &&
        eligibleQuestionIds.contains(normalizedPreferredQuestionId)) {
      fallbackQuestionId = normalizedPreferredQuestionId;
    }
    if (fallbackQuestionId.isNotEmpty &&
        eligibleQuestionIds.length > 1 &&
        lastAnsweredQuestionId.isNotEmpty &&
        normalizedPreferredQuestionId.isEmpty &&
        fallbackQuestionId == lastAnsweredQuestionId) {
      fallbackQuestionId = eligibleQuestionIds[1];
    }
    final fallbackPrompt = _buildGuidedQuestionFallback(
      questionId: fallbackQuestionId,
      questionCatalog: questionCatalog,
      latestUserAnswer: latestUserAnswer,
    );

    if (!isConfigured || !_consumeDailyQuota()) {
      return _fallbackResult(
        {
          'next_question_id': fallbackQuestionId,
          'question_text': fallbackPrompt['question_text'],
          'helper_text': fallbackPrompt['helper_text'],
          'suggested_replies': fallbackPrompt['suggested_replies'],
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
      'latest_user_answer': latestUserAnswer,
      'latest_answer_focus': latestAnswerFocus,
      'recent_conversation_context': recentConversationContext,
      'asked_question_ids': askedQuestionIds,
      'eligible_question_ids': eligibleQuestionIds,
      'preferred_question_id': normalizedPreferredQuestionId,
      'question_catalog': questionCatalog,
      'response_mode': 'hybrid_free_text_and_suggested_replies',
      'client_capabilities': {
        'show_option_chips': true,
        'prefer_open_text': true,
        'allow_suggested_replies': true,
      },
    };

    return _runWithChain(
      traceId: traceId,
      primaryModel: _triagePrimaryModel,
      fallbackModel: _triageFallbackModel,
      backupModels: _triageBackupModels,
      schemaValidator: _isValidGuidedQuestionSchema,
      systemPrompt: _guidedQuestionSystemPrompt,
      userPayload: payload,
      maxTokens: 340,
      temperature: 0.35,
      fallbackFactory: () => {
        'next_question_id': fallbackQuestionId,
        'question_text': fallbackPrompt['question_text'],
        'helper_text': fallbackPrompt['helper_text'],
        'suggested_replies': fallbackPrompt['suggested_replies'],
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
      backupModels: _triageBackupModels,
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
    required List<String> backupModels,
    required bool Function(Map<String, dynamic>) schemaValidator,
    required String systemPrompt,
    required Map<String, dynamic> userPayload,
    required int maxTokens,
    required double temperature,
    required Map<String, dynamic> Function() fallbackFactory,
  }) async {
    final started = DateTime.now();

    final modelOrder = <String>[];
    final seenModels = <String>{};

    void addModel(String model) {
      final value = model.trim();
      if (value.isEmpty || seenModels.contains(value)) {
        return;
      }
      seenModels.add(value);
      modelOrder.add(value);
    }

    addModel(primaryModel);
    addModel(fallbackModel);
    for (final model in backupModels) {
      addModel(model);
    }

    final chain = <_ChainNode>[];
    for (var i = 0; i < modelOrder.length; i++) {
      final model = modelOrder[i];
      chain.add(
        _ChainNode(
          model: model,
          level:
              i == 0 ? GroqFallbackLevel.none : GroqFallbackLevel.fallbackModel,
        ),
      );

      if (_maxRetries > 0) {
        chain.add(
          _ChainNode(
            model: model,
            level: i == 0
                ? GroqFallbackLevel.primaryRetry
                : GroqFallbackLevel.fallbackRetry,
          ),
        );
      }
    }

    GroqErrorType lastError = GroqErrorType.unknown;
    final skipRetryForModel = <String>{};

    for (final node in chain) {
      final isRetryNode = node.level == GroqFallbackLevel.primaryRetry ||
          node.level == GroqFallbackLevel.fallbackRetry;

      if (isRetryNode && skipRetryForModel.contains(node.model)) {
        continue;
      }

      if (_isModelTemporarilyUnavailable(node.model)) {
        continue;
      }

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

      _registerFailure(node.model);

      if (lastError == GroqErrorType.rateLimited) {
        _markModelRateLimited(node.model, attemptResult.retryAfter);
        skipRetryForModel.add(node.model);
      } else if (lastError == GroqErrorType.modelUnavailable) {
        _markModelUnavailable(node.model);
        skipRetryForModel.add(node.model);
      }

      if (_isRetryable(lastError)) {
        if (lastError == GroqErrorType.modelUnavailable) {
          continue;
        }

        final retryDelay = _computeBackoffDelay(
          level: node.level,
          retryAfter: attemptResult.retryAfter,
        );
        if (retryDelay.inMilliseconds > 0) {
          await Future.delayed(retryDelay);
        }
        continue;
      }

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
        final choices = _coerceDynamicList(body['choices']);
        if (choices.isEmpty || choices.first is! Map) {
          return const _AttemptResult(
            success: false,
            errorType: GroqErrorType.invalidSchema,
          );
        }

        final firstChoice = Map<String, dynamic>.from(choices.first as Map);
        final messageRaw = firstChoice['message'];
        final message =
            messageRaw is Map ? Map<String, dynamic>.from(messageRaw) : null;
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

      if (response.statusCode == 400 || response.statusCode == 404) {
        final modelErrorCode = _extractErrorCode(response.body);
        final modelErrorMessage = _extractErrorMessage(response.body);
        final normalizedCode = modelErrorCode.toLowerCase();
        final normalizedMessage = modelErrorMessage.toLowerCase();

        final looksUnavailable =
            normalizedCode.contains('model_decommissioned') ||
                normalizedCode.contains('model_not_found') ||
                normalizedCode.contains('model_unavailable') ||
                normalizedMessage.contains('model_decommissioned') ||
                normalizedMessage.contains('model not found') ||
                normalizedMessage.contains('has been decommissioned') ||
                normalizedMessage.contains('does not exist');

        if (looksUnavailable) {
          return const _AttemptResult(
            success: false,
            errorType: GroqErrorType.modelUnavailable,
          );
        }
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
        type == GroqErrorType.modelUnavailable ||
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

  bool _isModelTemporarilyUnavailable(String model) {
    final now = DateTime.now();

    final rateLimitUntil = _rateLimitedUntilByModel[model];
    if (rateLimitUntil != null) {
      if (now.isBefore(rateLimitUntil)) {
        return true;
      }
      _rateLimitedUntilByModel.remove(model);
    }

    final unavailableUntil = _unavailableUntilByModel[model];
    if (unavailableUntil != null) {
      if (now.isBefore(unavailableUntil)) {
        return true;
      }
      _unavailableUntilByModel.remove(model);
    }

    return false;
  }

  void _markModelRateLimited(String model, Duration? retryAfter) {
    final fallbackDelay = Duration(milliseconds: _rateLimitCooldownMs);
    final retryDelay = retryAfter ?? fallbackDelay;
    final boundedRetry = retryDelay.inMilliseconds > 60000
        ? const Duration(seconds: 60)
        : retryDelay;

    _rateLimitedUntilByModel[model] = DateTime.now().add(boundedRetry);
  }

  void _markModelUnavailable(String model) {
    _unavailableUntilByModel[model] = DateTime.now().add(
      Duration(minutes: _modelUnavailableCooldownMin),
    );
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
    final hasRequiredKeys = payload.containsKey('next_question_id') &&
        payload.containsKey('question_text') &&
        payload.containsKey('helper_text') &&
        payload.containsKey('should_finish') &&
        payload.containsKey('reason');

    if (!hasRequiredKeys) {
      return false;
    }

    final suggestedReplies = payload['suggested_replies'];
    if (suggestedReplies != null) {
      if (suggestedReplies is! List) {
        return false;
      }

      for (final item in suggestedReplies) {
        if (item is! String) {
          return false;
        }
      }
    }

    return payload['next_question_id'] is String &&
        payload['question_text'] is String &&
        payload['helper_text'] is String &&
        payload['should_finish'] is bool &&
        payload['reason'] is String;
  }

  bool _isValidStructuredSymptomPriorSchema(Map<String, dynamic> payload) {
    final hasRequiredKeys = payload.containsKey('symptoms') &&
        payload.containsKey('body_locations') &&
        payload.containsKey('duration') &&
        payload.containsKey('severity') &&
        payload.containsKey('exposure_factors') &&
        payload.containsKey('red_flags') &&
        payload.containsKey('triage_priors') &&
        payload.containsKey('summary');

    if (!hasRequiredKeys) {
      return false;
    }

    if (payload['symptoms'] is! List ||
        payload['body_locations'] is! List ||
        payload['exposure_factors'] is! List ||
        payload['red_flags'] is! List ||
        payload['triage_priors'] is! List ||
        payload['duration'] is! String ||
        payload['severity'] is! String ||
        payload['summary'] is! String) {
      return false;
    }

    final triagePriors = payload['triage_priors'] as List;
    for (final item in triagePriors) {
      if (item is! Map) {
        return false;
      }
    }

    return true;
  }

  Map<String, String> _extractLatestAnswerFocus(
      Map<String, dynamic> intakeData) {
    final questionId =
        intakeData['lastAnsweredQuestionId']?.toString().trim() ?? '';
    final questionText =
        intakeData['lastAnsweredQuestion']?.toString().trim() ?? '';

    if (questionId.isEmpty && questionText.isEmpty) {
      return <String, String>{};
    }

    return {
      if (questionId.isNotEmpty) 'question_id': questionId,
      if (questionText.isNotEmpty) 'question_text': questionText,
    };
  }

  String _extractLatestUserAnswer(Map<String, dynamic> intakeData) {
    final history = intakeData['conversationHistory'];
    if (history is List) {
      for (var i = history.length - 1; i >= 0; i--) {
        final item = history[i];
        if (item is! Map) continue;

        final role = item['role']?.toString().trim().toLowerCase() ?? '';
        if (role != 'user') continue;

        final text = item['text']?.toString().trim() ?? '';
        if (text.isNotEmpty) return text;
      }
    }

    return '';
  }

  List<Map<String, String>> _extractRecentConversationContext(
      Map<String, dynamic> intakeData) {
    final history = intakeData['conversationHistory'];
    if (history is! List || history.isEmpty) {
      return <Map<String, String>>[];
    }

    final output = <Map<String, String>>[];
    for (final item in history.reversed) {
      if (item is! Map) continue;

      final role = item['role']?.toString().trim().toLowerCase() ?? '';
      final text = item['text']?.toString().trim() ?? '';
      if ((role != 'assistant' && role != 'user') || text.isEmpty) {
        continue;
      }

      output.add({'role': role, 'text': text});
      if (output.length >= 6) break;
    }

    return output.reversed.toList(growable: false);
  }

  Map<String, dynamic> _buildGuidedQuestionFallback({
    required String questionId,
    required Map<String, dynamic> questionCatalog,
    required String latestUserAnswer,
  }) {
    final normalizedQuestionId = questionId.trim();
    final entry = Map<String, dynamic>.from(
      questionCatalog[normalizedQuestionId] as Map? ?? <String, dynamic>{},
    );

    final focus = entry['intent_focus']?.toString().trim();
    final intentFocus =
        (focus != null && focus.isNotEmpty) ? focus : 'the skin concern';

    final quickOptions = _coerceDynamicList(entry['quick_options'])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
      .take(4)
        .toList(growable: false);

    final stems = latestUserAnswer.trim().isNotEmpty
        ? <String>[
            'Thanks. Could you share one more detail about $intentFocus?',
            'Based on what you shared, what else can you tell me about $intentFocus?',
            'To narrow this down, can you clarify $intentFocus a bit more?',
          ]
        : <String>[
            'Could you share a detail about $intentFocus?',
            'Can you tell me more about $intentFocus?',
            'What can you share about $intentFocus?',
          ];

    final questionText = stems[Random().nextInt(stems.length)];
    final helperText = quickOptions.isNotEmpty
        ? 'If useful, you can mention ${quickOptions.join(', ')}.'
        : 'Any specific detail you can share helps.';

    return {
      'question_text': questionText,
      'helper_text': helperText,
      'suggested_replies': quickOptions,
    };
  }

  Map<String, dynamic> _deterministicStructuredSymptomPrior({
    required Map<String, dynamic> petProfile,
    required Map<String, dynamic> intakeData,
    required List<String> cameraDetectableConditions,
  }) {
    final appearance = _coerceDynamicList(intakeData['lesionAppearance'])
        .map((e) => e.toString())
        .toList();
    final distribution = _coerceDynamicList(intakeData['distributionAreas'])
        .map((e) => e.toString())
        .toList();
    final redFlags = _coerceDynamicList(intakeData['redFlags'])
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

  String _extractErrorCode(String rawBody) {
    try {
      final parsed = json.decode(rawBody);
      if (parsed is! Map) return '';

      final error = parsed['error'];
      if (error is Map) {
        return error['code']?.toString().trim() ?? '';
      }

      return parsed['code']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _extractErrorMessage(String rawBody) {
    try {
      final parsed = json.decode(rawBody);
      if (parsed is! Map) return rawBody;

      final error = parsed['error'];
      if (error is Map) {
        return error['message']?.toString().trim() ?? rawBody;
      }

      return parsed['message']?.toString().trim() ?? rawBody;
    } catch (_) {
      return rawBody;
    }
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
      'If preferred_question_id is provided, prioritize it unless latest_user_answer clearly points to another unresolved eligible field. '
      'Do not follow a fixed question order. '
      'If there is enough information to guide camera scanning, set should_finish=true and next_question_id="". '
      'Ground every question strictly in provided intake and conversation history. '
      'Use latest_user_answer and recent_conversation_context as primary grounding context for the next follow-up. '
      'Use latest_answer_focus.question_id and latest_answer_focus.question_text to continue naturally from the immediately previous question, not to restart intake. '
      'For dynamic_followup, ask the most useful unresolved question inferred from context instead of templates. '
      'If latest_user_answer already covers one detail, ask a different unresolved detail. '
      'Do not ask the same detail again if latest_user_answer already contains that detail unless user contradicted themselves. '
      'Prefer an open-ended follow-up question. '
      'Optionally include suggested_replies as a short list (2 to 6 items) to help quick tap answers, but do not depend on them. '
      'Question_text must be a contextual follow-up to what the owner just said, not a template copy. '
      'Do not invent symptoms, timelines, body locations, diagnoses, treatments, or risk claims. '
      'Avoid repeating a question intent that was already asked; prefer unresolved fields. '
      'Avoid repeating the exact same question wording from earlier turns unless the user explicitly asked for clarification. '
      'Avoid formulaic sentence starters and vary phrasing naturally between turns. '
      'Keep question_text concise and owner-friendly. '
      'Use simple, owner-friendly language. '
      'Required keys: next_question_id, question_text, helper_text, should_finish, reason. '
      'Optional key: suggested_replies (array of short strings).';

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

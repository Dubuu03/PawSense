import 'package:flutter/material.dart';
import 'package:pawsense/core/services/ai/groq_orchestration_service.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class AssessmentStepPreTriage extends StatefulWidget {
  final Map<String, dynamic> assessmentData;
  final Function(String, dynamic) onDataUpdate;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const AssessmentStepPreTriage({
    super.key,
    required this.assessmentData,
    required this.onDataUpdate,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<AssessmentStepPreTriage> createState() =>
      _AssessmentStepPreTriageState();
}

class _AssessmentStepPreTriageState extends State<AssessmentStepPreTriage> {
  static const List<String> _knownLabels = <String>[
    'dermatitis',
    'fleas',
    'fungal_infection',
    'hotspot',
    'mange',
    'pyoderma',
    'ringworm',
    'ticks',
    'unknown_abnormality',
  ];

  static const int _minTurnsForReadiness = 4;
  static const List<String> _internalAssistantMarkers = <String>[
    'ask one concise follow-up question',
    'camera-detectable skin conditions',
    'use plain language, ask only one question',
    'avoid diagnosis claims',
    'dynamic_followup',
  ];

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final GroqOrchestrationService _groqService =
      GroqOrchestrationService.instance;

  final List<Map<String, String>> _conversation = <Map<String, String>>[];
  final List<String> _questionTrace = <String>[];

  String? _activeQuestion;
  String? _activeQuestionId;
  List<String> _activeQuickOptions = <String>[];
  bool _showThinkingIndicator = false;
  bool _llmSaysDone = false;
  bool _isGeneratingNextQuestion = false;
  bool _isGeneratingStructuredPrior = false;
  bool _isDisposed = false;

  Map<String, dynamic> _llmChatTelemetry = <String, dynamic>{};
  Map<String, dynamic> _structuredSymptomPrior = <String, dynamic>{};
  String _lastAnsweredQuestionId = '';
  String _lastAnsweredQuestion = '';
  int _chatSessionSeed = 0;

  String _derivedOnsetDuration = '';
  String _derivedItchSeverity = 'not_sure';
  String _derivedProgression = 'not_sure';
  String _derivedParasitePreventionStatus = 'not_sure';
  String _derivedTriggerContext = 'not_sure';
  List<String> _derivedDistributionAreas = <String>[];
  List<String> _derivedLesionAppearance = <String>[];
  List<String> _derivedRedFlags = <String>[];

  int get _turnCount => _conversation.where((m) => m['role'] == 'user').length;

  bool get _hasAnyRedFlag => _derivedRedFlags.isNotEmpty;

  bool get _hasStructuredSignal {
    return _derivedDistributionAreas.isNotEmpty ||
        _derivedLesionAppearance.isNotEmpty ||
        _structuredPriorCandidateLabels().isNotEmpty;
  }

  bool get _isReadyForScan {
    final enoughTurns = _turnCount >= _minTurnsForReadiness;
    final llmDoneOrMaxTurns = _llmSaysDone || _turnCount >= 7;
    return enoughTurns && llmDoneOrMaxTurns && _hasStructuredSignal;
  }

  @override
  void initState() {
    super.initState();
    _hydrateFromExistingData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isDisposed) return;
      await _bootstrapConversation();
      if (!mounted || _isDisposed) return;
      _pushData();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingData() {
    final intake = Map<String, dynamic>.from(
      widget.assessmentData['clinicalIntake'] as Map? ?? <String, dynamic>{},
    );

    _derivedOnsetDuration = intake['onsetDuration']?.toString().trim() ?? '';
    _derivedItchSeverity =
        _normalizeSeverity(intake['itchSeverity']?.toString() ?? 'not_sure');
    _derivedProgression =
        _normalizeProgression(intake['progression']?.toString() ?? 'not_sure');
    _derivedParasitePreventionStatus = _normalizeParasiteStatus(
      intake['parasitePreventionStatus']?.toString() ??
          ((intake['parasitePrevention'] == true) ? 'yes' : 'not_sure'),
    );
    _derivedTriggerContext =
        _normalizeTrigger(intake['triggerContext']?.toString() ?? 'not_sure');

    _derivedDistributionAreas = _normalizeUniqueList(
      _coerceDynamicList(intake['distributionAreas'])
          .map((e) => e.toString()),
    );

    _derivedLesionAppearance = _normalizeUniqueList(
      _coerceDynamicList(intake['lesionAppearance'])
          .map((e) => e.toString()),
    );

    _derivedRedFlags = _normalizeUniqueList(
      _coerceDynamicList(intake['redFlags'])
          .map((e) => e.toString()),
    );

    _llmSaysDone = intake['llmQuestioningDone'] == true;
    _activeQuestion = intake['activeQuestion']?.toString().trim();
    _activeQuestionId = intake['activeQuestionId']?.toString().trim();
    if (_activeQuestionId != null && _activeQuestionId!.isEmpty) {
      _activeQuestionId = null;
    }
    if (_activeQuestion != null && _activeQuestion!.isEmpty) {
      _activeQuestion = null;
    }

    if (_activeQuestion == null) {
      _activeQuestionId = null;
      _activeQuickOptions = <String>[];
    }

    _activeQuickOptions = _normalizeQuickOptions(
      _coerceDynamicList(intake['activeQuickOptions']),
    );

    _llmChatTelemetry = Map<String, dynamic>.from(
      intake['llmChatTelemetry'] as Map? ?? <String, dynamic>{},
    );

    _structuredSymptomPrior = Map<String, dynamic>.from(
      intake['structuredSymptomPrior'] as Map? ?? <String, dynamic>{},
    );

    _lastAnsweredQuestionId =
        intake['lastAnsweredQuestionId']?.toString().trim() ?? '';
    _lastAnsweredQuestion =
        intake['lastAnsweredQuestion']?.toString().trim() ?? '';

    final persistedSeed =
      int.tryParse(intake['chatSessionSeed']?.toString() ?? '');
    _chatSessionSeed = (persistedSeed != null && persistedSeed > 0)
      ? persistedSeed
      : DateTime.now().millisecondsSinceEpoch;

    final savedFlow = _coerceDynamicList(intake['dynamicQuestionFlow'])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    _questionTrace
      ..clear()
      ..addAll(savedFlow);

    final historyRaw = intake['conversationHistory'];
    if (historyRaw is List) {
      for (final item in historyRaw) {
        if (item is! Map) continue;
        final role = item['role']?.toString().trim().toLowerCase() ?? '';
        final text = item['text']?.toString().trim() ?? '';
        if ((role == 'user' || role == 'assistant') && text.isNotEmpty) {
          _conversation.add({'role': role, 'text': text});
        }
      }
    }

    if (_conversation.isEmpty) {
      final legacyFreeText = Map<String, dynamic>.from(
        intake['chatFreeTextAnswers'] as Map? ?? <String, dynamic>{},
      );
      final entries = legacyFreeText.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in entries) {
        final text = entry.value.toString().trim();
        if (text.isEmpty) continue;
        _conversation.add({'role': 'user', 'text': text});
      }
    }

    if (_structuredSymptomPrior.isNotEmpty) {
      _applyStructuredPriorToDerivedIntake(_structuredSymptomPrior);
    }
  }

  Future<void> _bootstrapConversation() async {
    if (_conversation.isEmpty) {
      _appendMessage(
        role: 'assistant',
        text:
            'Hi! I will ask a few quick questions to understand your pet\'s skin concern before camera scanning.',
        persist: false,
      );
    }

    if (_isReadyForScan) {
      _activeQuestion = null;
      _activeQuestionId = null;
      _llmSaysDone = true;
      _pushData();
      return;
    }

    if (_activeQuestion == null && !_isGeneratingNextQuestion) {
      await _requestNextQuestion(isInitial: true);
    }

    _scrollToBottomSoon();
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

  List<String> _normalizeUniqueList(Iterable<String> values) {
    final seen = <String>{};
    final output = <String>[];

    for (final raw in values) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      output.add(value);
    }

    return output;
  }

  List<String> _normalizeQuickOptions(
    Iterable<dynamic> values, {
    int maxCount = 6,
  }) {
    final seen = <String>{};
    final output = <String>[];

    for (final raw in values) {
      final value = raw.toString().trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      output.add(value);
      if (output.length >= maxCount) break;
    }

    return output;
  }

  String _normalizeSeverity(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'mild' ||
        normalized == 'moderate' ||
        normalized == 'severe') {
      return normalized;
    }
    return 'not_sure';
  }

  String _normalizeProgression(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'stable':
      case 'about_the_same':
      case 'about the same':
        return 'stable';
      case 'getting_worse':
      case 'worse':
      case 'worsening':
        return 'getting_worse';
      case 'improving':
      case 'better':
        return 'improving';
      default:
        return 'not_sure';
    }
  }

  String _normalizeParasiteStatus(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'yes') return 'yes';
    if (normalized == 'no') return 'no';
    return 'not_sure';
  }

  String _normalizeTrigger(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'recent_grooming':
      case 'grooming':
      case 'shampoo_change':
        return 'recent_grooming';
      case 'possible_allergen':
      case 'allergen':
      case 'allergy':
        return 'possible_allergen';
      case 'recent_medication':
      case 'medication':
        return 'recent_medication';
      case 'none':
      case 'no_clear_trigger':
        return 'none';
      default:
        return 'not_sure';
    }
  }

  void _appendMessage({
    required String role,
    required String text,
    bool persist = true,
    bool notify = true,
  }) {
    var cleaned = text.trim();
    if (role == 'assistant') {
      cleaned = _sanitizeAssistantChatText(cleaned);
    }
    if (cleaned.isEmpty) return;

    if (notify && mounted) {
      setState(() {
        _conversation.add({'role': role, 'text': cleaned});
      });
    } else {
      _conversation.add({'role': role, 'text': cleaned});
    }

    if (persist && mounted && !_isDisposed) {
      _pushData();
    }

    _scrollToBottomSoon();
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      if (!_chatScrollController.hasClients) return;
      final position = _chatScrollController.position;
      if (!position.hasContentDimensions) return;

      try {
        _chatScrollController.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } catch (_) {
        // Ignore transient detach errors during page transitions.
      }
    });
  }

  Map<String, dynamic> _buildPetProfileSnapshot() {
    final newPetData = Map<String, dynamic>.from(
      widget.assessmentData['newPetData'] as Map? ?? <String, dynamic>{},
    );

    return {
      'pet_type': widget.assessmentData['selectedPetType']?.toString() ?? 'Dog',
      'age': newPetData['age']?.toString() ?? '',
      'breed': newPetData['breed']?.toString() ?? '',
      'weight': newPetData['weight']?.toString() ?? '',
      'sex': newPetData['gender']?.toString() ?? '',
    };
  }

  List<String> _structuredPriorCandidateLabels() {
    final raw = _structuredSymptomPrior['triage_priors'];
    if (raw is! List) return <String>[];

    final scored = <MapEntry<String, double>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final label = item['condition']?.toString().trim().toLowerCase() ?? '';
      if (label.isEmpty) continue;
      final score =
          item['score'] is num ? (item['score'] as num).toDouble() : 0.0;
      scored.add(MapEntry(label, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));

    final output = <String>[];
    final seen = <String>{};
    for (final entry in scored) {
      final normalized = entry.key.replaceAll('-', '_').replaceAll(' ', '_');
      if (!_knownLabels.contains(normalized) || seen.contains(normalized)) {
        continue;
      }
      seen.add(normalized);
      output.add(normalized);
      if (output.length >= 5) break;
    }

    return output;
  }

  String _fallbackQuestionByTurn({
    String questionId = 'dynamic_followup',
    Map<String, dynamic>? questionCatalog,
  }) {
    final catalog = questionCatalog ?? _buildQuestionCatalog();
    final normalizedQuestionId =
      questionId.trim().isEmpty ? 'dynamic_followup' : questionId.trim();

    return _buildAdaptivePromptForIntent(
      questionId: normalizedQuestionId,
      questionCatalog: catalog,
    );
  }

  bool _looksLikeInternalAssistantText(String text) {
    final normalized = text.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    for (final marker in _internalAssistantMarkers) {
      if (normalized.contains(marker)) {
        return true;
      }
    }

    return false;
  }

  String _buildVisibleAssistantPrompt({
    required String rawQuestion,
    required String rawHelper,
    String questionId = 'dynamic_followup',
    Map<String, dynamic>? questionCatalog,
  }) {
    var question = rawQuestion.trim();
    final helper = rawHelper.trim();
    final normalizedQuestionId =
      questionId.trim().isEmpty ? 'dynamic_followup' : questionId.trim();

    if (question.isEmpty || _looksLikeInternalAssistantText(question)) {
      return _fallbackQuestionByTurn(
        questionId: normalizedQuestionId,
        questionCatalog: questionCatalog,
      );
    }

    if (helper.isNotEmpty && !_looksLikeInternalAssistantText(helper)) {
      return '$question\n\n$helper';
    }

    return question;
  }

  String _sanitizeAssistantChatText(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty || _looksLikeInternalAssistantText(cleaned)) {
      return '';
    }
    return cleaned;
  }

  String _normalizeQuestionKey(String text) {
    final firstLine = text.split('\n').first.trim().toLowerCase();
    if (firstLine.isEmpty) return '';

    return firstLine
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isDuplicateAssistantQuestion(String prompt) {
    final candidate = _normalizeQuestionKey(prompt);
    if (candidate.isEmpty) return false;

    var inspected = 0;
    for (var i = _conversation.length - 1; i >= 0; i--) {
      final message = _conversation[i];
      if (message['role'] != 'assistant') continue;

      final prior = _normalizeQuestionKey(message['text'] ?? '');
      if (prior == candidate) {
        return true;
      }

      inspected += 1;
      if (inspected >= 3) {
        break;
      }
    }

    return false;
  }

  int _stableHash(String value) {
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = ((hash * 31) + unit) & 0x7fffffff;
    }
    return hash;
  }

  int _sessionVariantIndex({required String key, required int size}) {
    if (size <= 1) return 0;

    final latestAnswer = _latestUserAnswerText();
    final basis =
        '$_chatSessionSeed|$_turnCount|$_lastAnsweredQuestionId|$latestAnswer|$key';
    return _stableHash(basis) % size;
  }

  String _intentFocusForQuestionId({
    required String questionId,
    required Map<String, dynamic> questionCatalog,
  }) {
    final entry = Map<String, dynamic>.from(
      questionCatalog[questionId] as Map? ?? <String, dynamic>{},
    );
    final focus = entry['intent_focus']?.toString().trim();
    if (focus != null && focus.isNotEmpty) {
      return focus;
    }

    return 'the current skin concern';
  }

  String _buildAdaptivePromptForIntent({
    required String questionId,
    required Map<String, dynamic> questionCatalog,
  }) {
    final focus = _intentFocusForQuestionId(
      questionId: questionId,
      questionCatalog: questionCatalog,
    );
    final latestAnswer = _latestUserAnswerText();

    final rawOptions = _coerceDynamicList(
      (questionCatalog[questionId] as Map?)?['quick_options'],
    );
    final quickOptions = rawOptions
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList(growable: false);

    final stems = latestAnswer.isNotEmpty
        ? <String>[
            'Thanks. Could you share one more detail about $focus?',
            'Based on what you shared, what else can you tell me about $focus?',
            'To narrow this down, can you clarify $focus a bit more?',
          ]
        : <String>[
            'Could you share a detail about $focus?',
            'Can you tell me more about $focus?',
            'What can you share about $focus?',
          ];

    final stemIndex = _sessionVariantIndex(
      key: '$questionId|$focus|$latestAnswer|adaptive_prompt',
      size: stems.length,
    );

    final question = stems[stemIndex];
    if (quickOptions.isEmpty) {
      return question;
    }

    final helper = 'If useful, you can mention ${quickOptions.join(', ')}.';
    return '$question\n\n$helper';
  }

  String _pickAlternativeQuestionId({
    required List<String> eligibleQuestionIds,
    required String currentQuestionId,
  }) {
    if (eligibleQuestionIds.isEmpty) {
      return currentQuestionId;
    }

    for (final id in eligibleQuestionIds) {
      if (id == currentQuestionId) continue;
      if (id == _lastAnsweredQuestionId) continue;
      if (_questionTrace.isNotEmpty && id == _questionTrace.last) continue;
      return id;
    }

    for (final id in eligibleQuestionIds) {
      if (id != currentQuestionId) return id;
    }

    return currentQuestionId;
  }

  String _latestUserAnswerText() {
    for (var i = _conversation.length - 1; i >= 0; i--) {
      final item = _conversation[i];
      if (item['role'] != 'user') continue;

      final text = item['text']?.trim() ?? '';
      if (text.isNotEmpty) return text.toLowerCase();
    }

    return '';
  }

  bool _containsAnyKeyword(String source, List<String> keywords) {
    for (final keyword in keywords) {
      if (source.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  String _normalizeAnswerValue(String text) {
    return text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _applyDirectAnswerSignals({
    required String questionId,
    required String answerText,
  }) {
    if (questionId.trim().isEmpty || answerText.trim().isEmpty) {
      return;
    }

    final normalized = _normalizeAnswerValue(answerText);
    if (normalized.isEmpty) {
      return;
    }

    switch (questionId) {
      case 'distribution_areas':
        final inferred = <String>[];
        if (_containsAnyKeyword(normalized, <String>['face', 'muzzle'])) {
          inferred.add('Face');
        }
        if (_containsAnyKeyword(normalized, <String>['ear', 'ears'])) {
          inferred.add('Ears');
        }
        if (_containsAnyKeyword(normalized, <String>['neck'])) {
          inferred.add('Neck');
        }
        if (_containsAnyKeyword(normalized, <String>['back', 'spine'])) {
          inferred.add('Back');
        }
        if (_containsAnyKeyword(
            normalized, <String>['belly', 'abdomen', 'stomach'])) {
          inferred.add('Belly');
        }
        if (_containsAnyKeyword(normalized, <String>['paw', 'paws', 'foot'])) {
          inferred.add('Paws');
        }
        if (_containsAnyKeyword(normalized, <String>['tail'])) {
          inferred.add('Tail');
        }
        if (_containsAnyKeyword(normalized,
            <String>['widespread', 'all over', 'whole body', 'everywhere'])) {
          inferred.add('Widespread');
        }
        if (inferred.isNotEmpty) {
          _derivedDistributionAreas = _normalizeUniqueList(
            <String>[..._derivedDistributionAreas, ...inferred],
          );
        }
        break;
      case 'lesion_appearance':
        final inferred = <String>[];
        if (_containsAnyKeyword(
            normalized, <String>['red', 'rash', 'inflamed'])) {
          inferred.add('Redness / rash');
        }
        if (_containsAnyKeyword(
            normalized, <String>['hair loss', 'bald', 'alopecia'])) {
          inferred.add('Hair loss patches');
        }
        if (_containsAnyKeyword(
            normalized, <String>['scab', 'scabs', 'crust'])) {
          inferred.add('Scabs / crusts');
        }
        if (_containsAnyKeyword(
            normalized, <String>['moist', 'ooz', 'discharge', 'wet'])) {
          inferred.add('Moist or oozing skin');
        }
        if (_containsAnyKeyword(normalized, <String>['ring', 'circular'])) {
          inferred.add('Circular lesions');
        }
        if (_containsAnyKeyword(
            normalized, <String>['flaky', 'dandruff', 'scaly'])) {
          inferred.add('Flaky / dandruff-like');
        }
        if (_containsAnyKeyword(
            normalized, <String>['tiny moving dots', 'flea', 'tick', 'mite'])) {
          inferred.add('Tiny moving dots');
        }
        if (inferred.isNotEmpty) {
          _derivedLesionAppearance = _normalizeUniqueList(
            <String>[..._derivedLesionAppearance, ...inferred],
          );
        }
        break;
      case 'itch_severity':
        if (_containsAnyKeyword(
            normalized, <String>['severe', 'very itchy', 'extremely itchy'])) {
          _derivedItchSeverity = 'severe';
        } else if (_containsAnyKeyword(normalized, <String>['moderate'])) {
          _derivedItchSeverity = 'moderate';
        } else if (_containsAnyKeyword(
            normalized, <String>['mild', 'slight', 'not itchy', 'no itch'])) {
          _derivedItchSeverity = 'mild';
        } else if (_containsAnyKeyword(
            normalized, <String>['not sure', 'unsure'])) {
          _derivedItchSeverity = 'not_sure';
        }
        break;
      case 'progression':
        if (_containsAnyKeyword(
            normalized, <String>['worse', 'spreading', 'rapid'])) {
          _derivedProgression = 'getting_worse';
        } else if (_containsAnyKeyword(
            normalized, <String>['improving', 'better'])) {
          _derivedProgression = 'improving';
        } else if (_containsAnyKeyword(
            normalized, <String>['same', 'stable', 'unchanged'])) {
          _derivedProgression = 'stable';
        } else if (_containsAnyKeyword(
            normalized, <String>['not sure', 'unsure'])) {
          _derivedProgression = 'not_sure';
        }
        break;
      case 'onset_duration':
        final raw = answerText.trim();
        if (_containsAnyKeyword(normalized, <String>['today'])) {
          _derivedOnsetDuration = 'today';
        } else if (_containsAnyKeyword(
            normalized, <String>['1 to 3 days', '1 3 days', 'few days'])) {
          _derivedOnsetDuration = '1 to 3 days';
        } else if (_containsAnyKeyword(
            normalized, <String>['about a week', 'one week', 'week'])) {
          _derivedOnsetDuration = 'about a week';
        } else if (_containsAnyKeyword(
            normalized, <String>['more than a week', 'weeks', 'month'])) {
          _derivedOnsetDuration = 'more than a week';
        } else if (_containsAnyKeyword(
            normalized, <String>['not sure', 'unsure'])) {
          _derivedOnsetDuration = '';
        } else if (raw.isNotEmpty) {
          _derivedOnsetDuration = raw;
        }
        break;
      case 'parasite_prevention':
        if (_containsAnyKeyword(normalized, <String>['not sure', 'unsure'])) {
          _derivedParasitePreventionStatus = 'not_sure';
        } else if (_containsAnyKeyword(normalized, <String>['yes'])) {
          _derivedParasitePreventionStatus = 'yes';
        } else if (_containsAnyKeyword(normalized, <String>['no'])) {
          _derivedParasitePreventionStatus = 'no';
        }
        break;
      case 'trigger_context':
        if (_containsAnyKeyword(normalized, <String>['not sure', 'unsure'])) {
          _derivedTriggerContext = 'not_sure';
        } else if (_containsAnyKeyword(
            normalized, <String>['groom', 'shampoo'])) {
          _derivedTriggerContext = 'recent_grooming';
        } else if (_containsAnyKeyword(
            normalized, <String>['allergen', 'allergy', 'pollen', 'dust'])) {
          _derivedTriggerContext = 'possible_allergen';
        } else if (_containsAnyKeyword(
            normalized, <String>['medication', 'medicine'])) {
          _derivedTriggerContext = 'recent_medication';
        } else if (_containsAnyKeyword(
            normalized, <String>['no clear trigger', 'none', 'no trigger'])) {
          _derivedTriggerContext = 'none';
        }
        break;
      case 'red_flags_check':
        final hasWarningSignal = _containsAnyKeyword(normalized, <String>[
          'yes',
          'warning sign',
          'warning signs',
          'bleed',
          'discharge',
          'odor',
          'low energy',
          'weak',
          'letharg',
        ]);
        final explicitlyNoWarningSignal =
            _containsAnyKeyword(normalized, <String>[
          'no warning sign',
          'no warning signs',
          'no red flag',
          'none',
        ]);

        if (hasWarningSignal) {
          _derivedRedFlags = _normalizeUniqueList(
            <String>[..._derivedRedFlags, 'reported_warning_signs'],
          );
        } else if (explicitlyNoWarningSignal) {
          _derivedRedFlags = <String>[];
        }
        break;
    }
  }

  List<String> _buildEligibleQuestionIds() {
    _inferDerivedSignalsFromConversation();

    if (_isReadyForScan) {
      return const <String>[];
    }

    if (_turnCount == 0) {
      return const <String>['opening_context'];
    }

    return const <String>['dynamic_followup'];
  }

  Map<String, dynamic> _buildQuestionCatalog() {
    return {
      'opening_context': {
        'intent_focus': 'what you noticed first about the skin change',
        'input_type': 'free_text',
        'allow_free_text': true,
        'quick_options': <String>[
          'Itching or scratching',
          'Redness or rash',
          'Hair loss patch',
          'Scab or crust',
          'Moist skin or discharge',
          'Not sure',
        ],
      },
      'dynamic_followup': {
        'intent_focus':
            'the single most useful missing detail based on latest user answer and chat history',
        'input_type': 'free_text',
        'allow_free_text': true,
        'quick_options': <String>['Not sure'],
      },
    };
  }

  List<String> _suggestedRepliesForNextQuestion({
    required Map<String, dynamic> content,
    required String questionId,
    required Map<String, dynamic> questionCatalog,
  }) {
    final llmCandidates = <dynamic>[
      ..._coerceDynamicList(content['suggested_replies']),
      ..._coerceDynamicList(content['quick_options']),
      ..._coerceDynamicList(content['answer_options']),
    ];

    final llmOptions = _normalizeQuickOptions(
      llmCandidates,
      maxCount: 6,
    );
    if (llmOptions.isNotEmpty) {
      return llmOptions;
    }

    final catalogEntry = Map<String, dynamic>.from(
      questionCatalog[questionId] as Map? ?? <String, dynamic>{},
    );

    return _normalizeQuickOptions(
      _coerceDynamicList(catalogEntry['quick_options']),
      maxCount: 4,
    );
  }

  Future<void> _requestNextQuestion({bool isInitial = false}) async {
    if (_isGeneratingNextQuestion) return;
    if (_llmSaysDone) {
      if (_showThinkingIndicator && mounted) {
        setState(() => _showThinkingIndicator = false);
      }
      return;
    }

    setState(() {
      _isGeneratingNextQuestion = true;
      _showThinkingIndicator = true;
    });

    try {
      final petType =
          widget.assessmentData['selectedPetType']?.toString() ?? 'Dog';
      final intakeSnapshot = _buildCurrentIntakeSnapshot();
      final questionCatalog = _buildQuestionCatalog();
      final eligibleQuestionIds = _buildEligibleQuestionIds();
      var plannedQuestionId = eligibleQuestionIds.isNotEmpty
          ? eligibleQuestionIds.first
          : 'dynamic_followup';

      if (plannedQuestionId == 'opening_context' && _turnCount == 0) {
        final openingPrompt =
            'What did you notice first about your pet\'s skin issue?';
        final openingOptions = _normalizeQuickOptions(
          _coerceDynamicList(
            (questionCatalog['opening_context'] as Map?)?['quick_options'],
          ),
          maxCount: 6,
        );

        setState(() {
          _activeQuestion = openingPrompt;
          _activeQuestionId = 'opening_context';
          _activeQuickOptions = openingOptions;
          if (_questionTrace.isEmpty || _questionTrace.last != 'opening_context') {
            _questionTrace.add('opening_context');
          }
        });

        _appendMessage(
          role: 'assistant',
          text: openingPrompt,
          persist: false,
        );
        _pushData();
        return;
      }

      if (eligibleQuestionIds.length > 1 &&
          plannedQuestionId == _lastAnsweredQuestionId) {
        plannedQuestionId = _pickAlternativeQuestionId(
          eligibleQuestionIds: eligibleQuestionIds,
          currentQuestionId: plannedQuestionId,
        );
      }

      final result = await _groqService.generateGuidedChatQuestion(
        petType: petType,
        intakeData: intakeSnapshot,
        askedQuestionIds: _questionTrace,
        eligibleQuestionIds: eligibleQuestionIds,
        questionCatalog: questionCatalog,
        preferredQuestionId: plannedQuestionId,
      );

      if (!mounted) return;

      final content = Map<String, dynamic>.from(result.content);
      final rawQuestion = content['question_text']?.toString().trim() ?? '';
      final rawHelper = content['helper_text']?.toString().trim() ?? '';
      final llmQuestionId =
          content['next_question_id']?.toString().trim() ?? '';
      var resolvedQuestionId = plannedQuestionId.trim();
      if (resolvedQuestionId.isEmpty) {
        resolvedQuestionId = 'dynamic_followup';
      }

      if (llmQuestionId.isNotEmpty &&
          eligibleQuestionIds.contains(llmQuestionId) &&
          llmQuestionId != _lastAnsweredQuestionId) {
        resolvedQuestionId = llmQuestionId;
      }

      if (eligibleQuestionIds.length > 1 &&
          resolvedQuestionId == _lastAnsweredQuestionId) {
        resolvedQuestionId = _pickAlternativeQuestionId(
          eligibleQuestionIds: eligibleQuestionIds,
          currentQuestionId: resolvedQuestionId,
        );
      }

      final shouldFinish = !isInitial &&
          content['should_finish'] == true &&
          _turnCount >= _minTurnsForReadiness &&
          _hasStructuredSignal;

      final suggestedReplies = _suggestedRepliesForNextQuestion(
        content: content,
        questionId: resolvedQuestionId,
        questionCatalog: questionCatalog,
      );

      final requestCount =
          (_llmChatTelemetry['requestCount'] as num?)?.toInt() ?? 0;

      setState(() {
        _llmChatTelemetry = {
          ..._llmChatTelemetry,
          'requestCount': requestCount + 1,
          'plannedQuestionId': plannedQuestionId,
          'llmSuggestedQuestionId': llmQuestionId,
          'eligibleQuestionIds': eligibleQuestionIds,
          'lastModelUsed': result.modelUsed,
          'lastFallbackLevel': result.fallbackLevel.name,
          'lastErrorType': result.errorType.name,
          'lastLatencyMs': result.latencyMs,
          'lastCacheHit': result.cacheHit,
          'lastTraceId': result.traceId,
          'isConfigured': _groqService.isConfigured,
        };
      });

      if (shouldFinish) {
        setState(() {
          _llmSaysDone = true;
          _activeQuestion = null;
          _activeQuestionId = null;
          _activeQuickOptions = <String>[];
        });
        _appendMessage(
          role: 'assistant',
          text:
              'Thanks, I have enough details now. You can proceed to camera scan.',
          persist: false,
        );
        _pushData();
        return;
      }

      final prompt = _buildVisibleAssistantPrompt(
        rawQuestion: rawQuestion,
        rawHelper: rawHelper,
        questionId: resolvedQuestionId,
        questionCatalog: questionCatalog,
      );

      var finalPrompt = prompt;
      if (_isDuplicateAssistantQuestion(finalPrompt)) {
        if (eligibleQuestionIds.length > 1) {
          resolvedQuestionId = _pickAlternativeQuestionId(
            eligibleQuestionIds: eligibleQuestionIds,
            currentQuestionId: resolvedQuestionId,
          );
        }

        finalPrompt = _buildAdaptivePromptForIntent(
          questionId: resolvedQuestionId,
          questionCatalog: questionCatalog,
        );
      }

      if (_isDuplicateAssistantQuestion(finalPrompt)) {
        resolvedQuestionId = 'dynamic_followup';
        finalPrompt = _buildAdaptivePromptForIntent(
          questionId: resolvedQuestionId,
          questionCatalog: questionCatalog,
        );
      }

      if (_isDuplicateAssistantQuestion(finalPrompt)) {
        finalPrompt = _buildAdaptivePromptForIntent(
          questionId: resolvedQuestionId,
          questionCatalog: questionCatalog,
        );
      }

      setState(() {
        _activeQuestion = finalPrompt;
        _activeQuestionId = resolvedQuestionId;
        _activeQuickOptions = suggestedReplies;
        final traceId =
            resolvedQuestionId.isNotEmpty ? resolvedQuestionId : 'dynamic_followup';
        if (_questionTrace.isEmpty || _questionTrace.last != traceId) {
          _questionTrace.add(traceId);
        }
      });

      _appendMessage(
        role: 'assistant',
        text: finalPrompt,
        persist: false,
      );
      _pushData();
    } catch (_) {
      if (!mounted) return;

      final requestCount =
          (_llmChatTelemetry['requestCount'] as num?)?.toInt() ?? 0;
      setState(() {
        _llmChatTelemetry = {
          ..._llmChatTelemetry,
          'requestCount': requestCount + 1,
          'lastFallbackLevel': 'exception_fallback',
          'lastErrorType': 'exception',
          'isConfigured': _groqService.isConfigured,
        };
      });

      final questionCatalog = _buildQuestionCatalog();
      final fallbackCandidates = _buildEligibleQuestionIds();
      final fallbackQuestionId =
          fallbackCandidates.isNotEmpty ? fallbackCandidates.first : 'dynamic_followup';
      final prompt = _buildAdaptivePromptForIntent(
        questionId: fallbackQuestionId,
        questionCatalog: questionCatalog,
      );
      final fallbackReplies = _suggestedRepliesForNextQuestion(
        content: const <String, dynamic>{},
        questionId: fallbackQuestionId,
        questionCatalog: questionCatalog,
      );
      setState(() {
        _activeQuestion = prompt;
        _activeQuestionId = fallbackQuestionId;
        _activeQuickOptions = fallbackReplies;
        _questionTrace
            .add('exception_fallback_${DateTime.now().millisecondsSinceEpoch}');
      });

      _appendMessage(
        role: 'assistant',
        text: prompt,
        persist: false,
      );
      _pushData();
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingNextQuestion = false;
          _showThinkingIndicator = false;
        });
      }
    }
  }

  List<String> _mapSymptomsToLesionAppearance(List<String> symptoms) {
    final normalized = symptoms.map((s) => s.toLowerCase()).toList();
    final output = <String>[];

    void add(String label) {
      if (!output.contains(label)) {
        output.add(label);
      }
    }

    for (final symptom in normalized) {
      if (symptom.contains('red') || symptom.contains('rash')) {
        add('Redness / rash');
      }
      if (symptom.contains('hair_loss') ||
          symptom.contains('hair loss') ||
          symptom.contains('alopecia')) {
        add('Hair loss patches');
      }
      if (symptom.contains('crust') || symptom.contains('scab')) {
        add('Scabs / crusts');
      }
      if (symptom.contains('discharge') ||
          symptom.contains('ooz') ||
          symptom.contains('moist')) {
        add('Moist or oozing skin');
      }
      if (symptom.contains('ring') || symptom.contains('circular')) {
        add('Circular lesions');
      }
      if (symptom.contains('flaky') || symptom.contains('dandruff')) {
        add('Flaky / dandruff-like');
      }
      if (symptom.contains('flea') ||
          symptom.contains('tick') ||
          symptom.contains('mite') ||
          symptom.contains('parasite')) {
        add('Tiny moving dots');
      }
    }

    return output;
  }

  String _mapBodyLocation(String raw) {
    final normalized = raw.trim().toLowerCase().replaceAll('_', ' ');

    if (normalized.contains('face') || normalized.contains('muzzle')) {
      return 'Face';
    }
    if (normalized.contains('ear')) {
      return 'Ears';
    }
    if (normalized.contains('neck')) {
      return 'Neck';
    }
    if (normalized.contains('back') || normalized.contains('spine')) {
      return 'Back';
    }
    if (normalized.contains('belly') || normalized.contains('abdomen')) {
      return 'Belly';
    }
    if (normalized.contains('paw') || normalized.contains('foot')) {
      return 'Paws';
    }
    if (normalized.contains('tail')) {
      return 'Tail';
    }
    if (normalized.contains('widespread') ||
        normalized.contains('general') ||
        normalized.contains('multiple')) {
      return 'Widespread';
    }

    return '';
  }

  void _inferDerivedSignalsFromConversation() {
    final userText = _conversation
        .where((m) => m['role'] == 'user')
        .map((m) => m['text'] ?? '')
        .join(' ')
        .toLowerCase();

    bool hasAny(Iterable<String> keywords) {
      for (final keyword in keywords) {
        if (userText.contains(keyword)) return true;
      }
      return false;
    }

    if (_derivedOnsetDuration.trim().isEmpty) {
      if (hasAny(<String>['today', 'this morning', 'just started'])) {
        _derivedOnsetDuration = 'today';
      } else if (hasAny(<String>['yesterday', '1 day', 'one day'])) {
        _derivedOnsetDuration = '1 day';
      } else if (hasAny(<String>['2 day', '3 day', 'few days'])) {
        _derivedOnsetDuration = '1 to 3 days';
      } else if (hasAny(<String>['week', '7 days'])) {
        _derivedOnsetDuration = 'about a week';
      } else if (hasAny(<String>['month', 'weeks', 'long time'])) {
        _derivedOnsetDuration = 'more than a week';
      }
    }

    if (_derivedItchSeverity == 'not_sure') {
      if (hasAny(<String>[
        'very itchy',
        'extremely itchy',
        'constantly scratching',
        'keeps scratching',
        'all day scratching',
      ])) {
        _derivedItchSeverity = 'severe';
      } else if (hasAny(<String>[
        'slightly itchy',
        'a little itchy',
        'mild itch',
      ])) {
        _derivedItchSeverity = 'mild';
      } else if (hasAny(<String>[
        'itchy',
        'scratching',
        'itching',
      ])) {
        _derivedItchSeverity = 'moderate';
      }
    }

    if (_derivedDistributionAreas.isEmpty) {
      final inferredAreas = <String>[];
      if (hasAny(<String>['face', 'muzzle'])) inferredAreas.add('Face');
      if (hasAny(<String>['ear', 'ears'])) inferredAreas.add('Ears');
      if (hasAny(<String>['neck'])) inferredAreas.add('Neck');
      if (hasAny(<String>['back', 'spine'])) inferredAreas.add('Back');
      if (hasAny(<String>['belly', 'abdomen', 'stomach'])) {
        inferredAreas.add('Belly');
      }
      if (hasAny(<String>['paw', 'paws', 'foot', 'feet'])) {
        inferredAreas.add('Paws');
      }
      if (hasAny(<String>['tail'])) inferredAreas.add('Tail');
      if (hasAny(<String>['all over', 'everywhere', 'whole body'])) {
        inferredAreas.add('Widespread');
      }

      if (inferredAreas.isNotEmpty) {
        _derivedDistributionAreas = _normalizeUniqueList(inferredAreas);
      }
    }

    if (_derivedLesionAppearance.isEmpty) {
      final inferredAppearance = <String>[];
      if (hasAny(<String>['red', 'rash', 'inflamed'])) {
        inferredAppearance.add('Redness / rash');
      }
      if (hasAny(<String>['hair loss', 'bald', 'alopecia'])) {
        inferredAppearance.add('Hair loss patches');
      }
      if (hasAny(<String>['scab', 'scabs', 'crust', 'crusty'])) {
        inferredAppearance.add('Scabs / crusts');
      }
      if (hasAny(<String>['ooz', 'discharge', 'wet', 'moist'])) {
        inferredAppearance.add('Moist or oozing skin');
      }
      if (hasAny(<String>['ring', 'circular', 'circle'])) {
        inferredAppearance.add('Circular lesions');
      }
      if (hasAny(<String>['flaky', 'dandruff', 'scaly'])) {
        inferredAppearance.add('Flaky / dandruff-like');
      }
      if (hasAny(<String>['flea', 'tick', 'mites', 'moving dots'])) {
        inferredAppearance.add('Tiny moving dots');
      }

      if (inferredAppearance.isNotEmpty) {
        _derivedLesionAppearance = _normalizeUniqueList(inferredAppearance);
      }
    }

    if (_derivedProgression == 'not_sure') {
      if (userText.contains('worse') ||
          userText.contains('spreading') ||
          userText.contains('rapid')) {
        _derivedProgression = 'getting_worse';
      } else if (userText.contains('better') || userText.contains('improv')) {
        _derivedProgression = 'improving';
      } else if (userText.contains('same') || userText.contains('unchanged')) {
        _derivedProgression = 'stable';
      }
    }

    if (_derivedParasitePreventionStatus == 'not_sure') {
      if (userText.contains('not on prevention') ||
          userText.contains('overdue') ||
          userText.contains('no prevention')) {
        _derivedParasitePreventionStatus = 'no';
      } else if (userText.contains('on prevention') ||
          userText.contains('monthly prevention')) {
        _derivedParasitePreventionStatus = 'yes';
      }
    }

    if (_derivedTriggerContext == 'not_sure') {
      if (userText.contains('shampoo') || userText.contains('groom')) {
        _derivedTriggerContext = 'recent_grooming';
      } else if (userText.contains('allergy') ||
          userText.contains('allergen') ||
          userText.contains('dust') ||
          userText.contains('pollen')) {
        _derivedTriggerContext = 'possible_allergen';
      } else if (userText.contains('medication') ||
          userText.contains('medicine')) {
        _derivedTriggerContext = 'recent_medication';
      }
    }
  }

  void _applyStructuredPriorToDerivedIntake(Map<String, dynamic> prior) {
    final bodyLocations = _coerceDynamicList(prior['body_locations'])
      .map((e) => _mapBodyLocation(e.toString()))
      .where((e) => e.isNotEmpty)
      .toList();

    final symptoms = _coerceDynamicList(prior['symptoms'])
        .map((e) => e.toString())
        .toList();

    final redFlags = _coerceDynamicList(prior['red_flags'])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final exposure = _coerceDynamicList(prior['exposure_factors'])
      .map((e) => e.toString().toLowerCase())
      .toList();

    final duration = prior['duration']?.toString().trim() ?? '';
    final severity =
        _normalizeSeverity(prior['severity']?.toString() ?? 'not_sure');

    setState(() {
      if (duration.isNotEmpty) {
        _derivedOnsetDuration = duration;
      }

      _derivedItchSeverity = severity;
      _derivedDistributionAreas = _normalizeUniqueList(bodyLocations);
      _derivedLesionAppearance =
          _normalizeUniqueList(_mapSymptomsToLesionAppearance(symptoms));
      _derivedRedFlags = _normalizeUniqueList(redFlags);

      if (exposure.any((e) => e.contains('allergen'))) {
        _derivedTriggerContext = 'possible_allergen';
      } else if (exposure
          .any((e) => e.contains('shampoo') || e.contains('groom'))) {
        _derivedTriggerContext = 'recent_grooming';
      } else if (exposure.any((e) => e.contains('medication'))) {
        _derivedTriggerContext = 'recent_medication';
      }

      _inferDerivedSignalsFromConversation();
    });
  }

  Future<void> _refreshStructuredSymptomPrior() async {
    if (_isGeneratingStructuredPrior) return;
    if (_turnCount == 0) return;

    setState(() => _isGeneratingStructuredPrior = true);

    try {
      final intakeSnapshot = _buildCurrentIntakeSnapshot();
      final petProfile = _buildPetProfileSnapshot();
      final candidates = _coerceDynamicList(
        intakeSnapshot['visionCandidateLabels'],
      ).map((e) => e.toString()).toList();

      final result = await _groqService.generateStructuredSymptomPrior(
        petProfile: petProfile,
        intakeData: intakeSnapshot,
        cameraDetectableConditions: candidates,
      );

      if (!mounted) return;

      final content = Map<String, dynamic>.from(result.content);
      setState(() {
        _structuredSymptomPrior = content;
      });

      _applyStructuredPriorToDerivedIntake(content);

      final priorsRaw = content['triage_priors'];
      final topConditions = <Map<String, dynamic>>[];

      if (priorsRaw is List) {
        for (final item in priorsRaw) {
          if (item is! Map) continue;
          final condition = item['condition']?.toString().trim() ?? '';
          if (condition.isEmpty) continue;
          final score = item['score'] is num
              ? (item['score'] as num).toDouble().clamp(0.0, 1.0)
              : 0.0;
          topConditions.add({
            'condition': condition
                .toLowerCase()
                .replaceAll('-', '_')
                .replaceAll(' ', '_'),
            'score': score,
          });
        }
      }

      if (topConditions.isNotEmpty) {
        widget.onDataUpdate('triagePrior', {
          'top_conditions': topConditions,
          'confidence_band': 'symptom_informed_prior',
          'rationale': content['summary']?.toString() ??
              'Based on owner history and symptoms only.',
          'care_guidance': <String>[],
          'escalation_triggers': content['red_flags'] ?? <String>[],
          'confidence_note': 'This is a symptom-based prior, not a diagnosis.',
        });
      }

      widget.onDataUpdate('triageTelemetry', {
        'modelUsed': result.modelUsed,
        'fallbackLevel': result.fallbackLevel.name,
        'errorType': result.errorType.name,
        'latencyMs': result.latencyMs,
        'cacheHit': result.cacheHit,
        'traceId': result.traceId,
        'source': 'pretriage_structured_prior',
        'cameraConditionCount': candidates.length,
        'answeredCountAtGeneration': _turnCount,
      });

      _pushData();
    } catch (_) {
      // Keep chat responsive even if structured extraction fails.
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStructuredPrior = false);
      }
    }
  }

  List<String> _computeVisionCandidates() {
    final fromPrior = _structuredPriorCandidateLabels();
    if (fromPrior.isNotEmpty) {
      return fromPrior;
    }

    final scores = <String, int>{
      for (final label in _knownLabels) label: 1,
    };

    void boost(List<String> labels, [int by = 2]) {
      for (final label in labels) {
        if (!scores.containsKey(label)) continue;
        scores[label] = (scores[label] ?? 0) + by;
      }
    }

    if (_derivedItchSeverity == 'severe') {
      boost(<String>['fleas', 'ticks', 'mange', 'dermatitis', 'hotspot']);
    } else if (_derivedItchSeverity == 'moderate') {
      boost(<String>['fleas', 'mange', 'dermatitis', 'fungal_infection'], 1);
    }

    if (_derivedDistributionAreas.contains('Ears')) {
      boost(<String>['ticks', 'mange', 'ringworm'], 1);
    }
    if (_derivedDistributionAreas.contains('Paws')) {
      boost(<String>['dermatitis', 'fungal_infection', 'pyoderma'], 1);
    }
    if (_derivedDistributionAreas.contains('Back') ||
        _derivedDistributionAreas.contains('Tail')) {
      boost(<String>['fleas', 'ticks', 'hotspot'], 1);
    }
    if (_derivedDistributionAreas.contains('Widespread')) {
      boost(<String>['mange', 'dermatitis', 'fungal_infection'], 1);
    }

    if (_derivedLesionAppearance.contains('Circular lesions')) {
      boost(<String>['ringworm', 'fungal_infection', 'mange']);
    }
    if (_derivedLesionAppearance.contains('Moist or oozing skin')) {
      boost(<String>['hotspot', 'pyoderma', 'dermatitis']);
    }
    if (_derivedLesionAppearance.contains('Scabs / crusts')) {
      boost(<String>['mange', 'pyoderma', 'dermatitis']);
    }
    if (_derivedLesionAppearance.contains('Flaky / dandruff-like')) {
      boost(<String>['dermatitis', 'fungal_infection', 'mange']);
    }
    if (_derivedLesionAppearance.contains('Tiny moving dots')) {
      boost(<String>['fleas', 'ticks', 'mange']);
    }
    if (_derivedLesionAppearance.contains('Redness / rash')) {
      boost(<String>['dermatitis', 'hotspot', 'pyoderma'], 1);
    }
    if (_derivedLesionAppearance.contains('Hair loss patches')) {
      boost(<String>['ringworm', 'mange', 'fungal_infection']);
    }

    if (_derivedProgression == 'getting_worse') {
      boost(<String>['hotspot', 'pyoderma', 'mange'], 1);
    }

    if (_derivedParasitePreventionStatus == 'no') {
      boost(<String>['fleas', 'ticks'], 2);
    }

    if (_derivedTriggerContext == 'recent_grooming') {
      boost(<String>['dermatitis', 'hotspot'], 1);
    } else if (_derivedTriggerContext == 'possible_allergen') {
      boost(<String>['dermatitis'], 2);
    } else if (_derivedTriggerContext == 'recent_medication') {
      boost(<String>['dermatitis', 'unknown_abnormality'], 1);
    }

    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestScore = ranked.isEmpty ? 0 : ranked.first.value;
    final threshold = (bestScore - 1).clamp(1, bestScore);

    final shortlisted = ranked
        .where((entry) => entry.value >= threshold)
        .map((entry) => entry.key)
        .take(5)
        .toList();

    if (shortlisted.isEmpty) {
      final fallback = List<String>.from(_knownLabels)..sort();
      return fallback;
    }

    return shortlisted;
  }

  String _buildFunnelSummary(List<String> candidates) {
    if (!_isReadyForScan) {
      return 'Keep chatting for a few more turns so we can improve scan guidance.';
    }

    if (candidates.isEmpty) {
      return 'You are all set. We will scan across all supported conditions.';
    }

    return 'You are all set. Camera scan will prioritize likely visible conditions from this chat.';
  }

  Map<String, dynamic> _buildCurrentIntakeSnapshot({
    List<String>? visionCandidates,
  }) {
    final candidates = visionCandidates ?? _computeVisionCandidates();

    final freeTextByTurn = <String, String>{};
    var turnIndex = 0;
    for (final message in _conversation) {
      if (message['role'] != 'user') continue;
      freeTextByTurn['turn_$turnIndex'] = message['text'] ?? '';
      turnIndex += 1;
    }

    return {
      'onsetDuration': _derivedOnsetDuration,
      'progression': _derivedProgression,
      'itchSeverity': _derivedItchSeverity,
      'appetiteChange': 'not_sure',
      'distributionAreas': _derivedDistributionAreas,
      'lesionAppearance': _derivedLesionAppearance,
      'recentGrooming': _derivedTriggerContext == 'recent_grooming',
      'parasitePrevention': _derivedParasitePreventionStatus == 'yes',
      'parasitePreventionStatus': _derivedParasitePreventionStatus,
      'allergenExposure': _derivedTriggerContext == 'possible_allergen',
      'recentMedication': _derivedTriggerContext == 'recent_medication'
          ? 'reported_recently'
          : '',
      'redFlags': _derivedRedFlags,
      'hasRedFlags': _hasAnyRedFlag,
      'triggerContext': _derivedTriggerContext,
      'funnelStep': _turnCount,
      'preTriageAnsweredCount': _turnCount,
      'preTriageRequiredCount': _minTurnsForReadiness,
      'preTriageReadyForScan': _isReadyForScan,
      'dynamicQuestionFlow': _questionTrace,
      'llmQuestionTextById': <String, String>{},
      'llmHelperTextById': <String, String>{},
      'chatFreeTextAnswers': freeTextByTurn,
      'llmQuestioningDone': _llmSaysDone,
      'llmChatTelemetry': _llmChatTelemetry,
      'structuredSymptomPrior': _structuredSymptomPrior,
      'lastAnsweredQuestionId': _lastAnsweredQuestionId,
      'lastAnsweredQuestion': _lastAnsweredQuestion,
      'chatSessionSeed': _chatSessionSeed,
      'visionCandidateLabels': candidates,
      'funnelSummary': _buildFunnelSummary(candidates),
      'conversationHistory': _conversation,
      'activeQuestion': _activeQuestion,
      'activeQuestionId': _activeQuestionId,
      'activeQuickOptions': _activeQuickOptions,
      'chatMode': 'llm_open_text',
    };
  }

  void _pushData() {
    if (!mounted || _isDisposed) return;
    widget.onDataUpdate('clinicalIntake', _buildCurrentIntakeSnapshot());
  }

  Future<void> _sendCurrentMessage({String? prefilledText}) async {
    if (_isGeneratingNextQuestion || _showThinkingIndicator) return;

    final answeredQuestionId = _activeQuestionId?.trim() ?? '';
    final answeredQuestionText = _activeQuestion?.trim() ?? '';

    final text = (prefilledText ?? _messageController.text).trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please type your answer first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    _messageController.clear();

    setState(() {
      _activeQuestion = null;
      _activeQuestionId = null;
      _activeQuickOptions = <String>[];
      _showThinkingIndicator = true;
      _llmSaysDone = false;
      _lastAnsweredQuestionId = answeredQuestionId;
      _lastAnsweredQuestion = answeredQuestionText;
      _applyDirectAnswerSignals(
        questionId: answeredQuestionId,
        answerText: text,
      );
    });

    _appendMessage(role: 'user', text: text, persist: false);

    setState(() {
      _inferDerivedSignalsFromConversation();
    });

    _pushData();

    await _refreshStructuredSymptomPrior();

    if (_isReadyForScan) {
      setState(() {
        _showThinkingIndicator = false;
        _llmSaysDone = true;
      });
      _appendMessage(
        role: 'assistant',
        text:
            'Great, I have enough information now. You can proceed to camera scan whenever ready.',
        persist: false,
      );
      _pushData();
      return;
    }

    await _requestNextQuestion();
  }

  void _undoLastTurn() {
    if (_conversation.isEmpty || _isGeneratingNextQuestion) return;

    setState(() {
      // Remove trailing assistant prompt if present.
      if (_conversation.isNotEmpty &&
          _conversation.last['role'] == 'assistant') {
        _conversation.removeLast();
      }
      // Remove last user message.
      for (var i = _conversation.length - 1; i >= 0; i--) {
        if (_conversation[i]['role'] == 'user') {
          _conversation.removeAt(i);
          break;
        }
      }

      if (_questionTrace.isNotEmpty) {
        _questionTrace.removeLast();
      }

      _activeQuestion = null;
      _activeQuestionId = null;
      _activeQuickOptions = <String>[];
      _showThinkingIndicator = false;
      _llmSaysDone = false;
    });

    _pushData();

    // Ask another follow-up if needed after undo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposed) return;
      if (!_isReadyForScan && !_isGeneratingNextQuestion) {
        _requestNextQuestion();
      }
    });
  }

  List<String> _quickReplyOptionsForActiveQuestion() {
    if (_activeQuestion == null || _activeQuestion!.trim().isEmpty) {
      return const <String>[];
    }

    return _activeQuickOptions;
  }

  Future<void> _sendQuickReplyOption(String option) async {
    final text = option.trim();
    if (text.isEmpty || _isGeneratingNextQuestion || _showThinkingIndicator) {
      return;
    }

    await _sendCurrentMessage(prefilledText: text);
  }

  Widget _assistantBubbleContent(String text) {
    final baseStyle = kMobileTextStyleSubtitle.copyWith(
      color: AppColors.textPrimary,
      height: 1.35,
    );

    final segments = text
        .split(RegExp(r'\n\s*\n'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.length <= 1) {
      return Text(text, style: baseStyle);
    }

    final question = segments.first;
    final helper = segments.skip(1).join('\n\n');

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(
            text: question,
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ),
          if (helper.isNotEmpty)
            TextSpan(
              text: '\n\n$helper',
              style: baseStyle.copyWith(fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _chatBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    final rawText = message['text'] ?? '';
    final text = isUser ? rawText : _sanitizeAssistantChatText(rawText);

    if (text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: kSpacingSmall),
        padding: const EdgeInsets.symmetric(
          horizontal: kSpacingSmall,
          vertical: 10,
        ),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.border.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(
            color: isUser
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border.withValues(alpha: 0.4),
          ),
        ),
        child: isUser
            ? Text(
                text,
                style: kMobileTextStyleSubtitle.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              )
            : _assistantBubbleContent(text),
      ),
    );
  }

  Widget _headerStatusChip() {
    final ready = _isReadyForScan;
    final color = ready ? AppColors.success : AppColors.warning;
    final textColor = ready ? AppColors.success : AppColors.textPrimary;
    final icon = ready ? Icons.check_circle_outline : Icons.hourglass_bottom;
    final text = ready ? 'Ready' : 'Needs context';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: kMobileTextStyleLegend.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final llmConfigured = _groqService.isConfigured;
    final displayTurnCount =
        _isReadyForScan ? _minTurnsForReadiness : _turnCount;
    final quickReplyOptions = _quickReplyOptionsForActiveQuestion();
    final isAwaitingAssistant =
      _showThinkingIndicator || _isGeneratingNextQuestion;
    return Padding(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.forum_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skin Check Chat',
                        style: kMobileTextStyleTitle.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$displayTurnCount/$_minTurnsForReadiness turns • ${llmConfigured ? 'AI mode' : 'Fallback mode'}',
                        style: kMobileTextStyleLegend.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _headerStatusChip(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isReadyForScan
                ? 'Ready for scan'
                : '$_turnCount of $_minTurnsForReadiness guided turns completed',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingSmall),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final composerMaxHeight =
                      (constraints.maxHeight * 0.48).clamp(140.0, 320.0);

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _chatScrollController,
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: _conversation.length,
                          itemBuilder: (context, index) {
                            final message = _conversation[index];
                            return _chatBubble(message);
                          },
                        ),
                      ),
                      const SizedBox(height: kSpacingSmall),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: composerMaxHeight,
                        ),
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAwaitingAssistant)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'AI is thinking...',
                                          style: kMobileTextStyleLegend.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_hasAnyRedFlag) ...[
                                const SizedBox(height: kSpacingSmall),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(kSpacingSmall),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(kBorderRadius),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Potential urgent signs were mentioned. The app will prioritize safer escalation guidance.',
                                    style: kMobileTextStyleSubtitle.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                              if (_activeQuestion != null &&
                                  !isAwaitingAssistant)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Tip: type your answer or tap a quick option. "Not sure" is okay.',
                                      style: kMobileTextStyleLegend.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              if (_activeQuestion != null &&
                                  !isAwaitingAssistant &&
                                  quickReplyOptions.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: quickReplyOptions
                                          .map(
                                            (option) => ActionChip(
                                              onPressed: isAwaitingAssistant
                                                  ? null
                                                  : () => _sendQuickReplyOption(
                                                        option,
                                                      ),
                                              backgroundColor:
                                                  AppColors.primary.withValues(
                                                alpha: 0.08,
                                              ),
                                              side: BorderSide(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.3),
                                              ),
                                              label: Text(
                                                option,
                                                style:
                                                    kMobileTextStyleLegend.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: kSpacingSmall),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      minLines: 1,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: isAwaitingAssistant
                                          ? null
                                          : (_) => _sendCurrentMessage(),
                                      decoration: const InputDecoration(
                                        hintText: 'Type your answer here...',
                                        labelText: 'Your message',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: isAwaitingAssistant
                                        ? null
                                        : _sendCurrentMessage,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(52, 52),
                                      padding: const EdgeInsets.all(0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Icon(Icons.send),
                                  ),
                                ],
                              ),
                              if (_turnCount > 0 && !isAwaitingAssistant)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: _undoLastTurn,
                                    icon: const Icon(Icons.undo),
                                    label: const Text('Undo last answer'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
  final _durationController = TextEditingController();
  final _freeTextController = TextEditingController();
  final GroqOrchestrationService _groqService =
      GroqOrchestrationService.instance;

  String _itchSeverity = 'not_sure';
  String _progression = 'not_sure';
  String _parasitePreventionStatus = 'not_sure';
  String _triggerContext = 'not_sure';
  int _chatStep = 0;
  bool _llmSaysDone = false;
  bool _isGeneratingNextQuestion = false;
  bool _isGeneratingStructuredPrior = false;

  List<String> _questionOrder = [];
  final Map<String, String> _llmQuestionTextById = {};
  final Map<String, String> _llmHelperTextById = {};
  final Map<String, String> _freeTextByQuestion = {};
  String? _freeTextQuestionId;
  Map<String, dynamic> _llmChatTelemetry = {};
  Map<String, dynamic> _structuredSymptomPrior = {};

  bool _answeredRedFlags = false;
  bool _answeredDistribution = false;
  bool _answeredAppearance = false;
  bool _answeredItch = false;
  bool _answeredProgression = false;
  bool _answeredParasitePrevention = false;
  bool _answeredTriggerContext = false;

  final Map<String, bool> _distribution = {
    'Face': false,
    'Ears': false,
    'Neck': false,
    'Back': false,
    'Belly': false,
    'Paws': false,
    'Tail': false,
    'Widespread': false,
    'Not sure': false,
  };

  final Map<String, bool> _lesionAppearance = {
    'Redness / rash': false,
    'Hair loss patches': false,
    'Scabs / crusts': false,
    'Moist or oozing skin': false,
    'Circular lesions': false,
    'Flaky / dandruff-like': false,
    'Tiny moving dots': false,
    'Not sure': false,
  };

  final Map<String, bool> _redFlags = {
    'Bleeding': false,
    'Pus or discharge': false,
    'Foul odor': false,
    'Low appetite': false,
    'Unusual weakness': false,
    'Not sure': false,
  };

  @override
  void initState() {
    super.initState();
    _hydrateFromExistingData();
    _durationController.addListener(_pushData);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeChatbot());
  }

  @override
  void dispose() {
    _durationController.dispose();
    _freeTextController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingData() {
    final data = Map<String, dynamic>.from(
      widget.assessmentData['clinicalIntake'] as Map? ?? <String, dynamic>{},
    );

    _durationController.text = data['onsetDuration']?.toString() ?? '';
    _itchSeverity = data['itchSeverity']?.toString() ?? _itchSeverity;
    _progression = data['progression']?.toString() ?? _progression;
    _parasitePreventionStatus = data['parasitePreventionStatus']?.toString() ??
        ((data['parasitePrevention'] == true) ? 'yes' : 'not_sure');
    _triggerContext = data['triggerContext']?.toString() ?? _triggerContext;

    _restoreSelections(
      source: data['distributionAreas'],
      target: _distribution,
    );
    _restoreSelections(
      source: data['lesionAppearance'],
      target: _lesionAppearance,
    );
    _restoreSelections(
      source: data['redFlags'],
      target: _redFlags,
    );

    _answeredRedFlags = (data['redFlags'] as List?)?.isNotEmpty ?? false;
    _answeredDistribution =
        (data['distributionAreas'] as List?)?.isNotEmpty ?? false;
    _answeredAppearance =
        (data['lesionAppearance'] as List?)?.isNotEmpty ?? false;
    _answeredItch = data.containsKey('itchSeverity');
    _answeredProgression = data.containsKey('progression');
    _answeredParasitePrevention =
        data.containsKey('parasitePreventionStatus') ||
            data.containsKey('parasitePrevention');
    _answeredTriggerContext = data.containsKey('triggerContext');

    final savedStep = (data['funnelStep'] as num?)?.toInt() ?? 0;
    _chatStep = savedStep;

    final savedOrder = (data['dynamicQuestionFlow'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    _questionOrder = savedOrder.isNotEmpty ? savedOrder : <String>['red_flags'];

    _llmSaysDone = data['llmQuestioningDone'] == true;

    final savedQuestionText = Map<String, dynamic>.from(
      data['llmQuestionTextById'] as Map? ?? <String, dynamic>{},
    );
    _llmQuestionTextById
      ..clear()
      ..addEntries(
        savedQuestionText.entries
            .map((e) => MapEntry(e.key, e.value.toString())),
      );

    final savedHelperText = Map<String, dynamic>.from(
      data['llmHelperTextById'] as Map? ?? <String, dynamic>{},
    );
    _llmHelperTextById
      ..clear()
      ..addEntries(
        savedHelperText.entries.map((e) => MapEntry(e.key, e.value.toString())),
      );

    final savedFreeText = Map<String, dynamic>.from(
      data['chatFreeTextAnswers'] as Map? ?? <String, dynamic>{},
    );
    _freeTextByQuestion
      ..clear()
      ..addEntries(
        savedFreeText.entries.map((e) => MapEntry(e.key, e.value.toString())),
      );

    _llmChatTelemetry = Map<String, dynamic>.from(
      data['llmChatTelemetry'] as Map? ?? <String, dynamic>{},
    );
    _structuredSymptomPrior = Map<String, dynamic>.from(
      data['structuredSymptomPrior'] as Map? ?? <String, dynamic>{},
    );

    _ensureStepInRange();

    WidgetsBinding.instance.addPostFrameCallback((_) => _pushData());
  }

  void _restoreSelections({
    required dynamic source,
    required Map<String, bool> target,
  }) {
    if (source is! List) return;
    final selected = source.map((e) => e.toString()).toSet();
    target.updateAll((key, _) => selected.contains(key));
  }

  List<String> _selected(Map<String, bool> source) {
    return source.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  bool get _hasAnyRedFlag => _redFlags.values.any((v) => v);

  bool get _needsProgressionQuestion {
    final areas = _selected(_distribution);
    final appearance = _selected(_lesionAppearance);
    return _hasAnyRedFlag ||
        areas.contains('Widespread') ||
        appearance.contains('Moist or oozing skin') ||
        appearance.contains('Scabs / crusts');
  }

  bool get _needsParasiteQuestion {
    final areas = _selected(_distribution);
    final appearance = _selected(_lesionAppearance);
    return _itchSeverity == 'severe' ||
        _itchSeverity == 'moderate' ||
        appearance.contains('Tiny moving dots') ||
        areas.contains('Back') ||
        areas.contains('Tail');
  }

  bool get _needsTriggerQuestion {
    final areas = _selected(_distribution);
    final appearance = _selected(_lesionAppearance);
    return areas.contains('Not sure') || appearance.contains('Not sure');
  }

  static const List<String> _allQuestionIds = <String>[
    'red_flags',
    'distribution',
    'appearance',
    'progression',
    'trigger',
    'itch',
    'parasite',
  ];

  Future<void> _initializeChatbot() async {
    if (_questionOrder.isEmpty) {
      setState(() {
        _questionOrder = <String>['red_flags'];
      });
      _pushData();
      return;
    }

    if (_chatStep >= _questionOrder.length && !_llmSaysDone) {
      setState(() {
        _chatStep = (_questionOrder.length - 1).clamp(0, 999).toInt();
      });
    }

    if (_llmSaysDone || !mounted) return;

    if (_chatStep == _questionOrder.length - 1 &&
        _isQuestionAnswered(_questionOrder[_chatStep])) {
      await _requestNextQuestion();
    }
  }

  bool _hasCustomAnswer(String id) {
    final value = _freeTextByQuestion[id]?.trim() ?? '';
    return value.isNotEmpty;
  }

  void _markQuestionAnswered(String id) {
    switch (id) {
      case 'red_flags':
        _answeredRedFlags = true;
        break;
      case 'distribution':
        _answeredDistribution = true;
        break;
      case 'appearance':
        _answeredAppearance = true;
        break;
      case 'itch':
        _answeredItch = true;
        break;
      case 'progression':
        _answeredProgression = true;
        break;
      case 'parasite':
        _answeredParasitePrevention = true;
        break;
      case 'trigger':
        _answeredTriggerContext = true;
        break;
    }
  }

  bool _isQuestionAnswered(String id) {
    if (_hasCustomAnswer(id)) return true;

    switch (id) {
      case 'red_flags':
        return _answeredRedFlags;
      case 'distribution':
        return _answeredDistribution;
      case 'appearance':
        return _answeredAppearance;
      case 'itch':
        return _answeredItch;
      case 'progression':
        return _answeredProgression;
      case 'parasite':
        return _answeredParasitePrevention;
      case 'trigger':
        return _answeredTriggerContext;
      default:
        return false;
    }
  }

  bool _isQuestionEligible(String id) {
    if (_isQuestionAnswered(id)) return false;
    if (_questionOrder.contains(id)) return false;

    if (id == 'progression' && !_needsProgressionQuestion) return false;
    if (id == 'parasite' && !_needsParasiteQuestion) return false;
    if (id == 'trigger' && !_needsTriggerQuestion) return false;

    return true;
  }

  List<String> _eligibleQuestionIds() {
    return _allQuestionIds.where(_isQuestionEligible).toList();
  }

  int get _coreAnsweredCount {
    var core = 0;
    if (_isQuestionAnswered('red_flags')) core++;
    if (_isQuestionAnswered('distribution')) core++;
    if (_isQuestionAnswered('appearance')) core++;
    if (_isQuestionAnswered('itch')) core++;
    return core;
  }

  String _pickFallbackNextQuestion(List<String> eligible) {
    const preferredOrder = <String>[
      'distribution',
      'appearance',
      'progression',
      'trigger',
      'itch',
      'parasite',
    ];

    for (final id in preferredOrder) {
      if (eligible.contains(id)) return id;
    }
    return eligible.first;
  }

  Map<String, dynamic> _buildQuestionCatalog() {
    return {
      'red_flags': {
        'default_title': 'Safety first: any warning signs?',
        'default_helper': 'Choose any signs you noticed.',
        'input_type': 'multi_select',
        'allow_free_text': true,
        'options': _redFlags.keys.toList(),
      },
      'distribution': {
        'default_title': 'Where do you see the skin problem?',
        'default_helper': 'Select all areas that apply.',
        'input_type': 'multi_select',
        'allow_free_text': true,
        'options': _distribution.keys.toList(),
      },
      'appearance': {
        'default_title': 'What does it look like?',
        'default_helper': 'Pick the closest skin appearance.',
        'input_type': 'multi_select',
        'allow_free_text': true,
        'options': _lesionAppearance.keys.toList(),
      },
      'progression': {
        'default_title': 'How is it changing over time?',
        'default_helper': 'Pick the closest trend.',
        'input_type': 'single_select',
        'allow_free_text': true,
        'options': [
          'Not sure',
          'About the same',
          'Getting worse quickly',
          'Improving'
        ],
      },
      'trigger': {
        'default_title': 'Any likely trigger before symptoms started?',
        'default_helper': 'This helps narrow likely causes.',
        'input_type': 'single_select',
        'allow_free_text': true,
        'options': [
          'Not sure',
          'Recent grooming / shampoo change',
          'Possible allergen exposure',
          'Recent medication started',
          'No clear trigger',
        ],
      },
      'itch': {
        'default_title': 'How itchy does your pet seem?',
        'default_helper': 'Choose the closest level.',
        'input_type': 'single_select',
        'allow_free_text': true,
        'options': ['Not sure', 'Mild', 'Moderate', 'Severe'],
      },
      'parasite': {
        'default_title': 'Is your pet currently on parasite prevention?',
        'default_helper': 'This can help with scan guidance.',
        'input_type': 'single_select',
        'allow_free_text': true,
        'options': ['Not sure', 'Yes, regularly', 'No / overdue'],
      },
    };
  }

  Map<String, dynamic> _buildCurrentIntakeSnapshot({
    List<String>? visionCandidates,
  }) {
    final candidates = visionCandidates ?? _computeVisionCandidates();
    return {
      'onsetDuration': _durationController.text.trim(),
      'progression': _progression,
      'itchSeverity': _itchSeverity,
      'appetiteChange': 'not_sure',
      'distributionAreas': _selected(_distribution),
      'lesionAppearance': _selected(_lesionAppearance),
      'recentGrooming': _triggerContext == 'recent_grooming',
      'parasitePrevention': _parasitePreventionStatus == 'yes',
      'parasitePreventionStatus': _parasitePreventionStatus,
      'allergenExposure': _triggerContext == 'possible_allergen',
      'recentMedication':
          _triggerContext == 'recent_medication' ? 'reported_recently' : '',
      'redFlags': _selected(_redFlags),
      'hasRedFlags': _hasAnyRedFlag,
      'triggerContext': _triggerContext,
      'funnelStep': _chatStep,
      'preTriageAnsweredCount': _answeredCount,
      'preTriageRequiredCount': _requiredQuestionCount,
      'preTriageReadyForScan': _isReadyForScan,
      'dynamicQuestionFlow': _questionOrder,
      'llmQuestionTextById': _llmQuestionTextById,
      'llmHelperTextById': _llmHelperTextById,
      'chatFreeTextAnswers': _freeTextByQuestion,
      'llmQuestioningDone': _llmSaysDone,
      'llmChatTelemetry': _llmChatTelemetry,
      'structuredSymptomPrior': _structuredSymptomPrior,
      'visionCandidateLabels': candidates,
      'funnelSummary': _buildFunnelSummary(candidates),
    };
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

  Future<void> _refreshStructuredSymptomPrior() async {
    if (_isGeneratingStructuredPrior) return;
    if (_answeredCount < 2) return;

    setState(() => _isGeneratingStructuredPrior = true);

    try {
      final intakeSnapshot = _buildCurrentIntakeSnapshot();
      final petProfile = _buildPetProfileSnapshot();
      final candidates = (intakeSnapshot['visionCandidateLabels'] as List)
          .map((e) => e.toString())
          .toList();

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

      final priorsRaw = content['triage_priors'];
      final topConditions = <Map<String, dynamic>>[];
      if (priorsRaw is List) {
        for (final item in priorsRaw) {
          if (item is! Map) continue;
          final condition = item['condition']?.toString() ?? '';
          if (condition.trim().isEmpty) continue;
          final score =
              (item['score'] is num) ? (item['score'] as num).toDouble() : 0.0;
          topConditions.add({
            'condition': condition,
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
        'answeredCountAtGeneration': _answeredCount,
      });
      _pushData();
    } catch (_) {
      // Keep the chat responsive when prior refresh fails.
    } finally {
      if (mounted) {
        setState(() => _isGeneratingStructuredPrior = false);
      }
    }
  }

  void _ensureStepInRange() {
    final maxStep = _questionOrder.length.clamp(0, 999);
    if (_chatStep > maxStep) {
      _chatStep = maxStep;
    }
    if (_chatStep < 0) {
      _chatStep = 0;
    }
  }

  int get _answeredCount {
    return _questionOrder.where(_isQuestionAnswered).length;
  }

  int get _requiredQuestionCount {
    if (_llmSaysDone) return _answeredCount;
    return _questionOrder.length;
  }

  bool get _isReadyForScan => _llmSaysDone && _coreAnsweredCount >= 4;

  List<String> _computeVisionCandidates() {
    const knownLabels = <String>{
      'dermatitis',
      'fleas',
      'fungal_infection',
      'hotspot',
      'mange',
      'pyoderma',
      'ringworm',
      'ticks',
      'unknown_abnormality',
    };

    final scores = <String, int>{
      for (final label in knownLabels) label: 1,
    };

    final distribution = _selected(_distribution);
    final appearance = _selected(_lesionAppearance);

    void boost(List<String> labels, [int by = 2]) {
      for (final label in labels) {
        if (scores.containsKey(label)) {
          scores[label] = (scores[label] ?? 0) + by;
        }
      }
    }

    if (_itchSeverity == 'severe') {
      boost(['fleas', 'ticks', 'mange', 'dermatitis', 'hotspot']);
    } else if (_itchSeverity == 'moderate') {
      boost(['fleas', 'mange', 'dermatitis', 'fungal_infection'], 1);
    }

    if (distribution.contains('Ears')) {
      boost(['ticks', 'mange', 'ringworm'], 1);
    }
    if (distribution.contains('Paws')) {
      boost(['dermatitis', 'fungal_infection', 'pyoderma'], 1);
    }
    if (distribution.contains('Back') || distribution.contains('Tail')) {
      boost(['fleas', 'ticks', 'hotspot'], 1);
    }
    if (distribution.contains('Widespread')) {
      boost(['mange', 'dermatitis', 'fungal_infection'], 1);
    }

    if (appearance.contains('Circular lesions')) {
      boost(['ringworm', 'fungal_infection', 'mange']);
    }
    if (appearance.contains('Moist or oozing skin')) {
      boost(['hotspot', 'pyoderma', 'dermatitis']);
    }
    if (appearance.contains('Scabs / crusts')) {
      boost(['mange', 'pyoderma', 'dermatitis']);
    }
    if (appearance.contains('Flaky / dandruff-like')) {
      boost(['dermatitis', 'fungal_infection', 'mange']);
    }
    if (appearance.contains('Tiny moving dots')) {
      boost(['fleas', 'ticks', 'mange']);
    }
    if (appearance.contains('Redness / rash')) {
      boost(['dermatitis', 'hotspot', 'pyoderma'], 1);
    }
    if (appearance.contains('Hair loss patches')) {
      boost(['ringworm', 'mange', 'fungal_infection']);
    }

    if (_progression == 'getting_worse') {
      boost(['hotspot', 'pyoderma', 'mange'], 1);
    }

    if (_parasitePreventionStatus == 'no') {
      boost(['fleas', 'ticks'], 2);
    }

    if (_triggerContext == 'recent_grooming') {
      boost(['dermatitis', 'hotspot'], 1);
    } else if (_triggerContext == 'possible_allergen') {
      boost(['dermatitis'], 2);
    } else if (_triggerContext == 'recent_medication') {
      boost(['dermatitis', 'unknown_abnormality'], 1);
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
      return knownLabels.toList()..sort();
    }

    return shortlisted;
  }

  String _buildFunnelSummary(List<String> candidates) {
    if (!_isReadyForScan) {
      return 'Please answer the chat questions so camera scan results can be more accurate.';
    }

    if (candidates.isEmpty) {
      return 'You are all set to scan. We will check all supported skin conditions.';
    }

    return 'You are all set to scan. We will focus on the most likely visible skin conditions.';
  }

  void _setChipSelection({
    required Map<String, bool> source,
    required String key,
    required bool selected,
    required VoidCallback markAnswered,
  }) {
    source[key] = selected;

    if (key == 'Not sure' && selected) {
      source.updateAll((otherKey, _) => otherKey == 'Not sure');
    } else if (key != 'Not sure' && selected) {
      source['Not sure'] = false;
    }

    markAnswered();
  }

  void _syncFreeTextController(String questionId) {
    if (_freeTextQuestionId == questionId) return;

    _freeTextQuestionId = questionId;
    final existing = _freeTextByQuestion[questionId] ?? '';
    _freeTextController.text = existing;
    _freeTextController.selection = TextSelection.fromPosition(
      TextPosition(offset: _freeTextController.text.length),
    );
  }

  Widget _freeTextComposer(String questionId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: kSpacingSmall),
        Text(
          'Can\'t find the right option? Type your answer below.',
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _freeTextController,
          maxLines: 3,
          minLines: 1,
          decoration: const InputDecoration(
            hintText: 'Type your answer in your own words',
          ),
          onChanged: (value) {
            final normalized = value.trim();
            if (normalized.isEmpty) {
              _freeTextByQuestion.remove(questionId);
            } else {
              _freeTextByQuestion[questionId] = normalized;
            }
            _pushData();
          },
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final normalized = _freeTextController.text.trim();
              if (normalized.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please type your answer first.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setState(() {
                _freeTextByQuestion[questionId] = normalized;
                _markQuestionAnswered(questionId);
              });
              _pushData();
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Use typed answer'),
          ),
        ),
      ],
    );
  }

  Widget _withFreeTextAnswer(String questionId, Widget input) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        input,
        _freeTextComposer(questionId),
      ],
    );
  }

  bool _canContinueFromStep(int step) {
    final flow = _questionOrder;
    if (step < 0 || step >= flow.length) return true;
    return _isQuestionAnswered(flow[step]);
  }

  Future<void> _advanceStep() async {
    if (!_canContinueFromStep(_chatStep)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer the current question to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_chatStep < _questionOrder.length - 1) {
      await _refreshStructuredSymptomPrior();
      setState(() {
        _chatStep = (_chatStep + 1).clamp(0, _questionOrder.length).toInt();
      });
      _pushData();
      return;
    }

    await _refreshStructuredSymptomPrior();
    await _requestNextQuestion();
  }

  Future<void> _requestNextQuestion() async {
    if (_isGeneratingNextQuestion || _llmSaysDone) return;

    final eligible = _eligibleQuestionIds();
    if (eligible.isEmpty) {
      setState(() {
        _llmSaysDone = true;
        _chatStep = _questionOrder.length;
      });
      _pushData();
      return;
    }

    setState(() => _isGeneratingNextQuestion = true);

    try {
      final intake = _buildCurrentIntakeSnapshot();
      final petType =
          widget.assessmentData['selectedPetType']?.toString() ?? 'Dog';

      final result = await _groqService.generateGuidedChatQuestion(
        petType: petType,
        intakeData: intake,
        askedQuestionIds: _questionOrder,
        eligibleQuestionIds: eligible,
        questionCatalog: _buildQuestionCatalog(),
      );

      if (!mounted) return;

      final content = result.content;
      final shouldFinish = content['should_finish'] == true;

      setState(() {
        final previousRequests =
            (_llmChatTelemetry['requestCount'] as num?)?.toInt() ?? 0;
        _llmChatTelemetry = {
          ..._llmChatTelemetry,
          'requestCount': previousRequests + 1,
          'lastModelUsed': result.modelUsed,
          'lastFallbackLevel': result.fallbackLevel.name,
          'lastErrorType': result.errorType.name,
          'lastLatencyMs': result.latencyMs,
          'lastCacheHit': result.cacheHit,
          'lastTraceId': result.traceId,
          'isConfigured': _groqService.isConfigured,
        };
      });

      if (shouldFinish && _coreAnsweredCount >= 4) {
        setState(() {
          _llmSaysDone = true;
          _chatStep = _questionOrder.length;
        });
        _pushData();
        return;
      }

      final suggestedId = content['next_question_id']?.toString() ?? '';
      final nextId = eligible.contains(suggestedId)
          ? suggestedId
          : _pickFallbackNextQuestion(eligible);

      final llmQuestionText = content['question_text']?.toString().trim() ?? '';
      final llmHelperText = content['helper_text']?.toString().trim() ?? '';

      setState(() {
        _questionOrder.add(nextId);
        if (llmQuestionText.isNotEmpty) {
          _llmQuestionTextById[nextId] = llmQuestionText;
        }
        if (llmHelperText.isNotEmpty) {
          _llmHelperTextById[nextId] = llmHelperText;
        }
        _chatStep = (_questionOrder.length - 1).clamp(0, 999).toInt();
      });
      _pushData();
    } catch (_) {
      if (!mounted) return;
      final fallbackId = _pickFallbackNextQuestion(eligible);
      setState(() {
        final previousRequests =
            (_llmChatTelemetry['requestCount'] as num?)?.toInt() ?? 0;
        _llmChatTelemetry = {
          ..._llmChatTelemetry,
          'requestCount': previousRequests + 1,
          'lastFallbackLevel': 'exception_fallback',
          'lastErrorType': 'exception',
          'isConfigured': _groqService.isConfigured,
        };
        _questionOrder.add(fallbackId);
        _chatStep = (_questionOrder.length - 1).clamp(0, 999).toInt();
      });
      _pushData();
    } finally {
      if (mounted) {
        setState(() => _isGeneratingNextQuestion = false);
      }
    }
  }

  void _goToPreviousQuestion() {
    setState(() {
      _chatStep = (_chatStep - 1).clamp(0, _questionOrder.length).toInt();
      _llmSaysDone = false;
    });
    _pushData();
  }

  void _pushData() {
    _ensureStepInRange();
    widget.onDataUpdate('clinicalIntake', _buildCurrentIntakeSnapshot());
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSpacingSmall),
      child: Text(
        title,
        style: kMobileTextStyleTitle.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _choiceChips({
    required Map<String, bool> values,
    required void Function(String key, bool next) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.entries.map((entry) {
        return FilterChip(
          selected: entry.value,
          label: Text(entry.key),
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AppColors.primary,
          onSelected: (selected) {
            setState(() {
              onChanged(entry.key, selected);
            });
            _pushData();
          },
        );
      }).toList(),
    );
  }

  Widget _candidateChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.replaceAll('_', ' '),
        style: kMobileTextStyleSubtitle.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _answerPreview(String id) {
    final customAnswer = _freeTextByQuestion[id]?.trim() ?? '';
    if (customAnswer.isNotEmpty) {
      return customAnswer;
    }

    switch (id) {
      case 'red_flags':
        final selected = _selected(_redFlags);
        return selected.isEmpty ? 'No answer yet' : selected.join(', ');
      case 'distribution':
        final selected = _selected(_distribution);
        return selected.isEmpty ? 'No answer yet' : selected.join(', ');
      case 'appearance':
        final selected = _selected(_lesionAppearance);
        return selected.isEmpty ? 'No answer yet' : selected.join(', ');
      case 'itch':
        return _itchSeverity.replaceAll('_', ' ');
      case 'progression':
        return _progression.replaceAll('_', ' ');
      case 'parasite':
        return _parasitePreventionStatus.replaceAll('_', ' ');
      case 'trigger':
        return _triggerContext.replaceAll('_', ' ');
      default:
        return 'No answer yet';
    }
  }

  Widget _botBubble(String text, {bool active = false}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: kSpacingSmall),
        padding: const EdgeInsets.all(kSpacingSmall),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.border.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Text(
          text,
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textPrimary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: kSpacingMedium),
        padding: const EdgeInsets.all(kSpacingSmall),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(kBorderRadius),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          text,
          style: kMobileTextStyleSubtitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _questionInput(String id) {
    switch (id) {
      case 'red_flags':
        return _withFreeTextAnswer(
          id,
          _choiceChips(
            values: _redFlags,
            onChanged: (key, next) {
              _freeTextByQuestion.remove(id);
              _setChipSelection(
                source: _redFlags,
                key: key,
                selected: next,
                markAnswered: () => _answeredRedFlags = true,
              );
            },
          ),
        );
      case 'distribution':
        return _withFreeTextAnswer(
          id,
          _choiceChips(
            values: _distribution,
            onChanged: (key, next) {
              _freeTextByQuestion.remove(id);
              _setChipSelection(
                source: _distribution,
                key: key,
                selected: next,
                markAnswered: () => _answeredDistribution = true,
              );
            },
          ),
        );
      case 'appearance':
        return _withFreeTextAnswer(
          id,
          _choiceChips(
            values: _lesionAppearance,
            onChanged: (key, next) {
              _freeTextByQuestion.remove(id);
              _setChipSelection(
                source: _lesionAppearance,
                key: key,
                selected: next,
                markAnswered: () => _answeredAppearance = true,
              );
            },
          ),
        );
      case 'itch':
        return _withFreeTextAnswer(
          id,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _itchSeverity,
                decoration: const InputDecoration(labelText: 'Itch level'),
                items: const [
                  DropdownMenuItem(value: 'not_sure', child: Text('Not sure')),
                  DropdownMenuItem(value: 'mild', child: Text('Mild')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'severe', child: Text('Severe')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _freeTextByQuestion.remove(id);
                    _itchSeverity = value;
                    _answeredItch = true;
                  });
                  _pushData();
                },
              ),
              const SizedBox(height: kSpacingSmall),
              _sectionTitle('Optional: when did this start?'),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Onset / duration',
                  hintText: 'Example: today, 3 days, 2 weeks',
                ),
                onChanged: (_) => _pushData(),
              ),
            ],
          ),
        );
      case 'progression':
        return _withFreeTextAnswer(
          id,
          DropdownButtonFormField<String>(
            initialValue: _progression,
            decoration: const InputDecoration(
              labelText: 'How is it changing over time?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'not_sure',
                child: Text('Not sure'),
              ),
              DropdownMenuItem(
                value: 'stable',
                child: Text('About the same'),
              ),
              DropdownMenuItem(
                value: 'getting_worse',
                child: Text('Getting worse quickly'),
              ),
              DropdownMenuItem(
                value: 'improving',
                child: Text('Improving'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _freeTextByQuestion.remove(id);
                _progression = value;
                _answeredProgression = true;
              });
              _pushData();
            },
          ),
        );
      case 'parasite':
        return _withFreeTextAnswer(
          id,
          DropdownButtonFormField<String>(
            initialValue: _parasitePreventionStatus,
            decoration: const InputDecoration(
              labelText: 'Is your pet currently on parasite prevention?',
            ),
            items: const [
              DropdownMenuItem(value: 'not_sure', child: Text('Not sure')),
              DropdownMenuItem(value: 'yes', child: Text('Yes, regularly')),
              DropdownMenuItem(value: 'no', child: Text('No / overdue')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _freeTextByQuestion.remove(id);
                _parasitePreventionStatus = value;
                _answeredParasitePrevention = true;
              });
              _pushData();
            },
          ),
        );
      case 'trigger':
        return _withFreeTextAnswer(
          id,
          DropdownButtonFormField<String>(
            initialValue: _triggerContext,
            decoration: const InputDecoration(
              labelText: 'Any likely trigger before symptoms started?',
            ),
            items: const [
              DropdownMenuItem(value: 'not_sure', child: Text('Not sure')),
              DropdownMenuItem(
                value: 'recent_grooming',
                child: Text('Recent grooming / shampoo change'),
              ),
              DropdownMenuItem(
                value: 'possible_allergen',
                child: Text('Possible allergen exposure'),
              ),
              DropdownMenuItem(
                value: 'recent_medication',
                child: Text('Recent medication started'),
              ),
              DropdownMenuItem(value: 'none', child: Text('No clear trigger')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _freeTextByQuestion.remove(id);
                _triggerContext = value;
                _answeredTriggerContext = true;
              });
              _pushData();
            },
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _questionTitle(String id, int number) {
    final llmTitle = _llmQuestionTextById[id];
    if (llmTitle != null && llmTitle.trim().isNotEmpty) {
      return '$number) ${llmTitle.trim()}';
    }

    switch (id) {
      case 'red_flags':
        return '$number) Safety first: any urgent warning signs?';
      case 'distribution':
        return '$number) Where is it located?';
      case 'appearance':
        return '$number) What does it look like?';
      case 'itch':
        return '$number) How intense is the itching?';
      case 'progression':
        return '$number) Is it getting worse quickly?';
      case 'parasite':
        return '$number) Parasite prevention check';
      case 'trigger':
        return '$number) Clarify likely trigger';
      default:
        return '$number) Follow-up question';
    }
  }

  String _questionSubtitle(String id) {
    final llmHelper = _llmHelperTextById[id];
    if (llmHelper != null && llmHelper.trim().isNotEmpty) {
      return llmHelper.trim();
    }

    switch (id) {
      case 'red_flags':
        return 'This decides whether we prioritize urgent vet advice.';
      case 'distribution':
        return 'Area/location helps narrow likely classes.';
      case 'appearance':
        return 'Visible traits help the camera focus on likely matches.';
      case 'itch':
        return 'Severity helps refine plausible detections.';
      case 'progression':
        return 'Shown because urgent/widespread or higher-risk signs were selected.';
      case 'parasite':
        return 'Shown because your answers suggest possible parasite-related causes.';
      case 'trigger':
        return 'Shown because some earlier answers were not specific enough.';
      default:
        return 'Answer to continue narrowing scan candidates.';
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureStepInRange();
    final questionFlow = _questionOrder;
    final isChatComplete = _isReadyForScan;
    final llmConfigured = _groqService.isConfigured;
    final String? activeQuestionId =
        (!isChatComplete && _chatStep < questionFlow.length)
            ? questionFlow[_chatStep]
            : null;
    if (activeQuestionId != null) {
      _syncFreeTextController(activeQuestionId);
    }
    final previousCount = _chatStep.clamp(0, questionFlow.length);
    final answeredQuestionIds = questionFlow.take(previousCount);
    final candidates = _computeVisionCandidates();
    final completion = _requiredQuestionCount == 0
        ? 0.0
        : _answeredCount / _requiredQuestionCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingMedium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.16),
                  AppColors.info.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Skin Check Chat',
                      style: kMobileTextStyleTitle.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Answer a few short questions so we can guide the camera scan better.',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          LinearProgressIndicator(
            minHeight: 8,
            value: completion,
            borderRadius: BorderRadius.circular(100),
            backgroundColor: AppColors.border.withValues(alpha: 0.4),
            color: _isReadyForScan ? AppColors.success : AppColors.primary,
          ),
          const SizedBox(height: 6),
          Text(
            '$_answeredCount of $_requiredQuestionCount questions answered',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            llmConfigured
                ? 'AI question mode: active${_llmChatTelemetry['lastModelUsed'] != null ? ' (${_llmChatTelemetry['lastModelUsed']})' : ''}'
                : 'AI question mode: unavailable (using built-in fallback questions)',
            style: kMobileTextStyleSubtitle.copyWith(
              color: llmConfigured ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: kSpacingMedium),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...answeredQuestionIds.map((id) {
                  final index = questionFlow.indexOf(id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _botBubble(_questionTitle(id, index + 1)),
                      _userBubble(_answerPreview(id)),
                    ],
                  );
                }),
                if (_isGeneratingNextQuestion) ...[
                  _botBubble(
                    'Thanks. Let me think of the best next question for you...',
                    active: true,
                  ),
                  const LinearProgressIndicator(minHeight: 3),
                ] else if (!isChatComplete &&
                    _chatStep < questionFlow.length) ...[
                  _botBubble(
                    _questionTitle(questionFlow[_chatStep], _chatStep + 1),
                    active: true,
                  ),
                  Text(
                    _questionSubtitle(questionFlow[_chatStep]),
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: kSpacingSmall),
                  _questionInput(questionFlow[_chatStep]),
                  const SizedBox(height: kSpacingSmall),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _canContinueFromStep(_chatStep)
                          ? () async => _advanceStep()
                          : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Send answer'),
                    ),
                  ),
                ] else ...[
                  _botBubble(
                    'Thanks. I have enough details and can now narrow scan targets based on your answers.',
                    active: true,
                  ),
                ],
              ],
            ),
          ),
          if (_chatStep > 0 && !isChatComplete)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed:
                    _isGeneratingNextQuestion ? null : _goToPreviousQuestion,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Edit previous answer'),
              ),
            ),
          const SizedBox(height: kSpacingMedium),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: _isReadyForScan
                  ? AppColors.success.withValues(alpha: 0.08)
                  : AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(
                color: _isReadyForScan
                    ? AppColors.success.withValues(alpha: 0.35)
                    : AppColors.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isReadyForScan
                      ? 'Ready for scan'
                      : 'Need more answers before scan',
                  style: kMobileTextStyleTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _buildFunnelSummary(candidates),
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: kSpacingSmall),
                Text(
                  'Narrowed camera-detectable candidates',
                  style: kMobileTextStyleSubtitle.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidates.map(_candidateChip).toList(),
                ),
                const SizedBox(height: kSpacingSmall),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onPrevious,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: kSpacingSmall),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isReadyForScan ? widget.onNext : null,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Proceed to scan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_hasAnyRedFlag) ...[
            const SizedBox(height: kSpacingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingSmall),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(kBorderRadius),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Possible urgent signs selected. The app will prioritize vet-visit advice for safety.',
                style:
                    kMobileTextStyleSubtitle.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

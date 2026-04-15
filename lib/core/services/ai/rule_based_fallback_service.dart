class RuleBasedFallbackService {
  const RuleBasedFallbackService();

  Map<String, dynamic> triageFallback({
    required String petType,
    required List<String> symptoms,
    bool hasRedFlags = false,
    List<String>? allowedConditions,
  }) {
    final topConditions = _rankBySymptomHeuristics(
      symptoms,
      petType,
      allowedConditions: allowedConditions,
    );

    return {
      'top_conditions': topConditions,
      'confidence_band': hasRedFlags ? 'low' : 'low_to_moderate',
      'rationale': hasRedFlags
          ? 'Potential warning signs were reported. Automated triage is conservative in this case.'
          : 'This is a rule-based fallback generated from symptom mapping while AI service is unavailable.',
      'care_guidance': hasRedFlags
          ? [
              'Keep the pet calm and avoid self-medicating.',
              'Avoid applying new topical products until a veterinarian advises.',
            ]
          : [
              'Prevent scratching or licking of affected areas.',
              'Keep skin clean and dry using gentle routine care.',
              'Observe for spread or worsening over the next 24 to 48 hours.',
            ],
      'escalation_triggers': [
        'Rapid spread of lesions',
        'Pus, bleeding, or foul odor',
        'Lethargy or poor appetite',
      ],
      'confidence_note':
          'Preliminary support output only. This does not replace professional veterinary diagnosis.',
    };
  }

  Map<String, dynamic> recommendationFallback({
    required List<Map<String, dynamic>> fusedConditions,
    required bool hasRedFlags,
  }) {
    final primary = fusedConditions.isNotEmpty
        ? fusedConditions.first['condition']?.toString() ?? 'skin condition'
        : 'skin condition';

    if (hasRedFlags) {
      return {
        'summary':
            'Urgent signs may be present. Seek veterinary consultation as soon as possible.',
        'home_care': [
          'Do not apply new medications unless prescribed by a veterinarian.',
          'Keep the affected area clean and prevent licking/scratching.',
        ],
        'watchlist': [
          'Worsening redness or swelling',
          'Discharge, bleeding, or foul smell',
          'Decreased appetite or unusual behavior',
        ],
        'escalation_triggers': [
          'Immediate consult for severe discomfort or rapid deterioration',
        ],
        'confidence_note':
            'Emergency-safe fallback content was used due to AI service constraints.',
      };
    }

    return {
      'summary':
          'The current findings are most consistent with possible $primary. Continue close observation and seek veterinary advice for confirmation.',
      'home_care': [
        'Use gentle cleaning and keep affected skin dry.',
        'Prevent scratching using supervision or protective measures.',
        'Follow only veterinarian-approved topical care.',
      ],
      'watchlist': [
        'Increased redness or lesion size',
        'New lesions appearing in other areas',
        'Persistent itching or discomfort beyond 48 hours',
      ],
      'escalation_triggers': [
        'No improvement after 24 to 48 hours',
        'Pain, discharge, fever signs, or appetite loss',
      ],
      'confidence_note':
          'Rule-based fallback recommendation generated while AI service is unavailable.',
    };
  }

  List<Map<String, dynamic>> _rankBySymptomHeuristics(
    List<String> symptoms,
    String petType, {
    List<String>? allowedConditions,
  }) {
    final normalizedSymptoms = symptoms
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final candidateConditions = _buildCandidateConditionList(allowedConditions);
    final conditionScores = <String, int>{
      for (final condition in candidateConditions) condition: 0,
    };

    void boost(List<String> conditions, [int by = 1]) {
      for (final condition in conditions) {
        final normalized = _normalizeConditionLabel(condition);
        if (!conditionScores.containsKey(normalized)) continue;
        conditionScores[normalized] = (conditionScores[normalized] ?? 0) + by;
      }
    }

    for (final symptom in normalizedSymptoms) {
      if (symptom.contains('scratch') || symptom.contains('lick')) {
        boost(['dermatitis', 'fleas', 'mange'], 2);
      }
      if (symptom.contains('bit') || symptom.contains('chew')) {
        boost(['fleas', 'ticks', 'mange'], 2);
      }
      if (symptom.contains('head shaking')) {
        boost(['ticks', 'pyoderma'], 1);
      }
      if (symptom.contains('rolling') || symptom.contains('rubbing')) {
        boost(['dermatitis', 'fungal_infection'], 1);
      }
      if (symptom.contains('scoot')) {
        boost(['fleas', 'ticks'], 1);
      }
      if (symptom.contains('hair loss')) {
        boost(['mange', 'ringworm', 'fungal_infection'], 2);
      }
      if (symptom.contains('red') || symptom.contains('rash')) {
        boost(['dermatitis', 'pyoderma', 'hotspot'], 2);
      }
      if (symptom.contains('scab') || symptom.contains('crust')) {
        boost(['mange', 'pyoderma'], 2);
      }
      if (symptom.contains('ooz') || symptom.contains('moist')) {
        boost(['hotspot', 'pyoderma'], 2);
      }
      if (symptom.contains('circular') || symptom.contains('ring')) {
        boost(['ringworm', 'fungal_infection'], 2);
      }
      if (symptom.contains('flaky') || symptom.contains('dandruff')) {
        boost(['fungal_infection', 'dermatitis'], 1);
      }
      if (symptom.contains('odor') || symptom.contains('discharge')) {
        boost(['pyoderma', 'hotspot'], 1);
      }
    }

    if (petType.toLowerCase() == 'cat') {
      boost(['ringworm', 'fungal_infection'], 1);
    }

    final maxScore = conditionScores.values.isEmpty
        ? 0
        : conditionScores.values.reduce((a, b) => a > b ? a : b);

    final sorted = conditionScores.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });

    final top = sorted.take(candidateConditions.length.clamp(1, 5)).toList();
    final base = petType.toLowerCase() == 'cat' ? 0.52 : 0.55;

    return top.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final normalizedComponent =
          maxScore > 0 ? (item.value / maxScore) * 0.32 : 0.0;
      final score =
          (base + normalizedComponent - (index * 0.09)).clamp(0.18, 0.95);
      return {
        'condition': item.key,
        'score': double.parse(score.toStringAsFixed(2)),
        'source': 'rule_fallback',
      };
    }).toList();
  }

  List<String> _buildCandidateConditionList(List<String>? allowedConditions) {
    final normalizedAllowed = (allowedConditions ?? <String>[])
        .map(_normalizeConditionLabel)
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();

    if (normalizedAllowed.isNotEmpty) {
      normalizedAllowed.sort();
      return normalizedAllowed;
    }

    return <String>[
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
}

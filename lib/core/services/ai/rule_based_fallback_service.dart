class RuleBasedFallbackService {
  const RuleBasedFallbackService();

  Map<String, dynamic> triageFallback({
    required String petType,
    required List<String> symptoms,
    bool hasRedFlags = false,
  }) {
    final topConditions = _rankBySymptomHeuristics(symptoms, petType);

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
    String petType,
  ) {
    final normalized = symptoms.map((s) => s.toLowerCase()).toList();

    final conditionScores = <String, int>{
      'allergic_dermatitis': 0,
      'fungal_infection': 0,
      'bacterial_infection': 0,
      'mange_or_mites': 0,
    };

    for (final symptom in normalized) {
      if (symptom.contains('scratching') || symptom.contains('licking')) {
        conditionScores['allergic_dermatitis'] =
            (conditionScores['allergic_dermatitis'] ?? 0) + 2;
      }
      if (symptom.contains('biting') || symptom.contains('chewing')) {
        conditionScores['mange_or_mites'] =
            (conditionScores['mange_or_mites'] ?? 0) + 2;
      }
      if (symptom.contains('head shaking')) {
        conditionScores['bacterial_infection'] =
            (conditionScores['bacterial_infection'] ?? 0) + 1;
      }
      if (symptom.contains('rolling') || symptom.contains('rubbing')) {
        conditionScores['fungal_infection'] =
            (conditionScores['fungal_infection'] ?? 0) + 1;
      }
    }

    final sorted = conditionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(3).toList();
    final base = petType.toLowerCase() == 'cat' ? 0.56 : 0.58;

    return top.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final score = (base - (index * 0.08)).clamp(0.25, 0.95);
      return {
        'condition': item.key,
        'score': double.parse(score.toStringAsFixed(2)),
        'source': 'rule_fallback',
      };
    }).toList();
  }
}

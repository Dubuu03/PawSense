import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawsense/core/services/ai/groq_orchestration_service.dart';

void main() {
  group('GroqOrchestrationService deterministic pathways', () {
    final service = GroqOrchestrationService.instance;

    setUpAll(() {
      dotenv.testLoad(fileInput: '''
GROQ_ENABLED=false
GROQ_API_KEY=
''');
    });

    test('guided chat fallback returns expected schema', () async {
      final result = await service.generateGuidedChatQuestion(
        petType: 'Dog',
        intakeData: {
          'itchSeverity': 'moderate',
          'distributionAreas': <String>['Back'],
        },
        askedQuestionIds: <String>['red_flags'],
        eligibleQuestionIds: <String>['appearance', 'itch'],
        questionCatalog: {
          'appearance': {
            'input_type': 'multi_select',
            'options': <String>['Redness / rash', 'Scabs / crusts'],
          },
          'itch': {
            'input_type': 'single_select',
            'options': <String>['Mild', 'Moderate', 'Severe'],
          },
        },
      );

      expect(result.success, isFalse);
      expect(result.fallbackLevel, GroqFallbackLevel.deterministicFallback);
      expect(result.content['next_question_id'], equals('appearance'));
      expect(result.content['should_finish'], isFalse);
      expect(result.content['reason'], equals('deterministic_fallback'));
    });

    test('structured symptom prior fallback keeps camera conditions only',
        () async {
      const cameraLabels = <String>['dermatitis', 'mange', 'ringworm'];
      final result = await service.generateStructuredSymptomPrior(
        petProfile: {
          'pet_type': 'Dog',
          'age': '4',
          'breed': 'Mixed',
        },
        intakeData: {
          'itchSeverity': 'severe',
          'distributionAreas': <String>['Tail', 'Back'],
          'lesionAppearance': <String>['Scabs / crusts'],
          'redFlags': <String>['Foul odor'],
        },
        cameraDetectableConditions: cameraLabels,
      );

      expect(result.success, isFalse);
      expect(result.fallbackLevel, GroqFallbackLevel.deterministicFallback);
      final priors = result.content['triage_priors'] as List<dynamic>;
      expect(priors, isNotEmpty);

      for (final prior in priors) {
        final condition = (prior as Map)['condition']?.toString();
        expect(cameraLabels, contains(condition));
      }
    });

    test('triage prior fallback is constrained to allowed labels', () async {
      const allowed = <String>['ringworm', 'dermatitis'];
      final result = await service.generateTriagePrior(
        petType: 'Cat',
        symptoms: <String>['Scratching', 'Hair loss patches'],
        intakeData: {
          'itchSeverity': 'moderate',
          'distributionAreas': <String>['Face'],
          'lesionAppearance': <String>['Circular lesions'],
        },
        cameraDetectableConditions: allowed,
      );

      expect(result.fallbackLevel, GroqFallbackLevel.deterministicFallback);
      final topConditions = result.content['top_conditions'] as List<dynamic>;
      expect(topConditions, isNotEmpty);

      for (final condition in topConditions) {
        final label = (condition as Map)['condition']?.toString();
        expect(allowed, contains(label));
      }
    });
  });
}

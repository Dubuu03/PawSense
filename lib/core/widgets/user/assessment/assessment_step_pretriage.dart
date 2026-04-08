import 'package:flutter/material.dart';
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
  State<AssessmentStepPreTriage> createState() => _AssessmentStepPreTriageState();
}

class _AssessmentStepPreTriageState extends State<AssessmentStepPreTriage> {
  final _durationController = TextEditingController();
  String _itchSeverity = 'not_sure';

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
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingData() {
    final data = Map<String, dynamic>.from(
      widget.assessmentData['clinicalIntake'] as Map? ?? <String, dynamic>{},
    );

    _durationController.text = data['onsetDuration']?.toString() ?? '';
    _itchSeverity = data['itchSeverity']?.toString() ?? _itchSeverity;

    _restoreSelections(
      source: data['distributionAreas'],
      target: _distribution,
    );
    _restoreSelections(
      source: data['redFlags'],
      target: _redFlags,
    );

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

  void _pushData() {
    widget.onDataUpdate('clinicalIntake', {
      'onsetDuration': _durationController.text.trim(),
      'progression': 'not_sure',
      'itchSeverity': _itchSeverity,
      'appetiteChange': 'not_sure',
      'distributionAreas': _selected(_distribution),
      'lesionAppearance': <String>[],
      'recentGrooming': false,
      'parasitePrevention': false,
      'allergenExposure': false,
      'recentMedication': '',
      'redFlags': _selected(_redFlags),
      'hasRedFlags': _hasAnyRedFlag,
    });
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
          selectedColor: AppColors.primary.withOpacity(0.15),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(kSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Health Questions',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'Only a few important questions before scan. Choose Not sure anytime.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kSpacingSmall),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(kBorderRadius),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(
              'Tip: You can leave text fields blank and continue. Pick the closest answer when possible.',
              style: kMobileTextStyleSubtitle.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: kSpacingLarge ),

          _sectionTitle('1) When did you first notice this? (optional)'),
          TextFormField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'How long has this been happening?',
              hintText: 'Example: today, 3 days, 2 weeks',
            ),
            onChanged: (_) => _pushData(),
          ),
          const SizedBox(height: kSpacingSmall),

          _sectionTitle('2) How itchy does your pet seem?'),
          DropdownButtonFormField<String>(
            value: _itchSeverity,
            decoration: const InputDecoration(labelText: 'Itch level'),
            items: const [
              DropdownMenuItem(value: 'not_sure', child: Text('Not sure')),
              DropdownMenuItem(value: 'mild', child: Text('Mild')),
              DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
              DropdownMenuItem(value: 'severe', child: Text('Severe')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _itchSeverity = value);
              _pushData();
            },
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('3) Where do you see the skin issue?'),
          _choiceChips(
            values: _distribution,
            onChanged: (key, next) => _distribution[key] = next,
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('4) Any urgent warning signs?'),
          _choiceChips(
            values: _redFlags,
            onChanged: (key, next) => _redFlags[key] = next,
          ),
          if (_hasAnyRedFlag) ...[
            const SizedBox(height: kSpacingSmall),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(kSpacingSmall),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Text(
                'Possible urgent signs selected. The app will prioritize vet-visit advice for safety.',
                style: kMobileTextStyleSubtitle.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

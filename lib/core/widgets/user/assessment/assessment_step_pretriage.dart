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
  final _recentMedicationController = TextEditingController();

  String _progression = 'stable';
  String _itchSeverity = 'moderate';
  String _appetiteChange = 'no_change';
  bool _hasRecentGrooming = false;
  bool _hasParasitePrevention = false;
  bool _hasKnownAllergenExposure = false;

  final Map<String, bool> _distribution = {
    'Face': false,
    'Ears': false,
    'Neck': false,
    'Back': false,
    'Belly': false,
    'Paws': false,
    'Tail': false,
    'Widespread': false,
  };

  final Map<String, bool> _lesionAppearance = {
    'Redness': false,
    'Hair loss': false,
    'Crusting': false,
    'Scales/flakes': false,
    'Moist/oozing': false,
    'Dark patches': false,
    'Swelling': false,
    'Wounds': false,
  };

  final Map<String, bool> _redFlags = {
    'Bleeding': false,
    'Pus or discharge': false,
    'Foul odor': false,
    'Low appetite': false,
    'Unusual weakness': false,
  };

  @override
  void initState() {
    super.initState();
    _hydrateFromExistingData();
    _durationController.addListener(_pushData);
    _recentMedicationController.addListener(_pushData);
  }

  @override
  void dispose() {
    _durationController.dispose();
    _recentMedicationController.dispose();
    super.dispose();
  }

  void _hydrateFromExistingData() {
    final data = Map<String, dynamic>.from(
      widget.assessmentData['clinicalIntake'] as Map? ?? <String, dynamic>{},
    );

    _durationController.text = data['onsetDuration']?.toString() ?? '';
    _recentMedicationController.text =
        data['recentMedication']?.toString() ?? '';

    _progression = data['progression']?.toString() ?? _progression;
    _itchSeverity = data['itchSeverity']?.toString() ?? _itchSeverity;
    _appetiteChange = data['appetiteChange']?.toString() ?? _appetiteChange;
    _hasRecentGrooming = data['recentGrooming'] == true;
    _hasParasitePrevention = data['parasitePrevention'] == true;
    _hasKnownAllergenExposure = data['allergenExposure'] == true;

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
      'progression': _progression,
      'itchSeverity': _itchSeverity,
      'appetiteChange': _appetiteChange,
      'distributionAreas': _selected(_distribution),
      'lesionAppearance': _selected(_lesionAppearance),
      'recentGrooming': _hasRecentGrooming,
      'parasitePrevention': _hasParasitePrevention,
      'allergenExposure': _hasKnownAllergenExposure,
      'recentMedication': _recentMedicationController.text.trim(),
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
            'Clinical Intake Form',
            style: kMobileTextStyleTitle.copyWith(
              color: AppColors.textPrimary,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: kSpacingSmall),
          Text(
            'This mirrors a veterinary consultation to improve AI triage accuracy before image scan.',
            style: kMobileTextStyleSubtitle.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: kSpacingLarge ),

          _sectionTitle('Onset and progression'),
          TextFormField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'How long has this been present?',
              hintText: 'Example: 3 days, 2 weeks',
            ),
            onChanged: (_) => _pushData(),
          ),
          const SizedBox(height: kSpacingSmall),
          DropdownButtonFormField<String>(
            value: _progression,
            decoration: const InputDecoration(labelText: 'Is it improving or worsening?'),
            items: const [
              DropdownMenuItem(value: 'improving', child: Text('Improving')),
              DropdownMenuItem(value: 'stable', child: Text('Stable')),
              DropdownMenuItem(value: 'worsening', child: Text('Worsening')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _progression = value);
              _pushData();
            },
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('Severity indicators'),
          DropdownButtonFormField<String>(
            value: _itchSeverity,
            decoration: const InputDecoration(labelText: 'Itch severity'),
            items: const [
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
          const SizedBox(height: kSpacingSmall),
          DropdownButtonFormField<String>(
            value: _appetiteChange,
            decoration: const InputDecoration(labelText: 'Appetite/activity changes'),
            items: const [
              DropdownMenuItem(value: 'no_change', child: Text('No change')),
              DropdownMenuItem(value: 'slightly_reduced', child: Text('Slightly reduced')),
              DropdownMenuItem(value: 'significantly_reduced', child: Text('Significantly reduced')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _appetiteChange = value);
              _pushData();
            },
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('Lesion distribution'),
          _choiceChips(
            values: _distribution,
            onChanged: (key, next) => _distribution[key] = next,
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('Skin appearance observed'),
          _choiceChips(
            values: _lesionAppearance,
            onChanged: (key, next) => _lesionAppearance[key] = next,
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('History and exposure'),
          SwitchListTile(
            title: const Text('Recent grooming/shampoo change'),
            value: _hasRecentGrooming,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _hasRecentGrooming = value);
              _pushData();
            },
          ),
          SwitchListTile(
            title: const Text('Current parasite prevention active'),
            value: _hasParasitePrevention,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _hasParasitePrevention = value);
              _pushData();
            },
          ),
          SwitchListTile(
            title: const Text('Known recent allergen/environment exposure'),
            value: _hasKnownAllergenExposure,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _hasKnownAllergenExposure = value);
              _pushData();
            },
          ),
          TextFormField(
            controller: _recentMedicationController,
            decoration: const InputDecoration(
              labelText: 'Recent medication or topical products (optional)',
            ),
            onChanged: (_) => _pushData(),
          ),
          const SizedBox(height: kSpacingLarge),

          _sectionTitle('Urgent warning signs'),
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
                'Potential red flags detected. The final recommendation will prioritize veterinary escalation guidance.',
                style: kMobileTextStyleSubtitle.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

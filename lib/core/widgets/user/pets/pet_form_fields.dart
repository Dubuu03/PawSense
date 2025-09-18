import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  const PetFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: kMobileTextStyleServiceTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: kMobileSizedBoxMedium),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            border: OutlineInputBorder(
              borderRadius: kMobileBorderRadiusSmallPreset,
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: kMobileBorderRadiusSmallPreset,
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: kMobileBorderRadiusSmallPreset,
              borderSide: BorderSide(color: AppColors.primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: kMobileBorderRadiusSmallPreset,
              borderSide: const BorderSide(color: Colors.red),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: kMobileBorderRadiusSmallPreset,
              borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
            ),
            filled: true,
            fillColor: enabled ? AppColors.white : AppColors.background,
            contentPadding: kMobilePaddingCard,
          ),
        ),
      ],
    );
  }
}

class PetFormDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final void Function(String?) onChanged;
  final bool enabled;

  const PetFormDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled ? AppColors.border : AppColors.border.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(12),
            color: enabled ? AppColors.white : AppColors.background,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down, 
                color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              style: TextStyle(
                fontSize: 16,
                color: enabled ? AppColors.textPrimary : AppColors.textPrimary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(item),
                  ),
                );
              }).toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
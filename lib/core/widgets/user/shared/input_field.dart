import 'package:flutter/material.dart';

class CompactTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;

  const CompactTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.validator,
    this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fixed label above the field
        Text(
          labelText,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4), // small spacing between label & field
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            filled: true,
            fillColor: Colors.grey.shade100, // light bg
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade200, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

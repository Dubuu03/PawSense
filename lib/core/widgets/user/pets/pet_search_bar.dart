import 'package:flutter/material.dart';
import 'package:pawsense/core/utils/app_colors.dart';
import 'package:pawsense/core/utils/constants_mobile.dart';

class PetSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onChanged;
  final String hintText;

  const PetSearchBar({
    super.key,
    this.initialQuery = '',
    required this.onChanged,
    this.hintText = 'Search pets by name, breed, or type...',
  });

  @override
  State<PetSearchBar> createState() => _PetSearchBarState();
}

class _PetSearchBarState extends State<PetSearchBar> {
  late TextEditingController _controller;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    setState(() {
      _currentQuery = query;
    });
    widget.onChanged(query);
  }

  void _clearSearch() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(

      child: TextField(
        controller: _controller,
        onChanged: _onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                  onPressed: _clearSearch,
                )
              : null,
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
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: kMobilePaddingSmall,
            vertical: kMobilePaddingSmall,
          ),
        ),
      ),
    );
  }
}
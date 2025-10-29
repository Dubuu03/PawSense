import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants_mobile.dart';

/// A reusable OTP input widget for entering 6-digit codes
/// Features:
/// - Auto-focus management
/// - Paste support
/// - Custom styling
/// - Error states
/// - Auto-submit when complete
class OTPInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final String? errorMessage;
  final bool isEnabled;
  final int length;
  final bool autoFocus;

  const OTPInputWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.errorMessage,
    this.isEnabled = true,
    this.length = 6,
    this.autoFocus = true,
  });

  @override
  State<OTPInputWidget> createState() => _OTPInputWidgetState();
}

class _OTPInputWidgetState extends State<OTPInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );

    // Auto-focus first field
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste
      _handlePaste(value, index);
      return;
    }

    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, remove focus
        _focusNodes[index].unfocus();
      }
    }

    _updateOTP();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // Move to previous field if current is empty and backspace is pressed
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Extract only digits from pasted text
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length >= widget.length) {
      // Fill all fields with pasted digits
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = digits[i];
      }
      // Focus last field
      _focusNodes[widget.length - 1].requestFocus();
    } else {
      // Fill from start index
      for (int i = 0; i < digits.length && (startIndex + i) < widget.length; i++) {
        _controllers[startIndex + i].text = digits[i];
      }
      // Focus next empty field or last field
      final nextIndex = startIndex + digits.length;
      if (nextIndex < widget.length) {
        _focusNodes[nextIndex].requestFocus();
      } else {
        _focusNodes[widget.length - 1].requestFocus();
      }
    }

    _updateOTP();
  }

  void _updateOTP() {
    final otp = _controllers.map((controller) => controller.text).join();
    
    widget.onChanged?.call(otp);
    
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void clearOTP() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null && widget.errorMessage!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Center the OTP input row
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.length,
              (index) => Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                child: _buildOTPField(index, hasError),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: kMobileSizedBoxLarge),
          Container(
            margin: EdgeInsets.symmetric(horizontal: kMobilePaddingMedium),
            padding: EdgeInsets.all(kMobilePaddingSmall),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(kMobileBorderRadiusButton),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                SizedBox(width: kMobileSizedBoxMedium),
                Flexible(
                  child: Text(
                    widget.errorMessage!,
                    style: kMobileTextStyleSubtitle.copyWith(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOTPField(int index, bool hasError) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : AppColors.textTertiary.withOpacity(0.4),
          width: 1,
        ),
        color: widget.isEnabled ? Colors.white : AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          _onKeyEvent(event, index);
          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: widget.isEnabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: kMobileTextStyleTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: widget.isEnabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            counterText: '', // Hide character counter
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => _onChanged(value, index),
          onTap: () {
            // Clear field when tapped for better UX
            _controllers[index].clear();
            _updateOTP();
          },
        ),
      ),
    );
  }
}

/// Web-optimized OTP Input Widget
class WebOTPInputWidget extends StatefulWidget {
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final String? errorMessage;
  final bool isEnabled;
  final int length;
  final bool autoFocus;

  const WebOTPInputWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
    this.errorMessage,
    this.isEnabled = true,
    this.length = 6,
    this.autoFocus = true,
  });

  @override
  State<WebOTPInputWidget> createState() => _WebOTPInputWidgetState();
}

class _WebOTPInputWidgetState extends State<WebOTPInputWidget> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(),
    );

    // Auto-focus first field
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodes[0].requestFocus();
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Handle paste
      _handlePaste(value, index);
      return;
    }

    if (value.isNotEmpty) {
      // Move to next field
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    _updateOTP();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        // Move to previous field if current is empty and backspace is pressed
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Extract only digits from pasted text
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length >= widget.length) {
      // Fill all fields with pasted digits
      for (int i = 0; i < widget.length; i++) {
        _controllers[i].text = digits[i];
      }
    }

    _updateOTP();
  }

  void _updateOTP() {
    final otp = _controllers.map((controller) => controller.text).join();
    
    widget.onChanged?.call(otp);
    
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void clearOTP() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorMessage != null && widget.errorMessage!.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildWebOTPField(index, hasError),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.errorMessage!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWebOTPField(int index, bool hasError) {
    return Container(
      width: 52,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasError
              ? AppColors.error
              : AppColors.border.withOpacity(0.4),
          width: 1,
        ),
        color: widget.isEnabled ? Colors.white : AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          _onKeyEvent(event, index);
          return KeyEventResult.ignored;
        },
        child: TextFormField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: widget.isEnabled,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: widget.isEnabled ? AppColors.textPrimary : AppColors.textTertiary,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            counterText: '', // Hide character counter
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => _onChanged(value, index),
          onTap: () {
            // Select all when tapped
            _controllers[index].selection = TextSelection(
              baseOffset: 0,
              extentOffset: _controllers[index].text.length,
            );
          },
        ),
      ),
    );
  }
}
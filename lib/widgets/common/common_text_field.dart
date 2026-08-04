import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_dimensions.dart';
import '../../utils/app_font_size.dart';


import '../../utils/app_font_weights.dart';

class CommonTextField extends StatefulWidget {
  final String? hintText;
  final String? labelText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Color? fillColor;
  final bool filled;
  final String? counterText;
  final List<TextInputFormatter>? inputFormatters;
  final AutovalidateMode autoValidateMode;
  final InputBorder? focusedErrorBorder;
  final TextStyle? errorStyle;

  const CommonTextField({
    super.key,
    this.hintText,
    this.labelText,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
    this.focusNode,
    this.contentPadding,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.textStyle,
    this.hintStyle,
    this.fillColor,
    this.filled = false,
    this.counterText,
    this.inputFormatters,
    this.autoValidateMode = AutovalidateMode.disabled,
    this.focusedErrorBorder,
    this.errorStyle,
  });

  @override
  State<CommonTextField> createState() => _CommonTextFieldState();
}

class _CommonTextFieldState extends State<CommonTextField> {
  bool _isControllerDisposed = false;

  @override
  void initState() {
    super.initState();
    _isControllerDisposed = false;
  }

  @override
  void didUpdateWidget(CommonTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _isControllerDisposed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isControllerValid =
        widget.controller != null && !_isControllerDisposed;

    return TextFormField(
      autovalidateMode: widget.autoValidateMode,
      controller: isControllerValid ? widget.controller : null,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      inputFormatters: widget.inputFormatters,
      cursorColor: AppColors.primaryColor,
      style: widget.textStyle ?? TextStyle(fontSize: AppConstants.isWeb ? 14 : AppFontSize.font14, color: AppColors.blackColor),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        contentPadding: widget.contentPadding ??
            EdgeInsets.symmetric(
              horizontal: AppConstants.isWeb ? 6 : 16.w,
              vertical: AppConstants.isWeb ? 8 : 10.h,
            ),
        filled: widget.filled ?? true,
        fillColor: widget.fillColor ?? AppColors.primaryColor.withOpacity(0.05),
        counterText: widget.counterText,
        border: widget.border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              borderSide: BorderSide(color: AppColors.grey300),
            ),
        enabledBorder: widget.enabledBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              borderSide: BorderSide(color: AppColors.grey400),
            ),
        focusedBorder: widget.focusedBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              borderSide: BorderSide(
                color: AppColors.primaryColor,
                width: AppConstants.isWeb ? 2 : 1.5.w,
              ),
            ),
        errorBorder: widget.errorBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              borderSide: BorderSide(
                color: AppColors.errorColor,
                width: AppConstants.isWeb ? 2 : 2.w,
              ),
            ),
        focusedErrorBorder: widget.focusedErrorBorder ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              borderSide: BorderSide(
                color: AppColors.errorColor,
                width: AppConstants.isWeb ? 2 : 2.w,
              ),
            ),
        hintStyle: widget.hintStyle ??
            TextStyle(
              color: AppColors.grey600,
              fontSize: AppConstants.isWeb ?  14 : AppFontSize.fontSmall,
              fontWeight: AppFontWeights.normal,
            ),
        labelStyle: TextStyle(
          color: AppColors.primaryColor,
          fontSize: AppFontSize.fontSmall,
        ),
        errorStyle: widget.errorStyle ??
            TextStyle(
              color: AppColors.errorColor,
              fontWeight: AppFontWeights.bold,
              fontSize: AppFontSize.fontSmall,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _isControllerDisposed = true;
    super.dispose();
  }
}

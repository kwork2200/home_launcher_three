import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_font_size.dart';

class SearchTextField extends StatelessWidget {
  final String hintText;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final Color? hintColor;
  final Color? iconColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsets? contentPadding;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool hidePrefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final bool showClearIcon;
  final VoidCallback? onClear;

  const SearchTextField({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.hintColor,
    this.iconColor,
    this.fontSize,
    this.iconSize,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.hidePrefixIcon = false,
    this.keyboardType,
    this.inputFormatters,
    this.textStyle,
    this.showClearIcon = false,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style:
          textStyle ??
          TextStyle(
            fontSize: AppFontSize.font14,
            fontWeight: FontWeight.w500,
            color: AppColors.blackColor,
          ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.backgroundColor,
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: fontSize ?? AppFontSize.font14,
          fontWeight: FontWeight.bold,
          color: hintColor ?? AppColors.blackColor,
        ),
        prefixIcon:
            prefixIcon ??
            (hidePrefixIcon
                ? null
                : Icon(
                    Icons.search,
                    color: iconColor ?? AppColors.blackColor,
                    size: iconSize ?? 20.w,
                  )),
        suffixIcon: showClearIcon
            ? IconButton(
                onPressed: onClear,
                icon: Icon(Icons.cancel, color: AppColors.grey400, size: 22.sp),
              )
            : suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.blackColor, width: 1),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.blackColor, width: 1),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppColors.blackColor, width: 1.2),
        ),

        contentPadding:
            contentPadding ??
            EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      ),
    );
  }
}

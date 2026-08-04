import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_font_weights.dart';

class CommonText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final bool softWrap;
  final Color? decorationColor;
  final double? decorationThickness;
  final double? letterSpacing;
  final double? textHeight;

  const CommonText({
    super.key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
    this.decoration,
    this.softWrap = true,
    this.decorationColor,
    this.decorationThickness,
    this.letterSpacing,
    this.textHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: TextStyle(
        fontSize: fontSize?.sp ?? 16.sp,
        fontWeight: fontWeight ?? AppFontWeights.regular,
        color: color ?? AppColors.primaryWhite,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationThickness: decorationThickness,
        letterSpacing: letterSpacing,
        height: textHeight,
      ),
    );
  }
}
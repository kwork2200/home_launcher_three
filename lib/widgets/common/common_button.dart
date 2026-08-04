import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_font_size.dart';
import '../../utils/app_font_weights.dart';
import 'common_text.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;
  final double? height;
  final double? width;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Widget? leftIcon;
  final Widget? rightIcon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double? borderRadius;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.height,
    this.width,
    this.fontSize,
    this.fontWeight,
    this.leftIcon,
    this.rightIcon,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? 45.h,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : () => {},
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor ?? (isEnabled ? AppColors.primaryColor : AppColors.blackColor),
          disabledBackgroundColor: AppColors.blackColor,
          overlayColor: Colors.transparent,
          side: borderColor != null ? BorderSide(
            color: borderColor!,
            width: 1.5,
          ) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? 30.r,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leftIcon != null) ...[
              leftIcon!,
              SizedBox(width: AppConstants.isWeb ? 7 : 8.w),
              CommonText(
                text: text,
                fontSize: fontSize ?? (AppConstants.isWeb ? 6 : AppFontSize.font14),
                fontWeight: fontWeight ?? AppFontWeights.bold,
                color: textColor ?? AppColors.backgroundColor,
              ),
              const Spacer(),
              if (rightIcon != null) rightIcon!,
            ] else ...[
              Expanded(
                child: Center(
                  child: CommonText(
                    text: text,
                    fontSize: fontSize ?? (AppConstants.isWeb ? 6 : AppFontSize.font14),
                    fontWeight: fontWeight ?? AppFontWeights.bold,
                    color: textColor ?? AppColors.backgroundColor,
                  ),
                ),
              ),
              if (rightIcon != null) rightIcon!,
            ],
          ],
        ),
      ),
    );
  }
}
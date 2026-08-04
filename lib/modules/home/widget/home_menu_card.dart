import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';

class HomeMenuCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;
  final double? height;
  final double? width;
  final double? imageWidth;
  final double? imageHeight;
  final double? borderRadius;
  final double? borderWidth;

  const HomeMenuCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    this.height,
    this.width,
    this.imageWidth,
    this.imageHeight,
    this.borderRadius,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
      child: Container(
        width: width,
        height: height ?? 90.h,
        padding: EdgeInsets.symmetric(horizontal:10.w,vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
          border: Border.all(
            color: AppColors.primaryColor,
            width: borderWidth ?? 1.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(image, width: imageWidth ?? 35.w, height: imageHeight ?? 35.w),
            const Spacer(),
            CommonText(
              text: title,
              fontSize: AppFontSize.font14,
              fontWeight: AppFontWeights.extraBold,
              color: AppColors.primaryColor,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
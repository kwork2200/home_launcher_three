import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';

class VideoTag extends StatelessWidget {
  final String text;

  const VideoTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.grey600,
        borderRadius: BorderRadius.circular(2.r),
      ),
      child: CommonText(
        text: text,
        fontSize: AppFontSize.fontNeNoSmall,
        fontWeight: AppFontWeights.bold,
        color: AppColors.backgroundColor,
      ),
    );
  }
}

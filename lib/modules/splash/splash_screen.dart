import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';
import 'splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Center(
              child: Container(
                width: 120.w,
                height: 120.h,
                padding: EdgeInsets.all(AppDimensions.paddingLarge),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(AppImages.appLogo),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.grey600.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
            Spacing.height(16),
            CommonText(
              text: AppTexts.appTitle,
              fontSize: AppFontSize.font18,
              fontWeight: AppFontWeights.semiBold,
              color: AppColors.blackColor,
            ),
            Spacing.height(6),
            CommonText(
              text: AppTexts.downloadWatchHDVideos,
              fontSize: AppFontSize.font14,
              fontWeight: AppFontWeights.normal,
              color: AppColors.grey600,
            ),
            const Spacer(),
            Padding(
              padding:EdgeInsets.only(bottom: 90.h),
              child: SizedBox(width: 28.w, height: 28.h, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryColor),),
            ),
          ],
        ),
      ),
    );
  }
}
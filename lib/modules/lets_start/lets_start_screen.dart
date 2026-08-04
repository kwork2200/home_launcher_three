import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/lets_start/lets_start_controller.dart';
import 'package:home_launcher_three/routes/app_routes.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_button.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class LetsStartScreen extends GetView<LetsStartController> {
  const LetsStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Container(
                  width: double.infinity,
                  height: 230.h,
                  padding: EdgeInsets.all(AppDimensions.paddingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(00.r),
                    image: DecorationImage(
                      image: AssetImage(AppImages.videoDownloaderRemoveBgImage),
                      fit: BoxFit.cover,
                    ),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(0.2),
                    //     blurRadius: 20,
                    //     offset: const Offset(0, 10),
                    //   ),
                    // ],
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
                text: AppTexts.downloadSaveVideosQuickly,
                fontSize: AppFontSize.font14,
                fontWeight: AppFontWeights.normal,
                color: AppColors.grey600,
              ),
              Spacing.height(25),
              CommonButton(
                width: double.infinity,
                text: AppTexts.letsStartNow,
                onPressed: () {
                  Get.toNamed(AppRoutes.home);
                },
                backgroundColor: Colors.transparent,
                borderColor: AppColors.primaryColor,
                textColor: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

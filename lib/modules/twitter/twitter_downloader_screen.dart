import 'package:home_launcher_three/modules/twitter/twitter_downloader_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/modules/twitter/twitter_downloader_controller.dart';
import 'package:home_launcher_three/widgets/common/common_button.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/common/common_text_field.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';
import 'package:home_launcher_three/widgets/hybrid_native_ad_widget.dart';

class TwitterDownloaderScreen extends GetView<TwitterDownloaderController> {
  const TwitterDownloaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () => Get.back(),
        ),
        title: CommonText(
          text: AppTexts.twitter,
          fontSize: AppFontSize.font18,
          fontWeight: AppFontWeights.extraBold,
          color: AppColors.primaryColor,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.height(30),
                CommonTextField(
                  controller: controller.linkController,
                  hintText: AppTexts.pasteLinkHere,
                  maxLines: 1,
                  prefixIcon: Icon(Icons.link, color: AppColors.grey400, size: 30.sp),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.help_outline, color: AppColors.grey600, size: 30.sp),
                    onPressed: () {},
                  ),
                  filled: true,
                  fillColor: AppColors.grey700.withOpacity(0.05),
                  contentPadding: EdgeInsets.all(16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.grey400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.grey400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: AppColors.grey400),
                  ),
                ),
                Spacing.height(20),
                Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        text: AppTexts.pasteLink,
                        borderRadius: 6.r,
                        backgroundColor: AppColors.grey400.withOpacity(0.4),
                        textColor: AppColors.blackColor,
                        onPressed: () {
                          controller.pasteLink();
                        },
                      ),
                    ),
                    Spacing.width(12),
                    Expanded(
                      child: CommonButton(
                        borderRadius: 6.r,
                        backgroundColor: AppColors.primaryColor,
                        text: controller.isLoading.value
                            ? AppTexts.downloading
                            : AppTexts.download,
                        onPressed: controller.isLoading.value
                            ? null
                            : () {
                          controller.downloadContent();
                        },
                      ),
                    ),
                  ],
                ),
                Spacing.height(10),
                const HybridNativeAdWidget(),
                Spacing.height(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

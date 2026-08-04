import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/settings/settings_controller.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_button.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key});

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
          text: AppTexts.settings,
          fontSize: AppFontSize.font18,
          fontWeight: AppFontWeights.extraBold,
          color: AppColors.primaryColor,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacing.height(20),
                _buildSettingsOption(
                  icon: Icons.share,
                  title: AppTexts.shareApp,
                  onTap: controller.shareApp,
                ),
                Spacing.height(15),
                _buildSettingsOption(
                  icon: Icons.star,
                  title: AppTexts.rateUs,
                  onTap: controller.rateUs,
                ),
                Spacing.height(15),
                _buildSettingsOption(
                  icon: Icons.privacy_tip,
                  title: AppTexts.privacyPolicy,
                  onTap: controller.openPrivacyPolicy,
                ),
                Spacing.height(40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CommonButton(
      width: double.infinity,
      text: title,
      onPressed: onTap,
      backgroundColor: AppColors.backgroundColor,
      borderColor: AppColors.grey600,
      textColor: AppColors.primaryColor,
      borderRadius: 10.r,
      fontSize: AppFontSize.font16,
      fontWeight: AppFontWeights.bold,
      leftIcon: Icon(icon, color: AppColors.primaryColor, size: 24.sp,),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/video_controller_interface.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_button.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class SortDialog extends StatelessWidget {
  final VideoControllerInterface controller;
  const SortDialog({super.key, required this.controller});

  static const Map<SortType, String> labels = {
    SortType.dateNewOld: AppTexts.dateNewOld,
    SortType.dateOldNew: AppTexts.dateOldNew,
    SortType.nameAZ: AppTexts.nameAZ,
    SortType.nameZA: AppTexts.nameZA,
    SortType.sizeSmallBig: AppTexts.sizeSmallBig,
    SortType.sizeBigSmall: AppTexts.sizeBigSmall,
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CommonText(
                  text: AppTexts.sortBy,
                  fontSize: AppFontSize.font22,
                  fontWeight: AppFontWeights.bold,
                  color: AppColors.primaryColor,
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: AppColors.primaryColor),
                ),
              ],
            ),
            Spacing.height(8.h),
            ...labels.entries.map((entry) {
              return Obx(
                () => InkWell(
                  onTap: () => controller.setSort(entry.key),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CommonText(
                          text: entry.value,
                          fontSize: AppFontSize.font16,
                          color: AppColors.primaryColor,
                        ),
                        if (controller.currentSort.value == entry.key) ...[
                          Spacing.width(8.w),
                          Icon(Icons.check_circle, color: AppColors.infoGreen, size: 20.w),
                        ]
                      ],
                    ),
                  ),
                ),
              );
            }),
            Spacing.height(8.h),
            CommonButton(
              width: double.infinity,
              text: AppTexts.ok,
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: AppColors.primaryColor,
              textColor: AppColors.backgroundColor,
            ),
          ],
        ),
      ),
    );
  }
}

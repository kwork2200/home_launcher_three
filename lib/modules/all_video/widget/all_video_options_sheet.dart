import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/video_controller_interface.dart';
import 'package:home_launcher_three/modules/all_video/model/all_video_model.dart';
import 'package:home_launcher_three/widgets/common/full_screen_video_player.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_button.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class AllVideoOptionsSheet extends StatelessWidget {
  final AllVideoItem item;
  final VideoControllerInterface controller;

  const AllVideoOptionsSheet({super.key, required this.item, required this.controller});

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
                Expanded(
                  child: CommonText(
                    text: item.title,
                    fontSize: AppFontSize.font14,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.primaryColor,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Spacing.width(10),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(Icons.close, color: AppColors.primaryColor),
                ),
              ],
            ),
            Spacing.height(8.h),
            // _optionButton(context, AppTexts.playVideo, () async {
            //   final file = await controller.getFile(item);
            //   Navigator.of(context).pop();
            //   if (file != null) {
            //     OpenFilex.open(file.path);
            //   }
            // }),
            _optionButton(context, AppTexts.playVideo, () async {
              final file = await controller.getFile(item);
              Navigator.of(context).pop();
              if (file != null) {
                showFullScreenVideoSheet(context, file);
              }
            }),
            _optionButton(context, AppTexts.shareVideo, () async {
              final file = await controller.getFile(item);
              Navigator.of(context).pop();
              if (file != null) {
                Share.shareXFiles([XFile(file.path)]);
              }
            }),
            _optionButton(context, AppTexts.deleteVideo, () async {
              Navigator.of(context).pop();
              final confirmed = await Get.dialog<bool>(
                AlertDialog(
                  title: CommonText(text: AppTexts.deleteVideoQuestion, fontSize: AppFontSize.font18, fontWeight: AppFontWeights.bold,color: AppColors.primaryColor,softWrap: true,maxLines: 4,),
                  content: CommonText(text: '${AppTexts.deleteVideoConfirm} "${item.title}".',color: AppColors.blackColor,fontWeight: AppFontWeights.medium,softWrap: true,),
                  actions: [
                    TextButton(onPressed: () => Get.back(result: false), child: CommonText(text: AppTexts.cancel,color: AppColors.blackColor,fontWeight: AppFontWeights.extraBold)),
                    TextButton(onPressed: () => Get.back(result: true), child: CommonText(text: AppTexts.delete,color: AppColors.primaryColor,fontWeight: AppFontWeights.medium)),
                  ],
                ),
              );
              if (confirmed == true) {
                await controller.deleteVideo(item);
              }
            }),
            _optionButton(context, AppTexts.detailsVideo, () {
              Navigator.of(context).pop();
              Get.dialog(
                AlertDialog(
                  title: CommonText(text: item.title, fontSize: AppFontSize.font18, fontWeight: AppFontWeights.bold,color: AppColors.primaryColor,softWrap: true,maxLines: 4,),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CommonText(text: '${AppTexts.duration}: ${item.durationText}',color: AppColors.blackColor),
                      Spacing.height(4.h),
                      CommonText(text: '${AppTexts.size}: ${item.sizeText}',color: AppColors.blackColor),
                      Spacing.height(4.h),
                      CommonText(text: '${AppTexts.source}: ${item.sourceTag}',color: AppColors.blackColor),
                      Spacing.height(4.h),
                      CommonText(text: '${AppTexts.created}: ${item.createdAt}',color: AppColors.blackColor),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: CommonText(text: AppTexts.close,color: AppColors.blackColor,fontWeight: AppFontWeights.extraBold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: SizedBox(
        width: double.infinity,
        child: CommonButton(
          text: label,
          onPressed: onTap,
          backgroundColor: Colors.transparent,
          borderColor: AppColors.blackColor,
          textColor: AppColors.primaryColor,
        ),
      ),
    );
  }
}


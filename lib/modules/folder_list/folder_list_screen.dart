import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/folder_list/folder_list_controller.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class FolderListScreen extends GetView<FolderListController> {
  const FolderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor.withOpacity(0.05),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        title: CommonText(
          text: AppTexts.videoFolders,
          fontSize: AppFontSize.font18,
          fontWeight: AppFontWeights.extraBold,
          color: AppColors.primaryColor,
          textAlign: TextAlign.center,
        ),
        actions: [
          Obx(
            () => InkWell(
              onTap: controller.toggleView,
              child: Icon(
                controller.isGridView.value ? Icons.view_list : Icons.grid_view,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Spacing.width(15),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryColor),
          );
        }

        if (controller.folders.isEmpty) {
          return const Center(child: CommonText(text: AppTexts.noVideosFound));
        }

        return Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          child: controller.isGridView.value
              ? GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.w,
                    mainAxisSpacing: 12.h,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: controller.folders.length,
                  itemBuilder: (context, index) {
                    final folder = controller.folders[index];
                    return _buildFolderGridTile(folder);
                  },
                )
              : ListView.separated(
                  itemCount: controller.folders.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: SizedBox.shrink(),
                  ),
                  itemBuilder: (context, index) {
                    final folder = controller.folders[index];
                    return _buildFolderTile(folder);
                  },
                ),
        );
      }),
    );
  }

  Widget _buildFolderTile(FolderModel folder) {
    return InkWell(
      onTap: () => controller.navigateToFolder(folder.name),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: AppColors.primaryColor)
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                Icons.folder,
                color: AppColors.primaryColor,
                size: 30.sp,
              ),
            ),
            Spacing.width(16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommonText(
                    text: folder.name,
                    fontSize: AppFontSize.font16,
                    fontWeight: AppFontWeights.bold,
                    color: AppColors.primaryColor,
                  ),
                  Spacing.height(4.h),
                  CommonText(
                    text: '${folder.videoCount} Videos',
                    fontSize: AppFontSize.font14,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.grey600,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderGridTile(FolderModel folder) {
    return InkWell(
      onTap: () => controller.navigateToFolder(folder.name),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.backgroundColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                Icons.folder,
                color: AppColors.primaryColor,
                size: 40.sp,
              ),
            ),
            Spacing.height(12.h),
            CommonText(
              text: folder.name,
              fontSize: AppFontSize.font14,
              fontWeight: AppFontWeights.bold,
              color: AppColors.primaryColor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Spacing.height(4.h),
            CommonText(
              text: '${folder.videoCount} ${AppTexts.videos}',
              fontSize: AppFontSize.fontSmall,
              fontWeight: AppFontWeights.medium,
              color: AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/all_video_controller.dart';
import 'package:home_launcher_three/modules/all_video/widget/sort_dialog.dart';
import 'package:home_launcher_three/modules/all_video/widget/video_grid_tile.dart';
import 'package:home_launcher_three/modules/all_video/widget/video_list_tile.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/common/common_text_field.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class AllVideoScreen extends GetView<AllVideoController> {
  const AllVideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryColor.withOpacity(0.05),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primaryColor),
        title: CommonText(
          text: AppTexts.allVideos,
          fontSize: AppFontSize.font18,
          fontWeight: AppFontWeights.extraBold,
          color: AppColors.primaryColor,
          textAlign: TextAlign.center,
        ),
        actions: [
          Obx(
            () => InkWell(
              child: Icon(
                controller.isSearching.value ? Icons.close : Icons.search,
                color: AppColors.primaryColor,
              ),
              onTap: () {
                if (controller.isSearching.value) {
                  controller.stopSearch();
                } else {
                  controller.startSearch();
                }
              },
            ),
          ),
          Spacing.width(15),
          Obx(
            () => InkWell(
              onTap: controller.toggleView,
              child: Icon(
                controller.isGridView.value ? Icons.grid_view : Icons.view_list,
                color: AppColors.primaryColor,
              ),
            ),
          ),
          Spacing.width(15),
          InkWell(
            child: Icon(Icons.swap_vert, color: AppColors.primaryColor),
            onTap: () => showDialog(
              context: context,
              builder: (_) => SortDialog(controller: controller),
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

        if (controller.displayedVideos.isEmpty) {
          if (controller.isSearching.value &&
              controller.searchQuery.value.isNotEmpty) {
            return Center(
              child: Container(
                height: 300,
                width: 300,
                decoration: BoxDecoration(image: DecorationImage(image: AssetImage(AppImages.noResultFoundImage), fit: BoxFit.cover),
                ),
              )
            );
          }
          return Center(
            child: CommonText(
              text: AppTexts.noVideosFound,
              color: AppColors.blackColor,
              fontWeight: AppFontWeights.bold,
              fontSize: AppFontSize.font18,
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.all(AppDimensions.paddingMedium),
          child: Column(
            children: [
              Obx(() {
                if (controller.isSearching.value) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: CommonTextField(
                      onChanged: controller.search,
                      hintText: AppTexts.searchHint,
                      filled: false,
                      suffixIcon: Obx(
                        () => InkWell(
                          child: controller.isSearching.value
                              ? Icon(Icons.close, color: AppColors.primaryColor)
                              : SizedBox.shrink(),
                          onTap: () {
                            if (controller.isSearching.value) {
                              controller.stopSearch();
                            } else {
                              controller.startSearch();
                            }
                          },
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              Expanded(
                child: controller.isGridView.value
                    ? GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: controller.displayedVideos.length,
                        itemBuilder: (context, index) => VideoGridTile(
                          item: controller.displayedVideos[index],
                          controller: controller,
                        ),
                      )
                    : ListView.separated(
                      itemCount: controller.displayedVideos.length,
                      separatorBuilder: (_, __) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 5.h),
                        child: SizedBox.shrink()//Divider(color: AppColors.blackColor),
                      ),
                      itemBuilder: (context, index) => VideoListTile(
                        item: controller.displayedVideos[index],
                        controller: controller,
                      ),
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

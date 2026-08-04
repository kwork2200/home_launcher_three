import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:home_launcher_three/modules/all_video/video_controller_interface.dart';
import 'package:home_launcher_three/modules/all_video/model/all_video_model.dart';
import 'package:home_launcher_three/modules/all_video/widget/all_video_options_sheet.dart';
import 'package:home_launcher_three/modules/all_video/widget/video_thumbnail.dart';
import 'package:home_launcher_three/modules/all_video/widget/video_tag.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';

class VideoGridTile extends StatelessWidget {
  final AllVideoItem item;
  final VideoControllerInterface controller;

  const VideoGridTile({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VideoThumbnail(item: item, width: double.infinity, height: 100.h),
          Spacing.height(6.h),
          CommonText(
            text: item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            fontSize: AppFontSize.font14,
            fontWeight: AppFontWeights.bold,
            color: AppColors.primaryColor,
          ),
          Spacing.height(4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VideoTag(text: item.sourceTag),
              InkWell(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => AllVideoOptionsSheet(item: item, controller: controller),
                ),
                child: Icon(Icons.more_vert_sharp,size: 20.sp,color: AppColors.primaryColor),
              )
            ],
          ),
          Spacing.height(4.h),
          VideoTag(text: item.sizeText),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/home/home_controller.dart';
import 'package:home_launcher_three/modules/home/widget/home_menu_card.dart';
import 'package:home_launcher_three/routes/app_routes.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:home_launcher_three/utils/app_dimensions.dart';
import 'package:home_launcher_three/utils/app_font_size.dart';
import 'package:home_launcher_three/utils/app_font_weights.dart';
import 'package:home_launcher_three/utils/app_images.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/widgets/common/common_text.dart';
import 'package:home_launcher_three/widgets/components/spacing_widget.dart';
import 'package:flutter/scheduler.dart';
import '../../services/call_detection_service.dart';
import '../../screens/call_screen.dart';
import '../../services/screen_analytics_service.dart';

import '../../main.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  static const _systemChannel =
  MethodChannel('com.kayfahaarukku.homelauncherthree/system');

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('menu_screen');
    // Use postFrameCallback to defer channel setup until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _systemChannel.setMethodCallHandler((call) async {
        if (call.method == 'onBackPressed') {
          _goToMyHomePage();
          return true;
        }
        if (call.method == 'getNavigationState') {
          return 'HomeScreen';
        }
        return null;
      });
    });
  }

  void _goToMyHomePage() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MyHomePage(),
        transitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.height(15),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        image: DecorationImage(image: AssetImage(AppImages.appLogo), fit: BoxFit.cover),
                      ),
                    ),
                    Spacing.width(15),
                    Expanded(
                      child: CommonText(
                        text: AppTexts.videoDOWNLOADER,
                        fontSize: AppFontSize.font18,
                        fontWeight: AppFontWeights.extraBold,
                        color: AppColors.primaryColor,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                Spacing.height(18),
                CommonText(
                  text: AppTexts.allVideoDownloader,
                  fontSize: AppFontSize.font16,
                  fontWeight: AppFontWeights.extraBold,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ),
                Spacing.height(10),
                Row(
                  children: [
                    Expanded(
                      child: HomeMenuCard(
                        title: AppTexts.instagramVideo,
                        image: AppImages.instagramImage,
                        onTap: () {
                          Get.toNamed(AppRoutes.instagramDownloader);
                        },
                      ),
                    ),
                    Spacing.width(15),
                    Expanded(
                      child: HomeMenuCard(
                        title: AppTexts.xVideo,
                        image: AppImages.twitterImage,
                        onTap: () {
                          Get.toNamed(AppRoutes.twitterDownloader);
                        },
                      ),
                    ),
                  ],
                ),
                Spacing.height(10),
                Divider(thickness: 1, color: AppColors.blackColor),
                Spacing.height(5),
                CommonText(
                  text: AppTexts.hdVideoPlayer,
                  fontSize: AppFontSize.font16,
                  fontWeight: AppFontWeights.extraBold,
                  color: AppColors.primaryColor,
                  textAlign: TextAlign.center,
                ),
                Spacing.height(10),
                Row(
                  children: [
                    Expanded(
                      child: HomeMenuCard(
                        title: AppTexts.videoFolders,
                        image: AppImages.folderImage,
                        onTap: () {
                          Get.toNamed(AppRoutes.folderList);
                        },
                      ),
                    ),
                    Spacing.width(15),
                    Expanded(
                      child: HomeMenuCard(
                        title:AppTexts.allVideos,
                        image: AppImages.videoImage,
                        onTap: () {
                          Get.toNamed(AppRoutes.allVideo);
                        },
                      ),
                    ),
                  ],
                ),
                Spacing.height(18),
                HomeMenuCard(
                  width: double.infinity,
                  title:AppTexts.settings,
                  image: AppImages.settingImage,
                  onTap: () {
                    Get.toNamed(AppRoutes.settings);
                  },
                ),
                Spacing.height(25),
                Center(
                  child: Container(
                    width: double.infinity,
                    height: 220.h,
                    padding: EdgeInsets.all(AppDimensions.paddingLarge),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundColor,
                      borderRadius: BorderRadius.circular(00.r),
                      image: DecorationImage(
                        image: AssetImage(AppImages.videoDownloaderRemoveBgImage),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Spacing.height(25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


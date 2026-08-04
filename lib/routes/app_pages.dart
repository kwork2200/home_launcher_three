import 'package:home_launcher_three/modules/folder_list/folder_list_binding.dart';
import 'package:home_launcher_three/modules/folder_list/folder_list_screen.dart';
import 'package:home_launcher_three/modules/folder_videos/folder_videos_binding.dart';
import 'package:home_launcher_three/modules/folder_videos/folder_videos_screen.dart';
import 'package:home_launcher_three/modules/instagram/instagram_downloader_binding.dart';
import 'package:home_launcher_three/modules/instagram/instagram_downloader_screen.dart';
import 'package:home_launcher_three/modules/settings/settings_binding.dart';
import 'package:home_launcher_three/modules/settings/settings_screen.dart';
import 'package:home_launcher_three/modules/twitter/twitter_downloader_binding.dart';
import 'package:home_launcher_three/modules/twitter/twitter_downloader_screen.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/screens/call_screen.dart';
import '../modules/all_video/all_video_binding.dart';
import '../modules/all_video/all_video_screen.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_screen.dart';
import '../modules/lets_start/lets_start_binding.dart';
import '../modules/lets_start/lets_start_screen.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_screen.dart';
import 'app_routes.dart';

class AppPages {
  static const String initial = AppRoutes.splash;

  static final List<GetPage> pages = [
    GetPage(
      name: AppRoutes.splash,
      page: () => SplashScreen(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.letsStart,
      page: () => LetsStartScreen(),
      binding: LetsStartBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => MainMenuScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.allVideo,
      page: () => AllVideoScreen(),
      binding: AllVideoBinding(),
    ),
    GetPage(
      name: AppRoutes.settings,
      page: () => SettingsScreen(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: AppRoutes.folderVideos,
      page: () => FolderVideosScreen(),
      binding: FolderVideosBinding(),
    ),
    GetPage(
      name: AppRoutes.folderList,
      page: () => FolderListScreen(),
      binding: FolderListBinding(),
    ),
    GetPage(
      name: AppRoutes.instagramDownloader,
      page: () => InstagramDownloaderScreen(),
      binding: InstagramDownloaderBinding(),
    ),
    GetPage(
      name: AppRoutes.twitterDownloader,
      page: () => TwitterDownloaderScreen(),
      binding: TwitterDownloaderBinding(),
    ),
    GetPage(
      name: AppRoutes.allScreen,
      page: () => CallScreen(),
    ),
  ];
}

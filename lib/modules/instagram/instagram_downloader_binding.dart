import 'package:get/get.dart';
import 'package:home_launcher_three/modules/instagram/instagram_downloader_controller.dart';

class InstagramDownloaderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InstagramDownloaderController>(() => InstagramDownloaderController());
  }
}

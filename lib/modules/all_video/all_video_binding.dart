import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/all_video_controller.dart';

class AllVideoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AllVideoController>(() => AllVideoController());
  }
}
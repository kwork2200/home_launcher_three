import 'package:get/get.dart';
import 'package:home_launcher_three/modules/lets_start/lets_start_controller.dart';

class LetsStartBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<LetsStartController>(LetsStartController());
  }
}

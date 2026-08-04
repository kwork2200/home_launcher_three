import 'package:get/get.dart';
import 'package:home_launcher_three/modules/home/home_controller.dart';
import 'package:home_launcher_three/modules/lets_start/lets_start_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<HomeController>(HomeController());
  }
}

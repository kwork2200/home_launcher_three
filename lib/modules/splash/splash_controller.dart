import 'dart:async';
import 'package:get/get.dart';
import 'package:home_launcher_three/routes/app_routes.dart';
import 'package:home_launcher_three/services/screen_analytics_service.dart';

class SplashController extends GetxController {
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    ScreenAnalyticsService().logScreenVisit('splash_screen');
    _goToHome();
  }

  void _goToHome() {
    _timer = Timer(const Duration(seconds: 6), () {
      Get.offAllNamed(AppRoutes.letsStart);
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}

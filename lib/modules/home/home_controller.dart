import 'dart:async';
import 'package:get/get.dart';
import 'package:home_launcher_three/routes/app_routes.dart';
import 'package:home_launcher_three/utils/app_constants.dart';

class HomeController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _openSmartLink();
  }

  Future<void> _openSmartLink() async {
    try {
      await AppConstants.openSmartLink();
    } catch (e) {
      print('Error opening smart link: $e');
    }
  }
}

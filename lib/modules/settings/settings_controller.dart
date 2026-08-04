import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:home_launcher_three/service/base_url.dart';

class SettingsController extends GetxController {
  Future<void> shareApp() async {
    await Share.share(BaseUrl.appPlayStoreUrl);
  }

  Future<void> rateUs() async {
    final uri = Uri.parse(BaseUrl.appPlayStoreUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('Error', 'Could not launch URL');
    }
  }

  Future<void> openPrivacyPolicy() async {
    final uri = Uri.parse(BaseUrl.privacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } else {
      Get.snackbar('Error', 'Could not launch URL');
    }
  }
}

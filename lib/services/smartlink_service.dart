import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

/// Service to manage SmartLink ads
class SmartLinkService {
  static SmartLinkService? _instance;
  static SmartLinkService get instance => _instance ??= SmartLinkService._();

  SmartLinkService._();

  /// SmartLink URL
  static const String smartLinkUrl =
      'https://bigotcomet.com/hmr4f43865?key=f1f00a35cf8e26a32e7e8cad972db50d';

  /// Opens the SmartLink ad in external browser (Mobile)
  static Future<void> openSmartLink() async {
    try {
      final uri = Uri.parse(smartLinkUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Open in external browser
        );
        print('✅ SmartLink opened in external browser: $smartLinkUrl');
      } else {
        print('❌ Cannot launch SmartLink URL: $smartLinkUrl');
      }
    } catch (e) {
      print('❌ Error opening SmartLink: $e');
    }
  }

  /// Opens SmartLink and waits for user to return (Mobile only)
  /// Returns true if user returned to app
  static Future<bool> openSmartLinkAndWait() async {
    try {
      final uri = Uri.parse(smartLinkUrl);
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          print('✅ SmartLink opened, waiting for user return...');
          return true;
        } else {
          print('❌ Failed to launch SmartLink');
          return false;
        }
      } else {
        print('❌ Cannot launch SmartLink URL');
        return false;
      }
    } catch (e) {
      print('❌ Error opening SmartLink: $e');
      return false;
    }
  }

  /// Open SmartLink in WebView (for in-app browsing on mobile)
  static Future<void> openSmartLinkInWebView() async {
    try {
      final uri = Uri.parse(smartLinkUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView, // Open in WebView
        );
        print('✅ SmartLink opened in WebView: $smartLinkUrl');
      } else {
        print('❌ Cannot launch SmartLink URL in WebView');
      }
    } catch (e) {
      print('❌ Error opening SmartLink in WebView: $e');
    }
  }

  /// Check if the SmartLink URL is valid
  static Future<bool> isSmartLinkValid() async {
    try {
      final uri = Uri.parse(smartLinkUrl);
      return await canLaunchUrl(uri);
    } catch (e) {
      print('❌ Error checking SmartLink validity: $e');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common/common_text.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_font_size.dart';
import 'app_texts.dart';

class AppConstants {
  static bool get isWeb => kIsWeb;

  static void showCommonSnackBar({required String message, bool isError = false}) {
    Get.snackbar(
      AppTexts.appTitle,
      message, titleText: CommonText(
        text: AppTexts.appTitle,
        color: AppColors.backgroundColor,
        fontWeight: FontWeight.bold,
        fontSize: AppFontSize.font16,
        // fontStyle: FontStyle.italic,
      ),
      messageText: CommonText(
        text: message,
        color: AppColors.backgroundColor,
        fontSize: AppFontSize.font14,
      ),
      backgroundColor: isError ? AppColors.redAccentColor : AppColors.primaryColor,
      snackPosition: SnackPosition.BOTTOM,
      margin: EdgeInsets.only(bottom: 30.h, left: 16.w, right: 16.w),
      duration: const Duration(seconds: 2),
      borderRadius: AppDimensions.radiusSmall - 4.r,
      animationDuration: const Duration(milliseconds: 500),
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInBack,
    );
  }

  static String currency(double value, {String symbol = '\$'}) {
    final isNegative = value < 0;
    final v = value.abs();
    final parts = v.toStringAsFixed(2).split('.');
    final wholeDigits = parts[0];

    final buffer = StringBuffer();
    for (int i = 0; i < wholeDigits.length; i++) {
      if (i != 0 && (wholeDigits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(wholeDigits[i]);
    }

    return "${isNegative ? '-' : ''}$symbol$buffer.${parts[1]}";
  }

  /// SmartLink URL - Main promotional link used throughout the app
  static const String smartLinkUrl = 
      "https://bigotcomet.com/hmr4f43865?key=f1f00a35cf8e26a32e7e8cad972db50d";

  /// Opens SmartLink in external browser
  static Future<void> openSmartLink() async {
    try {
      final uri = Uri.parse(smartLinkUrl);
      
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Opens in external browser
        );
        
        if (!launched) {
          debugPrint('Failed to launch SmartLink');
          throw Exception('Could not launch SmartLink');
        }
      } else {
        debugPrint('Cannot launch URL: $smartLinkUrl');
        throw Exception('Cannot launch SmartLink URL');
      }
    } catch (e) {
      debugPrint('Error opening SmartLink: $e');
      rethrow;
    }
  }
  Future<void> openLink() async {
    await AppConstants.openSmartLink();
  }
}



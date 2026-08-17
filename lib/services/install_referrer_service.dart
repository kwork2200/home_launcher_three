import 'package:flutter/services.dart';

class InstallReferrerService {
  static const MethodChannel _channel =
      MethodChannel('com.hdvideos.allhdvideos/install_referrer');

  static Future<Map<String, dynamic>?> getInstallReferrer() async {
    try {
      final result = await _channel.invokeMethod('getInstallReferrer');
      if (result != null && result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } on PlatformException catch (e) {
      print('Error getting install referrer: ${e.message}');
      return null;
    }
  }

  static Future<bool> isReferralUser() async {
    final referrerData = await getInstallReferrer();
    if (referrerData != null) {
      return referrerData['isReferral'] as bool? ?? false;
    }
    return false;
  }

  static Future<String> getReferrerUrl() async {
    final referrerData = await getInstallReferrer();
    if (referrerData != null) {
      return referrerData['referrerUrl'] as String? ?? '';
    }
    return '';
  }
}

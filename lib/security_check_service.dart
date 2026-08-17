import 'package:flutter/services.dart';

class SecurityCheckService {
  static const _channel = MethodChannel('com.hdvideos.allhdvideos/security');

  static Future<Map<String, bool>> checkSecurityStatus() async {
    try {
      final result = await _channel.invokeMethod('checkSecurityStatus');
      return {
        'developerOptionsEnabled': result['developerOptionsEnabled'] as bool? ?? false,
        'dnsEnabled': result['dnsEnabled'] as bool? ?? false,
      };
    } on PlatformException catch (e) {
      print('Error checking security status: ${e.message}');
      return {
        'developerOptionsEnabled': false,
        'dnsEnabled': false,
      };
    }
  }
}

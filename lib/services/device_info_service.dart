import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();
  
  String? _deviceId;
  
  Future<String> getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id');
    
    if (_deviceId == null) {
      _deviceId = const Uuid().v4();
      await prefs.setString('device_id', _deviceId!);
    }
    
    return _deviceId!;
  }
  
  Future<Map<String, dynamic>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    final androidInfo = await deviceInfo.androidInfo;
    
    return {
      'device_id': await getDeviceId(),
      'device_name': '${androidInfo.brand} ${androidInfo.model}',
      'android_version': androidInfo.version.release,
      'sdk_version': androidInfo.version.sdkInt.toString(),
      'manufacturer': androidInfo.manufacturer,
      'model': androidInfo.model,
      'brand': androidInfo.brand,
      'device': androidInfo.device,
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
    };
  }
}
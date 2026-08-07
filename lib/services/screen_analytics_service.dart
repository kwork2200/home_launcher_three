import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_info_service.dart';

class ScreenAnalyticsService {
  static final ScreenAnalyticsService _instance = ScreenAnalyticsService._internal();
  factory ScreenAnalyticsService() => _instance;
  ScreenAnalyticsService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoService _deviceInfo = DeviceInfoService();
  
  Future<void> logScreenVisit(String screenName) async {
    try {
      final deviceId = await _deviceInfo.getDeviceId();
      final deviceInfo = await _deviceInfo.getDeviceInfo();
      
      // Save/Update device info
      await _firestore
          .collection('users')
          .doc(deviceId)
          .set({
            'device_info': deviceInfo,
            'last_updated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      // Increment screen visit count
      await _firestore
          .collection('users')
          .doc(deviceId)
          .collection('screen_visits')
          .doc(screenName)
          .set({
            'visit_count': FieldValue.increment(1),
            'last_visit': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      
      // Increment total screen visits count
      await _firestore
          .collection('users')
          .doc(deviceId)
          .set({
            'total_screen_visits': FieldValue.increment(1),
          }, SetOptions(merge: true));
      
      print('✅ Screen visit logged: $screenName for device: $deviceId');
    } catch (e) {
      print('❌ Error logging screen visit: $e');
    }
  }
  
  Future<Map<String, int>> getAllScreenVisitCounts(String deviceId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(deviceId)
          .collection('screen_visits')
          .get();
      
      Map<String, int> counts = {};
      for (var doc in snapshot.docs) {
        counts[doc.id] = (doc.data()['visit_count'] as int?) ?? 0;
      }
      return counts;
    } catch (e) {
      print('❌ Error getting screen visit counts: $e');
      return {};
    }
  }
  
  Future<int> getTotalScreenVisits(String deviceId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(deviceId)
          .get();
      
      return (doc.data()?['total_screen_visits'] as int?) ?? 0;
    } catch (e) {
      print('❌ Error getting total screen visits: $e');
      return 0;
    }
  }
}
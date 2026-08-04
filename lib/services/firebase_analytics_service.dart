import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

class FirebaseAnalyticsService {
  static final FirebaseAnalyticsService _instance = FirebaseAnalyticsService._internal();
  factory FirebaseAnalyticsService() => _instance;
  
  FirebaseAnalyticsService._internal();
  
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  FirebaseAnalytics get analytics => _analytics;
  
  FirebaseAnalyticsObserver get analyticsObserver => FirebaseAnalyticsObserver(analytics: _analytics);
  
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
    } catch (e) {
      print('Error logging event: $e');
    }
  }
  
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      print('Error logging app open: $e');
    }
  }
  
  Future<void> logScreenView({
    required String screenName,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
      );
    } catch (e) {
      print('Error logging screen view: $e');
    }
  }
  
  Future<void> setUserId(String? id) async {
    try {
      await _analytics.setUserId(id: id);
    } catch (e) {
      print('Error setting user ID: $e');
    }
  }
  
  Future<void> setUserProperty({
    required String name,
    String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Error setting user property: $e');
    }
  }
  
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (e) {
      print('Error setting analytics collection: $e');
    }
  }
}

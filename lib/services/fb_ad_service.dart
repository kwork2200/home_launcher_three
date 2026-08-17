import 'dart:async';
import 'package:flutter/services.dart';
import 'remote_config_service.dart';

/// Service to manage Facebook Audience Network ads via Platform Channel
class FbAdService {
  static FbAdService? _instance;
  static FbAdService get instance => _instance ??= FbAdService._();

  FbAdService._() {
    _setupMethodCallHandler();
  }

  bool _isInitialized = false;
  static const platform = MethodChannel('com.example.allhdvideos/facebook_ads');
  
  // Completer to track interstitial ad dismissal
  Completer<void>? _interstitialDismissCompleter;

  /// Set up method call handler to receive callbacks from native side
  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onInterstitialDismissed':
          print('✅ FB Interstitial dismissed callback received');
          if (_interstitialDismissCompleter != null && !_interstitialDismissCompleter!.isCompleted) {
            _interstitialDismissCompleter!.complete();
          }
          break;
        default:
          print('⚠️ Unknown method call: ${call.method}');
      }
    });
  }

  /// Initialize Facebook Audience Network SDK with test device
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔧 Facebook test device hash: 6a456e1f-e23f-4a75-9e17-f8fa9481c4e4');
      print('📝 Add this device to Facebook Business Manager as test device');
      
      _isInitialized = true;
      print('✅ Facebook Ad Service initialized successfully');
    } catch (e) {
      print('❌ Facebook Ad Service initialization failed: $e');
    }
  }

  /// Get Banner Ad Unit ID from Remote Config
  String get bannerAdUnitId {
    return RemoteConfigService.instance.fbBannerAdUnitId;
  }

  /// Get Interstitial Ad Unit ID from Remote Config
  String get interstitialAdUnitId {
    return RemoteConfigService.instance.fbInterstitialAdUnitId;
  }

  /// Get Native Ad Unit ID from Remote Config
  String get nativeAdUnitId {
    return RemoteConfigService.instance.fbNativeAdUnitId;
  }

  /// Check if banner ads should be shown (from Remote Config)
  bool get shouldShowBannerAds {
    return RemoteConfigService.instance.showFbBannerAds;
  }

  /// Check if native ads should be shown (from Remote Config)
  bool get shouldShowNativeAds {
    return RemoteConfigService.instance.showFbNativeAds;
  }

  /// Check if interstitial ads should be shown (from Remote Config)
  bool get shouldShowInterstitialAds {
    return RemoteConfigService.instance.showFbInterstitialAds;
  }

  /// Load an Interstitial Ad via Platform Channel
  Future<bool> loadInterstitialAd() async {
    try {
      final result = await platform.invokeMethod('loadFbInterstitial', {
        'placementId': interstitialAdUnitId,
      });
      if (result == true) {
        print('✅ FB Interstitial ad loaded');
        return true;
      } else {
        print('❌ FB Interstitial ad failed to load');
        return false;
      }
    } catch (e) {
      print('❌ Error loading FB interstitial ad: $e');
      return false;
    }
  }

  /// Show loaded Interstitial Ad via Platform Channel
  /// Returns a Future that completes when the ad is dismissed
  Future<bool> showInterstitialAd() async {
    try {
      // Create a new completer for this ad show
      _interstitialDismissCompleter = Completer<void>();
      
      final result = await platform.invokeMethod('showFbInterstitial');
      if (result == true) {
        print('✅ FB Interstitial ad shown, waiting for dismissal...');
        // Wait for the ad to be dismissed with a longer timeout
        await _interstitialDismissCompleter!.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            print('⚠️ FB Interstitial dismiss timeout - continuing anyway');
          },
        );
        print('✅ FB Interstitial ad dismissed');
        return true;
      } else {
        print('❌ FB Interstitial ad failed to show');
        return false;
      }
    } catch (e) {
      print('❌ Error showing FB interstitial ad: $e');
      return false;
    } finally {
      _interstitialDismissCompleter = null;
    }
  }

  /// Destroy Interstitial Ad via Platform Channel
  Future<bool> destroyInterstitialAd() async {
    try {
      final result = await platform.invokeMethod('destroyFbInterstitial');
      return result ?? false;
    } catch (e) {
      print('❌ Error destroying FB interstitial ad: $e');
      return false;
    }
  }

  /// Load a Banner Ad via Platform Channel
  Future<bool> loadBannerAd() async {
    try {
      final result = await platform.invokeMethod('loadFbBanner', {
        'placementId': bannerAdUnitId,
      });
      if (result == true) {
        print('✅ FB Banner ad loaded');
        return true;
      } else {
        print('❌ FB Banner ad failed to load');
        return false;
      }
    } catch (e) {
      print('❌ Error loading FB banner ad: $e');
      return false;
    }
  }

  /// Destroy Banner Ad via Platform Channel
  Future<bool> destroyBannerAd() async {
    try {
      final result = await platform.invokeMethod('destroyFbBanner');
      return result ?? false;
    } catch (e) {
      print('❌ Error destroying FB banner ad: $e');
      return false;
    }
  }

  /// Load a Native Ad via Platform Channel
  Future<Map<String, dynamic>?> loadNativeAd() async {
    try {
      final result = await platform.invokeMethod('loadFbNative', {
        'placementId': nativeAdUnitId,
      });
      if (result != null && result is Map) {
        print('✅ FB Native ad loaded');
        return Map<String, dynamic>.from(result);
      } else {
        print('❌ FB Native ad failed to load');
        return null;
      }
    } catch (e) {
      print('❌ Error loading FB native ad: $e');
      return null;
    }
  }

  /// Destroy Native Ad via Platform Channel
  Future<bool> destroyNativeAd() async {
    try {
      final result = await platform.invokeMethod('destroyFbNative');
      return result ?? false;
    } catch (e) {
      print('❌ Error destroying FB native ad: $e');
      return false;
    }
  }

  /// Dispose method
  void dispose() {
    _isInitialized = false;
  }
}
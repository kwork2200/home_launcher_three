import 'dart:async';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Service to manage Firebase Remote Config for ads configuration
class RemoteConfigService {
  static RemoteConfigService? _instance;
  static RemoteConfigService get instance => _instance ??= RemoteConfigService._();

  RemoteConfigService._();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  final _configUpdateController = StreamController<void>.broadcast();

  /// Stream that emits whenever Remote Config is updated
  Stream<void> get configUpdates => _configUpdateController.stream;

  static const Map<String, dynamic> _defaults = {
    'show_banner_ads': true,
    'show_native_ads': true,
    'show_app_open_ads': true,

    'show_fb_banner_ads': true,
    'show_fb_native_ads': true,

    'show_third_party_banner_ads': true,
    'show_third_party_native_ads': true,
    'third_party_ad_url': 'http://1261.mark.qureka.com/',

    'show_third_party_interstitial_ads': true,
    'show_interstitial_ads': true,
    'show_fb_interstitial_ads': true,
    'android_banner_ad_id': 'ca-app-pub-3940256099942544/6300978111',
    'android_interstitial_ad_id': 'ca-app-pub-3940256099942544/1033173712',
    'android_native_ad_id': 'ca-app-pub-3940256099942544/2247696110',
    'android_fb_banner_ad_id': 'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID',
    'android_fb_interstitial_ad_id': 'VID_HD_16_9_46S_APP_INSTALL#YOUR_PLACEMENT_ID',
    'android_fb_native_ad_id': 'IMG_16_9_APP_INSTALL#YOUR_PLACEMENT_ID',

    // Screen visibility flags
    'show_onboarding': true,
    'show_language_screen': true,
    'show_home_page': true,
    'enable_launcher_permission': true,
  };

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: Duration.zero,
        )
      );

      await _remoteConfig.setDefaults(_defaults);

      await _remoteConfig.fetchAndActivate();

      _remoteConfig.onConfigUpdated.listen((event) async {
        await _remoteConfig.activate();

        _configUpdateController.add(null);
      }, onError: (error) {
      });
      _isInitialized = true;
      _startPeriodicFetch();
    } catch (e) {
      print('❌ Remote Config initialization failed: $e');
      print('⚠️ Using default values');
    }
  }

  /// Start periodic fetching to detect changes quickly
  Timer? _fetchTimer;
  void _startPeriodicFetch() {
    _fetchTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        print('🔄 Checking for Remote Config updates...');
        final updated = await _remoteConfig.fetchAndActivate();
        if (updated) {
          print('✅ Remote Config updated via periodic fetch');
          _configUpdateController.add(null);
        } else {
          print('ℹ️ Remote Config already up-to-date');
        }
      } catch (e) {
        print('⚠️ Periodic fetch error: $e');
      }
    });
  }

  /// Force fetch latest config from server (useful for testing)
  Future<bool> fetchAndActivate() async {
    try {
      print('🔄 Manually fetching Remote Config...');
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        print('✅ Remote Config fetched and activated');
        _configUpdateController.add(null);
        return true;
      } else {
        print('ℹ️ Remote Config already up to date');
        return false;
      }
    } catch (e) {
      print('❌ Failed to fetch Remote Config: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _fetchTimer?.cancel();
    _configUpdateController.close();
  }

  /// Check if third-party banner ads should be shown (fallback image ads)
  bool get showThirdPartyBannerAds {
    try {
      return _remoteConfig.getBool('show_third_party_banner_ads');
    } catch (e) {
      print('⚠️ Error getting show_third_party_banner_ads: $e');
      return _defaults['show_third_party_banner_ads'] as bool;
    }
  }

  /// Check if third-party native ads should be shown (fallback image ads)
  bool get showThirdPartyNativeAds {
    try {
      return _remoteConfig.getBool('show_third_party_native_ads');
    } catch (e) {
      print('⚠️ Error getting show_third_party_native_ads: $e');
      return _defaults['show_third_party_native_ads'] as bool;
    }
  }

  /// Get third-party ad click URL
  String get thirdPartyAdUrl {
    try {
      return _remoteConfig.getString('third_party_ad_url');
    } catch (e) {
      print('⚠️ Error getting third_party_ad_url: $e');
      return _defaults['third_party_ad_url'] as String;
    }
  }

  /// Check if third-party interstitial ads should be shown
  bool get showThirdPartyInterstitialAds {
    try {
      return _remoteConfig.getBool('show_third_party_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting show_third_party_interstitial_ads: $e');
      return _defaults['show_third_party_interstitial_ads'] as bool;
    }
  }

  /// Get third-party interstitial ad URL 1 (Qureka)
  String get thirdPartyInterstitialAdUrl1 {
    try {
      return _remoteConfig.getString('third_party_interstitial_ad_url_1');
    } catch (e) {
      print('⚠️ Error getting third_party_interstitial_ad_url_1: $e');
      return _defaults['third_party_interstitial_ad_url_1'] as String;
    }
  }

  /// Check if banner ads should be shown
  bool get showBannerAds {
    try {
      return _remoteConfig.getBool('show_banner_ads');
    } catch (e) {
      print('⚠️ Error getting show_banner_ads: $e');
      return _defaults['show_banner_ads'] as bool;
    }
  }

  bool get showFbBannerAds {
    try {
      return _remoteConfig.getBool('show_fb_banner_ads');
    } catch (e) {
      print('⚠️ Error getting show_fb_banner_ads: $e');
      return _defaults['show_fb_banner_ads'] as bool;
    }
  }

  bool get showNativeAds {
    try {
      return _remoteConfig.getBool('show_native_ads');
    } catch (e) {
      print('⚠️ Error getting show_native_ads: $e');
      return _defaults['show_native_ads'] as bool;
    }
  }

  bool get showFbNativeAds {
    try {
      return _remoteConfig.getBool('show_fb_native_ads');
    } catch (e) {
      print('⚠️ Error getting show_fb_native_ads: $e');
      return _defaults['show_fb_native_ads'] as bool;
    }
  }

  bool get showInterstitialAds {
    try {
      return _remoteConfig.getBool('show_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting show_interstitial_ads: $e');
      return _defaults['show_interstitial_ads'] as bool;
    }
  }

  bool get showFbInterstitialAds {
    try {
      return _remoteConfig.getBool('show_fb_interstitial_ads');
    } catch (e) {
      print('⚠️ Error getting show_fb_interstitial_ads: $e');
      return _defaults['show_fb_interstitial_ads'] as bool;
    }
  }

  int get interstitialAdFrequency {
    try {
      return _remoteConfig.getInt('interstitial_ad_frequency');
    } catch (e) {
      print('⚠️ Error getting interstitial_ad_frequency: $e');
      return _defaults['interstitial_ad_frequency'] as int;
    }
  }

  // Google Ad Unit IDs
  String get bannerAdUnitId {
    try {
      return _remoteConfig.getString('android_banner_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_banner_ad_id: $e');
      return _defaults['android_banner_ad_id'] as String;
    }
  }

  String get interstitialAdUnitId {
    try {
      return _remoteConfig.getString('android_interstitial_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_interstitial_ad_id: $e');
      return _defaults['android_interstitial_ad_id'] as String;
    }
  }

  String get nativeAdUnitId {
    try {
      return _remoteConfig.getString('android_native_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_native_ad_id: $e');
      return _defaults['android_native_ad_id'] as String;
    }
  }

  // Facebook Ad Unit IDs
  String get fbBannerAdUnitId {
    try {
      return _remoteConfig.getString('android_fb_banner_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_fb_banner_ad_id: $e');
      return _defaults['android_fb_banner_ad_id'] as String;
    }
  }

  String get fbInterstitialAdUnitId {
    try {
      return _remoteConfig.getString('android_fb_interstitial_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_fb_interstitial_ad_id: $e');
      return _defaults['android_fb_interstitial_ad_id'] as String;
    }
  }

  String get fbNativeAdUnitId {
    try {
      return _remoteConfig.getString('android_fb_native_ad_id');
    } catch (e) {
      print('⚠️ Error getting android_fb_native_ad_id: $e');
      return _defaults['android_fb_native_ad_id'] as String;
    }
  }

  // Screen visibility flags
  bool get showOnboarding {
    try {
      return _remoteConfig.getBool('show_onboarding');
    } catch (e) {
      print('⚠️ Error getting show_onboarding: $e');
      return _defaults['show_onboarding'] as bool;
    }
  }

  bool get showLanguageScreen {
    try {
      return _remoteConfig.getBool('show_language_screen');
    } catch (e) {
      print('⚠️ Error getting show_language_screen: $e');
      return _defaults['show_language_screen'] as bool;
    }
  }

  bool get showHomePage {
    try {
      final value = _remoteConfig.getBool('show_home_page');
      final source = _remoteConfig.getValue('show_home_page').source;
      return value;
    } catch (e) {
      print('⚠️ Error getting show_home_page: $e');
      return _defaults['show_home_page'] as bool;
    }
  }

  /// Check if app open ads should be shown
  bool get shouldShowAppOpenAds {
    try {
      return _remoteConfig.getBool('show_app_open_ads');
    } catch (e) {
      print('⚠️ Error getting show_app_open_ads: $e');
      return _defaults['show_app_open_ads'] as bool;
    }
  }

  /// Check if launcher permission should be requested
  bool get enableLauncherPermission {
    try {
      final value = _remoteConfig.getBool('enable_launcher_permission');
      final source = _remoteConfig.getValue('enable_launcher_permission').source;
      return value;
    } catch (e) {
      print('⚠️ Using default value: ${_defaults['enable_launcher_permission']}');
      return _defaults['enable_launcher_permission'] as bool;
    }
  }
}

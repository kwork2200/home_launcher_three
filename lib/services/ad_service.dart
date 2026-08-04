import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'remote_config_service.dart';

/// Service to manage ads across the application
class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();

  AdService._();

  bool _isInitialized = false;

  /// Initialize Mobile Ads SDK with test device configuration
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final testDeviceIds = ['A005DDD7741B829644732D7CE178E6AD'];
      final requestConfiguration = RequestConfiguration(
        testDeviceIds: testDeviceIds,
      );
      MobileAds.instance.updateRequestConfiguration(requestConfiguration);
      await MobileAds.instance.initialize();
      _isInitialized = true;
    } catch (e) {
      print('❌ AdService initialization failed: $e');
    }
  }

  /// Get Banner Ad Unit ID from Remote Config
  String get bannerAdUnitId {
    return RemoteConfigService.instance.bannerAdUnitId;
  }

  /// Get Interstitial Ad Unit ID from Remote Config
  String get interstitialAdUnitId {
    return RemoteConfigService.instance.interstitialAdUnitId;
  }

  /// Get Native Ad Unit ID from Remote Config
  String get nativeAdUnitId {
    return RemoteConfigService.instance.nativeAdUnitId;
  }

  /// App Open Ad Unit ID (hardcoded for now)
  String get appOpenAdUnitId => 'ca-app-pub-3940256099942544/9257395921';

  /// Check if banner ads should be shown (from Remote Config)
  bool get shouldShowBannerAds {
    return RemoteConfigService.instance.showBannerAds;
  }

  /// Check if native ads should be shown (from Remote Config)
  bool get shouldShowNativeAds {
    return RemoteConfigService.instance.showNativeAds;
  }

  /// Check if interstitial ads should be shown (from Remote Config)
  bool get shouldShowInterstitialAds {
    return RemoteConfigService.instance.showInterstitialAds;
  }

  /// Get interstitial ad frequency from Remote Config
  int get interstitialAdFrequency {
    return RemoteConfigService.instance.interstitialAdFrequency;
  }

  /// Load a Banner Ad
  BannerAd createBannerAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    AdSize? size,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  /// Load an Interstitial Ad
  Future<InterstitialAd?> loadInterstitialAd() async {
    try {
      InterstitialAd? interstitialAd;
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            interstitialAd = ad;
            print('✅ Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            print('❌ Interstitial ad failed to load: $error');
          },
        ),
      );
      return interstitialAd;
    } catch (e) {
      print('❌ Error loading interstitial ad: $e');
      return null;
    }
  }

  /// Load a Native Ad
  NativeAd createNativeAd({
    required Function(Ad ad) onAdLoaded,
    required Function(Ad ad, LoadAdError error) onAdFailedToLoad,
    String factoryId = 'nativeAd',

  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: factoryId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  /// Dispose method
  void dispose() {
    _isInitialized = false;
  }
}

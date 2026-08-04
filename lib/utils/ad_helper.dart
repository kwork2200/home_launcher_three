import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Common Ad Helper class to manage all Google Ads throughout the app
class AdHelper {
  // Singleton pattern
  static final AdHelper _instance = AdHelper._internal();
  factory AdHelper() => _instance;
  AdHelper._internal();

  // Ad Unit IDs - Replace with your actual Ad Unit IDs
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      // For testing: 'ca-app-pub-3940256099942544/2247696110'
      // For production: Replace with your actual Native Ad Unit ID
      return 'ca-app-pub-3940256099942544/2247696110';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/3986624511';
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // For testing: 'ca-app-pub-3940256099942544/6300978111'
      // For production: Replace with your actual Banner Ad Unit ID
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    throw UnsupportedError('Unsupported platform');
  }

  /// Create a Native Ad instance
  NativeAd createNativeAd({
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    required Function(Ad) onAdLoaded,
  }) {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      factoryId: 'listTile', // Must match the ID in native code
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdClicked: (Ad ad) {
          print('Native Ad clicked');
        },
        onAdImpression: (Ad ad) {
          print('Native Ad impression');
        },
      ),
    );
  }

  /// Create a Banner Ad instance
  BannerAd createBannerAd({
    required Function(Ad, LoadAdError) onAdFailedToLoad,
    required Function(Ad) onAdLoaded,
    AdSize size = AdSize.banner,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
        onAdClicked: (Ad ad) {
          print('Banner Ad clicked');
        },
        onAdImpression: (Ad ad) {
          print('Banner Ad impression');
        },
      ),
    );
  }

  /// Dispose ad safely
  void disposeAd(Ad? ad) {
    ad?.dispose();
  }
}

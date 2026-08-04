import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

/// Manager for Google App Open Ads
/// Shows ads when user returns to the app from another app
class AppOpenAdManager {
  static AppOpenAdManager? _instance;
  static AppOpenAdManager get instance => _instance ??= AppOpenAdManager._();

  AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isLoadingAd = false;
  static bool _hasShownFirstLaunchAd = false;

  /// Load an App Open Ad
  Future<void> loadAd() async {
    if (_isLoadingAd || _appOpenAd != null) return;

    _isLoadingAd = true;
    final completer = Completer<void>();

    try {
      await AppOpenAd.load(
        adUnitId: AdService.instance.appOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoadingAd = false;
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToLoad: (error) {
            _isLoadingAd = false;
            _appOpenAd = null;
            if (!completer.isCompleted) completer.complete();
          },
        ),
      );
    } catch (e) {
      _isLoadingAd = false;
      _appOpenAd = null;
      if (!completer.isCompleted) completer.complete();
    }

    // Actual ad load ka wait karo, timeout ke saath
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoadingAd = false;
      },
    );
  }

  /// Show App Open Ad if available
  Future<void> showAdIfAvailable() async {
    if (_isShowingAd) {
      print('⏭️ App Open Ad already showing');
      return;
    }
    
    if (_appOpenAd == null) {
      print('⏭️ App Open Ad not loaded, attempting to load...');
      await loadAd();
      if (_appOpenAd != null) {
        await showAdIfAvailable();
      } else {
        print('⏭️ App Open Ad still not available after load attempt');
      }
      return;
    }
    
    _isShowingAd = true;

    try {
      _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          print('✅ App Open Ad shown');
        },
        onAdDismissedFullScreenContent: (ad) {
          print('✅ App Open Ad dismissed');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('❌ App Open Ad failed to show: $error');
          _isShowingAd = false;
          ad.dispose();
          _appOpenAd = null;
          loadAd();
        },
      );

      await _appOpenAd!.show();
    } catch (e) {
      print('❌ Error showing App Open Ad: $e');
      _isShowingAd = false;
      _appOpenAd = null;
      loadAd();
    }
  }

  /// Show App Open Ad for first launch (prevents duplicate calls)
  Future<void> showFirstLaunchAd() async {
    if (_hasShownFirstLaunchAd) {
      print('⏭️ First launch ad already shown, skipping');
      return;
    }
    
    print('🎯 Showing first launch App Open Ad');
    _hasShownFirstLaunchAd = true;
    await showAdIfAvailable();
  }

  /// Reset first launch flag (useful for testing)
  static void resetFirstLaunchFlag() {
    _hasShownFirstLaunchAd = false;
  }

  /// Check if ad is ready to show
  bool get isAdReady => _appOpenAd != null && !_isShowingAd;

  /// Dispose resources
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}

import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Manager for Google AdMob Interstitial Ads
/// Simple load and show mechanism
class GoogleInterstitialAdManager {
  static GoogleInterstitialAdManager? _instance;
  static GoogleInterstitialAdManager get instance =>
      _instance ??= GoogleInterstitialAdManager._();

  GoogleInterstitialAdManager._();

  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  DateTime? _lastAdShownTime;
  static const Duration _adCooldown = Duration(seconds: 30); // 30 seconds cooldown

  // Test Ad Unit ID - Replace with your actual Ad Unit ID for production
  // Android Test: ca-app-pub-3940256099942544/1033173712
  // iOS Test: ca-app-pub-3940256099942544/4411468910
  static const String _adUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// Check if ad is ready to show
  bool get isAdReady => _isAdLoaded && _interstitialAd != null;

  /// Get current ad loaded status for debugging
  String get adStatus => _isAdLoaded && _interstitialAd != null
      ? '✅ Google Ad Loaded & Ready'
      : _isAdLoading
          ? '⏳ Google Ad Loading...'
          : '❌ No Google Ad Loaded';

  /// Load Google Interstitial Ad
  Future<void> loadAd() async {
    if (_isAdLoaded && _interstitialAd != null) {
      print('⏭️ Google Interstitial ad already loaded');
      return;
    }

    if (_isAdLoading) {
      print('⏳ Google Interstitial ad is already loading');
      return;
    }

    _isAdLoading = true;
    print('🔄 Starting to load Google Interstitial ad...');

    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('✅ Google Interstitial ad loaded successfully - ready to show');
            _interstitialAd = ad;
            _isAdLoaded = true;
            _isAdLoading = false;
            _setAdCallbacks();
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('❌ Google Interstitial ad failed to load: ${error.message}');
            _interstitialAd = null;
            _isAdLoaded = false;
            _isAdLoading = false;
          },
        ),
      );
    } catch (e) {
      print('❌ Error loading Google Interstitial ad: $e');
      _interstitialAd = null;
      _isAdLoaded = false;
      _isAdLoading = false;
    }
  }

  /// Set ad callbacks
  void _setAdCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        print('📺 Google Interstitial ad showed full screen');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('✅ Google Interstitial ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        // Preload next ad
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('❌ Google Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        // Preload next ad
        loadAd();
      },
    );
  }

  /// Show Google Interstitial Ad ALWAYS
  /// If ad is not loaded, it will try to load and show, or continue after timeout
  /// Returns only after ad is closed or failed/timeout
  Future<void> showAdAlways() async {
    print('🎯 Attempting to show Google Interstitial ad ALWAYS');
    print('📊 Current Status: $adStatus');

    if (_isAdLoaded && _interstitialAd != null) {
      print('📺 Showing Google Interstitial ad');
      try {
        final completer = Completer<void>();
        
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdShowedFullScreenContent: (InterstitialAd ad) {
            print('📺 Google Interstitial ad showed full screen');
          },
          onAdDismissedFullScreenContent: (InterstitialAd ad) {
            print('✅ Google Interstitial ad dismissed by user');
            ad.dispose();
            _interstitialAd = null;
            _isAdLoaded = false;
            // Preload next ad
            loadAd();
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
            print('❌ Google Interstitial ad failed to show: ${error.message}');
            ad.dispose();
            _interstitialAd = null;
            _isAdLoaded = false;
            // Preload next ad
            loadAd();
            if (!completer.isCompleted) completer.complete();
          },
        );
        
        await _interstitialAd!.show();
        print('✅ Google Interstitial ad show() called, waiting for user to close...');
        
        // Wait for ad to be dismissed
        await completer.future;
        print('✅ Ad closed, continuing...');
      } catch (e) {
        print('❌ Error showing Google Interstitial ad: $e');
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _isAdLoaded = false;
        loadAd();
      }
    } else if (_isAdLoading) {
      print('⏳ Ad is loading, waiting up to 5 seconds...');
      // Wait for up to 5 seconds for the ad to load
      final startTime = DateTime.now();
      while (_isAdLoading &&
          DateTime.now().difference(startTime).inSeconds < 5) {
        await Future.delayed(const Duration(milliseconds: 200));
      }

      if (_isAdLoaded && _interstitialAd != null) {
        print('✅ Ad loaded while waiting, showing now...');
        // Recursively call to show the loaded ad
        await showAdAlways();
      } else {
        print('⏱️ Ad loading timeout - continuing without ad');
        loadAd(); // Try loading for next time
      }
    } else {
      print('⚠️ Google Interstitial ad not ready, attempting quick load...');

      // Try to load and show quickly
      final completer = Completer<void>();
      var adShown = false;

      try {
        await InterstitialAd.load(
          adUnitId: _adUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) async {
              print('✅ Quick load successful, showing now...');
              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdShowedFullScreenContent: (InterstitialAd ad) {
                  print('📺 Quick loaded ad showed full screen');
                },
                onAdDismissedFullScreenContent: (InterstitialAd ad) {
                  print('✅ Quick loaded ad dismissed by user');
                  ad.dispose();
                  loadAd(); // Preload for next time
                  if (!completer.isCompleted) completer.complete();
                },
                onAdFailedToShowFullScreenContent:
                    (InterstitialAd ad, AdError error) {
                  print('❌ Quick loaded ad failed to show: ${error.message}');
                  ad.dispose();
                  loadAd();
                  if (!completer.isCompleted) completer.complete();
                },
              );

              try {
                await ad.show();
                adShown = true;
                print('✅ Quick loaded ad show() called, waiting for user to close...');
                // Wait for ad to be dismissed
                await completer.future;
                print('✅ Quick loaded ad closed, continuing...');
              } catch (e) {
                print('❌ Error showing quick loaded ad: $e');
                ad.dispose();
                if (!completer.isCompleted) completer.complete();
              }
            },
            onAdFailedToLoad: (LoadAdError error) {
              print('❌ Quick load failed: ${error.message}');
              if (!completer.isCompleted) completer.complete();
            },
          ),
        );

        // Wait for load/show with timeout
        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⏱️ Quick load timeout - continuing without ad');
          },
        );
      } catch (e) {
        print('❌ Error in quick load attempt: $e');
      }

      // Load for next time if we didn't show an ad
      if (!adShown) {
        loadAd();
      }
    }
  }

  /// Dispose the ad
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdLoaded = false;
    _isAdLoading = false;
  }
}

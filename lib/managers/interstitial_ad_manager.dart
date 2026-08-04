import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';

/// Manager for Interstitial Ads with real-time Remote Config updates
/// Supports both Google Ads and Facebook Ads with fallback logic
class InterstitialAdManager {
  static InterstitialAdManager? _instance;
  static InterstitialAdManager get instance => _instance ??= InterstitialAdManager._();

  InterstitialAdManager._() {
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _handleConfigUpdate();
    });
  }

  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _isFbAdLoaded = false;
  int _screenCounter = 0;
  StreamSubscription? _configSubscription;

  void _handleConfigUpdate() {
    final shouldShow = AdService.instance.shouldShowInterstitialAds;
    final shouldShowFb = FbAdService.instance.shouldShowInterstitialAds;
    
    if (!shouldShow && !shouldShowFb) {
      print('🚫 All interstitial ads disabled via Remote Config');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdLoading = false;
      _isFbAdLoaded = false;
    } else {
      print('📢 Interstitial ads enabled via Remote Config');
      // Load both if enabled, but prioritize Google
      if (shouldShow && _interstitialAd == null && !_isAdLoading) {
        loadAd();
      }
      if (shouldShowFb && !_isFbAdLoaded) {
        _loadFacebookAd();
      }
    }
  }

  int get _adFrequency => AdService.instance.interstitialAdFrequency;

  /// Get current screen counter for external frequency checks
  int get screenCounter => _screenCounter;

  /// Reset screen counter (used after showing third-party ads)
  void resetCounter() {
    _screenCounter = 0;
  }

  /// Check if frequency allows showing ad (without incrementing counter)
  bool shouldShowAdByFrequency() {
    return (_screenCounter + 1) % _adFrequency == 0;
  }

  /// Increment counter manually (for third-party ads)
  void incrementCounter() {
    _screenCounter++;
  }

  /// Check if any ad (Google or Facebook) is ready to show
  bool get isAdReady {
    final googleReady = AdService.instance.shouldShowInterstitialAds && _interstitialAd != null;
    final facebookReady = FbAdService.instance.shouldShowInterstitialAds && _isFbAdLoaded;
    return googleReady || facebookReady;
  }

  /// Load the interstitial ad - Prioritize Google Ads first, then Facebook as fallback
  Future<void> loadAd() async {
    // Priority 1: Try loading Google Ads if enabled
    if (AdService.instance.shouldShowInterstitialAds) {
      if (_isAdLoading || _interstitialAd != null) {
        print('⏭️ Google ad already loading or loaded');
      } else {
        _loadGoogleAd();
      }
    } else {
      print('⏭️ Google ads disabled via Remote Config');
    }
    
    // Priority 2: Also load Facebook Ads as fallback if enabled
    if (FbAdService.instance.shouldShowInterstitialAds) {
      if (!_isFbAdLoaded) {
        _loadFacebookAd();
      } else {
        print('⏭️ Facebook ad already loaded');
      }
    } else {
      print('⏭️ Facebook ads disabled via Remote Config');
    }
  }

  /// Load Google Interstitial Ad
  Future<void> _loadGoogleAd() async {
    if (_isAdLoading || _interstitialAd != null) return;
    _isAdLoading = true;
    
    try {
      await InterstitialAd.load(
        adUnitId: AdService.instance.interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isAdLoading = false;
            print('✅ Google Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            print('❌ Google Interstitial ad failed to load: $error');
            _isAdLoading = false;
            _interstitialAd = null;
            // Fallback to Facebook Ads if not already loaded
            if (FbAdService.instance.shouldShowInterstitialAds && !_isFbAdLoaded) {
              print('🔄 Google ads failed, loading Facebook ads as fallback');
              _loadFacebookAd();
            }
          },
        ),
      );
    } catch (e) {
      print('❌ Error loading Google interstitial ad: $e');
      _isAdLoading = false;
      // Fallback to Facebook Ads if not already loaded
      if (FbAdService.instance.shouldShowInterstitialAds && !_isFbAdLoaded) {
        print('🔄 Google ads error, loading Facebook ads as fallback');
        _loadFacebookAd();
      }
    }
  }

  /// Load Facebook Interstitial Ad
  Future<void> _loadFacebookAd() async {
    if (_isFbAdLoaded) return;
    try {
      final loaded = await FbAdService.instance.loadInterstitialAd();
      _isFbAdLoaded = loaded;
      if (loaded) {
        print('✅ Facebook Interstitial ad loaded');
      }
    } catch (e) {
      print('❌ Error loading Facebook interstitial ad: $e');
      _isFbAdLoaded = false;
    }
  }

  /// Show interstitial ad on screen enter (with frequency control)
  /// Priority: 1. Google Ads (if enabled), 2. Facebook Ads (fallback), 3. Third-party (if both disabled)
  /// Falls back to third-party ads if both networks are disabled
  /// 
  /// Returns true if ad should be shown (including third-party ads)
  /// Caller should handle third-party ad display if both Google/Facebook are disabled
  Future<bool> showAdIfAvailable() async {
    try {
      debugPrint('🎯 showAdIfAvailable called');
      
      // Check if ANY ad network is enabled
      final bool googleEnabled = AdService.instance.shouldShowInterstitialAds;
      final bool facebookEnabled = FbAdService.instance.shouldShowInterstitialAds;
      
      // Increment counter FIRST for all ad types (Google, Facebook, Third-party)
      _screenCounter++;
      
      if (!googleEnabled && !facebookEnabled) {
        print('🚫 Both Google and Facebook ads disabled, checking third-party ad frequency');
        if (_screenCounter % _adFrequency != 0) {
          print('⏭️ Skipping third-party ad (counter: $_screenCounter, frequency: $_adFrequency)');
          return false; // Don't show ad
        }
        print('✅ Third-party ad frequency check passed');
        _screenCounter = 0;
        // Return true to indicate caller should show third-party ad
        return true;
      }

      if (_screenCounter % _adFrequency != 0) {
        print('⏭️ Skipping ad (counter: $_screenCounter, frequency: $_adFrequency)');
        return false;
      }

      debugPrint('📺 Ad frequency check passed, attempting to show ad');

      // Priority 1: Google Ads are ENABLED - try Google first
      if (googleEnabled && _interstitialAd != null) {
        print('📺 Showing Google interstitial ad (Priority 1)');
        final completer = Completer<bool>();
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('✅ Google ad dismissed');
            ad.dispose();
            _interstitialAd = null;
            _screenCounter = 0;
            _loadGoogleAd(); // Preload next Google ad only
            if (!completer.isCompleted) completer.complete(true);
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('❌ Google ad failed to show: $error');
            ad.dispose();
            _interstitialAd = null;
            _screenCounter = 0;
            // Fallback to Facebook if available
            if (facebookEnabled && _isFbAdLoaded) {
              print('🔄 Google ad failed, showing Facebook ad as fallback');
              if (!completer.isCompleted) _completeWithFacebookAd(completer);
            } else {
              if (!completer.isCompleted) completer.complete(false);
              loadAd();
            }
          },
          onAdShowedFullScreenContent: (ad) {
            debugPrint('✅ Google ad shown');
          },
        );

        await _interstitialAd!.show();
        return await completer.future;
      }

      // Priority 3: Google Ads disabled or not loaded, try Facebook as fallback
      if (facebookEnabled && _isFbAdLoaded) {
        print('📺 Showing Facebook interstitial ad (fallback)');
        try {
          await FbAdService.instance.showInterstitialAd();
          _isFbAdLoaded = false;
          _screenCounter = 0;
          _loadFacebookAd(); // Preload next ad
          debugPrint('✅ Facebook ad completed successfully');
          return true;
        } catch (e) {
          debugPrint('❌ Facebook ad error: $e');
          _isFbAdLoaded = false;
          _screenCounter = 0;
          return false;
        }
      }

      // Priority 4: Neither Google nor Facebook ready, load and return false
      print('⚠️ No ad ready, loading for next time...');
      _screenCounter = 0;
      await loadAd();
      return false;
    } catch (e) {
      debugPrint('❌ Error in showAdIfAvailable: $e');
      _screenCounter = 0;
      return false;
    }
  }

  Future<void> _completeWithFacebookAd(Completer<bool> completer) async {
    try {
      await FbAdService.instance.showInterstitialAd();
      _isFbAdLoaded = false;
      _screenCounter = 0;
      _loadFacebookAd();
      if (!completer.isCompleted) completer.complete(true);
    } catch (e) {
      debugPrint('❌ Fallback Facebook ad error: $e');
      _isFbAdLoaded = false;
      _screenCounter = 0;
      if (!completer.isCompleted) completer.complete(false);
    }
  }

  Future<void> _completeWithFacebookAdVoid(Completer<void> completer) async {
    try {
      await FbAdService.instance.showInterstitialAd();
      _isFbAdLoaded = false;
      _loadFacebookAd();
      if (!completer.isCompleted) completer.complete();
    } catch (e) {
      debugPrint('❌ Fallback Facebook ad error: $e');
      _isFbAdLoaded = false;
      if (!completer.isCompleted) completer.complete();
    }
  }

  /// Show interstitial ad on back navigation — ALWAYS shows if ad is ready
  /// Only shows ONE ad per call - Google priority, Facebook fallback only if Google fails
  Future<void> showAdOnBack() async {
    final googleReady = AdService.instance.shouldShowInterstitialAds && _interstitialAd != null;
    final facebookReady = FbAdService.instance.shouldShowInterstitialAds && _isFbAdLoaded;

    if (googleReady) {
      print('📺 Showing Google interstitial ad on back navigation');
      try {
        final completer = Completer<void>();
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _loadGoogleAd();
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            if (facebookReady) {
              print('🔄 Google ad failed to show, showing Facebook as fallback');
              if (!completer.isCompleted) _completeWithFacebookAdVoid(completer);
            } else {
              if (!completer.isCompleted) completer.complete();
              loadAd();
            }
          },
        );
        await _interstitialAd!.show();
        await completer.future;
        print('✅ Google ad dismissed');
      } catch (e) {
        print('❌ Error showing Google ad on back: $e');
        _interstitialAd = null;
        // Only fallback to Facebook if Google ad errors
        if (facebookReady) {
          print('🔄 Google ad error, showing Facebook as fallback');
          try {
            await FbAdService.instance.showInterstitialAd();
            _isFbAdLoaded = false;
            loadAd();
            print('✅ Facebook fallback ad dismissed');
          } catch (fbError) {
            print('❌ Facebook fallback ad error: $fbError');
            _isFbAdLoaded = false;
            loadAd();
          }
        } else {
          loadAd();
        }
      }
    } else if (facebookReady) {
      print('📺 Showing Facebook interstitial ad on back navigation (Google not ready)');
      try {
        await FbAdService.instance.showInterstitialAd();
        _isFbAdLoaded = false;
        loadAd();
        print('✅ Facebook ad dismissed');
      } catch (e) {
        print('❌ Error showing Facebook ad on back: $e');
        _isFbAdLoaded = false;
        loadAd();
      }
    } else {
      print('⚠️ No ad ready (back) — navigating without ad');
      loadAd();
    }
  }

  /// Show interstitial ad ALWAYS without frequency control
  /// Only shows ONE ad per call - Google priority, Facebook fallback only if Google fails
  Future<void> showAdAlways() async {
    print('🎯 Attempting to show ad ALWAYS (no frequency control)');
    
    final googleReady = AdService.instance.shouldShowInterstitialAds && _interstitialAd != null;
    final facebookReady = FbAdService.instance.shouldShowInterstitialAds && _isFbAdLoaded;

    if (googleReady) {
      print('📺 Showing Google interstitial ad');
      try {
        final completer = Completer<void>();
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            // Only reload ads, don't show Facebook ad as fallback after successful Google ad
            _loadGoogleAd(); // Preload next Google ad only
            if (!completer.isCompleted) completer.complete();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            // Only fallback to Facebook if Google ad fails to show
            if (facebookReady) {
              print('🔄 Google ad failed to show, showing Facebook as fallback');
              if (!completer.isCompleted) _completeWithFacebookAdVoid(completer);
            } else {
              if (!completer.isCompleted) completer.complete();
              loadAd();
            }
          },
        );
        await _interstitialAd!.show();
        await completer.future;
        print('✅ Google ad completed successfully');
      } catch (e) {
        print('❌ Error showing Google ad: $e');
        _interstitialAd = null;
        // Only fallback to Facebook if Google ad errors
        if (facebookReady) {
          print('🔄 Google ad error, showing Facebook as fallback');
          try {
            await FbAdService.instance.showInterstitialAd();
            _isFbAdLoaded = false;
            loadAd();
            print('✅ Facebook fallback ad completed successfully');
          } catch (fbError) {
            print('❌ Facebook fallback ad error: $fbError');
            _isFbAdLoaded = false;
            loadAd();
          }
        } else {
          loadAd();
        }
      }
    } else if (facebookReady) {
      print('📺 Showing Facebook interstitial ad (Google not ready)');
      try {
        await FbAdService.instance.showInterstitialAd();
        _isFbAdLoaded = false;
        loadAd();
        print('✅ Facebook ad completed successfully');
      } catch (e) {
        print('❌ Error showing Facebook ad: $e');
        _isFbAdLoaded = false;
        loadAd();
      }
    } else {
      print('⚠️ No ad ready, attempting to load and show...');
      await loadAd();
    }
  }

  void dispose() {
    _configSubscription?.cancel();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isFbAdLoaded = false;
    FbAdService.instance.destroyInterstitialAd();
  }
}
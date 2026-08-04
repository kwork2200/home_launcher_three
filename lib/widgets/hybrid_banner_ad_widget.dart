import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';
import 'custom_banner_ad.dart';
import 'fb_banner_ad_widget.dart';
import 'third_party_image_ad.dart';

/// Hybrid Banner Ad Widget - Shows Facebook or Google ads based on Remote Config
class HybridBannerAdWidget extends StatefulWidget {
  const HybridBannerAdWidget({super.key});

  @override
  State<HybridBannerAdWidget> createState() => _HybridBannerAdWidgetState();
}

class _HybridBannerAdWidgetState extends State<HybridBannerAdWidget> {
  StreamSubscription? _configSubscription;
  bool _showGoogleAds = false;
  bool _showFacebookAds = false;

  @override
  void initState() {
    super.initState();
    _updateAdPreferences();

    // Listen to Remote Config changes
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _updateAdPreferences();
    });
  }

  void _updateAdPreferences() {
    setState(() {
      _showGoogleAds = AdService.instance.shouldShowBannerAds;
      // Show Facebook ads if Google ads are disabled
      _showFacebookAds = !AdService.instance.shouldShowBannerAds && FbAdService.instance.shouldShowBannerAds;
    });
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Priority 1: Try Google Ads first if enabled
    if (_showGoogleAds) {
      return const CustomBannerAd();
    }

    // Priority 2: Try Facebook Ads if Google is disabled
    if (FbAdService.instance.shouldShowBannerAds) {
      return const FbBannerAdWidget();
    }

    // Priority 3: Show third-party image ad if enabled in Remote Config
    final showThirdPartyAd = RemoteConfigService.instance.showThirdPartyBannerAds;
    if (showThirdPartyAd) {
      return const ThirdPartyImageAd(
        height: 50,
        isNativeSize: false,
        margin: EdgeInsets.zero,
      );
    }

    return const SizedBox.shrink();
  }
}
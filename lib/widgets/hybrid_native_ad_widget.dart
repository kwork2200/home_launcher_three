import 'package:flutter/material.dart';
import 'dart:async';
import '../services/ad_service.dart';
import '../services/fb_ad_service.dart';
import '../services/remote_config_service.dart';
import 'custom_native_ad.dart';
import 'fb_native_ad_widget.dart';
import 'third_party_image_ad.dart';

class HybridNativeAdWidget extends StatefulWidget {
  final double height;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const HybridNativeAdWidget({
    super.key,
    this.height = 150,
    this.margin,
    this.padding,
  });

  @override
  State<HybridNativeAdWidget> createState() => _HybridNativeAdWidgetState();
}

class _HybridNativeAdWidgetState extends State<HybridNativeAdWidget> {
  StreamSubscription? _configSubscription;
  bool _showGoogleAds = false;
  bool _showFacebookAds = false;

  @override
  void initState() {
    super.initState();
    _updateAdPreferences();
    _configSubscription = RemoteConfigService.instance.configUpdates.listen((_) {
      _updateAdPreferences();
    });
  }

  void _updateAdPreferences() {
    setState(() {
      _showGoogleAds = AdService.instance.shouldShowNativeAds;
      // Show Facebook ads if Google ads are disabled
      _showFacebookAds = !AdService.instance.shouldShowNativeAds && FbAdService.instance.shouldShowNativeAds;
      
      print('🔀 HybridNativeAd: Google=$_showGoogleAds, FB=$_showFacebookAds');
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
      return CustomNativeAd(
        height: 300,
          size: NativeAdSize.large
      );
    }

    if (FbAdService.instance.shouldShowNativeAds) {
      return FbNativeAdWidget(
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
      );
    }

    // Priority 3: Show third-party image ad if enabled in Remote Config
    final showThirdPartyAd = RemoteConfigService.instance.showThirdPartyNativeAds;
    if (showThirdPartyAd) {
      return ThirdPartyImageAd(
        height: widget.height,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
        padding: widget.padding,
        isNativeSize: true,
      );
    }
    return const SizedBox.shrink();
  }
}
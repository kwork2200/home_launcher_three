import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../main.dart';
import '../managers/google_interstitial_ad_manager.dart';
import '../managers/app_open_ad_manager.dart';
import '../services/install_referrer_service.dart';
import '../services/remote_config_service.dart';
import '../services/screen_analytics_service.dart';
import 'onboarding_screen.dart';
import 'language_selection_screen.dart';
import 'no_text_screen.dart';
import 'leftSideView.dart';
import '../modules/home/home_screen.dart';

class FirstLaunchFlowScreen extends StatefulWidget {
  const FirstLaunchFlowScreen({super.key});

  @override
  State<FirstLaunchFlowScreen> createState() => _FirstLaunchFlowScreenState();
}

class _FirstLaunchFlowScreenState extends State<FirstLaunchFlowScreen> with WidgetsBindingObserver {
  bool _isLoadingAd = false;
  bool _waitingForUserReturn = false;
  SharedPreferences? _prefs;
  bool? _isReferralUserCache;

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('first_launch_screen');
    WidgetsBinding.instance.addObserver(this);
    _checkFirstLaunchStatus();
    _preloadReferralCheck();
  }

  Future<void> _preloadReferralCheck() async {
    _isReferralUserCache = await InstallReferrerService.isReferralUser();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Detect when user returns from browser
    if (state == AppLifecycleState.resumed && _waitingForUserReturn) {
      _waitingForUserReturn = false;
      _completeFirstLaunch();
    }
  }

  Future<void> _checkFirstLaunchStatus() async {
    _prefs = await SharedPreferences.getInstance();
    final hasCompletedFirstLaunch = _prefs!.getBool('first_launch_completed') ?? false;

    if (hasCompletedFirstLaunch) {
      // If first launch already completed, skip this screen entirely and go to home
      await _navigateToActualHome();
    } else {
      await _showAdAndComplete();
    }
  }

  Future<void> _showAdAndComplete() async {
    debugPrint("🎯 Showing App Open Ad...");
    // Show the App Open Ad for first launch - don't block with setState
    unawaited(AppOpenAdManager.instance.showFirstLaunchAd().then((_) {
      debugPrint("✅ App Open Ad dismissed - completing first launch");
      _completeFirstLaunch();
    }));
  }

  Future<void> _completeFirstLaunch() async {
    debugPrint("✅ Completing first launch - navigating to actual home");
    await _prefs!.setBool('first_launch_completed', true);
    await _navigateToActualHome();
  }

  Future<void> _navigateToActualHome() async {
    if (mounted) {
      final remoteConfig = RemoteConfigService.instance;
      final isDefault = await LauncherHelper.isDefaultLauncher();
      debugPrint("🏠 Default launcher status: $isDefault");

      final hasCompletedOnboarding = _prefs!.getBool('onboarding_completed') ?? false;
      final showOnboarding = remoteConfig.showOnboarding;
      
      if (showOnboarding && !hasCompletedOnboarding) {
        if (isDefault) {
          debugPrint("🏠 Already default launcher - skipping onboarding");
        } else {
          debugPrint("🏠 Onboarding enabled and not completed - navigating to OnboardingScreen");
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const OnboardingScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
          return;
        }
      }

      final hasCompletedLanguageSelection = _prefs!.getBool('language_selection_completed') ?? false;
      final showLanguageScreen = remoteConfig.showLanguageScreen;

      if (showLanguageScreen && !hasCompletedLanguageSelection) {
        if (isDefault) {
          debugPrint("🏠 Already default launcher - skipping language screen");
        } else {
          debugPrint("🏠 Language screen enabled and not completed - navigating to LanguageSelectionScreen");
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const LanguageSelectionScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
          return;
        }
      }

      final showHomePage = remoteConfig.showHomePage;

      if (!showHomePage) {
        if (isDefault) {
          debugPrint("🏠 Already default launcher - skipping NoTextScreen, going to home");
        } else {
          debugPrint("🏠 Home page disabled - navigating to NoTextScreen");
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const NoTextScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
            (route) => false,
          );
          return;
        }
      }

      final isReferralUser = _isReferralUserCache ?? await InstallReferrerService.isReferralUser();
      debugPrint("🏠 Navigating to actual home screen. Is referral user: $isReferralUser");
      
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => isReferralUser 
              ? const MainMenuScreen() 
              : const MyHomePage(),
          transitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false, // Disable back button
        child: Scaffold(
          backgroundColor: const Color(0xFF141414),
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: Color(0xFFf84241)),
                  SizedBox(height: 20),
                  Text(
                    'Please wait...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
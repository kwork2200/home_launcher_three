  import 'package:home_launcher_three/screens/call_screen.dart';
import 'package:home_launcher_three/screens/first_launch_flow_screen.dart';
  import 'package:home_launcher_three/screens/onboarding_screen.dart';
  import 'package:home_launcher_three/screens/leftSideView.dart';
  import 'package:home_launcher_three/screens/right_view_screen.dart';
  import 'package:home_launcher_three/screens/search_settings_screen.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:installed_apps/app_info.dart';
  import 'package:installed_apps/installed_apps.dart';
  import 'widget_manager.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'app_usage_tracker.dart';
  import 'sort_options.dart';
  import 'app_sections.dart';
  import 'package:flutter/foundation.dart' show listEquals, unawaited;
  import 'dart:convert' show jsonDecode, jsonEncode;
  import 'dart:io' show Platform;
  import 'notification_service.dart';
  import 'auth_service.dart';
  import 'navigation_state.dart';
  import 'hidden_apps_manager.dart';
  import 'live_widget_preview.dart';
  import 'database/app_database.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'layouts/app_layout_switcher.dart';
  import 'layouts/app_layout_manager.dart';
  import 'dart:async';
  import 'app_package_manager.dart';
  import 'models/folder.dart';
  import 'package:flutter_screenutil/flutter_screenutil.dart';
  import 'package:get/get.dart';
  import 'app_library_view.dart';
  import 'security_check_service.dart';
  import 'package:google_mobile_ads/google_mobile_ads.dart';
  import 'managers/interstitial_ad_manager.dart';
  import 'managers/app_open_ad_manager.dart';
  import 'widgets/hybrid_banner_ad_widget.dart';
  import 'widgets/hybrid_native_ad_widget.dart';
  import 'services/remote_config_service.dart';
  import 'services/fb_ad_service.dart';
  import 'services/ad_service.dart';
  import 'services/install_referrer_service.dart';
  import 'modules/home/home_screen.dart';
import 'services/call_detection_service.dart';
import 'routes/app_pages.dart';
import 'package:firebase_core/firebase_core.dart';
  class AdFlowState {
    static bool suppressAppOpenAdOnNextResume = false;
    static bool adsInitialized = false;
  }
  const String _selfPackageName = 'com.kayfahaarukku.homelauncherthree';

  Future<List<AppInfo>> _filterApps(List<AppInfo> apps) async {
    // Step 1: remove self
    final withoutSelf =
    apps.where((app) => app.packageName != _selfPackageName).toList();

    // Step 2: check system-app status in parallel, filter out true ones
    final results = await Future.wait(
      withoutSelf.map((app) async {
        try {
          final isSystem = await InstalledApps.isSystemApp(app.packageName);
          return MapEntry(app, isSystem ?? false);
        } catch (e) {
          // If check fails, assume it's NOT a system app (safer to show than hide by mistake)
          return MapEntry(app, false);
        }
      }),
    );

    return results.where((entry) => entry.value == false).map((e) => e.key).toList();
  }
  List<AppInfo> _excludeSelf(List<AppInfo> apps) {
    return apps.where((app) => app.packageName != _selfPackageName).toList();
  }
  class LauncherHelper {
    static const _channel = MethodChannel('com.kayfahaarukku.homelauncherthree/launcher');

    static Future<bool> requestSetAsDefaultLauncher() async {
      try {
        final result = await _channel.invokeMethod('requestHomeRole');
        return result == true;
      } on PlatformException catch (e) {
        debugPrint('Error requesting home role: ${e.message}');
        return false;
      }
    }

    static Future<void> openHomeSettingsPage() async {
      try {
        await _channel.invokeMethod('openHomeSettings');
      } on PlatformException catch (e) {
        debugPrint('Error opening home settings: ${e.message}');
      }
    }

    static Future<bool> isDefaultLauncher() async {
      try {
        final result = await _channel.invokeMethod('isDefaultLauncher');
        return result == true;
      } on PlatformException catch (e) {
        debugPrint('Error checking default launcher: ${e.message}');
        return false;
      }
    }

    static Future<void> initializeAdsIfDefaultLauncher() async {
      final isDefault = await isDefaultLauncher();
      print('🏠 Checking default launcher status for ad initialization: $isDefault');

      if (isDefault && !AdFlowState.adsInitialized) {
        print('🚀 Initializing ads - app is default launcher');
        unawaited(InterstitialAdManager.instance.loadAd());
        print('🚀 Starting AppOpenAd load...');
        unawaited(AppOpenAdManager.instance.loadAd());
        AdFlowState.adsInitialized = true;
      } else if (!isDefault) {
        print('⏭️ Skipping ad initialization - app is not default launcher');
      } else {
        print('⏭️ Ads already initialized');
      }
    }
  }

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase and Remote Config first
    await Firebase.initializeApp();
    await RemoteConfigService.instance.initialize();
    await AdService.instance.initialize();
    await FbAdService.instance.initialize();

    // Optimize UI setup
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await LauncherHelper.initializeAdsIfDefaultLauncher();

    // Set up system UI callback after app starts
    if (Platform.isAndroid) {
      SystemChrome.setSystemUIChangeCallback((systemOverlaysAreVisible) async {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        return;
      });
    }

    runApp(const MyApp());
  }

  class MyApp extends StatefulWidget {
    const MyApp({super.key});

    @override
    State<MyApp> createState() => _MyAppState();
  }

  class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
    bool _wasInBackground = false;
    bool _isFirstResume = true;

    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
    }

    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      super.dispose();
    }

    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);

      if (state == AppLifecycleState.inactive ||
          state == AppLifecycleState.paused) {
        _wasInBackground = true;
      } else if (state == AppLifecycleState.resumed) {
        if (_wasInBackground) {
          if (AdFlowState.suppressAppOpenAdOnNextResume) {
            // This resume came from launching an app via the launcher —
            // GoogleInterstitialAd already handles it, skip AppOpenAd.
            AdFlowState.suppressAppOpenAdOnNextResume = false;
          } else {
            print('🏠 App resumed from background, showing AppOpenAd');
            AppOpenAdManager.instance.showAdIfAvailable();
          }
          _wasInBackground = false;
        }
        _isFirstResume = false;
      }
    }

    @override
    Widget build(BuildContext context) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return GetMaterialApp(
            navigatorKey: CallDetectionService().navigatorKey,
            title: 'FuseLauncher',
            getPages: AppPages.pages,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6750A4), // Primary purple color
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.light().textTheme,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
                iconTheme: const IconThemeData(color: Color(0xFF6750A4)),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6750A4),
                ),
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFD0BCFF), // Lighter purple for dark mode
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              textTheme: GoogleFonts.poppinsTextTheme(
                ThemeData.dark().textTheme,
              ),
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: const Color(0xFF2D2D2D),
              ),
              appBarTheme: AppBarTheme(
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent, //
                iconTheme: const IconThemeData(color: Color(0xFFD0BCFF)),
                titleTextStyle: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD0BCFF),
                ),
              ),
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: const Color(0xFF1E1E1E),
              ),
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFF2D2D2D),
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            themeMode: ThemeMode.system,
            debugShowCheckedModeBanner: false,
            home: const AppInitializer(),
          );
        },
      );
    }
  }
  
  class AppInitializer extends StatefulWidget {
    const AppInitializer({super.key});
  
    @override
    State<AppInitializer> createState() => _AppInitializerState();
  }
  
  class _AppInitializerState extends State<AppInitializer> {
    @override
    void initState() {
      super.initState();
      _initializeApp();
    }
  
    Future<void> _initializeApp() async {
      CallDetectionService().initialize();
      // await _openSystemDefaultDialog();
      //
      // // Check security status FIRST before anything else
      // final securityStatus = await SecurityCheckService.checkSecurityStatus();
      //
      // if (securityStatus['developerOptionsEnabled'] == true ||
      //     securityStatus['dnsEnabled'] == true) {
      //   if (mounted) {
      //     _showSecurityWarning(securityStatus);
      //   }
      //   return; // Don't proceed with first launch/onboarding if security issues exist
      // }
      _checkFirstLaunchAndOnboarding();
    }
  
    Future<void> _checkFirstLaunchAndOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
  
      // Check if first launch flow (ads + link) is completed
      final hasCompletedFirstLaunch = prefs.getBool('first_launch_completed') ?? false;
  
      if (!hasCompletedFirstLaunch) {
        // First time opening app - show FirstLaunchFlowScreen (ads + link)
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FirstLaunchFlowScreen(),
            ),
          );
        }
        return;
      }
      final hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
  
      if (!hasCompletedOnboarding) {
        debugPrint('DEBUG: Onboarding not completed - showing OnboardingScreen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const OnboardingScreen(),
            ),
          );
        }
        return;
      }
      final isReferralUser = await InstallReferrerService.isReferralUser();
      debugPrint('DEBUG: isReferralUser = $isReferralUser');
  
      if (mounted) {
        if (isReferralUser) {
          // User came from referral link - go to MainMenuScreen
          debugPrint('DEBUG: Referral user - navigating to MainMenuScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MainMenuScreen(),
            ),
          );
        } else {
          // Normal user - go to MyHomePage
          debugPrint('DEBUG: Normal user - navigating to MyHomePage');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const MyHomePage(),
            ),
          );
        }
      }
    }
  
    Future<void> _openSystemDefaultDialog() async {
      final prefs = await SharedPreferences.getInstance();
      final hasShownDefaultDialog = prefs.getBool('default_dialog_shown') ?? false;
  
      debugPrint('DEBUG: hasShownDefaultDialog = $hasShownDefaultDialog');
  
      if (!hasShownDefaultDialog) {
        debugPrint('DEBUG: Calling requestSetAsDefaultLauncher');
        LauncherHelper.requestSetAsDefaultLauncher();
        await prefs.setBool('default_dialog_shown', true);
        debugPrint('DEBUG: Set default_dialog_shown to true');
        
        // Check if app is now default launcher and initialize ads if so
        await LauncherHelper.initializeAdsIfDefaultLauncher();
      } else {
        debugPrint('DEBUG: Dialog already shown before, skipping');
        // Even if dialog was shown before, check if app is now default launcher
        await LauncherHelper.initializeAdsIfDefaultLauncher();
      }
    }
  
    Future<void> _recheckSecurity() async {
      final securityStatus = await SecurityCheckService.checkSecurityStatus();
  
      if (securityStatus['developerOptionsEnabled'] == true ||
          securityStatus['dnsEnabled'] == true) {
        if (mounted) {
          _showSecurityWarning(securityStatus);
        }
      } else {
        if (mounted) {
          _checkFirstLaunchAndOnboarding();
        }
      }
    }
  
    void _showSecurityWarning(Map<String, bool> securityStatus) {
      String message = '';
      if (securityStatus['developerOptionsEnabled'] == true) {
        message = 'Developer Options is enabled. Please turn them off and try again.';
      } else if (securityStatus['dnsEnabled'] == true) {
        message = 'Private DNS is enabled. Please turn it off and try again.';
      } else {
        message = 'Developer Options and Private DNS are enabled. Please turn them off and try again.';
      }
  
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Important Notice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
  
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _recheckSecurity();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _recheckSecurity();
              },
              child: const Text('ReCheck'),
            ),
          ],
        ),
      );
    }
  
    @override
    Widget build(BuildContext context) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
  
  class MyHomePage extends StatefulWidget {
    const MyHomePage({super.key});
  
    @override
    State<MyHomePage> createState() => _MyHomePageState();
  }
  
  class _MyHomePageState extends State<MyHomePage>
      with SingleTickerProviderStateMixin, WidgetsBindingObserver {
    late TabController _tabController;
    late final ScrollController _scrollController = ScrollController();
    final ScrollController _widgetsScrollController = ScrollController();
    final TextEditingController _searchController = TextEditingController();
    final TextEditingController _hiddenAppsSearchController =
    TextEditingController();
    final List<String> _tabs = ['Apps', 'Widgets'];
    int _selectedIndex = 0;
    List<AppInfo> _apps = [];
    List<Folder> _folders = [];
    List<WidgetInfo> _addedWidgets = [];
    bool _isLoading = true;
    bool _isBackgroundLoading = false;
    List<AppInfo> _pinnedApps = [];
    bool _isReorderingWidgets = false;
    AppListSortType _appListSortType = AppListSortType.alphabeticalAsc;
    List<AppSection> _appSections = [];
    String _currentSection = '';
    final Map<String, Uint8List> _iconCache = {};
    final int _maxCacheSize = 50; // Adjust based on your needs
    final FocusNode _searchFocusNode = FocusNode();
    final Map<String, int> _notificationCounts = {};
    bool _showNotificationBadges = true;
    final List<String> _hiddenApps = [];
    bool _showingHiddenApps = false;
    double _horizontalDragStart = 0;
    bool _isSwipeInProgress = false;
    bool _hasCompletedFirstSwipe = false;
    DateTime? _lastSwipeTime;
    final Set<String> _pinnedAppsBackup = {};
    final Map<String, int> _hiddenAppFolderMap = {};
    bool _isSelectingAppsToHide = false;
    bool _showingAppLibrary = false;
    Key _appLayoutKey = UniqueKey();
    bool _isWidgetsScrolling = false;
    Timer? _widgetsScrollEndTimer;
    bool _isAppsScrolling = false;
    Timer? _appsScrollEndTimer;
    Timer? _securityCheckTimer;
    Timer? _clockTimer;
    bool _isBottomSheetOpen = false;
    final PageController _bottomSheetPageController = PageController();
    int _currentBottomSheetPage = 0;
    final PageController _sideViewPageController =
      PageController(initialPage: 1, viewportFraction: 1.0);
    int _currentSidePage = 1; // 0 = Left, 1 = Main (Apps/Widgets), 2 = Right
  
    @override
    void initState() {
      super.initState();
      WidgetsBinding.instance.addObserver(this);
      FocusManager.instance.primaryFocus?.unfocus();
      _tabController = TabController(length: 2, vsync: this);
      int previousIndex = 0;
      print('🎯 TabController setup completed with initial index: ${_tabController.index}');
      _tabController.addListener(() {
        print('🔄 TabController called - currentIndex: ${_tabController.index}, previousIndex: $previousIndex');
        if (_tabController.index != previousIndex) {
          setState(() {
            _selectedIndex = _tabController.index;
            _unfocusSearch();
          });
          // Show AppOpenAd only when switching to home tab (Apps tab, index 0)
          if (_tabController.index == 0 && previousIndex != 0) {
            print('🏠 Switching to home tab, will show AppOpenAd after delay');
            // Small delay to ensure tab switch is smooth
            Future.delayed(const Duration(milliseconds: 300), () async {
              print('⏰ Delay completed, checking if should show AppOpenAd');
              final isDefault = await LauncherHelper.isDefaultLauncher();
              if (isDefault) {
                print('⏰ Calling showAdIfAvailable');
                AppOpenAdManager.instance.showAdIfAvailable();
              } else {
                print('⏭️ Skipping AppOpenAd - app is not default launcher');
              }
            });
          }
          previousIndex = _tabController.index;
        }
      });
  
      _isLoading = false;
      if (_apps.isEmpty) {
        _loadApps();
      }
  
      // Clean up database on startup
      _performDatabaseCleanup();
      _loadAddedWidgets();
      _loadSortTypes();
      NotificationService.initialize();
      NotificationService.notificationStream.listen((counts) {
        setState(() {
          _notificationCounts.clear();
          _notificationCounts.addAll(counts);
        });
      });
      _loadSettings();
      _loadHiddenApps();
      _loadPinnedAppsBackup();
      _loadHiddenAppFolderMap();
      InterstitialAdManager.instance.loadAd();
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {});
        }
      });
  
      const systemChannel =
      MethodChannel('com.kayfahaarukku.homelauncherthree/system');
      systemChannel.setMethodCallHandler((call) async {
        if (call.method == 'getNavigationState') {
          return NavigationState.currentScreen;
        }
        if (call.method == 'onBackPressed') {
          if (_isBottomSheetOpen) {
            Navigator.of(context).pop();
            return true;
          }
          if (_currentSidePage != 1) {
            _sideViewPageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
            return true;
          }
          if (Get.key.currentState?.canPop() ?? false) {
            Get.back();
            return true;
          }
          if (_searchController.text.isNotEmpty) {
            setState(() {
              _searchController.clear();
            });
            return true;
          }
          if (_showingAppLibrary) {
            setState(() {
              _showingAppLibrary = false;
            });
            return true;
          }
          if (_showingHiddenApps) {
            setState(() {
              _showingHiddenApps = false;
              _isSelectingAppsToHide = false;
              _searchController.clear();
              _hiddenAppsSearchController.clear();
            });
            return true;
          }
          if (_selectedIndex == 1) {
            _tabController.animateTo(0);
            setState(() {
              _selectedIndex = 0;
            });
            return true;
          }
          // Only show interstitial ad if app is default launcher
          final isDefault = await LauncherHelper.isDefaultLauncher();
          if (isDefault) {
            await InterstitialAdManager.instance.showAdAlways();
          }
          return true;
        }
        return null;
      });
      _widgetsScrollController.addListener(_widgetsScrollListener);
      _scrollController.addListener(_appsScrollListener);
    }
  
    /// changes 3
    void _openSystemDefaultDialog() async {
      final prefs = await SharedPreferences.getInstance();
      final hasShownDefaultDialog = prefs.getBool('default_dialog_shown') ?? false;
  
      if (!hasShownDefaultDialog) {
        LauncherHelper.requestSetAsDefaultLauncher();
        await prefs.setBool('default_dialog_shown', true);
      }
    }
    Future<void> _loadFolders() async {
      final folders = await AppDatabase.getFolders();
      for (var folder in folders) {
        folder.apps = folder.appPackageNames
            .map((packageName) {
          try {
            return _apps.firstWhere((app) => app.packageName == packageName);
          } catch (e) {
            return null;
          }
        })
            .whereType<AppInfo>()
            .toList();
      }
  
      // Sort folders based on current sort type
      _sortFolders(folders, _appListSortType);
  
      if (mounted) {
        setState(() {
          _folders = folders;
        });
      }
    }
  
    void _sortFolders(List<Folder> folders, AppListSortType sortType) {
      switch (sortType) {
        case AppListSortType.alphabeticalAsc:
          folders.sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          break;
        case AppListSortType.alphabeticalDesc:
          folders.sort(
                  (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
          break;
        case AppListSortType.usage:
        // For usage-based sorting, sort by the highest priority app in each folder
          folders.sort((a, b) {
            // Find the highest priority (lowest index) app in each folder
            int getHighestPriorityIndex(Folder folder) {
              if (folder.apps.isEmpty) return 999999;
  
              int highestPriority = 999999;
              for (var app in folder.apps) {
                final index =
                _apps.indexWhere((a) => a.packageName == app.packageName);
                if (index != -1 && index < highestPriority) {
                  highestPriority = index;
                }
              }
              return highestPriority;
            }
  
            final aPriority = getHighestPriorityIndex(a);
            final bPriority = getHighestPriorityIndex(b);
  
            // If both folders have no valid apps, sort alphabetically
            if (aPriority == 999999 && bPriority == 999999) {
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }
  
            return aPriority.compareTo(bPriority);
          });
          break;
      }
    }
  
    /// Clean up the database to ensure it's in sync with installed apps
    Future<void> _performDatabaseCleanup() async {
      try {
        // Get all installed package names directly from device
        final validPackages = await AppPackageManager.getInstalledPackageNames();
  
        // Clean up the database, removing any apps that aren't installed
        await AppDatabase.cleanupInvalidApps(validPackages);
        debugPrint('Database cleanup complete');
      } catch (e) {
        debugPrint('Error during database cleanup: $e');
      }
    }
  
    Future<void> _loadSettings() async {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _showNotificationBadges =
            prefs.getBool('show_notification_badges') ?? true;
      });
    }
  
    void _startSecurityCheck() {
      _securityCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
        if (!mounted) return;
  
        final securityStatus = await SecurityCheckService.checkSecurityStatus();
  
        if (securityStatus['developerOptionsEnabled'] == true ||
            securityStatus['dnsEnabled'] == true) {
          if (mounted) {
            _showSecurityWarning(securityStatus);
          }
        }
      });
    }
  
    void _showSecurityWarning(Map<String, bool> securityStatus) {
      String message = '';
      if (securityStatus['developerOptionsEnabled'] == true) {
        message = 'Developer Options is enabled. Please turn them off and try again.';
      } else if (securityStatus['dnsEnabled'] == true) {
        message = 'Private DNS is enabled. Please turn it off and try again.';
      } else {
        message = 'Developer Options and Private DNS are enabled. Please turn them off and try again.';
      }
  
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Important Notice',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  
  
    @override
    void dispose() {
      WidgetsBinding.instance.removeObserver(this);
      _tabController.dispose();
      _scrollController.removeListener(_appsScrollListener);
      _scrollController.dispose();
      _widgetsScrollController.dispose();
      _searchController.dispose();
      _hiddenAppsSearchController.dispose();
      _iconCache.clear();
      _searchFocusNode.dispose();
      NotificationService.dispose();
      _appsScrollEndTimer?.cancel();
      _widgetsScrollEndTimer?.cancel();
      _securityCheckTimer?.cancel();
      _clockTimer?.cancel();
      _bottomSheetPageController.dispose();
      super.dispose();
    }
  
    Future<void> _loadApps(
        {bool background = false, bool forceRefresh = false}) async {
      if ((_isLoading && !background) || (_isBackgroundLoading && background)) {
        debugPrint('Loading already in progress, skipping');
        return;
      }
  
      try {
        if (background) {
          setState(() {
            _isBackgroundLoading = true;
          });
        } else {
          setState(() {
            _isLoading = true;
          });
        }
  
        // First try to load from cache - but only if not forcing refresh
        if (!background && !forceRefresh) {
          await _loadCachedApps();
        }
  
        // Then check if we need to refresh from the system
        final lastUpdate = await AppDatabase.getLastUpdateTime();
        final now = DateTime.now();
        final shouldRefresh = forceRefresh ||
            lastUpdate == null ||
            now.difference(lastUpdate) > const Duration(minutes: 10);
  
        if (shouldRefresh || background) {
          // If we need to update, do it in the background
          await _refreshAppsInBackground();
        }
  
        // Always reset loading state when done
        if (mounted) {
          setState(() {
            if (background) {
              _isBackgroundLoading = false;
            } else {
              _isLoading = false;
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading apps: $e');
        if (mounted) {
          setState(() {
            if (!background) {
              _isLoading = false;
            }
            _isBackgroundLoading = false;
          });
        }
      }
    }
  
    Future<void> _loadCachedApps() async {
      final cachedApps = await AppDatabase.getCachedApps();
      if (cachedApps.isNotEmpty && mounted) {
        final filtered = await _filterApps(cachedApps);
        setState(() {
          _apps = filtered;
          _isLoading = false;
        });
        await AppUsageTracker.sortAppList(_apps, _appListSortType);
        await _loadPinnedApps();
        await _loadFolders();
        if (mounted) {
          setState(() {
            _appSections = AppSectionManager.createSections(_apps,
                sortType: _appListSortType);
          });
        }
      }
      await _loadFolders();
      await _updateRecentAndGoogleApps();
    }

    Future<void> _refreshAppsInBackground() async {
      try {
        // Fetch all apps directly from the system
        List<AppInfo> freshApps = [];
        try {
          freshApps = await InstalledApps.getInstalledApps(true, true);
        } catch (e) {
          // If we get an exception fetching all apps, try a safer approach
          debugPrint('Error fetching all apps: $e');
          freshApps = await _getSafeInstalledApps();
        }
        freshApps = await _filterApps(freshApps);
        if (freshApps.isEmpty) {
          // If we still couldn't get apps, don't proceed with updates
          debugPrint('Could not get app list - skipping update');
          return;
        }

        // Clean up any invalid apps from the database
        final validPackageNames =
        freshApps.map((app) => app.packageName).toList();
        await AppDatabase.cleanupInvalidApps(validPackageNames);

        // Track changes between old and new app lists
        final Set<String> oldPackageNames =
        _apps.map((app) => app.packageName).toSet();
        final Set<String> newPackageNames =
        freshApps.map((app) => app.packageName).toSet();

        // Find apps that were removed and added
        final Set<String> removedApps =
        oldPackageNames.difference(newPackageNames);
        final Set<String> addedApps = newPackageNames.difference(oldPackageNames);

        // Log changes for debugging
        if (removedApps.isNotEmpty) {
          debugPrint('Detected removed apps: ${removedApps.join(', ')}');
        }

        if (addedApps.isNotEmpty) {
          debugPrint('Detected new apps: ${addedApps.join(', ')}');
        }

        // Handle changes to pinned apps if necessary
        if (removedApps.isNotEmpty) {
          for (final packageName in removedApps) {
            // Remove from database
            await AppDatabase.removeApp(packageName);

            // Remove from pinned apps list
            _pinnedApps.removeWhere((app) => app.packageName == packageName);
          }
          await _savePinnedApps();
        }

        // Cache the fresh data in the database
        await AppDatabase.cacheApps(freshApps);

        if (mounted) {
          // Update the app list with the fresh data
          setState(() {
            _apps = freshApps;
          });

          // Sort the app list
          await AppUsageTracker.sortAppList(_apps, _appListSortType);

          // Refresh pinned apps to ensure consistency
          await _loadPinnedApps();

          await _loadFolders();

          if (mounted) {
            setState(() {
              _appSections = AppSectionManager.createSections(_apps,
                  sortType: _appListSortType);
            });
          }
        }
        await _loadFolders();
        await _updateRecentAndGoogleApps();
      } catch (e) {
        debugPrint('Error refreshing apps: $e');
        rethrow;
      }
    }
  
    Future<List<AppInfo>> _getSafeInstalledApps() async {
      return AppPackageManager.getInstalledAppsSafely(
          excludeSystemApps: true, withIcon: true, includeAppSize: false);
    }
  
    Future<bool> _onWillPop() async {
      if (_currentSidePage != 1) {
        _sideViewPageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
        return false;
      }
      if (_searchController.text.isNotEmpty ||
          _hiddenAppsSearchController.text.isNotEmpty) {
        setState(() {
          _searchController.clear();
          _hiddenAppsSearchController.clear();
        });
        return false;
      }
      if (_showingAppLibrary) {
        // 👈 NAYA
        setState(() {
          _showingAppLibrary = false;
        });
        return false;
      }
      if (_showingHiddenApps) {
        setState(() {
          _showingHiddenApps = false;
          _isSelectingAppsToHide = false;
          _searchController.clear();
          _hiddenAppsSearchController.clear();
        });
        return false;
      }
      if (_selectedIndex == 1) {
        _tabController.animateTo(0);
        setState(() {
          _selectedIndex = 0;
        });
        return false;
      }
      // Only show interstitial ad if app is default launcher
      final isDefault = await LauncherHelper.isDefaultLauncher();
      if (isDefault) {
        await InterstitialAdManager.instance.showAdAlways();
      }
      return true;
    }
  
    void _showAppOptions(BuildContext context, AppInfo application, bool isPinned,
        {VoidCallback? onAppRemoved}) async {
      bool? isSystemAppResult =
      await InstalledApps.isSystemApp(application.packageName);
      bool isSystemApp = isSystemAppResult ?? true;
      bool isHidden = _hiddenApps.contains(application.packageName);
      Folder? parentFolder;
      try {
        parentFolder = _folders.firstWhere(
                (f) => f.appPackageNames.contains(application.packageName));
      } catch (e) {
        parentFolder = null;
      }
  
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor:
          isDarkMode ? const Color(0xFF252525) : Colors.white.withAlpha(242),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          isScrollControlled: true,
          builder: (context) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF757575)
                        : const Color(0xFFBDBDBD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: _getBottomSheetPadding(context),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? const Color(0xFF424242)
                                        : const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: application.icon != null
                                        ? Image.memory(
                                      application.icon!,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Icon(
                                          Icons.android,
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black54,
                                        );
                                      },
                                    )
                                        : Icon(
                                      Icons.android,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        application.name,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        application.packageName,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isHidden)
                            ListTile(
                              leading: Icon(Icons.visibility,
                                  color:
                                  isDarkMode ? Colors.white : Colors.black),
                              title: Text(
                                'Unhide App',
                                style: TextStyle(
                                    color:
                                    isDarkMode ? Colors.white : Colors.black),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                await _restoreAppToFolder(
                                    application.packageName);
                                setState(() {
                                  _hiddenApps.remove(application.packageName);
                                  _searchController.clear();
                                  _hiddenAppsSearchController.clear();
                                  // Don't restore pinned status - require user to pin again
                                  if (_pinnedAppsBackup
                                      .contains(application.packageName)) {
                                    // Don't add back to _pinnedApps
                                    _pinnedAppsBackup
                                        .remove(application.packageName);
                                  }
                                });
                                await _saveHiddenApps();
                                await _savePinnedApps();
                                await _savePinnedAppsBackup();
                              },
                            ),
                          ListTile(
                            leading: Icon(
                              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            title: Text(
                              isPinned ? 'Unpin' : 'Pin to Top',
                              style: TextStyle(
                                  color:
                                  isDarkMode ? Colors.white : Colors.black),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              // Check if app is hidden - if so, don't allow pinning
                              if (!isPinned &&
                                  _hiddenApps.contains(application.packageName)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hidden apps cannot be pinned'),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                if (isPinned) {
                                  _pinnedApps.removeWhere((pinnedApp) =>
                                  pinnedApp.packageName ==
                                      application.packageName);
                                } else {
                                  if (!_pinnedApps.any((app) =>
                                  app.packageName ==
                                      application.packageName)) {
                                    if (_pinnedApps.length < 10) {
                                      _pinnedApps.add(application);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Maximum 10 apps can be pinned'),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '${application.name} is already pinned'),
                                      ),
                                    );
                                  }
                                }
                              });
                              await _savePinnedApps();
                            },
                          ),
                          /*if (!isSystemApp)
                            ListTile(
                              leading:
                              const Icon(Icons.delete, color: Colors.red),
                              title: Text(
                                'Uninstall',
                                style: TextStyle(
                                    color:
                                    isDarkMode ? Colors.white : Colors.black),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
  
                                try {
                                  // Start the uninstallation process
                                  await InstalledApps.uninstallApp(
                                      application.packageName);
  
                                  // Remove from any folder
                                  for (var folder in _folders) {
                                    if (folder.appPackageNames
                                        .contains(application.packageName)) {
                                      folder.appPackageNames
                                          .remove(application.packageName);
                                      await AppDatabase.updateFolder(folder);
                                    }
                                  }
  
                                  // Immediately remove from our database
                                  await AppDatabase.removeApp(
                                      application.packageName);
  
                                  // Remove the app from the current list directly
                                  if (mounted) {
                                    setState(() {
                                      _apps.removeWhere((app) =>
                                      app.packageName ==
                                          application.packageName);
                                      _pinnedApps.removeWhere((app) =>
                                      app.packageName ==
                                          application.packageName);
                                      _appSections =
                                          AppSectionManager.createSections(_apps,
                                              sortType: _appListSortType);
                                      // Reset loading indicators to prevent stuck state
                                      _isBackgroundLoading = false;
                                      _isLoading = false;
                                    });
                                  }
  
                                  // Force refresh app list after uninstall
                                  if (mounted) {
                                    _loadApps(
                                        background: true, forceRefresh: true);
                                  }
                                } catch (e) {
                                  // If any error occurs, ensure loading states are reset
                                  if (mounted) {
                                    setState(() {
                                      _isBackgroundLoading = false;
                                      _isLoading = false;
                                    });
                                  }
                                  debugPrint('Error during uninstall: $e');
                                }
                              },
                            ),*/
                          ListTile(
                            leading: Icon(Icons.info_outline,
                                color: isDarkMode ? Colors.white : Colors.black),
                            title: Text(
                              'App Info',
                              style: TextStyle(
                                  color:
                                  isDarkMode ? Colors.white : Colors.black),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              await InstalledApps.openSettings(
                                  application.packageName);
  
                              // When returning from app settings, force refresh the app list
                              // as the user might have uninstalled or updated the app
                              if (mounted) {
                                _loadApps(background: true, forceRefresh: true);
                              }
                            },
                          ),
                          if (parentFolder != null)
                            ListTile(
                              leading: Icon(Icons.folder_off_outlined,
                                  color:
                                  isDarkMode ? Colors.white : Colors.black),
                              title: Text(
                                'Remove from Folder',
                                style: TextStyle(
                                    color:
                                    isDarkMode ? Colors.white : Colors.black),
                              ),
                              onTap: () async {
                                Navigator.pop(context);
                                parentFolder!.appPackageNames
                                    .remove(application.packageName);
                                await AppDatabase.updateFolder(parentFolder);
                                await _loadFolders();
                                onAppRemoved?.call();
                              },
                            )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    }
  
    List<AppInfo> _recentUsedApps = [];
    List<AppInfo> _googleInstalledApps = [];
  
    static const _googlePackages = [
      'com.google.android.youtube',
      'com.google.android.apps.maps',
      'com.google.android.apps.docs',
      'com.google.android.gm',        // Gmail
      'com.android.chrome',
      'com.google.android.apps.photos',
    ];
  
    Future<void> _updateRecentAndGoogleApps() async {
      if (_apps.isEmpty) return;
  
      final sorted = List<AppInfo>.from(_apps);
      await AppUsageTracker.sortAppList(sorted, AppListSortType.usage);
  
      setState(() {
        _recentUsedApps = sorted.take(4).toList();
        _googleInstalledApps = _apps
            .where((a) => _googlePackages.contains(a.packageName))
            .take(4)
            .toList();
      });
    }
    Future<void> _loadAddedWidgets() async {
      if (mounted) {
        setState(() {
          _addedWidgets = []; // Clear the list while loading
        });
      }
  
      final widgets = await WidgetManager.getAddedWidgets();
      final prefs = await SharedPreferences.getInstance();
  
      // Load saved widget order
      final savedOrder = prefs.getStringList('widget_order') ?? [];
      final orderedWidgets = <WidgetInfo>[];
      final unorderedWidgets = List<WidgetInfo>.from(widgets);
  
      // First add widgets in the saved order
      for (var widgetId in savedOrder) {
        final index = unorderedWidgets
            .indexWhere((w) => w.widgetId?.toString() == widgetId);
        if (index != -1) {
          orderedWidgets.add(unorderedWidgets[index]);
          unorderedWidgets.removeAt(index);
        }
      }
  
      // Add any remaining widgets at the end
      orderedWidgets.addAll(unorderedWidgets);
  
      // Load saved sizes
      final savedSizesString = prefs.getString('widget_sizes');
      if (savedSizesString != null) {
        final savedSizes = jsonDecode(savedSizesString) as List;
        for (var widget in orderedWidgets) {
          final savedSize = savedSizes.firstWhere(
                (size) => size['widgetId'] == widget.widgetId,
            orElse: () => null,
          );
          if (savedSize != null) {
            widget.currentWidth = savedSize['width'];
            widget.currentHeight = savedSize['height'];
          }
        }
      }
  
      if (mounted) {
        setState(() {
          _addedWidgets = orderedWidgets;
        });
      }
    }
  
    @override
    Widget build(BuildContext context) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      double _mainDragAccum = 0;
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (!didPop) {
            await _onWillPop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          body: PageView(
            controller: _sideViewPageController,
            physics: (_selectedIndex == 0 && !_isSelectingAppsToHide)
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            onPageChanged: (index) async {
              setState(() {
                _currentSidePage = index;
              });
              if (index != 1) {
                NavigationState.currentScreen = 'subview';
                AdFlowState.suppressAppOpenAdOnNextResume = true;
                final isDefault = await LauncherHelper.isDefaultLauncher();
                if (isDefault) {
                  await InterstitialAdManager.instance.showAdAlways();
                }
              } else {
                NavigationState.currentScreen = 'main';
              }
            },
            children: [
              const LeftViewScreen(),
              GestureDetector(
                onTap: _unfocusSearch,
                onVerticalDragStart: (details) {
                  _mainDragAccum = 0;
                },
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy < 0) {
                    _mainDragAccum += details.delta.dy;
                  }
                  if (_mainDragAccum < -50 && !_isBottomSheetOpen) {
                    setState(() {
                      _isBottomSheetOpen = true;
                    });
                    _showAppDrawerBottomSheet();
                  }
                },
                onVerticalDragEnd: (details) {
                  _mainDragAccum = 0;
                },
                child: Container(
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: SafeArea(
                    bottom: true,
                    child: Column(
                      children: [
                        _buildClockWidget(),
                        const SizedBox(height: 350),
  
                        if (_isSelectingAppsToHide)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Select apps to hide',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final authenticated =
                                        await AuthService.authenticateUser();
                                        if (authenticated) {
                                          await _saveHiddenApps();
                                          await _savePinnedApps();
                                          await _savePinnedAppsBackup();
  
                                          setState(() {
                                            _searchController.clear();
                                            _hiddenAppsSearchController.clear();
                                            _isSelectingAppsToHide = false;
                                            _showingHiddenApps = true;
                                          });
                                        }
                                      },
                                      child: Text(
                                        'Done',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(13, 0, 0, 0),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _hiddenAppsSearchController,
                                    style: TextStyle(
                                      color:
                                      isDarkMode ? Colors.white : Colors.black,
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      hintText: 'Search apps to hide...',
                                      hintStyle: TextStyle(
                                        color: (isDarkMode
                                            ? Colors.white
                                            : Colors.black)
                                            .withAlpha(128),
                                        fontSize: 16,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        color: (isDarkMode
                                            ? Colors.white
                                            : Colors.black)
                                            .withAlpha(179),
                                        size: 22,
                                      ),
                                      suffixIcon: _hiddenAppsSearchController
                                          .text.isNotEmpty
                                          ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: (isDarkMode
                                              ? Colors.white
                                              : Colors.black)
                                              .withAlpha(179),
                                          size: 22,
                                        ),
                                        onPressed: () {
                                          _hiddenAppsSearchController.clear();
                                          setState(() {});
                                        },
                                      )
                                          : null,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? const Color(0xFF2D2D2D)
                                          : Colors.white,
                                    ),
                                    onChanged: (_) {
                                      setState(() {});
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
  
                        _isSelectingAppsToHide
                            ? Expanded(
                          child: ScrollConfiguration(
                            behavior: AppScrollBehavior().copyWith(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                            ),
                            child: AppLayoutSwitcher(
                              key: _appLayoutKey,
                              apps: _apps,
                              folders: const [],
                              onFoldersChanged: _loadFolders,
                              pinnedApps: const [],
                              showingHiddenApps: _showingHiddenApps,
                              onAppLongPress: (context, app, isPinned,
                                  {onAppRemoved}) =>
                                  _showAppOptions(context, app, isPinned,
                                      onAppRemoved: onAppRemoved),
                              isSelectingAppsToHide: _isSelectingAppsToHide,
                              hiddenApps: _hiddenApps,
                              onAppLaunch: (packageName) async {
                                if (_hiddenApps.contains(packageName)) {
                                  await _restoreAppToFolder(packageName);
                                  setState(() {
                                    _hiddenApps.remove(packageName);
                                  });
                                } else {
                                  await _removeAppFromFolderIfHidden(
                                      packageName);
                                  setState(() {
                                    _hiddenApps.add(packageName);
                                  });
                                }
                              },
                              sortType: _appListSortType,
                              notificationCounts: _notificationCounts,
                              showNotificationBadges:
                              _showNotificationBadges,
                              searchController: _showingHiddenApps ||
                                  _isSelectingAppsToHide
                                  ? _hiddenAppsSearchController
                                  : _searchController,
                              isBackgroundLoading: _isBackgroundLoading,
                            ),
                          ),
                        )
                            : Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildAppsList(),
                              _buildWidgetsList(),
                            ],
                          ),
                        ),
  
                        _buildSearchBar(),
                      ],
                    ),
                  ),
                ),
              ),
  
              RightViewScreen(
                recentApps: _recentUsedApps,
                googleApps: _googleInstalledApps,
                nativeAdBuilder: (context) => const HybridNativeAdWidget(),
              ),
            ],
          ),
        ),
      );
    }
  
    Widget _buildClockWidget() {
      final now = DateTime.now();
      final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      final dateString = _getFormattedDate(now);
  
      return Padding(
        padding: const EdgeInsets.only(top: 32.0, bottom: 16.0),
        child: Column(
          children: [
            Text(
              dateString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3.0,
                    color: Color.fromARGB(128, 0, 0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timeString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.w300,
                height: 1.0,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4.0,
                    color: Color.fromARGB(128, 0, 0, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  
    String _getFormattedDate(DateTime date) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
    Widget _buildAppsList() {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      List<AppInfo> visibleApps = _apps.where((app) {
        if (_hiddenApps.contains(app.packageName)) return false;
        if (_searchController.text.isEmpty) return true;
        return app.name.toLowerCase().contains(_searchController.text.toLowerCase());
      }).toList();

      final displayApps = visibleApps.take(10).toList();
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAppRow(displayApps.take(5).toList()),
                      const SizedBox(height: 12),
                      _buildAppRow(displayApps.skip(5).take(5).toList()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
  
    Widget _buildAppRow(List<AppInfo> apps) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(5, (index) {
          if (index < apps.length) {
            final app = apps[index];
            return _buildAppIcon(app);
          } else {
            return const SizedBox(width: 60, height: 80);
          }
        }),
      );
    }
  
    Widget _buildAppIcon(AppInfo app) {
      final notificationCount = _notificationCounts[app.packageName] ?? 0;
      final hasNotification = _showNotificationBadges && notificationCount > 0;
  
      return GestureDetector(
        onTap: () async {
          print("🎯 App tapped: name");
          print("📊 Ad Status: ${InterstitialAdManager.instance.isAdReady}");
          
          // Only show interstitial ad if app is default launcher
          final isDefault = await LauncherHelper.isDefaultLauncher();
          if (isDefault) {
            await InterstitialAdManager.instance.showAdAlways();
          }
  
          print("✅ Ad flow completed, launching app...");
          await AppUsageTracker.recordAppLaunch(app.packageName);
          _pendingAppReturnAd = true;
          AdFlowState.suppressAppOpenAdOnNextResume = true;
          await InstalledApps.startApp(app.packageName);
        },
        onLongPress: () {
          final isPinned = _pinnedApps.any((a) => a.packageName == app.packageName);
          _showAppOptions(context, app, isPinned);
        },
        child: SizedBox(
          width: 60,
          height: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: app.icon != null
                          ? Image.memory(
                              app.icon!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.android, size: 30),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.android, size: 30),
                            ),
                    ),
                  ),
                  if (hasNotification)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          notificationCount > 99 ? '99+' : '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                app.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2.0,
                      color: Color.fromARGB(128, 0, 0, 0),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  

    Widget _buildWidgetsList() {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
      return Stack(
        children: [
          GestureDetector(
            onLongPress: _isReorderingWidgets
                ? null
                : () {
              if (_addedWidgets.isNotEmpty) {
                HapticFeedback.heavyImpact();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: isDarkMode
                      ? const Color(0xFF212121)
                      : const Color(0xFFF5F5F5),
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.reorder,
                              color:
                              isDarkMode ? Colors.white : Colors.black),
                          title: Text(
                            'Reorder Widgets',
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _isReorderingWidgets = true;
                            });
                          },
                        ),
                        ListTile(
                          leading:
                          Icon(Icons.delete_sweep, color: Colors.red),
                          title: Text(
                            'Remove All Widgets',
                            style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white
                                    : Colors.black),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: isDarkMode
                                    ? const Color(0xFF212121)
                                    : const Color(0xFFF5F5F5),
                                title: Text(
                                  'Clear All Widgets',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                                content: Text(
                                  'Are you sure you want to remove all widgets?',
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.black54),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      for (var widget in _addedWidgets) {
                                        if (widget.widgetId != null) {
                                          await WidgetManager.removeWidget(
                                              widget.widgetId!);
                                        }
                                      }
                                      await _loadAddedWidgets();
                                      setState(() {});
                                    },
                                    child: Text(
                                      'Remove All',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: Column(
              children: [
                if (_isReorderingWidgets)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drag widgets to reorder them',
                            style: TextStyle(
                              color: Colors.white.withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isReorderingWidgets = false;
                            });
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),if (_isReorderingWidgets)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drag widgets to reorder them',
                            style: TextStyle(
                              color: Colors.white.withAlpha(179),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isReorderingWidgets = false;
                            });
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _addedWidgets.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No widgets added',
                          style:
                          TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showAddWidgetDialog,
                          child: const Text('Add Widget'),
                        ),
                      ],
                    ),
                  )
                      : ReorderableListView.builder(
                    scrollController: _widgetsScrollController,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _addedWidgets.removeAt(oldIndex);
                        _addedWidgets.insert(newIndex, item);
                      });
                      _saveWidgetOrder();
                    },
                    onReorderStart: (_) {
                      HapticFeedback.heavyImpact();
                    },
                    itemCount: _addedWidgets.length,
                    itemBuilder: (context, index) => Padding(
                      key: ValueKey(_addedWidgets[index].widgetId),
                      padding: const EdgeInsets.all(16),
                      child: ResizableWidget(
                        isReorderMode: _isReorderingWidgets,
                        onLongPress: () => _showWidgetOptions(
                            context, _addedWidgets[index]),
                        child: Container(
                          width: double.infinity,
                          height: _addedWidgets[index]
                              .minHeight
                              .toDouble(),
                          decoration: BoxDecoration(
                            color: (isDarkMode
                                ? Colors.white
                                : Colors.black)
                                .withAlpha(26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: LiveWidgetPreview(
                            widgetId: _addedWidgets[index].widgetId!,
                            minHeight: _addedWidgets[index].minHeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _showAddWidgetDialog,
              backgroundColor:
              isDarkMode ? const Color(0xFF6750A4) : const Color(0xFF6200EE),
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      );
    }
  
    Future<void> _showAddWidgetDialog() async {
      final widgets = await WidgetManager.getAvailableWidgets();
  
      if (!mounted) return;
  
      await showDialog(
        context: context,
        builder: (context) {
          final searchController = TextEditingController();
          List<WidgetInfo> filteredWidgets = List.from(widgets);
  
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: isDarkMode
                    ? const Color(0xFF212121)
                    : const Color(0xFFF5F5F5),
                title: const Text(
                  'Add Widget',
                  style: TextStyle(color: Colors.white),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search widgets...',
                          hintStyle: TextStyle(
                              color:
                              isDarkMode ? Colors.white70 : Colors.black54),
                          prefixIcon: Icon(Icons.search,
                              color:
                              isDarkMode ? Colors.white70 : Colors.black54),
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE0E0E0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            filteredWidgets = widgets
                                .where((widget) =>
                            widget.appName
                                .toLowerCase()
                                .contains(value.toLowerCase()) ||
                                widget.label
                                    .toLowerCase()
                                    .contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _groupWidgetsByApp(filteredWidgets).length,
                          itemBuilder: (context, index) {
                            final entry = _groupWidgetsByApp(filteredWidgets)
                                .entries
                                .elementAt(index);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                                  child: Text(
                                    entry.key,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(179),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...entry.value.map((widget) => ListTile(
                                  title: Text(
                                    widget.label,
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                  subtitle: Text(
                                    '${(widget.minWidth / MediaQuery.of(context).devicePixelRatio).round()}x'
                                        '${(widget.minHeight / MediaQuery.of(context).devicePixelRatio).round()} dp',
                                    style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(context);
                                    final success =
                                    await WidgetManager.addWidget(widget);
                                    if (success && mounted) {
                                      await _loadAddedWidgets();
                                      setState(
                                              () {}); // Refresh the widget list
                                    }
                                  },
                                )),
                                Divider(
                                    color: isDarkMode
                                        ? const Color(0x3DFFFFFF)
                                        : const Color(0x3D000000)),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
  
      // Refresh widgets list after dialog is closed
      if (mounted) {
        await _loadAddedWidgets();
        setState(() {}); // Refresh the main widget list
      }
    }
  
    Map<String, List<WidgetInfo>> _groupWidgetsByApp(List<WidgetInfo> widgets) {
      final grouped = <String, List<WidgetInfo>>{};
      for (var widget in widgets) {
        // Skip widgets with invalid dimensions (0 in either width or height)
        if (widget.minWidth <= 0 || widget.minHeight <= 0) {
          continue;
        }
  
        if (!grouped.containsKey(widget.appName)) {
          grouped[widget.appName] = [];
        }
        grouped[widget.appName]!.add(widget);
      }
      // Remove empty app groups
      grouped.removeWhere((key, value) => value.isEmpty);
  
      return Map.fromEntries(
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    }
  
    void _showWidgetOptions(BuildContext context, WidgetInfo widget) {
      HapticFeedback.heavyImpact();
      showModalBottomSheet(
        context: context,
        backgroundColor:
        isDarkMode ? const Color(0xFF212121) : const Color(0xFFF5F5F5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        isScrollControlled: true,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF757575)
                      : const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: _getBottomSheetPadding(context),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 20),
                          child: Row(
                            children: [
                              FutureBuilder<Widget>(
                                future: _getAppIcon(widget.packageName),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: snapshot.data,
                                    );
                                  }
                                  return const SizedBox(width: 40, height: 40);
                                },
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.label,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      widget.appName,
                                      style: TextStyle(
                                        color: isDarkMode
                                            ? Colors.white70
                                            : Colors.black54,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.reorder,
                              color: isDarkMode ? Colors.white : Colors.black),
                          title: Text(
                            'Reorder Widgets',
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              _isReorderingWidgets = true;
                            });
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Remove Widget',
                            style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            if (widget.widgetId != null) {
                              await WidgetManager.removeWidget(widget.widgetId!);
                              await _loadAddedWidgets();
                              setState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  
    Future<Widget> _getAppIcon(String packageName) async {
      try {
        final iconData = await _getAppIconData(packageName);
        if (iconData != null) {
          return Image.memory(iconData);
        }
        return const SizedBox();
      } catch (e) {
        debugPrint('Error creating app icon widget for $packageName: $e');
        return const SizedBox();
      }
    }
  
    Future<Uint8List?> _getAppIconData(String packageName) async {
      try {
        // First try to get from the loaded apps list
        try {
          final app = _apps.firstWhere((app) => app.packageName == packageName);
          if (app.icon != null) {
            return app.icon;
          }
        } catch (e) {
          // App not found in the list, continue to other methods
          debugPrint(
              'App $packageName not found in current list when loading icon data: $e');
        }
  
        // If not found or icon is null, try to load icon
        return await _loadAppIcon(packageName);
      } catch (e) {
        debugPrint('Error getting app icon data for $packageName: $e');
        return null;
      }
    }
  
    Future<Uint8List?> _loadAppIcon(String packageName) async {
      if (_iconCache.containsKey(packageName)) {
        return _iconCache[packageName];
      }
  
      try {
        // First try to load from database cache
        final iconData = await AppDatabase.loadIconFromCache(packageName);
        if (iconData != null) {
          // Manage cache size
          if (_iconCache.length >= _maxCacheSize) {
            _iconCache.remove(_iconCache.keys.first);
          }
          _iconCache[packageName] = iconData;
          return iconData;
        }
  
        // Fallback to loading from app if not in cache
        final app = _apps.firstWhere((app) => app.packageName == packageName);
        if (app.icon != null) {
          // Manage cache size
          if (_iconCache.length >= _maxCacheSize) {
            _iconCache.remove(_iconCache.keys.first);
          }
          _iconCache[packageName] = app.icon!;
          return app.icon;
        }
      } catch (e) {
        debugPrint('Error loading icon: $e');
      }
      return null;
    }
    bool _isFirstResume = true;
    bool _pendingAppReturnAd = false;
    @override
    void didChangeAppLifecycleState(AppLifecycleState state) {
      super.didChangeAppLifecycleState(state);
      switch (state) {
        case AppLifecycleState.resumed:
        // App is in the foreground
          debugPrint('App resumed - refreshing app list');
          _loadApps(background: true, forceRefresh: true);
  
          if (_pendingAppReturnAd) {
            _pendingAppReturnAd = false;
            _showAdOnResume();
          }
          break;
        case AppLifecycleState.inactive:
          break;
        case AppLifecycleState.paused:
        // App is in the background
          _savePinnedAppsBackup();
          break;
        case AppLifecycleState.detached:
        // App is detached from UI (being killed)
          _savePinnedAppsBackup();
          break;
        case AppLifecycleState.hidden:
          break;
      }
    }
  
    Future<void> _showAdOnResume() async {
      print('🎯 App resumed - showing ad before navigation back completes');
      print('📊 Ad Status: ${InterstitialAdManager.instance.isAdReady}');
      
      // Only show interstitial ad if app is default launcher
      final isDefault = await LauncherHelper.isDefaultLauncher();
      if (isDefault) {
        await InterstitialAdManager.instance.showAdAlways();
      }
      
      print('✅ Ad flow completed on resume');
    }
  
    Future<void> _savePinnedApps() async {
      final prefs = await SharedPreferences.getInstance();
  
      // Keep only valid apps while preserving order
      final validPinnedApps = _pinnedApps
          .where((app) => _apps.any((a) => a.packageName == app.packageName))
          .toList();
  
      if (!listEquals(validPinnedApps, _pinnedApps)) {
        setState(() {
          _pinnedApps = validPinnedApps;
        });
      }
  
      // Save both package names and their order
      final pinnedAppData = validPinnedApps
          .asMap()
          .map((index, app) => MapEntry(app.packageName, index));
      await prefs.setString('pinned_apps_data', jsonEncode(pinnedAppData));
    }
  
    Future<void> _loadPinnedApps() async {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString('pinned_apps_data');
  
      if (_apps.isEmpty || savedData == null) return;
  
      try {
        final Map<String, dynamic> pinnedData = jsonDecode(savedData);
        final orderedApps = <AppInfo>[];
  
        // Sort by saved index and create list
        final sortedEntries = pinnedData.entries.toList()
          ..sort((a, b) => (a.value as int).compareTo(b.value as int));
  
        for (var entry in sortedEntries) {
          try {
            final app = _apps.firstWhere(
                  (app) => app.packageName == entry.key,
            );
            orderedApps.add(app);
          } catch (e) {
            // Skip if app not found
            continue;
          }
        }
  
        setState(() {
          _pinnedApps = orderedApps;
        });
      } catch (e) {
        debugPrint('Error loading pinned apps: $e');
      }
    }
  
    Future<void> _saveWidgetOrder() async {
      final prefs = await SharedPreferences.getInstance();
      final widgetIds = _addedWidgets
          .where((w) => w.widgetId != null)
          .map((w) => w.widgetId.toString())
          .toList();
      await prefs.setStringList('widget_order', widgetIds);
    }

    Future<void> _loadSortTypes() async {
      _appListSortType = await AppUsageTracker.getSavedAppListSortType();
      if (mounted) setState(() {});
    }
  
    double _getBottomSheetPadding(BuildContext context) {
      // Get the bottom padding (includes navigation bar height)
      final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
      // Add additional padding for visual spacing
      return bottomPadding + 16.0;
    }
  
    void _unfocusSearch() {
      _searchFocusNode.unfocus();
      setState(() {});
    }
  
    void _openWebViewScreen() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchFeedScreen(),
        ),
      );
    }
  
  
    void _handleMicTap() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SearchFeedScreen(triggerMicPermission: true),
        ),
      );
    }
  
    Widget _buildSearchBar() {
      final isDarkMode = Theme.of(context).brightness != Brightness.dark;
      final controller = _showingHiddenApps || _isSelectingAppsToHide
          ? _hiddenAppsSearchController
          : _searchController;
  
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom:  12,
          top: 0, // Removed top padding to bring apps closer to search bar
        ),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              // Search Icon + TextField
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: _searchFocusNode,
                  onTap: (){
                    FocusManager.instance.primaryFocus?.unfocus();
                    _openWebViewScreen();
                  },
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    hintText: _showingHiddenApps
                        ? 'Search hidden apps...'
                        : _isSelectingAppsToHide
                        ? 'Search apps to hide...'
                        : 'Search',
                    hintStyle: TextStyle(
                      color: (isDarkMode ? Colors.white : Colors.black54),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDarkMode ? Colors.white54 : Colors.black45,
                      size: 22,
                    ),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDarkMode ? Colors.white54 : Colors.black45,
                        size: 20,
                      ),
                      onPressed: () {
                        controller.clear();
                        setState(() {});
                      },
                    )
                        : null,
                    border: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
  
              // Divider
              Container(
                width: 1,
                height: 24,
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
  
              // Mic Icon
              IconButton(
                icon: Icon(
                  Icons.mic,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 22,
                ),
                onPressed: _handleMicTap,
              ),
  
              // Divider
              Container(
                width: 1,
                height: 24,
                color: isDarkMode ? Colors.white24 : Colors.black12,
              ),
  
              // Settings Icon
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  size: 22,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeftViewScreen(initialIndex: 2,),
                    ),
                  );
                },
              ),
  
              const SizedBox(width: 4),
            ],
          ),
        ),
      );
    }
    Future<void> _loadHiddenApps() async {
      final hiddenApps = await HiddenAppsManager.loadHiddenApps();
      setState(() {
        _hiddenApps.clear();
        _hiddenApps.addAll(hiddenApps);
      });
    }
  
    Future<void> _saveHiddenApps() async {
      await HiddenAppsManager.saveHiddenApps(_hiddenApps);
    }
  
    Future<void> _savePinnedAppsBackup() async {
      await HiddenAppsManager.savePinnedAppsBackup(_pinnedAppsBackup);
    }
  
    Future<void> _loadPinnedAppsBackup() async {
      final backup = await HiddenAppsManager.loadPinnedAppsBackup();
      _pinnedAppsBackup.clear();
      _pinnedAppsBackup.addAll(backup);
    }
  
    Future<void> _loadHiddenAppFolderMap() async {
      final map = await HiddenAppsManager.loadHiddenAppFolderMap();
      if (mounted) {
        setState(() {
          _hiddenAppFolderMap.clear();
          _hiddenAppFolderMap.addAll(map);
        });
      }
    }
  
    Future<void> _saveHiddenAppFolderMap() async {
      await HiddenAppsManager.saveHiddenAppFolderMap(_hiddenAppFolderMap);
    }
  
    bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  
    void _refreshAppLayout() {
      setState(() {
        // Force rebuild of the app layout
        _appLayoutKey = UniqueKey();
      });
    }
  
    void _widgetsScrollListener() {
      // Update scrolling state
      if (!_isWidgetsScrolling) {
        setState(() {
          _isWidgetsScrolling = true;
        });
      }
  
      // Reset timer on each scroll event
      _widgetsScrollEndTimer?.cancel();
      _widgetsScrollEndTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isWidgetsScrolling = false;
          });
        }
      });
    }
  
    void _appsScrollListener() {
      // Update scrolling state
      if (!_isAppsScrolling) {
        setState(() {
          _isAppsScrolling = true;
        });
      }
  
      // Reset timer on each scroll event
      _appsScrollEndTimer?.cancel();
      _appsScrollEndTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isAppsScrolling = false;
          });
        }
      });
  
      // Keep the existing smooth scroll listener functionality
      if (!_scrollController.hasClients) return;
  
      final position = _scrollController.position.pixels;
  
      // Calculate current section
      double currentPos = 0;
      if (_pinnedApps.isNotEmpty && _searchController.text.isEmpty) {
        currentPos += 48.0 + (_pinnedApps.length * 72.0) + 16.0 + 48.0;
      }
  
      String newSection = '';
      for (var section in _appSections) {
        final sectionHeight = 40.0 + (section.apps.length * 72.0);
        if (position >= currentPos && position < (currentPos + sectionHeight)) {
          newSection = section.letter;
          break;
        }
        currentPos += sectionHeight;
      }
  
      if (newSection != _currentSection) {
        _currentSection = newSection;
        HapticFeedback.selectionClick();
      }
    }
  
    Future<void> _restoreAppToFolder(String packageName) async {
      if (_hiddenAppFolderMap.containsKey(packageName)) {
        final int? folderId = _hiddenAppFolderMap[packageName];
        if (folderId == null) {
          _hiddenAppFolderMap.remove(packageName);
          await _saveHiddenAppFolderMap();
          return;
        }
        try {
          final targetFolder = _folders.firstWhere((f) => f.id == folderId);
          if (!targetFolder.appPackageNames.contains(packageName)) {
            targetFolder.appPackageNames.add(packageName);
            await AppDatabase.updateFolder(targetFolder);
          }
          _hiddenAppFolderMap.remove(packageName);
          await _saveHiddenAppFolderMap();
          await _loadFolders();
        } catch (e) {
          _hiddenAppFolderMap.remove(packageName);
          await _saveHiddenAppFolderMap();
          debugPrint("Folder with id $folderId not found for app $packageName");
        }
      }
    }
  
    Future<void> _removeAppFromFolderIfHidden(String packageName) async {
      Folder? parentFolder;
      try {
        parentFolder = _folders.firstWhere(
              (f) => f.appPackageNames.contains(packageName),
        );
      } catch (e) {
        parentFolder = null;
      }
  
      if (parentFolder != null && parentFolder.id != null) {
        _hiddenAppFolderMap[packageName] = parentFolder.id!;
        parentFolder.appPackageNames.remove(packageName);
        await AppDatabase.updateFolder(parentFolder);
        await _saveHiddenAppFolderMap();
        await _loadFolders();
      }
    }

    void _showAppDrawerBottomSheet() {
      final TextEditingController _bottomSheetSearchController =
      TextEditingController();
      NavigationState.currentScreen = 'bottom_sheet';

      double _dragAccum = 0;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height,
          maxWidth: MediaQuery.of(context).size.width,
        ),
        builder: (context) => PopScope(
          canPop: true,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              void handleDragUpdate(DragUpdateDetails details) {
                if (details.delta.dy > 0) {
                  _dragAccum += details.delta.dy;
                }
              }

              void handleDragEnd(DragEndDetails details) {
                final velocity = details.primaryVelocity ?? 0;
                if (_dragAccum > 40 || velocity > 250) {
                  Navigator.of(context).pop();
                }
                _dragAccum = 0;
              }

              return SafeArea(
                child: Container(
                  height: MediaQuery.of(context).size.height * 1.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFfefbfe),
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      // ── DRAGGABLE HEADER ZONE (handle + search bar) ──
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: handleDragUpdate,
                        onVerticalDragEnd: handleDragEnd,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: TextField(
                                controller: _bottomSheetSearchController,
                                onChanged: (value) {
                                  setModalState(() {});
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search apps...',
                                  hintStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.5)),
                                  prefixIcon: Icon(Icons.search,
                                      color: Colors.black.withOpacity(0.7)),
                                  suffixIcon: _bottomSheetSearchController
                                      .text.isNotEmpty
                                      ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color:
                                        Colors.black.withOpacity(0.7)),
                                    onPressed: () {
                                      _bottomSheetSearchController.clear();
                                      setModalState(() {});
                                    },
                                  )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.05),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                ),
                                style: const TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── App list: overscroll-from-top bhi close karega ──
                      Expanded(
                        child: NotificationListener<OverscrollNotification>(
                          onNotification: (notification) {
                            if (notification.overscroll < -10 &&
                                notification.metrics.pixels <=
                                    notification.metrics.minScrollExtent) {
                              Navigator.of(context).pop();
                            }
                            return false;
                          },
                          child: _bottomSheetSearchController.text.trim().isEmpty
                              ? Builder(
                            builder: (context) {
                              final filteredApps = _apps;
                              return PageView.builder(
                                controller: _bottomSheetPageController,
                                onPageChanged: (page) {
                                  setModalState(() {
                                    _currentBottomSheetPage = page;
                                  });
                                },
                                itemCount:
                                (filteredApps.length / 20).ceil(),
                                itemBuilder: (context, pageIndex) {
                                  final startIndex = pageIndex * 20;
                                  final endIndex = (startIndex + 20)
                                      .clamp(0, filteredApps.length);
                                  final pageApps = filteredApps.sublist(
                                      startIndex, endIndex);
                                  return _appsGrid(pageApps);
                                },
                              );
                            },
                          )
                              : Builder(
                            builder: (context) {
                              final query = _bottomSheetSearchController
                                  .text
                                  .trim()
                                  .toLowerCase();
                              final filteredApps = _apps.where((app) {
                                if (app.packageName ==
                                    'com.kayfahaarukku.homelauncherthree') {
                                  return false;
                                }
                                return app.name
                                    .toLowerCase()
                                    .contains(query) ||
                                    app.packageName
                                        .toLowerCase()
                                        .contains(query);
                              }).toList();
                              return _appsGrid(filteredApps);
                            },
                          ),
                        ),
                      ),
                      const HybridBannerAdWidget(),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ).then((_) {
        setState(() {
          _isBottomSheetOpen = false;
          NavigationState.currentScreen = 'main';
        });
      });
    }
    Widget _appsGrid(List<AppInfo> apps) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: apps.length,
        itemBuilder: (context, index) {
          final app = apps[index];
          return GestureDetector(
            onTap: () async {
              Navigator.pop(context);

              // Only show interstitial ad if app is default launcher
              final isDefault = await LauncherHelper.isDefaultLauncher();
              if (isDefault) {
                await InterstitialAdManager.instance.showAdAlways();
              }

              await AppUsageTracker.recordAppLaunch(app.packageName);
              _pendingAppReturnAd = true;
              AdFlowState.suppressAppOpenAdOnNextResume = true;
              await InstalledApps.startApp(app.packageName);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: app.icon != null
                        ? Image.memory(
                      app.icon!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.apps, size: 32, color: Colors.black45),
                    )
                        : const Icon(Icons.apps, size: 32, color: Colors.black45),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app.name,
                  style: const TextStyle(fontSize: 11, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }
  }

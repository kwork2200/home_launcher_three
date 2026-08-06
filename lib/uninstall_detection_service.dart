import 'package:installed_apps/installed_apps.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class UninstallDetectionService {
  static final UninstallDetectionService _instance = UninstallDetectionService._internal();
  factory UninstallDetectionService() => _instance;
  UninstallDetectionService._internal();

  List<String> _previousInstalledPackages = [];
  bool _initialized = false;
  bool _isChecking = false;
  Timer? _periodicCheckTimer;
  bool _periodicCheckingStarted = false;
  
  bool get isInitialized => _initialized;
  
  /// Callback for when uninstalled apps are detected
  Function(List<String>)? onUninstalledAppsDetected;

  /// Initialize the service with current installed apps
  Future<void> initialize() async {
    try {
      final apps = await InstalledApps.getInstalledApps();
      _previousInstalledPackages = apps.map((app) => app.packageName).toList();
      _initialized = true;
      debugPrint('🔍 UninstallDetectionService initialized with ${_previousInstalledPackages.length} apps');
    } catch (e) {
      debugPrint('❌ Error initializing UninstallDetectionService: $e');
    }
  }

  /// Start periodic checking for uninstalled apps (every 30 seconds)
  void startPeriodicChecking() {
    if (_periodicCheckingStarted) {
      debugPrint('⏸️ Periodic checking already started, skipping');
      return;
    }
    
    stopPeriodicChecking();
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      debugPrint('⏰ Running periodic uninstall check');
      final uninstalled = await checkForUninstalledApps();
      if (uninstalled.isNotEmpty && onUninstalledAppsDetected != null) {
        debugPrint('📢 Calling uninstall callback with ${uninstalled.length} apps');
        // Use Future.microtask to ensure callback runs in proper event loop
        Future.microtask(() {
          if (onUninstalledAppsDetected != null) {
            onUninstalledAppsDetected!(uninstalled);
          }
        });
      }
    });
    _periodicCheckingStarted = true;
    debugPrint('🔄 Started periodic uninstall checking');
  }

  /// Stop periodic checking
  void stopPeriodicChecking() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
    _periodicCheckingStarted = false;
    debugPrint('⏹️ Stopped periodic uninstall checking');
  }

  /// Check for uninstalled apps and return the package names
  Future<List<String>> checkForUninstalledApps() async {
    // Prevent concurrent checks
    if (_isChecking) {
      debugPrint('⏳ Uninstall check already in progress, skipping');
      return [];
    }
    
    _isChecking = true;
    
    try {
      if (!_initialized) {
        await initialize();
      }

      final currentApps = await InstalledApps.getInstalledApps();
      final currentPackages = currentApps.map((app) => app.packageName).toList();

      // Find packages that were in previous list but not in current list
      final uninstalledPackages = _previousInstalledPackages.where((previousPackage) {
        return !currentPackages.contains(previousPackage);
      }).toList();

      if (uninstalledPackages.isNotEmpty) {
        debugPrint('🗑️ Detected ${uninstalledPackages.length} uninstalled apps: $uninstalledPackages');
      }

      // Update the previous list
      _previousInstalledPackages = currentPackages;

      return uninstalledPackages;
    } catch (e) {
      debugPrint('❌ Error checking for uninstalled apps: $e');
      return [];
    } finally {
      _isChecking = false;
    }
  }

  /// Force refresh the current installed apps list without checking for uninstalls
  Future<void> refreshInstalledApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps();
      _previousInstalledPackages = apps.map((app) => app.packageName).toList();
      _initialized = true;
      debugPrint('🔄 UninstallDetectionService refreshed with ${_previousInstalledPackages.length} apps');
      
      // Ensure periodic checking is running if callback is set
      if (onUninstalledAppsDetected != null && !_periodicCheckingStarted) {
        debugPrint('🔄 Ensuring periodic checking is running after refresh');
        startPeriodicChecking();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing UninstallDetectionService: $e');
    }
  }

  /// Reset the service (call this when you want to start fresh)
  void reset() {
    _previousInstalledPackages = [];
    _initialized = false;
    _isChecking = false;
    stopPeriodicChecking();
  }
  
  /// Clean up resources
  void dispose() {
    stopPeriodicChecking();
  }
}

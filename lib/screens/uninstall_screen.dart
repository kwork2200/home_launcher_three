import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_native_ad.dart';
import '../database/app_database.dart';
import '../models/folder.dart';
import 'dart:async';
import '../services/screen_analytics_service.dart';

class UninstallScreen extends StatefulWidget {
  final AppInfo app;
  final List<Folder> folders;
  final Function()? onUninstallComplete;
  final bool showSystemDialog;

  const UninstallScreen({
    super.key,
    required this.app,
    required this.folders,
    this.onUninstallComplete,
    this.showSystemDialog = true,
  });

  @override
  State<UninstallScreen> createState() => _UninstallScreenState();
}

class _UninstallScreenState extends State<UninstallScreen>
    with SingleTickerProviderStateMixin {
  bool _isUninstalling = false;
  bool _isUninstalled = false;
  bool _showToast = false;

  late AnimationController _progressController;

  static const Color _brandColor = Color(0xFF6750A4);

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('uninstall_screen');
    debugPrint('📱 UninstallScreen initState - showSystemDialog: ${widget.showSystemDialog}');

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // If system dialog was already shown, automatically start uninstall process
    if (!widget.showSystemDialog) {
      debugPrint('⚡ Auto-starting uninstall process');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          debugPrint('🚀 Calling _performUninstall');
          _performUninstall();
        } else {
          debugPrint('❌ Widget not mounted, cannot start uninstall');
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Uninstall App',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isDarkMode ? Colors.white : Colors.black).withAlpha(13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: isDarkMode ? Colors.white : Colors.black,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      _buildStatusIcon(isDarkMode),
                      const SizedBox(height: 28),
                      _buildProgressBar(isDarkMode),
                      const SizedBox(height: 28),
                      _buildMessageCard(isDarkMode),
                      const SizedBox(height: 28),
                      const CustomNativeAd(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: (_isUninstalled
                          ? () => Navigator.pop(context, true)
                          : _performUninstall),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isUninstalled ? Colors.green : _brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _isUninstalled ? 'Done' : 'Uninstall',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Bottom toast, e.g. "Uninstalled AppName"
          if (_showToast)
            Positioned(
              left: 40,
              right: 40,
              bottom: 90,
              child: AnimatedOpacity(
                opacity: _showToast ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(200),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'Uninstalled ${widget.app.name}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Circular outlined icon with a small badge (check / warning / spinner)
  Widget _buildStatusIcon(bool isDarkMode) {
    Color badgeColor;
    Widget badgeIcon;

    if (_isUninstalled) {
      badgeColor = Colors.green;
      badgeIcon = const Icon(Icons.check, color: Colors.white, size: 18);
    } else if (_isUninstalling) {
      badgeColor = _brandColor;
      badgeIcon = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    } else {
      badgeColor = Colors.orange;
      badgeIcon =
      const Icon(Icons.priority_high_rounded, color: Colors.white, size: 18);
    }

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isUninstalled ? Colors.green : _brandColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 46,
                color: _isUninstalled ? Colors.green : _brandColor,
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: badgeIcon),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDarkMode) {
    if (_isUninstalled) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: _isUninstalling ? _progressController.value : 0.08,
              backgroundColor: (isDarkMode ? Colors.white : Colors.black)
                  .withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(
                _isUninstalled ? Colors.green : _brandColor,
              ),
              minHeight: 6,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          _isUninstalling ? 'Processing...' : 'Ready to uninstall',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: (isDarkMode ? Colors.white : Colors.black).withAlpha(153),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(bool isDarkMode) {
    late String title;
    late String subtitle;

    if (_isUninstalled) {
      title = 'App Removed';
      subtitle = '${widget.app.name} has been removed from your device.';
    } else if (_isUninstalling) {
      title = widget.showSystemDialog ? 'Uninstalling...' : 'Processing...';
      subtitle = widget.showSystemDialog
          ? 'Please wait while we remove ${widget.app.name}'
          : 'Completing uninstall process for ${widget.app.name}';
    } else {
      title = 'Are you sure?';
      subtitle =
      'This action will uninstall ${widget.app.name} from your device. This cannot be undone.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF1EFEE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: (isDarkMode ? Colors.white : Colors.black).withAlpha(153),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<bool> _waitForUninstallComplete() async {
    const maxAttempts = 100; // Check for up to 10 seconds (100 * 100ms)
    const checkInterval = Duration(milliseconds: 100);
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      await Future.delayed(checkInterval);
      
      try {
        // Check if app is still installed
        final isInstalled = await InstalledApps.isAppInstalled(widget.app.packageName);
        
        if (isInstalled == false) {
          debugPrint('✅ App ${widget.app.packageName} successfully uninstalled after ${attempt * checkInterval.inMilliseconds}ms');
          return true;
        }
        
        // Only log every 10 attempts to reduce noise
        if (attempt % 10 == 0) {
          debugPrint('⏳ Attempt $attempt: App still installed, checking again...');
        }
      } catch (e) {
        debugPrint('⚠️ Error checking install status: $e');
        // If we can't check, assume it might be uninstalled
        if (attempt > 5) {
          debugPrint('⚠️ Assuming uninstalled after multiple check failures');
          return true;
        }
      }
    }
    
    debugPrint('⚠️ Timeout waiting for uninstall, proceeding anyway');
    return true; // Proceed even if timeout to avoid blocking
  }

  Future<void> _cleanupAppData() async {
    debugPrint('🗂️ Removing from folders');
    // Remove from any folder
    for (var folder in widget.folders) {
      if (folder.appPackageNames.contains(widget.app.packageName)) {
        folder.appPackageNames.remove(widget.app.packageName);
        await AppDatabase.updateFolder(folder);
        debugPrint('✅ Removed from folder: ${folder.name}');
      }
    }

    debugPrint('💾 Removing from database');
    // Immediately remove from our database
    await AppDatabase.removeApp(widget.app.packageName);
    debugPrint('✅ Removed from database');
  }

  Future<void> _performUninstall() async {
    debugPrint('🔧 _performUninstall called');

    if (!mounted) {
      debugPrint('❌ Widget not mounted in _performUninstall');
      return;
    }

    // Check if app is already uninstalled before proceeding
    try {
      final isInstalled = await InstalledApps.isAppInstalled(widget.app.packageName);
      if (isInstalled == false) {
        debugPrint('✅ App already uninstalled, showing confirmation UI');
        if (mounted) {
          setState(() {
            _isUninstalling = false;
            _isUninstalled = true;
            _showToast = true;
          });

          await _cleanupAppData();

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _showToast = false);
          });

          // ✅ Ye add karo — pehle missing tha
          await Future.delayed(const Duration(milliseconds: 1200));
          widget.onUninstallComplete?.call();
        }
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking install status: $e');
    }

    debugPrint('⏳ Setting _isUninstalling to true');
    setState(() {
      _isUninstalling = true;
    });
    _progressController.forward(from: 0);

    try {
      debugPrint('📋 Starting uninstall process for ${widget.app.packageName}');

      // Only show system dialog if the flag is true
      if (widget.showSystemDialog) {
        debugPrint('📱 Showing system uninstall dialog');

        // Start polling IMMEDIATELY in parallel with the system dialog
        // This will detect uninstall as soon as user confirms in system dialog
        final pollingFuture = _waitForUninstallComplete();

        // Show system dialog (this will wait for user interaction)
        await InstalledApps.uninstallApp(widget.app.packageName);
        debugPrint('✅ System dialog completed');

        // Wait for polling to complete (should already be done if user confirmed)
        await pollingFuture;
        debugPrint('✅ Polling completed');
      } else {
        debugPrint('⏭️ Skipping system dialog (already shown)');

        // If dialog was already shown, just poll for completion
        await _waitForUninstallComplete();
      }

      // Clean up app data
      await _cleanupAppData();

      if (mounted) {
        debugPrint('✅ Setting success state');
        setState(() {
          _isUninstalling = false;
          _isUninstalled = true;
          _showToast = true;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showToast = false;
            });
          }
        });

        debugPrint('📞 Calling onUninstallComplete callback after 1500ms delay');
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onUninstallComplete?.call();
      } else {
        debugPrint('❌ Widget not mounted after uninstall');
      }
    } catch (e) {
      debugPrint('❌ Error in uninstall process: $e');
      if (mounted) {
        setState(() {
          _isUninstalling = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to uninstall: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
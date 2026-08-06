import 'package:flutter/material.dart';
import '../main.dart';

class NoTextScreen extends StatefulWidget {
  const NoTextScreen({
    super.key,
    this.title = "Nothing here yet",
    this.subtitle = "There's no data to show right now.\nCheck back later.",
    this.icon = Icons.inbox_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<NoTextScreen> createState() => _NoTextScreenState();
}

class _NoTextScreenState extends State<NoTextScreen> {
  bool _isLauncherDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _checkDefaultLauncherAndShowDialog();
  }

  Future<void> _checkDefaultLauncherAndShowDialog() async {
    final isDefault = await LauncherHelper.isDefaultLauncher();
    debugPrint("🏠 NoTextScreen - Default launcher status: $isDefault");
    
    if (isDefault) {
      // Skip NoTextScreen if already default launcher
      debugPrint("🏠 Already default launcher - skipping NoTextScreen, going to home");
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyHomePage()),
            (route) => false,
      );
    } else {
      // Show system dialog to set as default launcher
      debugPrint("🏠 Not default launcher - showing system dialog");
      setState(() => _isLauncherDialogOpen = true);
      await LauncherHelper.requestSetAsDefaultLauncher();
      setState(() => _isLauncherDialogOpen = false);
      
      // Check again after dialog
      final isDefaultAfterDialog = await LauncherHelper.isDefaultLauncher();
      if (isDefaultAfterDialog && mounted) {
        debugPrint("🏠 Now default launcher - going to home");
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
              (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if default launcher is set
        final isDefault = await LauncherHelper.isDefaultLauncher();
        
        // Block back button if not default launcher or during dialog
        if (!isDefault || _isLauncherDialogOpen) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glowing circular icon container
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 42,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Thin decorative divider dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                              (i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15 + (i * 0.1)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLauncherDialogOpen)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFF61601)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
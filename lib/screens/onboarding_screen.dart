import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../managers/app_open_ad_manager.dart';
import 'language_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const Color primaryColor = Color(0xFFf84241);
  static const Color backgroundColor = Color(0xFF141414);
  static const Color subtitleColor = Color(0xFFBDBDBD);
  static const Color indicatorInactiveColor = Color(0xFF4A4A4A);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isProcessing = false;
  bool _isLauncherDialogOpen = false;
  int _dialogCancelCount = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Watch hd videos anytime',
      description: 'Download and watch hd videos',
      illustration: 'assets/images/onBordingImg.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _showAppOpenAd();
  }


  Future<void> _showAppOpenAd() async {
    print('🎯 Onboarding screen opened, showing AppOpenAd');
    await Future.delayed(const Duration(milliseconds: 500));
    AppOpenAdManager.instance.showAdIfAvailable();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', 'hi');
    // Don't set language_selection_completed here - let LanguageSelectionScreen handle it
    await prefs.setBool('onboarding_completed', true);

    setState(() => _isLauncherDialogOpen = true);
    await LauncherHelper.requestSetAsDefaultLauncher();
    setState(() => _isLauncherDialogOpen = false);

    final isDefault = await LauncherHelper.isDefaultLauncher();

    if (isDefault) {
      await LauncherHelper.initializeAdsIfDefaultLauncher();

      if (!mounted) return;
      setState(() => _isProcessing = false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LanguageSelectionScreen()),
            (route) => false,
      );
    } else {
      if (!mounted) return;
      setState(() => _isProcessing = false);

      _dialogCancelCount++;

      if (_dialogCancelCount >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setting as default launcher is required. Please tap the checkmark to try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please set as default launcher to continue'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    /*// Check if app is now default launcher and initialize ads if so
    await LauncherHelper.initializeAdsIfDefaultLauncher();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MyHomePage()),
          (route) => false,
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Check if default launcher is set
        final isDefault = await LauncherHelper.isDefaultLauncher();
        
        // Block back button if not default launcher or during processing/dialog
        if (!isDefault || _isProcessing || _isLauncherDialogOpen) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Page view
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPageContent(_pages[index]);
                      },
                    ),
                  ),

                  // Page indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Next/Get Started button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: subtitleColor,
              height: 1.4,
            ),
          ),
          Image.asset(
            page.illustration,
            height: 260,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : indicatorInactiveColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String illustration;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });
}
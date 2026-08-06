import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../modules/home/home_controller.dart';
import '../modules/home/home_screen.dart';
import 'first_launch_flow_screen.dart';
import '../widgets/native_small_ad_widget.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const Color primaryColor = Color(0xFFF61601);
  static const Color backgroundColor = Color(0xFF141414);
  static const Color cardColor = Color(0xFF262626);
  static const Color radioInactiveColor = Color(0xFF6E6E6E);

  String _selectedLanguage = 'hi';
  bool _isProcessing = false;
  bool _isLauncherDialogOpen = false;
  int _dialogCancelCount = 0;

  final List<LanguageOption> _languages = [
    LanguageOption(code: 'hi', name: 'Hindi', flag: '🇮🇳'),
    LanguageOption(code: 'vi', name: 'Vietnamese', flag: '🇻🇳'),
    LanguageOption(code: 'ar', name: 'Arabic', flag: '🇸🇦'),
    LanguageOption(code: 'th', name: 'Thai', flag: '🇹🇭'),
    LanguageOption(code: 'id', name: 'Indonesian', flag: '🇮🇩'),
    LanguageOption(code: 'ne', name: 'Nepali', flag: '🇳🇵'),
    LanguageOption(code: 'ru', name: 'Russian', flag: '🇷🇺'),
    LanguageOption(code: 'fr', name: 'French', flag: '🇫🇷'),
    LanguageOption(code: 'de', name: 'German', flag: '🇩🇪'),
    LanguageOption(code: 'es', name: 'Spanish', flag: '🇪🇸'),
    LanguageOption(code: 'el', name: 'Greek', flag: '🇬🇷'),
    LanguageOption(code: 'ja', name: 'Japanese', flag: '🇯🇵'),
    LanguageOption(code: 'en', name: 'English', flag: '🇬🇧'),
  ];

  @override
  void initState() {
    super.initState();
    // _checkDefaultLauncherAndSkip();
    _loadSavedLanguage();
  }

  Future<void> _checkDefaultLauncherAndSkip() async {
    final isDefault = await LauncherHelper.isDefaultLauncher();
    debugPrint("🏠 LanguageSelectionScreen - Default launcher status: $isDefault");
    
    if (isDefault) {
      // Skip language selection if already default launcher
      debugPrint("🏠 Already default launcher - skipping language selection screen");
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('language_selection_completed', true);
      await prefs.setBool('onboarding_completed', true);
      
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
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('language_selection_completed', true);
        await prefs.setBool('onboarding_completed', true);
        
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MyHomePage()),
              (route) => false,
        );
      }
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selected_language') ?? 'hi';
    });
  }

  Future<void> _saveLanguageAndContinue() async {
    if (_isProcessing) return; // double-tap se bachne ke liye
    setState(() => _isProcessing = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', _selectedLanguage);
    await prefs.setBool('language_selection_completed', true);
    await prefs.setBool('onboarding_completed', true);
    _checkDefaultLauncherAndSkip();
    // Always show the default launcher dialog for better user experience
    // Dialog will appear consistently across all Android versions
    // await LauncherHelper.requestSetAsDefaultLauncher();

    // Check if app is now default launcher and initialize ads if so
    // await LauncherHelper.initializeAdsIfDefaultLauncher();

    if (!mounted) return;
    setState(() => _isProcessing = false);

    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (context) => const MyHomePage()),
    //       (route) => false,
    // );
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
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // Header: title + checkmark confirm button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Language',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          InkWell(
                            onTap: _saveLanguageAndContinue,
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              height: 44,
                              width: 44,
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Language list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _languages.length + ((_languages.length - 1) ~/ 2),
                    itemBuilder: (context, index) {
                      final isAdPosition = (index + 1) % 3 == 0;
                      
                      if (isAdPosition) {
                        // Show small native ad
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: NativeSmallAdWidget(
                            height: 80,
                            adKey: 'language_selection',
                            size: NativeAdSize.small,
                          ),
                        );
                      }
                      final languageIndex = index - (index ~/ 3);
                      final language = _languages[languageIndex];
                      final isSelected = _selectedLanguage == language.code;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedLanguage = language.code;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  // Flag
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: backgroundColor,
                                    child: Text(
                                      language.flag,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Language name
                                  Expanded(
                                    child: Text(
                                      language.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                  // Radio indicator
                                  Container(
                                    height: 24,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : radioInactiveColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                      child: Container(
                                        height: 12,
                                        width: 12,
                                        decoration: const BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing || _isLauncherDialogOpen)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            ),
        ],
      ),
    ));
  }
}

class LanguageOption {
  final String code;
  final String name;
  final String flag;

  LanguageOption({
    required this.code,
    required this.name,
    required this.flag,
  });
}


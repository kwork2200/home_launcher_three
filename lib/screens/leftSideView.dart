import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:home_launcher_three/widgets/hybrid_native_ad_widget.dart';

import '../navigation_state.dart';
import '../routes/app_routes.dart';
import '../utils/app_texts.dart';
import '../services/screen_analytics_service.dart';

const String kPrivacyPolicyUrl = 'https://example.com/privacy-policy';
const String kTeamAndConditionyUrl = 'https://docs.google.com/document/d/1x7AZ3ZyWw7J_EidQxqDu_VA46_7BC8EwYnkk2XyX1h4/edit?usp=sharing';

Future<void> _launchUrl(String urlString) async {
  final Uri url = Uri.parse(urlString);
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $urlString');
  }
}

const Color kBackground = Colors.white;
const Color kTextPrimary = Colors.black;
const Color kTextSecondary = Color(0xFF616161);
const Color kBorder = Color(0xFFE0E0E0);
const Color kCardFill = Color(0xFFF5F5F5);
const Color kRed = Color(0xFFE53935);

class LeftViewScreen extends StatefulWidget {
  final int initialIndex;
  const LeftViewScreen({super.key, this.initialIndex = 0});

  @override
  State<LeftViewScreen> createState() => _LeftViewScreenState();
}

class _LeftViewScreenState extends State<LeftViewScreen> {
  late int _selectedIndex = widget.initialIndex;

  static const List<Widget> _screens = [
    HomeScreen(),
    DownloadScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('left_view_screen');
    NavigationState.currentScreen = 'left_view';
  }

  @override
  void dispose() {
    NavigationState.currentScreen = 'main';
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Track tab visits
    switch (index) {
      case 0:
        ScreenAnalyticsService().logScreenVisit('left_view_home_screen');
        break;
      case 1:
        ScreenAnalyticsService().logScreenVisit('left_view_download_screen');
        break;
      case 2:
        ScreenAnalyticsService().logScreenVisit('left_view_settings_screen');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: kBackground,
        body: SafeArea(
          // IndexedStack keeps each tab's state alive when switching
          child: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: kBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: kBackground,
            selectedItemColor: kRed,
            unselectedItemColor: Colors.black54,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.download_outlined),
                activeIcon: Icon(Icons.download),
                label: 'Download',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('left_view_home_screen');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No longer needed as we use HybridNativeAdWidget
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'All Video Downloader',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Download videos from any platform',
            style: TextStyle(
              fontSize: 14,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 16),

          const HybridNativeAdWidget(
            height: 200,
          ),

          const SizedBox(height: 16),

          // Link input + Download button card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: kBorder),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: kBorder),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _linkController,
                          style: const TextStyle(color: kTextPrimary),

                          decoration: InputDecoration(
                            fillColor: AppColors.primaryWhite,
                            hintText: 'Paste your link here',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.copy_outlined,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement download functionality
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Popular Platforms
          const Text(
            'Popular Platforms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _platformTile(
                label: 'Instagram',
                icon: Icons.camera_alt,
                iconColor: Colors.white,
                onTap: (){
                  Get.toNamed(AppRoutes.instagramDownloader);
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFEDA75),
                    Color(0xFFE1306C),
                    Color(0xFF833AB4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              _platformTile(
                label: 'Twitter',
                icon: Icons.close,
                iconColor: Colors.white,
                fill: Colors.black,
                onTap: (){
                  Get.toNamed(AppRoutes.twitterDownloader);
                },
              ),
              _platformTile(
                label:AppTexts.allVideoDownloader,
                icon: Icons.play_arrow,
                iconColor: Colors.white,
                fill: const Color(0xFFEC407A),
                circular: true,
                onTap: (){
                  Get.toNamed(AppRoutes.allVideo);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),
          const HybridNativeAdWidget(
            height: 200,
          ),
        ],
      ),
    );
  }


  /// Platform tile styled like the reference image: a colored rounded-square
  /// (or circle) icon with a brand color / gradient, white glyph, black label.
  Widget _platformTile({
    required String label,
    required IconData icon,
    required Color iconColor,
    Color? fill,
    Gradient? gradient,
    bool circular = false,
    void Function()? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: gradient == null ? fill : null,
              gradient: gradient,
              shape: circular ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circular ? null : BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: kTextPrimary),
          ),
        ],
      ),
    );
  }
}

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('left_view_download_screen');
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No longer needed as we use HybridNativeAdWidget
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: kTextSecondary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kRed,
          tabs: const [
            Tab(text: 'Downloads'),
            Tab(text: 'History'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Downloads tab
              const Center(
                child: Text('No downloads yet'),
              ),
              // History tab
              const Center(
                child: Text('No history yet'),
              ),
            ],
          ),
        ),
        // Native Ad at top center
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: HybridNativeAdWidget(
            height: 250,
          ),
        ),
        const SizedBox(height: 50),

        // Small Native Ad at bottom
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: HybridNativeAdWidget(
            height: 220,
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('left_view_settings_screen');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No longer needed as we use HybridNativeAdWidget
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 15, color: kTextPrimary),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              _launchUrl(kPrivacyPolicyUrl);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.privacy_tip_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
            title: const Text(
              'Team and Condition',
              style: TextStyle(fontSize: 15, color: kTextPrimary),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () {
              _launchUrl(kTeamAndConditionyUrl);
            },
          ),
          const SizedBox(height: 12),

          const Center(
            child: Text(
              'Version: 1.19',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 16),

          // Native Ad at top center
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: HybridNativeAdWidget(
              height: 250,
            ),
          ),
          const SizedBox(height: 50),

          // Small Native Ad at bottom
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: HybridNativeAdWidget(
              height: 220,
            ),
          ),
        ],
      ),
    );
  }
}

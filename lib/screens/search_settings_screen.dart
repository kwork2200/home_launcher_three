import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/ad_helper.dart';
import '../widgets/hybrid_banner_ad_widget.dart';
import '../widgets/hybrid_native_ad_widget.dart';
import '../services/screen_analytics_service.dart';

class SearchFeedScreen extends StatefulWidget {
  final bool triggerMicPermission;

  const SearchFeedScreen({super.key, this.triggerMicPermission = false});

  @override
  State<SearchFeedScreen> createState() => _SearchFeedScreenState();
}

class _SearchFeedScreenState extends State<SearchFeedScreen> {
  static const _systemChannel = MethodChannel('com.example.allhdvideos/system');
  final TextEditingController _searchController = TextEditingController();
  WebViewController? _webViewController;
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    ScreenAnalyticsService().logScreenVisit('search_feed_screen');
    _systemChannel.setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        Navigator.of(context).pop();
        return true;
      }
      if (call.method == 'getNavigationState') {
        return 'SearchFeedScreen';
      }
      return null;
    });

    // Sirf mic tap se aaya ho tab hi permission check ho
    if (widget.triggerMicPermission) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkMicPermission();
      });
    }
  }
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    final encodedQuery = Uri.encodeComponent(query.trim());
    final url = 'https://www.google.com/search?q=$encodedQuery&igu=1';

    setState(() {
      _showSearchResults = true;
    });

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      )
      ..loadRequest(Uri.parse(url));
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showSearchResults = false;
      _webViewController = null;
    });
  }
  Future<void> _checkMicPermission() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted && mounted) {
      _showMicPermissionDialog();
    }
  }
  void _showMicPermissionDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.redAccent, width: 3),
                  ),
                  child: const Icon(Icons.mic, color: Colors.blueAccent, size: 32),
                ),
                const SizedBox(height: 32),
                const Text(
                  'We need your permission to use the mic',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // close dialog
                    final status = await Permission.microphone.request();
                    if (!status.isGranted && mounted) {
                      if (status.isPermanentlyDenied) {
                        openAppSettings();
                      } else {
                        // Show dialog again if still not granted
                        _showMicPermissionDialog();
                      }
                    }
                  },
                  child: const Text(
                    'Try again',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'English (United Kingdom)',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showSearchResults,
      onPopInvokedWithResult: (didPop, result) {
        FocusManager.instance.primaryFocus?.unfocus();
        if (!didPop) {
          if (_showSearchResults) {
            _clearSearch();
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.primaryWhite,
          body: Column(
            children: [
              _buildSearchBar(),
              const SizedBox(height: 8),
              Expanded(
                child: _showSearchResults
                    ? _buildSearchResultsWebView()
                    : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildAdCard(),
                    const SizedBox(height: 8),
                    _buildNewsCard(),
                    const SizedBox(height: 8),

                    _buildNewsCard(),
                    const SizedBox(height: 8),

                    _buildNewsCard(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: _showSearchResults ? null : _buildAppInstallBanner(),
        ),
      ),
    );
  }

  Widget _buildSearchResultsWebView() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return WebViewWidget(controller: _webViewController!);
  }
  // ---------------- Search Bar ----------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDED),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(color: Colors.black87, fontSize: 16),
                      decoration: const InputDecoration(
                        fillColor: Color(0xFFEDEDED),
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.black54, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: _performSearch,
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: const Icon(Icons.close, color: Colors.black54),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                      onTap:
                          (){
                        _showMicPermissionDialog();
                          },
                      child: const Icon(Icons.mic, color: Colors.black87)),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Ad Card (Custom Native Ad) ----------------
  Widget _buildAdCard() {
    return const HybridNativeAdWidget();
  }

  // ---------------- News Card ----------------
  Widget _buildNewsCard() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.zero,
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
            ),
          child:  Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTcBkZS8sx3LoCd7DQFONM2uZ1fbPtOyBr2nHO97L9gpQ&s=10")
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Example Headline: Local Court Delivers Verdict '
                      'in High-Profile Case',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Thu, 30 Jul 2026 11:09 AM',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Banner Ad (Google Banner Ad) ----------------
  Widget _buildAppInstallBanner() {
    return const HybridBannerAdWidget();
  }

  // ---------------- Bottom Nav Bar ----------------
  Widget _buildBottomBar() {
    return Container(
      height: 56,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          Icon(Icons.menu),
          Icon(Icons.crop_square_outlined),
          Icon(Icons.arrow_back),
          Icon(Icons.accessibility_new),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:home_launcher_three/utils/app_colors.dart';
import '../modules/home/widget/home_menu_card.dart';
import '../navigation_state.dart';
import '../routes/app_routes.dart';
import '../utils/app_images.dart';
import '../utils/app_texts.dart';
import '../widgets/components/spacing_widget.dart';
import '../widgets/hybrid_native_ad_widget.dart';

class CallScreen extends StatefulWidget {
  final String? callerName;
  final String? callerNumber;
  final int? callDuration; // in seconds
  final bool? isIncoming;
  final DateTime? callStartTime;

  const CallScreen({
    super.key,
    this.callerName,
    this.callerNumber,
    this.callDuration,
    this.isIncoming,
    this.callStartTime,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int _selectedTab = 0;
  late String _currentTime;
  late String _formattedDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Set navigation state to allow back button
    NavigationState.currentScreen = 'call_screen';
    _updateCurrentTime();
    _updateDuration();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCurrentTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Reset navigation state to main when leaving call screen
    NavigationState.currentScreen = 'main';
    super.dispose();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    });
  }

  void _updateDuration() {
    if (widget.callDuration != null) {
      final minutes = widget.callDuration! ~/ 60;
      final seconds = widget.callDuration! % 60;
      setState(() {
        _formattedDuration = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    } else {
      setState(() {
        _formattedDuration = '00:00';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.primaryWhite,
        body: SafeArea(
          child: Column(
            children: [
              _buildCallInfoHeader(),
              _buildTabBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickDownloadSection(),
                      const SizedBox(height: 24),
                      _buildAdCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Top section: caller name + call info + logo
  Widget _buildCallInfoHeader() {
    final displayName = widget.callerName ?? 'Private Number';
    final callType = widget.isIncoming == true ? 'Incoming Call' : 'Outgoing Call';

    return Container(
      color: const Color(0xFFF3F3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFD9D9D9),
            child: Icon(
              Icons.person,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayName,
                      style:  TextStyle(
                        fontSize: 22,
                        color: AppColors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'V',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        color: AppColors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      callType,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const Spacer(),
                    const Icon(Icons.call, color: Colors.green, size: 26),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        color: AppColors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formattedDuration,
                      style: const TextStyle(fontSize: 16, color: AppColors.black87,
                        fontWeight: FontWeight.bold,),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Red tab bar with 3 icons
  Widget _buildTabBar() {
    final icons = [Icons.menu, Icons.chat_bubble_outline, Icons.more_horiz];
    return Container(
      color: Colors.red,
      child: Row(
        children: List.generate(icons.length, (index) {
          final bool isSelected = index == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: isSelected
                      ? const Border(
                          bottom: BorderSide(color: Colors.white, width: 3),
                        )
                      : null,
                ),
                child: Icon(
                  index == 2 ? Icons.more_horiz : icons[index],
                  color: Colors.white,
                  size: index == 2 ? 28 : 24,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // "Quick Download Platform" title + 2x2 grid of app buttons
  Widget _buildQuickDownloadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
           Text(
            'Quick Download Platform',
            style: TextStyle(
              fontSize: 26,
              fontStyle: FontStyle.italic,
              color: AppColors.black87,
              fontFamily: 'cursive',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HomeMenuCard(
                  title: AppTexts.instagramVideo,
                  image: AppImages.instagramImage,
                  onTap: () {
                    Get.toNamed(AppRoutes.instagramDownloader);
                  },
                ),
              ),
              Spacing.width(15),
              Expanded(
                child: HomeMenuCard(
                  title: AppTexts.xVideo,
                  image: AppImages.twitterImage,
                  onTap: () {
                    Get.toNamed(AppRoutes.twitterDownloader);
                  },
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }

  // Custom Native Ad
  Widget _buildAdCard() {
    return const HybridNativeAdWidget();
  }
}

// Reusable rounded rectangle button used in the 2x2 platform grid
class _PlatformButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconBg;
  final Gradient? gradient;
  final Color iconColor;

  const _PlatformButton({
    required this.label,
    required this.icon,
    this.iconBg,
    this.gradient,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                gradient: gradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.black87,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

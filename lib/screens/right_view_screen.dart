import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class NewsItem {
  final String title;
  final String imageUrl;
  final String source;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.source,
  });
}


class RightViewScreen extends StatefulWidget {
  final List<AppInfo> recentApps;
  final List<AppInfo> googleApps;
  final List<NewsItem> newsItems;


  final WidgetBuilder? nativeAdBuilder;

  const RightViewScreen({
    super.key,
    this.recentApps = const [],
    this.googleApps = const [],
    this.newsItems = const [],
    this.nativeAdBuilder,
  });

  @override
  State<RightViewScreen> createState() => _RightViewScreenState();
}

class _RightViewScreenState extends State<RightViewScreen> {
  // Fixed "Google Apps" shortcuts — edit package names to match real apps.
  final List<_QuickApp> _googleApps = const [
    _QuickApp(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_fill,
      iconColor: Colors.red,
    ),
    _QuickApp(
      name: 'Maps',
      packageName: 'com.google.android.apps.maps',
      icon: Icons.location_on,
      iconColor: Colors.green,
    ),
    _QuickApp(
      name: 'Drive',
      packageName: 'com.google.android.apps.docs',
      icon: Icons.insert_drive_file_outlined,
      iconColor: Colors.blue,
    ),
    _QuickApp(
      name: 'Docs',
      packageName: 'com.google.android.apps.docs.editors.docs',
      icon: Icons.description,
      iconColor: Colors.blue,
    ),
  ];

  Future<void> _launchPackage(String packageName) async {
    try {
      await InstalledApps.startApp(packageName);
    } catch (e) {
      debugPrint('Could not launch $packageName: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
            _sectionTitle('Recent Used'),
              _appRowCard(
                apps: widget.recentApps
                    .map((a) => _QuickApp(name: a.name, packageName: a.packageName, iconBytes: a.icon))
                    .toList(),
              ),
            _sectionTitle('Google Apps'),
              _appRowCard(
                apps: widget.googleApps
                    .map((a) => _QuickApp(name: a.name, packageName: a.packageName, iconBytes: a.icon))
                    .toList(),
              ),
            const SizedBox(height: 8),
            widget.nativeAdBuilder != null
                ? widget.nativeAdBuilder!(context)
                : _placeholderAdCard(),
            const SizedBox(height: 8),
            _sectionTitle('Latest News'),
            ..._newsList(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _appRowCard({required List<_QuickApp> apps}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: apps.take(4).map((app) => _appIconTile(app)).toList(),
        ),
      ),
    );
  }

  Widget _appIconTile(_QuickApp app) {
    return GestureDetector(
      onTap: () => _launchPackage(app.packageName),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: app.iconBytes != null
                    ? Image.memory(app.iconBytes!, fit: BoxFit.cover)
                    : Icon(
                        app.icon ?? Icons.apps,
                        color: app.iconColor ?? Colors.black54,
                        size: 30,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              app.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  /// Placeholder native-ad card styled like the reference screenshot.
  /// Swap this out for your real ad SDK's widget via [nativeAdBuilder].
  Widget _placeholderAdCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Sponsored App',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Ad',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'A short description of the promoted app goes here',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: Colors.grey.shade300),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OPEN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _newsList() {
    if (widget.newsItems.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'No news available',
            style: TextStyle(color: Colors.white.withAlpha(150)),
          ),
        ),
      ];
    }

    return widget.newsItems
        .map((item) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.grey.shade800),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withAlpha(200),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.source,
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }
}

class _QuickApp {
  final String name;
  final String packageName;
  final IconData? icon;
  final Color? iconColor;
  final dynamic iconBytes; // Uint8List? from AppInfo.icon

  const _QuickApp({
    required this.name,
    required this.packageName,
    this.icon,
    this.iconColor,
    this.iconBytes,
  });
}

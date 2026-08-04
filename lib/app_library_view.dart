import 'dart:typed_data';
import 'package:home_launcher_three/utils/app_colors.dart';
import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// DATA MODELS
/// ---------------------------------------------------------------------------

class LibraryApp {
  final String name;

  /// Real installed app's package name (used to launch it). Null for demo/sample apps.
  final String? packageName;

  /// Real app icon bytes (e.g. from AppInfo.icon). If provided, this is used
  /// instead of [icon] + [background].
  final Uint8List? iconBytes;

  /// Placeholder icon used only when [iconBytes] is not available.
  final IconData icon;
  final Color background;
  final Color iconColor;

  const LibraryApp({
    required this.name,
    this.packageName,
    this.iconBytes,
    this.icon = Icons.apps,
    this.background = Colors.grey,
    this.iconColor = Colors.white,
  });
}

class LibraryCategory {
  final String title;
  final List<LibraryApp> apps;

  const LibraryCategory({
    required this.title,
    required this.apps,
  });
}

/// ---------------------------------------------------------------------------
/// SAMPLE DATA (replace with your real installed-apps grouping logic)
/// ---------------------------------------------------------------------------

final List<LibraryCategory> sampleCategories = [
  LibraryCategory(
    title: 'Entertainment',
    apps: [
      LibraryApp(name: 'Music', icon: Icons.music_note, background: const Color(0xFFFF5A6E)),
      LibraryApp(name: 'Podcasts', icon: Icons.graphic_eq, background: const Color(0xFFFF3B30)),
      LibraryApp(name: 'YouTube', icon: Icons.play_arrow_rounded, background: Colors.white, iconColor: const Color(0xFFFF0000)),
    ],
  ),
  LibraryCategory(
    title: 'Productivity',
    apps: [
      LibraryApp(name: 'Notes', icon: Icons.layers, background: const Color(0xFF34C759)),
      LibraryApp(name: 'Calendar', icon: Icons.calendar_today, background: const Color(0xFF3B82F6)),
      LibraryApp(name: 'Files', icon: Icons.folder, background: const Color(0xFFFFC107)),
      LibraryApp(name: 'Google', icon: Icons.g_mobiledata, background: Colors.white, iconColor: const Color(0xFF4285F4)),
    ],
  ),
  LibraryCategory(
    title: 'Social',
    apps: [
      LibraryApp(name: 'Chrome', icon: Icons.circle, background: Colors.white, iconColor: const Color(0xFF4285F4)),
      LibraryApp(name: 'Gmail', icon: Icons.email, background: Colors.white, iconColor: const Color(0xFFEA4335)),
      LibraryApp(name: 'Camera Cam', icon: Icons.videocam, background: const Color(0xFFFFC107)),
      LibraryApp(name: 'WhatsApp', icon: Icons.chat, background: const Color(0xFF25D366)),
    ],
  ),
  LibraryCategory(
    title: 'Tools',
    apps: [
      LibraryApp(name: 'Calculator', icon: Icons.calculate, background: const Color(0xFFFF9500)),
      LibraryApp(name: 'Clock', icon: Icons.access_time, background: Colors.white, iconColor: Colors.black87),
      LibraryApp(name: 'Editor', icon: Icons.auto_awesome, background: const Color(0xFF8B5CF6)),
    ],
  ),
  LibraryCategory(
    title: 'Utilities',
    apps: [
      LibraryApp(name: 'Camera', icon: Icons.camera_alt, background: Colors.white, iconColor: Colors.purple),
      LibraryApp(name: 'Compass', icon: Icons.explore, background: const Color(0xFF8E8E93)),
      LibraryApp(name: 'Contacts', icon: Icons.person, background: const Color(0xFF3B82F6)),
      LibraryApp(name: 'Downloads', icon: Icons.arrow_downward, background: const Color(0xFF4CD964)),
    ],
  ),
];

/// ---------------------------------------------------------------------------
/// MAIN SCREEN
/// ---------------------------------------------------------------------------

class AppLibraryView extends StatelessWidget {
  final List<LibraryCategory> categories;
  final VoidCallback? onDownloadTap;
  final void Function(LibraryApp app)? onAppTap;
  final void Function(LibraryCategory category)? onCategoryTap;

  const AppLibraryView({
    super.key,
    required this.categories,
    this.onDownloadTap,
    this.onAppTap,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeaderPill(),
            const SizedBox(height: 16),
            _buildDownloadBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: _buildCategoryGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderPill() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2C),
          borderRadius: BorderRadius.circular(30),
        ),
        alignment: Alignment.center,
        child: const Text(
          'App library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: onDownloadTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              Icon(
                Icons.video_settings_outlined,
                size: 40,
                color: Colors.grey.shade600,
              ),
              const SizedBox(height: 10),
              Text(
                'Tap to open your download video',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Download video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.92,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          category: category,
          onTap: onCategoryTap == null ? null : () => onCategoryTap!(category),
          onAppTap: onAppTap,
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// CATEGORY FOLDER CARD
/// ---------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  final LibraryCategory category;
  final VoidCallback? onTap;
  final void Function(LibraryApp app)? onAppTap;

  const _CategoryCard({
    required this.category,
    this.onTap,
    this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show up to 4 icons in a 2x2 layout, like iOS App Library folders.
    final displayApps = category.apps.take(4).toList();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              category.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 25,
              mainAxisSpacing: 5, // childAspectRatio: 0.,
              children: List.generate(4, (i) {
                if (i < displayApps.length) {
                  return _AppIcon(
                    app: displayApps[i],
                    onTap: onAppTap == null
                        ? null
                        : () => onAppTap!(displayApps[i]),
                  );
                }
                // Empty slot to keep the 2x2 grid shape consistent
                return const SizedBox.shrink();
              }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _AppIcon extends StatelessWidget {
  final LibraryApp app;
  final VoidCallback? onTap;

  const _AppIcon({required this.app, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: app.iconBytes != null ? Colors.white : app.background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: app.iconBytes != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            app.iconBytes!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              app.icon,
              color: app.iconColor,
              size: 25,
            ),
          ),
        )
            : Icon(
          app.icon,
          color: app.iconColor,
          size: 28,
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/app_info.dart';
import '../database/app_database.dart';

/// Shared icon caching service to improve performance across the app
/// Eliminates duplicate caching logic in different views
class IconCacheService {
  static IconCacheService? _instance;
  static IconCacheService get instance => _instance ??= IconCacheService._();

  IconCacheService._();

  final Map<String, Uint8List> _memoryCache = {};
  final int _maxCacheSize = 100;
  final LinkedHashMap<String, Uint8List> _lruCache = LinkedHashMap();

  /// Get icon from cache or load it
  Future<Uint8List?> getIcon(String packageName, {List<AppInfo>? apps}) async {
    // Check memory cache first
    if (_memoryCache.containsKey(packageName)) {
      // Move to end of LRU cache (most recently used)
      final icon = _memoryCache[packageName]!;
      _lruCache.remove(packageName);
      _lruCache[packageName] = icon;
      return icon;
    }

    // Try loading from database cache
    final iconData = await AppDatabase.loadIconFromCache(packageName);
    if (iconData != null) {
      _addToCache(packageName, iconData);
      return iconData;
    }

    // Fallback to loading from app list if provided
    if (apps != null) {
      try {
        final app = apps.firstWhere((app) => app.packageName == packageName);
        if (app.icon != null) {
          _addToCache(packageName, app.icon!);
          return app.icon;
        }
      } catch (e) {
        debugPrint('Error loading icon from app list: $e');
      }
    }

    return null;
  }

  /// Add icon to cache with LRU eviction
  void _addToCache(String packageName, Uint8List iconData) {
    // Manage cache size
    if (_memoryCache.length >= _maxCacheSize) {
      final oldestKey = _lruCache.keys.first;
      _memoryCache.remove(oldestKey);
      _lruCache.remove(oldestKey);
    }

    _memoryCache[packageName] = iconData;
    _lruCache[packageName] = iconData;
  }

  /// Preload icons for better performance
  Future<void> preloadIcons(List<String> packageNames, {List<AppInfo>? apps}) async {
    for (final packageName in packageNames.take(20)) { // Limit preload to 20 icons
      if (!_memoryCache.containsKey(packageName)) {
        await getIcon(packageName, apps: apps);
      }
    }
  }

  /// Clear cache
  void clearCache() {
    _memoryCache.clear();
    _lruCache.clear();
  }

  /// Get cache stats for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'maxCacheSize': _maxCacheSize,
      'cacheHitRate': 'N/A', // Could be implemented with hit/miss tracking
    };
  }
}

/// LinkedHashMap for LRU cache implementation
class LinkedHashMap<K, V> {
  final Map<K, V> _map = {};
  final List<K> _keys = [];

  V? operator [](K key) => _map[key];

  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _keys.remove(key);
    }
    _map[key] = value;
    _keys.add(key);
  }

  void remove(K key) {
    _map.remove(key);
    _keys.remove(key);
  }

  K get first => _keys.first;

  Iterable<K> get keys => _keys;

  void clear() {
    _map.clear();
    _keys.clear();
  }

  bool containsKey(K key) => _map.containsKey(key);
}

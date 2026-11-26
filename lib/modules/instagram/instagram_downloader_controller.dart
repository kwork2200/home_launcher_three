import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:home_launcher_three/utils/app_texts.dart';
import 'package:home_launcher_three/services/screen_analytics_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';

class InstagramDownloaderController extends GetxController {
  final linkController = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    ScreenAnalyticsService().logScreenVisit('instagram_downloader');
  }

  void pasteLink() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      linkController.text = clipboardData.text!;
    }
  }

  /// Google Play Policy Compliant Download Method
  /// Uses Gal.putVideo without requesting broad media permissions
  /// This automatically uses Android Photo Picker API on Android 13+
  Future<void> downloadContent() async {
    // Validate input
    if (linkController.text.isEmpty) {
      errorMessage.value = AppTexts.pleasePasteValidInstagramLink;
      Get.snackbar(
        'Error', 
        AppTexts.pleasePasteValidInstagramLink, 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      // Step 1: Fetch video URL from API
      final videoUrl = await _fetchInstagramVideoUrl(linkController.text);
      
      if (videoUrl.isEmpty) {
        throw Exception('Could not extract video URL from Instagram link');
      }

      // Step 2: Download video to temporary directory
      final tempPath = await _downloadVideoToTemp(videoUrl);

      // Step 3: Save to gallery using Photo Picker (Google Play compliant)
      await _saveToGalleryWithPhotoPickerAPI(tempPath);

      // Step 4: Show success message
      Get.snackbar(
        'Success ✓', 
        'Video saved to gallery successfully!', 
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

    } catch (e, stackTrace) {
      debugPrint("===== DOWNLOAD ERROR =====");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");

      errorMessage.value = 'Download failed: ${e.toString()}';
      Get.snackbar(
        'Download Failed', 
        _getUserFriendlyErrorMessage(e),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch Instagram video URL from API
  Future<String> _fetchInstagramVideoUrl(String instagramLink) async {
    final dio = Dio();
    const apiUrl = 'https://instagram-media-download.vercel.app/api/instagram';

    debugPrint('Fetching video URL for: $instagramLink');

    final response = await dio.post(
      apiUrl,
      data: {'url': instagramLink},
      options: Options(
        headers: {
          'accept': '*/*',
          'accept-language': 'en-US,en;q=0.9',
          'content-type': 'application/json',
          'origin': 'https://instagram-media-download.vercel.app',
          'referer': 'https://instagram-media-download.vercel.app/',
        },
        validateStatus: (status) => status! < 500,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('API returned status ${response.statusCode}');
    }

    final data = response.data as Map<String, dynamic>;
    
    // Try multiple possible URL fields
    if (data['mediaUrl'] != null && data['mediaUrl'].toString().isNotEmpty) {
      return data['mediaUrl'].toString();
    } else if (data['mediaUrls'] != null && data['mediaUrls'] is List && (data['mediaUrls'] as List).isNotEmpty) {
      return (data['mediaUrls'] as List)[0].toString();
    }

    throw Exception('Video URL not found in API response');
  }

  /// Download video to temporary directory
  Future<String> _downloadVideoToTemp(String videoUrl) async {
    final dio = Dio();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'instagram_reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final tempPath = '${tempDir.path}/$fileName';

    debugPrint('Downloading video from: $videoUrl');
    debugPrint('Saving to temp path: $tempPath');

    await dio.download(
      videoUrl,
      tempPath,
      options: Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.instagram.com/',
        },
      ),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = (received / total * 100).toStringAsFixed(0);
          debugPrint('Download progress: $progress%');
        }
      },
    );

    // Verify file was downloaded
    final file = File(tempPath);
    if (!await file.exists()) {
      throw Exception('Downloaded file not found at $tempPath');
    }

    final fileSize = await file.length();
    if (fileSize == 0) {
      throw Exception('Downloaded file is empty');
    }

    debugPrint('Video downloaded successfully: $fileSize bytes');
    return tempPath;
  }

  /// Save video to gallery using Photo Picker API (Android 13+)
  /// This method does NOT request READ_MEDIA_IMAGES/VIDEO permissions
  /// Instead, it uses the system Photo Picker which is Google Play compliant
  Future<void> _saveToGalleryWithPhotoPickerAPI(String filePath) async {
    try {
      // Gal.putVideo automatically uses Android Photo Picker API on Android 13+
      // No broad permissions required - fully compliant with Google Play policies
      await Gal.putVideo(filePath, album: 'Instagram Reels');
      
      debugPrint('Video saved to gallery successfully via Photo Picker API');

    } on GalException catch (galError) {
      debugPrint('Gal Error Type: ${galError.type}');
      debugPrint('Gal Error: $galError');
      
      // Handle specific error cases
      if (galError.type == GalExceptionType.accessDenied) {
        throw Exception('Gallery access denied. Please allow access when prompted.');
      } else if (galError.type == GalExceptionType.notEnoughSpace) {
        throw Exception('Not enough storage space available');
      } else if (galError.type == GalExceptionType.notSupportedFormat) {
        throw Exception('Video format not supported');
      } else {
        throw Exception('Failed to save video: ${galError.type}');
      }
    } catch (e) {
      debugPrint('Unexpected error saving to gallery: $e');
      rethrow;
    } finally {
      // Always clean up temporary file
      try {
        final tempFile = File(filePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
          debugPrint('Temporary file deleted: $filePath');
        }
      } catch (deleteError) {
        debugPrint('Warning: Could not delete temp file: $deleteError');
      }
    }
  }

  /// Convert technical errors to user-friendly messages
  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('gallery access denied') || errorStr.contains('access denied')) {
      return 'Please allow gallery access to save videos';
    } else if (errorStr.contains('not enough space') || errorStr.contains('storage')) {
      return 'Not enough storage space on your device';
    } else if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection';
    } else if (errorStr.contains('video url not found') || errorStr.contains('extract')) {
      return 'Could not extract video from Instagram link. Please try a different link';
    } else if (errorStr.contains('api')) {
      return 'Service temporarily unavailable. Please try again later';
    } else if (errorStr.contains('format')) {
      return 'Video format not supported';
    } else {
      return 'An error occurred. Please try again';
    }
  }

  void clearResult() {
    errorMessage.value = '';
  }

  @override
  void onClose() {
    linkController.dispose();
    super.onClose();
  }
}

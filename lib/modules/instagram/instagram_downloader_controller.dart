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

  void downloadContent() async {
    if (linkController.text.isEmpty) {
      errorMessage.value = AppTexts.pleasePasteValidInstagramLink;
      Get.snackbar('Error', AppTexts.pleasePasteValidInstagramLink, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // gal se gallery access permission check/request
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final granted = await Gal.requestAccess();
      if (!granted) {
        Get.snackbar('Permission Denied', 'Gallery permission is required to save videos', snackPosition: SnackPosition.BOTTOM);
        return;
      }
    }

    isLoading.value = true;

    try {
      Dio dio = Dio();
      String apiUrl = 'https://instagram-media-download.vercel.app/api/instagram';

      final response = await dio.post(
        apiUrl,
        data: {'url': linkController.text},
        options: Options(
          headers: {
            'accept': '*/*',
            'accept-language': 'en-US,en;q=0.9',
            'content-type': 'application/json',
            'origin': 'https://instagram-media-download.vercel.app',
            'referer': 'https://instagram-media-download.vercel.app/',
          },
        ),
      );

      debugPrint('API Response: ${response.data}');

      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data;

        String videoUrl = '';

        if (data['mediaUrl'] != null && data['mediaUrl'].isNotEmpty) {
          videoUrl = data['mediaUrl'];
        } else if (data['mediaUrls'] != null && data['mediaUrls'].isNotEmpty) {
          videoUrl = data['mediaUrls'][0];
        }

        if (videoUrl.isEmpty) {
          throw Exception('Video URL not found in API response');
        }

        Directory tempDir = await getTemporaryDirectory();
        String fileName = 'instagram_reel_${DateTime.now().millisecondsSinceEpoch}.mp4';
        String tempPath = '${tempDir.path}/$fileName';

        debugPrint('Downloading video from: $videoUrl');

        await dio.download(
          videoUrl,
          tempPath,
          options: Options(
            headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
          ),
        );

        await Gal.putVideo(tempPath, album: 'Instagram Reels');

        final tempFile = File(tempPath);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        Get.snackbar('Success', 'Your reel has been downloaded and saved to the gallery.', snackPosition: SnackPosition.BOTTOM);
      } else {
        throw Exception('API request failed with status ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint("===== DOWNLOAD ERROR =====");
      debugPrint("Error: $e");
      debugPrint("StackTrace: $stackTrace");

      Get.snackbar('Error', 'Failed to download: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
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
import 'package:flutter/services.dart';
import 'package:home_launcher_three/modules/all_video/model/all_video_model.dart';

class VideoService {
  static const platform = MethodChannel('com.allhdvideos.app/videos');

  static Future<List<AllVideoItem>> fetchAllVideos() async {
    try {
      print('VideoService: Calling native getAllVideos...');
      final List<dynamic> result = await platform.invokeMethod('getAllVideos');
      print('VideoService: Received ${result.length} videos from native');
      
      final videos = result.map((json) {
        print('VideoService: Processing video - ${json['name']}');
        return AllVideoItem.fromJson(Map<String, dynamic>.from(json));
      }).toList();
      
      print('VideoService: Successfully parsed ${videos.length} videos');
      return videos;
    } on PlatformException catch (e) {
      print("VideoService ERROR: Failed to get videos: ${e.message}");
      print("VideoService ERROR Details: ${e.details}");
      return [];
    } catch (e) {
      print("VideoService UNEXPECTED ERROR: $e");
      return [];
    }
  }

  static Future<bool> deleteVideo(String path) async {
    try {
      final bool result = await platform.invokeMethod('deleteVideo', {'path': path});
      return result;
    } on PlatformException catch (e) {
      print("Failed to delete video: ${e.message}");
      return false;
    }
  }
}

import 'package:get/get.dart';
import 'package:home_launcher_three/modules/folder_videos/folder_videos_controller.dart';

class FolderVideosBinding extends Bindings {
  @override
  void dependencies() {
    final folderName = Get.parameters['folderName'] ?? 'Videos';
    Get.lazyPut<FolderVideosController>(() => FolderVideosController(folderName: folderName));
  }
}

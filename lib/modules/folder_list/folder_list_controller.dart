import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class FolderModel {
  final String name;
  final int videoCount;
  final AssetPathEntity assetPath;

  FolderModel({
    required this.name,
    required this.videoCount,
    required this.assetPath,
  });
}

class FolderListController extends GetxController {
  final RxList<FolderModel> folders = <FolderModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isGridView = false.obs;

  void toggleView() => isGridView.value = !isGridView.value;

  @override
  void onInit() {
    super.onInit();
    fetchFolders();
  }

  Future<void> fetchFolders() async {
    isLoading.value = true;

    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      isLoading.value = false;
      folders.clear();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
    );

    final folderList = <FolderModel>[];
    for (final album in albums) {
      final count = await album.assetCountAsync;
      if (count > 0) {
        folderList.add(FolderModel(
          name: album.name,
          videoCount: count,
          assetPath: album,
        ));
      }
    }

    folders.assignAll(folderList);
    isLoading.value = false;
  }

  void navigateToFolder(String folderName) {
    Get.toNamed('/folder-videos', parameters: {'folderName': folderName});
  }
}

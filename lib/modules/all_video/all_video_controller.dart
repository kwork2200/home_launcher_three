import 'dart:io';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/model/all_video_model.dart';
import 'package:home_launcher_three/modules/all_video/video_controller_interface.dart';
import 'package:photo_manager/photo_manager.dart';

class AllVideoController extends VideoControllerInterface {
  final RxList<AllVideoItem> allVideos = <AllVideoItem>[].obs;
  final RxList<AllVideoItem> displayedVideos = <AllVideoItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isGridView = false.obs;
  final Rx<SortType> currentSort = SortType.dateNewOld.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  void startSearch() {
    isSearching.value = true;
  }

  void stopSearch() {
    isSearching.value = false;
    searchQuery.value = '';
    displayedVideos.assignAll(allVideos);
    _applySort();
  }

  @override
  void onInit() {
    super.onInit();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    isLoading.value = true;

    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      isLoading.value = false;
      allVideos.clear();
      displayedVideos.clear();
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );

    if (albums.isEmpty) {
      isLoading.value = false;
      return;
    }

    final recentAlbum = albums.first;
    final count = await recentAlbum.assetCountAsync;
    final assets = await recentAlbum.getAssetListRange(start: 0, end: count);

    final items = <AllVideoItem>[];
    for (final asset in assets) {
      final file = await asset.file;
      final size = file != null && await file.exists() ? await file.length() : 0;
      items.add(AllVideoItem(asset: asset, fileSizeBytes: size));
    }

    allVideos.assignAll(items);
    _applySort();
    isLoading.value = false;
  }

  void toggleView() => isGridView.value = !isGridView.value;

  void setSort(SortType type) {
    currentSort.value = type;
    _applySort();
  }

  void _applySort() {
    final list = List<AllVideoItem>.from(allVideos);
    switch (currentSort.value) {
      case SortType.dateNewOld:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.dateOldNew:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.nameAZ:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortType.nameZA:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortType.sizeSmallBig:
        list.sort((a, b) => a.fileSizeBytes.compareTo(b.fileSizeBytes));
        break;
      case SortType.sizeBigSmall:
        list.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
    }
    displayedVideos.assignAll(list);
    if (searchQuery.value.isNotEmpty) {
      search(searchQuery.value);
    }
  }

  void search(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      displayedVideos.assignAll(allVideos);
      _applySort();
      return;
    }
    final lower = query.toLowerCase();
    final filtered = allVideos.where((v) => v.title.toLowerCase().contains(lower)).toList();
    displayedVideos.assignAll(filtered);
    // Re-apply sort after filtering to maintain sort order
    _applySortToDisplayedList();
  }

  void _applySortToDisplayedList() {
    final list = List<AllVideoItem>.from(displayedVideos);
    switch (currentSort.value) {
      case SortType.dateNewOld:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortType.dateOldNew:
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortType.nameAZ:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortType.nameZA:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case SortType.sizeSmallBig:
        list.sort((a, b) => a.fileSizeBytes.compareTo(b.fileSizeBytes));
        break;
      case SortType.sizeBigSmall:
        list.sort((a, b) => b.fileSizeBytes.compareTo(a.fileSizeBytes));
        break;
    }
    displayedVideos.assignAll(list);
  }

  Future<bool> deleteVideo(AllVideoItem item) async {
    final result = await PhotoManager.editor.deleteWithIds([item.asset.id]);
    if (result.isNotEmpty) {
      allVideos.removeWhere((v) => v.asset.id == item.asset.id);
      displayedVideos.removeWhere((v) => v.asset.id == item.asset.id);
      return true;
    }
    return false;
  }

  Future<File?> getFile(AllVideoItem item) => item.asset.file;
}

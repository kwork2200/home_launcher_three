import 'dart:io';
import 'package:get/get.dart';
import 'package:home_launcher_three/modules/all_video/model/all_video_model.dart';

enum SortType { dateNewOld, dateOldNew, nameAZ, nameZA, sizeSmallBig, sizeBigSmall }

abstract class VideoControllerInterface extends GetxController {
  Rx<SortType> get currentSort;
  void setSort(SortType type);
  RxBool get isGridView;
  void toggleView();
  RxBool get isSearching;
  void startSearch();
  void stopSearch();
  RxString get searchQuery;
  void search(String query);
  RxList get displayedVideos;
  Future<File?> getFile(AllVideoItem item);
  Future<bool> deleteVideo(AllVideoItem item);
}

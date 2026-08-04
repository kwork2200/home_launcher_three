import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/app_texts.dart';

class TwitterDownloaderController extends GetxController {
  final linkController = TextEditingController();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  
  void pasteLink() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      linkController.text = clipboardData.text!;
    }
  }
  
  void downloadContent() {
    if (linkController.text.isEmpty) {
      errorMessage.value = AppTexts.pleasePasteValidTwitterLink;
      return;
    }
    
    isLoading.value = true;
    // Add download logic here
    Future.delayed(Duration(seconds: 2), () {
      isLoading.value = false;
    });
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

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../utils/app_colors.dart';
import '../../utils/app_dimensions.dart';

class FullScreenVideoPlayer extends StatefulWidget {
  final File file;
  const FullScreenVideoPlayer({super.key, required this.file});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.file)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _isInitialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: AppColors.blackColor,
              child: Center(
                child: _isInitialized
                    ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ) : CircularProgressIndicator(color: AppColors.primaryWhite),
              ),
            ),
          ),
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(color: Colors.transparent),
              ),
            ),
          Positioned(
            top: AppDimensions.paddingXLarge40,
            right: AppDimensions.paddingMedium,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: EdgeInsets.all(AppDimensions.marginSmall),
                decoration: BoxDecoration(color: AppColors.black87, shape: BoxShape.circle),
                child: Icon(Icons.close, color: AppColors.primaryWhite, size: AppDimensions.iconMedium),
              ),
            ),
          ),
          if (_isInitialized)
            Positioned(
              bottom: AppDimensions.paddingXLarge,
              left: AppDimensions.paddingMedium,
              right: AppDimensions.paddingMedium,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.primaryColor,
                  bufferedColor: AppColors.primaryWhite70,
                  backgroundColor: AppColors.whiteBorder,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void showFullScreenVideoSheet(BuildContext context, File file) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black,
    barrierColor: Colors.black87,
    shape: const RoundedRectangleBorder(),
    builder: (_) => FullScreenVideoPlayer(file: file),
  );
}

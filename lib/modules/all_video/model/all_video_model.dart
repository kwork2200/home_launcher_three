import 'package:photo_manager/photo_manager.dart';

class AllVideoItem {
  final AssetEntity asset;
  final int fileSizeBytes;

  AllVideoItem({required this.asset, required this.fileSizeBytes});

  String get title => asset.title ?? 'Unknown';

  String get durationText {
    final d = asset.videoDuration;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get sizeText {
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(2)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(2)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(2)} GB';
  }

  String get sourceTag {
    final path = asset.relativePath?.toLowerCase() ?? '';
    if (path.contains('whatsapp')) return 'WhatsApp Video';
    if (path.contains('download')) return 'Download';
    if (path.contains('camera') || path.contains('dcim')) return 'Camera';
    return 'Video';
  }

  DateTime get createdAt => asset.createDateTime;
}

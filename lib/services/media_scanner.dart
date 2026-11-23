import 'dart:io';

import '../models/media_item.dart';

/// 扫描本地文件夹生成播放列表。
///
/// 只读取文件夹第一层，按文件名排序，过滤常见的图片/视频后缀。
class MediaScanner {
  const MediaScanner();

  static const imageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
  };
  static const videoExtensions = {
    '.mp4',
    '.mkv',
    '.webm',
    '.mov',
    '.avi',
    '.3gp',
  };

  List<MediaItem> scan(Directory directory) {
    if (!directory.existsSync()) return <MediaItem>[];

    final files = directory
        .listSync(recursive: false)
        .whereType<File>()
        .toList(growable: false);

    final items = <MediaItem>[];
    for (final file in files) {
      final extension = _extension(file.path);
      if (imageExtensions.contains(extension)) {
        items.add(MediaItem(path: file.path, type: MediaType.image));
      } else if (videoExtensions.contains(extension)) {
        items.add(MediaItem(path: file.path, type: MediaType.video));
      }
    }

    items.sort((a, b) {
      final left = a.fileName.toLowerCase();
      final right = b.fileName.toLowerCase();
      return left.compareTo(right);
    });
    return items;
  }

  String _extension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) return '';
    return name.substring(dot).toLowerCase();
  }
}

import 'dart:io';

enum MediaType { image, video }

/// 播放列表里的一项内容。
class MediaItem {
  const MediaItem({
    required this.path,
    required this.type,
    this.duration = const Duration(seconds: 8),
  });

  final String path;
  final MediaType type;

  /// 图片停留时长，视频该项无效。
  final Duration duration;

  String get fileName => path.split(RegExp(r'[/\\]')).last;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          other.path == path &&
          other.type == type &&
          other.duration == duration;

  @override
  int get hashCode => Object.hash(path, type, duration);
}

/// 把本地路径转成可展示的 File，避免各页面重复 import dart:io。
File mediaFile(MediaItem item) => File(item.path);

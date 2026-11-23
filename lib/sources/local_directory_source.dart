import 'dart:io';

import '../models/device_config.dart';
import '../models/media_item.dart';
import '../services/media_scanner.dart';
import 'content_source.dart';

/// 从设备本地文件夹读取素材。
class LocalDirectorySource implements ContentSource {
  const LocalDirectorySource(this.directoryPath);

  final String directoryPath;

  @override
  Future<List<MediaItem>> fetchPlaylist(DeviceConfig device) async {
    // device 在本地模式下暂不使用，接口先统一保留。
    return MediaScanner().scan(Directory(directoryPath));
  }

  @override
  Future<void> reportStatus(DeviceConfig device, String currentItemPath) async {
    // 本地内容源无需上报。
  }
}

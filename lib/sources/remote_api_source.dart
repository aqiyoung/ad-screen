import '../models/device_config.dart';
import '../models/media_item.dart';
import 'content_source.dart';

/// 云端内容源占位。
///
/// 后台上线后在这里实现：
///   GET {baseUrl}/devices/{deviceId}/playlist  -> 下载/缓存素材并返回播放列表
///   POST {baseUrl}/devices/{deviceId}/status   -> 上报当前播放项
/// 播放器无需改动。
class RemoteApiSource implements ContentSource {
  const RemoteApiSource(this.baseUrl);

  final String baseUrl;

  @override
  Future<List<MediaItem>> fetchPlaylist(DeviceConfig device) async {
    throw UnimplementedError('云端内容源尚未实现，请在设置里切回「本地文件夹」。');
  }

  @override
  Future<void> reportStatus(DeviceConfig device, String currentItemPath) async {
    // TODO: 接入服务端后上报心跳。
  }
}

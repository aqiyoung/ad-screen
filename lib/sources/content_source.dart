import '../config/app_config.dart';
import '../models/device_config.dart';
import '../models/media_item.dart';
import 'local_directory_source.dart';
import 'remote_api_source.dart';

/// 内容源接口。
///
/// 播放器只依赖这个抽象类：现在的实现是本地文件夹，
/// 以后接服务端只需新增一个实现并在 [ContentSourceFactory] 里切换。
abstract class ContentSource {
  const ContentSource();

  Future<List<MediaItem>> fetchPlaylist(DeviceConfig device);

  /// 预留：以后向服务端上报当前播放项 / 心跳。
  Future<void> reportStatus(DeviceConfig device, String currentItemPath) async {
    // 默认空实现，本地内容源不需要上报。
  }
}

class ContentSourceFactory {
  const ContentSourceFactory();

  ContentSource create(AppConfig config) {
    switch (config.sourceType) {
      case ContentSourceType.remote:
        return RemoteApiSource(config.remoteBaseUrl);
      case ContentSourceType.local:
        return LocalDirectorySource(config.mediaPath);
    }
  }
}

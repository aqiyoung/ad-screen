import 'package:ad_screen/config/app_config.dart';
import 'package:ad_screen/models/device_config.dart';
import 'package:ad_screen/sources/content_source.dart';
import 'package:ad_screen/sources/local_directory_source.dart';
import 'package:ad_screen/sources/remote_api_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppConfig JSON 往返保留内容源和设备信息', () {
    final original = AppConfig(
      mediaPath: '/sdcard/media',
      imageDurationSeconds: 12,
      device: const DeviceConfig(deviceId: 'screen-02', name: '大厅屏'),
      sourceType: ContentSourceType.remote,
      remoteBaseUrl: 'https://example.com/api',
    );

    final restored = AppConfig.fromJson(original.toJson());

    expect(restored.mediaPath, original.mediaPath);
    expect(restored.imageDurationSeconds, 12);
    expect(restored.sourceType, ContentSourceType.remote);
    expect(restored.remoteBaseUrl, 'https://example.com/api');
    expect(restored.device.deviceId, 'screen-02');
  });

  test('内容源工厂按配置选择实现', () {
    final factory = const ContentSourceFactory();

    expect(
      factory.create(const AppConfig(mediaPath: '/tmp')),
      isA<LocalDirectorySource>(),
    );
    expect(
      factory.create(
        const AppConfig(
          mediaPath: '/tmp',
          sourceType: ContentSourceType.remote,
          remoteBaseUrl: 'https://example.com',
        ),
      ),
      isA<RemoteApiSource>(),
    );
  });
}

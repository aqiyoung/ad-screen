/// 一台屏幕的身份信息。
///
/// 目前只在本地保存，等后台上线后用于向服务端拉取属于这台设备的播放列表。
class DeviceConfig {
  const DeviceConfig({
    required this.deviceId,
    this.name = '',
    this.playlistId = '',
  });

  final String deviceId;
  final String name;
  final String playlistId;

  static DeviceConfig fromJson(Map<String, dynamic> json) => DeviceConfig(
    deviceId: (json['deviceId'] as String?)?.trim().isNotEmpty == true
        ? json['deviceId'] as String
        : 'screen-01',
    name: json['name'] as String? ?? '',
    playlistId: json['playlistId'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'playlistId': playlistId,
  };
}

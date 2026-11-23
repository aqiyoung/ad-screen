import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/device_config.dart';

enum ContentSourceType { local, remote }

/// 全部本地配置，存一份 JSON 在 SharedPreferences。
class AppConfig {
  const AppConfig({
    required this.mediaPath,
    this.imageDurationSeconds = 8,
    this.refreshIntervalSeconds = 15,
    this.device = const DeviceConfig(deviceId: 'screen-01'),
    this.sourceType = ContentSourceType.local,
    this.remoteBaseUrl = '',
  });

  final String mediaPath;
  final int imageDurationSeconds;
  final int refreshIntervalSeconds;
  final DeviceConfig device;
  final ContentSourceType sourceType;

  /// 预留：接入服务端后的接口根地址，例如 https://ad.example.com/api
  final String remoteBaseUrl;

  static const _storageKey = 'app_config_v1';

  AppConfig copyWith({
    String? mediaPath,
    int? imageDurationSeconds,
    int? refreshIntervalSeconds,
    DeviceConfig? device,
    ContentSourceType? sourceType,
    String? remoteBaseUrl,
  }) {
    return AppConfig(
      mediaPath: mediaPath ?? this.mediaPath,
      imageDurationSeconds: imageDurationSeconds ?? this.imageDurationSeconds,
      refreshIntervalSeconds:
          refreshIntervalSeconds ?? this.refreshIntervalSeconds,
      device: device ?? this.device,
      sourceType: sourceType ?? this.sourceType,
      remoteBaseUrl: remoteBaseUrl ?? this.remoteBaseUrl,
    );
  }

  static Future<AppConfig> load({required String defaultMediaPath}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return AppConfig(mediaPath: defaultMediaPath);
    try {
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppConfig(mediaPath: defaultMediaPath);
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }

  static AppConfig fromJson(Map<String, dynamic> json) {
    final sourceName = json['sourceType'] as String? ?? 'local';
    return AppConfig(
      mediaPath: json['mediaPath'] as String? ?? '',
      imageDurationSeconds:
          (json['imageDurationSeconds'] as num?)?.toInt() ?? 8,
      refreshIntervalSeconds:
          (json['refreshIntervalSeconds'] as num?)?.toInt() ?? 15,
      device: DeviceConfig.fromJson(
        (json['device'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      sourceType: sourceName == 'remote'
          ? ContentSourceType.remote
          : ContentSourceType.local,
      remoteBaseUrl: json['remoteBaseUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'mediaPath': mediaPath,
    'imageDurationSeconds': imageDurationSeconds,
    'refreshIntervalSeconds': refreshIntervalSeconds,
    'device': device.toJson(),
    'sourceType': sourceType == ContentSourceType.remote ? 'remote' : 'local',
    'remoteBaseUrl': remoteBaseUrl,
  };
}

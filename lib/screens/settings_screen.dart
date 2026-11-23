import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/device_config.dart';
import '../services/media_importer.dart';

/// 设置页。保存后把新的 AppConfig 返回给播放器。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.config});

  final AppConfig config;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _mediaPath;
  late final TextEditingController _imageDuration;
  late final TextEditingController _refreshInterval;
  late final TextEditingController _deviceId;
  late final TextEditingController _deviceName;
  late final TextEditingController _playlistId;
  late final TextEditingController _remoteBaseUrl;
  late ContentSourceType _sourceType;

  @override
  void initState() {
    super.initState();
    _mediaPath = TextEditingController(text: widget.config.mediaPath);
    _imageDuration = TextEditingController(
      text: '${widget.config.imageDurationSeconds}',
    );
    _refreshInterval = TextEditingController(
      text: '${widget.config.refreshIntervalSeconds}',
    );
    _deviceId = TextEditingController(text: widget.config.device.deviceId);
    _deviceName = TextEditingController(text: widget.config.device.name);
    _playlistId = TextEditingController(text: widget.config.device.playlistId);
    _remoteBaseUrl = TextEditingController(text: widget.config.remoteBaseUrl);
    _sourceType = widget.config.sourceType;
  }

  @override
  void dispose() {
    _mediaPath.dispose();
    _imageDuration.dispose();
    _refreshInterval.dispose();
    _deviceId.dispose();
    _deviceName.dispose();
    _playlistId.dispose();
    _remoteBaseUrl.dispose();
    super.dispose();
  }

  Future<void> _importFiles() async {
    final path = _mediaPath.text.trim();
    final count = await const MediaImporter().importInto(path);
    if (!mounted || count == 0) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('已导入 $count 个文件到 $path')));
  }

  Future<void> _save() async {
    final config = AppConfig(
      mediaPath: _mediaPath.text.trim(),
      imageDurationSeconds:
          int.tryParse(_imageDuration.text.trim()) ??
          widget.config.imageDurationSeconds,
      refreshIntervalSeconds:
          int.tryParse(_refreshInterval.text.trim()) ??
          widget.config.refreshIntervalSeconds,
      device: DeviceConfig(
        deviceId: _deviceId.text.trim().isEmpty
            ? 'screen-01'
            : _deviceId.text.trim(),
        name: _deviceName.text.trim(),
        playlistId: _playlistId.text.trim(),
      ),
      sourceType: _sourceType,
      remoteBaseUrl: _remoteBaseUrl.text.trim(),
    );
    await config.save();
    if (!mounted) return;
    Navigator.pop<AppConfig>(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('广告屏设置'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: '保存',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('素材'),
            TextField(
              controller: _mediaPath,
              decoration: const InputDecoration(
                labelText: '素材文件夹路径',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _importFiles,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('从本机导入图片/视频'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageDuration,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '图片停留（秒）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _refreshInterval,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '刷新间隔（秒）',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle('这台设备'),
            TextField(
              controller: _deviceId,
              decoration: const InputDecoration(
                labelText: '设备 ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deviceName,
              decoration: const InputDecoration(
                labelText: '设备名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _playlistId,
              decoration: const InputDecoration(
                labelText: '播放列表 ID（后台用）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle('内容源'),
            DropdownButtonFormField<ContentSourceType>(
              initialValue: _sourceType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: ContentSourceType.local,
                  child: Text('本地文件夹（当前可用）'),
                ),
                DropdownMenuItem(
                  value: ContentSourceType.remote,
                  child: Text('云端接口（尚未实现）'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sourceType = value);
              },
            ),
            if (_sourceType == ContentSourceType.remote) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _remoteBaseUrl,
                decoration: const InputDecoration(
                  labelText: '接口根地址 https://...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: _save, child: const Text('保存并返回播放')),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    );
  }
}

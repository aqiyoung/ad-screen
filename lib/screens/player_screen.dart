import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/app_config.dart';
import '../models/media_item.dart';
import '../sources/content_source.dart';

/// 全屏循环播放页面。
class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.config,
    required this.onOpenSettings,
  });

  final AppConfig config;
  final Future<AppConfig?> Function() onOpenSettings;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late ContentSource _source;
  List<MediaItem> _items = const <MediaItem>[];
  int _index = 0;

  /// 每次切换都自增，保证只有一个视频时也会重新创建播放器从头播。
  int _cycle = 0;

  bool _loading = true;
  Object? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _source = const ContentSourceFactory().create(widget.config);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _refresh();
    final seconds = widget.config.refreshIntervalSeconds < 3
        ? 3
        : widget.config.refreshIntervalSeconds;
    _refreshTimer = Timer.periodic(
      Duration(seconds: seconds),
      (_) => _refresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final fetched = await _source.fetchPlaylist(widget.config.device);
      if (!mounted) return;
      final currentPath = (_items.isNotEmpty && _index < _items.length)
          ? _items[_index].path
          : null;
      setState(() {
        _items = fetched;
        _error = null;
        if (fetched.isEmpty) {
          _index = 0;
        } else if (currentPath != null) {
          final found = fetched.indexWhere((item) => item.path == currentPath);
          _index = found < 0 ? 0 : found;
        } else {
          _index = 0;
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _advance() {
    if (_items.isEmpty) return;
    setState(() {
      _index = (_index + 1) % _items.length;
      _cycle++;
    });
  }

  Future<void> _openSettings() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await widget.onOpenSettings();
    if (!mounted) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: _openSettings,
        child: Stack(
          children: [
            Positioned.fill(child: _buildContent()),
            Positioned(
              right: 14,
              bottom: 14,
              child: GestureDetector(
                onTap: _openSettings,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.settings,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return _Message(
        text: '内容源出错：$_error\n请到设置里检查配置。',
        onSettings: _openSettings,
      );
    }
    if (_items.isEmpty) {
      return _Message(
        text: '没有找到图片或视频\n${widget.config.mediaPath}\n\n长按屏幕或点右下角进入设置。',
        onSettings: _openSettings,
      );
    }

    final item = _items[_index];
    final seconds = widget.config.imageDurationSeconds < 1
        ? 1
        : widget.config.imageDurationSeconds;
    return _MediaSlide(
      key: ValueKey('${item.path}@$_cycle'),
      item: item,
      imageDuration: Duration(seconds: seconds),
      onNext: _advance,
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onSettings});

  final String text;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onSettings, child: const Text('打开设置')),
          ],
        ),
      ),
    );
  }
}

class _MediaSlide extends StatelessWidget {
  const _MediaSlide({
    super.key,
    required this.item,
    required this.imageDuration,
    required this.onNext,
  });

  final MediaItem item;
  final Duration imageDuration;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (item.type == MediaType.image) {
      return _ImageSlide(item: item, duration: imageDuration, onNext: onNext);
    }
    return _VideoSlide(item: item, onNext: onNext);
  }
}

class _ImageSlide extends StatefulWidget {
  const _ImageSlide({
    required this.item,
    required this.duration,
    required this.onNext,
  });

  final MediaItem item;
  final Duration duration;
  final VoidCallback onNext;

  @override
  State<_ImageSlide> createState() => _ImageSlideState();
}

class _ImageSlideState extends State<_ImageSlide> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.file(
        File(widget.item.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
      ),
    );
  }
}

class _VideoSlide extends StatefulWidget {
  const _VideoSlide({required this.item, required this.onNext});

  final MediaItem item;
  final VoidCallback onNext;

  @override
  State<_VideoSlide> createState() => _VideoSlideState();
}

class _VideoSlideState extends State<_VideoSlide> {
  late VideoPlayerController _controller;
  bool _ready = false;
  String? _error;
  bool _advanced = false;
  Timer? _errorTimer;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.item.path));
    _controller.addListener(_onControllerUpdate);
    _controller
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() => _ready = true);
          _controller.setLooping(false);
          _controller.play();
        })
        .catchError((Object error) {
          _fail(error.toString());
        });
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    _errorTimer?.cancel();
    _errorTimer = Timer(const Duration(seconds: 3), widget.onNext);
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    if (_controller.value.hasError) {
      _fail(_controller.value.errorDescription ?? '视频播放失败');
      return;
    }
    if (_controller.value.isCompleted && !_advanced) {
      _advanced = true;
      widget.onNext();
    }
  }

  @override
  void dispose() {
    _errorTimer?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text(
          '视频无法播放：$_error',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    final size = _controller.value.size;
    if (size.width <= 0 || size.height <= 0) {
      return const ColoredBox(color: Colors.black);
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

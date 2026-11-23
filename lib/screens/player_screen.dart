import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/app_config.dart';
import '../models/media_item.dart';
import '../services/media_importer.dart';
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

  bool _controlsVisible = false;
  Timer? _controlsTimer;
  bool _hintVisible = true;
  Timer? _hintTimer;

  bool get _hasMedia => !_loading && _error == null && _items.isNotEmpty;

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
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controlsTimer?.cancel();
    _hintTimer?.cancel();
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
      _controlsVisible = false;
      _hintVisible = false;
    });
    _controlsTimer?.cancel();
  }

  void _showControls() {
    if (!mounted || !_hasMedia) return;
    setState(() {
      _controlsVisible = true;
      _hintVisible = false;
    });
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), _hideControls);
  }

  void _hideControls() {
    if (!mounted) return;
    setState(() => _controlsVisible = false);
  }

  void _onScreenTap() {
    if (!_hasMedia) return;
    if (_controlsVisible) {
      _hideControls();
    } else {
      _showControls();
    }
  }

  Future<void> _openSettings() async {
    _controlsTimer?.cancel();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await widget.onOpenSettings();
    if (!mounted) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _importMedia() async {
    _controlsTimer?.cancel();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final count = await const MediaImporter().importInto(
      widget.config.mediaPath,
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(count > 0 ? '已导入 $count 个文件，即将开始播放' : '未选择文件')),
    );
    if (count > 0) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final playing = _hasMedia;
    final showOverlay = playing && _controlsVisible;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 轻触显示/隐藏控件，长按直接进入设置。translucent 让黑边区域也能响应。
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onScreenTap,
              onLongPress: _openSettings,
              child: _buildContent(),
            ),
          ),
          if (showOverlay)
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x66000000),
                        Colors.transparent,
                        Colors.transparent,
                        Color(0xB3000000),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (showOverlay)
            Positioned(
              top: 24,
              right: 24,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${_items.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          if (playing && _hintVisible && !_controlsVisible)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 28,
              child: IgnorePointer(
                child: Center(
                  child: Text(
                    '轻触屏幕显示操作',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ),
              ),
            ),
          if (showOverlay)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        Icons.add_photo_alternate_outlined,
                        '导入素材',
                        _importMedia,
                      ),
                      const SizedBox(width: 40),
                      _controlButton(
                        Icons.settings_outlined,
                        '设置',
                        _openSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
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
        title: '内容源出错',
        subtitle: '$_error\n请到设置里检查配置。',
        onImport: _importMedia,
        onSettings: _openSettings,
      );
    }
    if (_items.isEmpty) {
      return _Message(
        title: '还没有素材',
        subtitle: '导入图片或视频后自动开始轮播\n\n素材目录：${widget.config.mediaPath}',
        onImport: _importMedia,
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
  const _Message({
    required this.title,
    required this.subtitle,
    required this.onImport,
    required this.onSettings,
  });

  final String title;
  final String subtitle;
  final VoidCallback onImport;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0x333A78FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('导入图片/视频'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(onPressed: onSettings, child: const Text('打开设置')),
              ],
            ),
          ),
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
    // contain 保证横屏/竖屏图片都完整显示，不裁切，黑边留给屏幕背景。
    return SizedBox.expand(
      child: Image.file(
        File(widget.item.path),
        fit: BoxFit.contain,
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
    // contain 保证横屏/竖屏视频完整显示。
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

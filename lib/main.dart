import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'config/app_config.dart';
import 'screens/player_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 默认素材目录：应用自己的外部存储目录，Android 各版本都可直接读写。
  final external = await getExternalStorageDirectory();
  final defaultPath = external == null
      ? '/sdcard/ad_screen'
      : '${external.path}/media';

  final config = await AppConfig.load(defaultMediaPath: defaultPath);
  runApp(AdScreenApp(config: config));
}

class AdScreenApp extends StatefulWidget {
  const AdScreenApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<AdScreenApp> createState() => _AdScreenAppState();
}

class _AdScreenAppState extends State<AdScreenApp> {
  late AppConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  void _onSettingsSaved(AppConfig updated) {
    if (!mounted) return;
    setState(() => _config = updated);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdScreen 广告屏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2F6BFF),
        brightness: Brightness.dark,
      ),
      home: PlayerScreen(
        key: ValueKey(_config.toJson().toString()),
        config: _config,
        onSettingsSaved: _onSettingsSaved,
      ),
    );
  }
}

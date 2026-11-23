import 'dart:io';

import 'package:ad_screen/models/media_item.dart';
import 'package:ad_screen/services/media_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaScanner', () {
    late Directory directory;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('ad_screen_test_');
    });

    tearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    test('只返回支持的图片/视频，并按文件名排序', () {
      File('${directory.path}/b_post.jpg').createSync();
      File('${directory.path}/a_intro.mp4').createSync();
      File('${directory.path}/readme.txt').createSync();
      File('${directory.path}/c_banner.WEBP').createSync();

      final items = const MediaScanner().scan(directory);

      expect(items.map((item) => item.fileName), [
        'a_intro.mp4',
        'b_post.jpg',
        'c_banner.WEBP',
      ]);
      expect(items.map((item) => item.type), [
        MediaType.video,
        MediaType.image,
        MediaType.image,
      ]);
    });

    test('忽略子目录', () {
      final nested = Directory('${directory.path}/sub')..createSync();
      File('${nested.path}/hidden.png').createSync();

      expect(const MediaScanner().scan(directory), isEmpty);
    });

    test('目录不存在时返回空列表', () {
      final missing = Directory('${directory.path}/not_there');
      expect(const MediaScanner().scan(missing), isEmpty);
    });
  });
}

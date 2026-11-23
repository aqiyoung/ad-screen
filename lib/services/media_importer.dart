import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// 用系统文件选择器把图片/视频复制进素材目录。
///
/// 不申请相册/存储权限，符合「只从应用内导入」的要求。
class MediaImporter {
  const MediaImporter();

  /// 返回实际导入的文件数；用户取消时返回 0。
  Future<int> importInto(String directoryPath) async {
    final picked = await FilePicker.pickFiles(type: FileType.media);
    if (picked.isEmpty) return 0;

    final directory = Directory(directoryPath);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    var count = 0;
    for (final file in picked) {
      final source = file.path;
      if (source == null) continue;
      final name = source.split(RegExp(r'[/\\]')).last;
      await File(source)
          .copy('${directory.path}${Platform.pathSeparator}$name');
      count++;
    }
    return count;
  }
}

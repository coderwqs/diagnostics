import 'dart:io';

import 'package:open_file/open_file.dart';

extension FileExt on File {
  Future<void> revealInFileExplorer() async {
    if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', absolute.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', ['-R', absolute.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [parent.path]);
    } else {
      // Android/iOS 使用原生插件
      try {
        await OpenFile.open(absolute.path);
      } catch (e) {
        throw Exception('无法打开目录: $e');
      }
    }
  }
}
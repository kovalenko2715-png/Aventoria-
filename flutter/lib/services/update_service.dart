import 'dart:convert';
import 'dart:io';

import 'package:open_filex/open_filex.dart';

/// In-app updater: checks GitHub Releases and installs newer APKs.
class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const _repo = 'kovalenko2715-png/Aventoria-';

  String? _latestTag;
  String? _apkUrl;
  int _apkSize = 0;

  bool get hasUpdate => _apkUrl != null;

  String get latestTag => _latestTag ?? '';

  int get apkSize => _apkSize;

  static String _normalized(String v) {
    var s = v.trim();
    if (s.startsWith('v')) s = s.substring(1);
    final plus = s.indexOf('+');
    if (plus >= 0) s = s.substring(0, plus);
    return s;
  }

  static int _versionValue(String v) {
    final parts = _normalized(v).split('.');
    var value = 0;
    for (var i = 0; i < 3; i++) {
      final p = i < parts.length ? int.tryParse(parts[i]) ?? 0 : 0;
      value = value * 1000 + p;
    }
    return value;
  }

  static bool isNewer(String remote, String local) =>
      _versionValue(remote) > _versionValue(local);

  Future<void> checkForUpdate(String appVersion) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(
          Uri.parse('https://api.github.com/repos/$_repo/releases/latest'));
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        client.close(force: true);
        return;
      }
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);
      final tag = jsonDecode(body)['tag_name'] as String?;
      if (tag == null || !isNewer(tag, appVersion)) return;
      final assets = jsonDecode(body)['assets'] as List<dynamic>;
      for (final a in assets) {
        final name = a['name'] as String? ?? '';
        if (name.endsWith('.apk') && name.contains('release')) {
          _apkUrl = a['browser_download_url'] as String?;
          _apkSize = a['size'] as int? ?? 0;
          _latestTag = _normalized(tag);
          return;
        }
      }
    } catch (_) {}
  }

  Future<File> downloadApk(
    void Function(int received, int total, int bytesPerSec) onProgress, {
    String savePath = '/tmp/',
  }) async {
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(_apkUrl!));
    final res = await req.close().timeout(const Duration(seconds: 300));
    if (res.statusCode != 200) {
      client.close(force: true);
      throw Exception('Сервер ответил ${res.statusCode}');
    }
    final file = File('${savePath}aventoria-update.apk');
    final sink = file.openWrite();
    var received = 0;
    final total = res.contentLength > 0
        ? res.contentLength
        : (_apkSize > 0 ? _apkSize : 0);
    final sw = Stopwatch()..start();
    var lastReported = 0;
    await for (final chunk in res) {
      received += chunk.length;
      sink.add(chunk);
      if (sw.elapsedMilliseconds >= 500) {
        final bps =
            ((received - lastReported) * 1000) ~/ sw.elapsedMilliseconds;
        lastReported = received;
        sw.reset();
        onProgress(received, total, bps);
      }
    }
    onProgress(received, total, 0);
    await sink.flush();
    sink.close();
    client.close(force: true);
    return file;
  }

  Future<void> install(File apk) async {
    await OpenFilex.open(apk.path,
        type: 'application/vnd.android.package-archive');
  }
}

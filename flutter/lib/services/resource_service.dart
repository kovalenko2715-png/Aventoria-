import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

/// Игровые ресурсы (аудио, фон, карта) не зашиты в APK — клиент их
/// скачивает с GitHub Releases при первом запуске, как в лаунчерах.
class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  static const _repo = 'kovalenko2715-png/Aventoria-';

  Directory? _base;
  String _resourceVersion = '';

  String? latestUrl;
  int latestSize = 0;

  Future<void> loadLocal() async {
    final dir = await getApplicationDocumentsDirectory();
    _base = Directory('${dir.path}/game_resources');
    if (!await _base!.exists()) {
      await _base!.create(recursive: true);
    }
    final marker = File('${_base!.path}/version.txt');
    if (await marker.exists()) {
      _resourceVersion = (await marker.readAsString()).trim();
    }
  }

  bool isVersion(String appVersion) => _resourceVersion == appVersion;

  /// Путь к скачанному файлу ресурса (asset без префикса assets/),
  /// либо null — тогда берём из бандла.
  String? filePath(String asset) {
    final base = _base;
    if (base == null) return null;
    final f = File('${base.path}/$asset');
    return f.existsSync() ? f.path : null;
  }

  Future<void> checkRemote() async {
    final client = HttpClient();
    final req =
        await client.getUrl(Uri.parse('https://api.github.com/repos/$_repo/releases/latest'));
    req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final res = await req.close().timeout(const Duration(seconds: 15));
    final body = await res.transform(utf8.decoder).join();
    client.close(force: true);
    final assets = (jsonDecode(body)['assets'] as List<dynamic>? ?? const []);
    for (final a in assets) {
      final name = a['name'] as String? ?? '';
      if (name == 'aventoria-resources.zip') {
        latestUrl = a['browser_download_url'] as String?;
        latestSize = a['size'] as int? ?? 0;
        return;
      }
    }
    throw Exception('Ресурсы не найдены на GitHub');
  }

  Future<void> download(
      String appVersion, void Function(int received, int total, int bps) onProgress) async {
    if (latestUrl == null) throw Exception('Нет адреса загрузки');
    if (_base == null) throw Exception('Хранилище ресурсов не готово');
    final client = HttpClient();
    final req = await client.getUrl(Uri.parse(latestUrl!));
    final res = await req.close();
    if (res.statusCode != 200) {
      client.close(force: true);
      throw Exception('Сервер ответил ${res.statusCode}');
    }
    final file = File('${Directory.systemTemp.path}/aventoria-resources.zip');
    final sink = file.openWrite();
    var received = 0;
    final total = res.contentLength > 0 ? res.contentLength : latestSize;
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
    await sink.flush();
    sink.close();
    client.close(force: true);

    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    for (final entry in archive) {
      if (entry.isFile) {
        final name = entry.name.replaceAll('\\', '/');
        if (name.contains('..')) continue;
        final out = File('${_base!.path}/$name');
        await out.parent.create(recursive: true);
        await out.writeAsBytes(entry.content as List<int>);
      }
    }
    await File('${_base!.path}/version.txt').writeAsString(appVersion);
    _resourceVersion = appVersion;
    if (await file.exists()) await file.delete();
  }
}

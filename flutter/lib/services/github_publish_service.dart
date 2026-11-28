import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<List<int>?> _compressImageIsolate(String path, {int maxSide = 256}) async {
  try {
    final decoded = img.decodeImage(File(path).readAsBytesSync());
    if (decoded == null) return null;
    final big =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = big > maxSide
        ? img.copyResize(decoded,
            width: (decoded.width * maxSide / big).round(),
            height: (decoded.height * maxSide / big).round())
        : decoded;
    return img.encodePng(resized);
  } catch (_) {
    return null;
  }
}

/// Прямая загрузка файлов в репозиторий игры через GitHub Contents API.
/// Токен хранится ТОЛЬКО локально на устройстве админа (в документы приложения),
/// ни в базу, ни в APK он не попадает.
class GithubPublishService {
  GithubPublishService._();
  static final GithubPublishService instance = GithubPublishService._();

  static const repo = 'kovalenko2715-png/Aventoria-';
  static const branch = 'vibe/flutter-port-a0bddf';

  String? _cachedToken;

  Future<String?> token() async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) return _cachedToken;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/.gh_token');
      if (f.existsSync()) {
        final t = f.readAsStringSync().trim();
        if (t.isNotEmpty) _cachedToken = t;
      }
    } catch (_) {}
    return _cachedToken;
  }

  Future<void> saveToken(String t) async {
    _cachedToken = t.trim();
    final dir = await getApplicationDocumentsDirectory();
    File('${dir.path}/.gh_token').writeAsStringSync(_cachedToken!);
  }

  Future<bool> hasToken() async => (await token())?.isNotEmpty ?? false;

  Uri _api(String path) =>
      Uri.parse('https://api.github.com/repos/$repo/contents/$path');

  Map<String, String> _headers([bool json = false]) => {
        'Authorization': 'Bearer $_cachedToken',
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'Aventoria-Game',
        if (json) 'Content-Type': 'application/json',
      };

  /// Загружает один файл в репо. Возвращает null при успехе, иначе текст ошибки.
  Future<String?> uploadFile(
      String repoPath, List<int> bytes, String commitMessage) async {
    final tok = await token();
    if (tok == null || tok.isEmpty) {
      return 'Не задан токен GitHub (ключ в админ-панели).';
    }
    try {
      // Существующий файл? нужен его sha для перезаписи.
      String? sha;
      final getRes = await http
          .get(_api(repoPath).replace(queryParameters: {'ref': branch}),
              headers: _headers())
          .timeout(const Duration(seconds: 30));
      if (getRes.statusCode == 200) {
        sha = (jsonDecode(getRes.body) as Map<String, dynamic>)['sha']
            ?.toString();
      } else if (getRes.statusCode != 404) {
        return 'GitHub: чтение файла ${getRes.statusCode}';
      }
      final putRes = await http
          .put(_api(repoPath),
              headers: _headers(true),
              body: jsonEncode({
                'message': commitMessage,
                'content': base64Encode(bytes),
                'branch': branch,
                if (sha != null) 'sha': sha,
              }))
          .timeout(const Duration(seconds: 90));
      if (putRes.statusCode >= 200 && putRes.statusCode < 300) return null;
      return 'GitHub: загрузка ${putRes.statusCode}';
    } catch (e) {
      return '$e';
    }
  }

  /// Жмёт картинку: до `maxSide` px по большей стороне, PNG (альфа сохраняется).
  /// Возвращает null, если картинка не читается.
  Future<List<int>?> compressImage(File src, {int maxSide = 256}) {
    return compute(_compressImageIsolate, src.path);
  }

  /// Читает текстовый файл из репозитория (нужен токен).
  /// Кидает исключение при ошибке.
  Future<String> readText(String repoPath) async {
    final tok = await token();
    if (tok == null || tok.isEmpty) throw Exception('Нет токена GitHub');
    final getRes = await http
        .get(_api(repoPath).replace(queryParameters: {'ref': branch}),
            headers: _headers())
        .timeout(const Duration(seconds: 30));
    if (getRes.statusCode != 200) {
      throw Exception('GitHub: чтение ' + getRes.statusCode.toString());
    }
    final body = jsonDecode(getRes.body) as Map<String, dynamic>;
    final content = (body['content'] as String? ?? '').replaceAll('
', '');
    return utf8.decode(base64.decode(content));
  }

  /// Пишет текстовый файл с перезаписью. Возвращает null при успехе.
  Future<String?> writeText(
      String repoPath, String content, String commitMessage) async {
    return uploadFile(repoPath, utf8.encode(content), commitMessage);
  }
}

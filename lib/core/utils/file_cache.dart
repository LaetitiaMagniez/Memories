import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';

Future<String> getCachedFilePath(String url) async {
  final cacheDir = await getApplicationDocumentsDirectory();
  final urlHash = md5.convert(utf8.encode(url)).toString();

  final existingFile = Directory(cacheDir.path)
      .listSync()
      .whereType<File>()
      .firstWhere(
        (file) => file.path.contains(urlHash),
    orElse: () => File('${cacheDir.path}/__not_found__'),
  );

  if (await existingFile.exists() && !existingFile.path.endsWith('__not_found__')) {
    return existingFile.path;
  }

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Erreur lors du téléchargement : ${response.statusCode}');
  }

  final contentType = response.headers['content-type'] ?? 'application/octet-stream';
  final fileExtension = _extensionFromMime(contentType);
  final filePath = '${cacheDir.path}/$urlHash.$fileExtension';

  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);

  return file.path;
}

String _extensionFromMime(String mime) {
  switch (mime) {
    case 'image/png':
      return 'png';
    case 'image/webp':
      return 'webp';
    case 'image/gif':
      return 'gif';
    case 'image/jpeg':
      return 'jpg';
    case 'video/mp4':
      return 'mp4';
    default:
      return 'jpg';
  }
}

Future<String?> getCachedThumbnailPath(String videoUrl) async {
  try {
    final cacheDir = await getApplicationDocumentsDirectory();
    final urlHash = md5.convert(utf8.encode(videoUrl)).toString();
    final thumbPath = '${cacheDir.path}/$urlHash-thumb.png';

    if (await File(thumbPath).exists()) return thumbPath;

    String videoPath = videoUrl;
    if (videoUrl.startsWith('http')) {
      videoPath = await getCachedFilePath(videoUrl);
    }

    final thumbnail = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbPath,
      imageFormat: ImageFormat.PNG,
      maxWidth: 120,
      quality: 75,
    );

    return thumbnail;
  } catch (e, st) {
    debugPrint('Erreur dans getCachedThumbnailPath: $e\n$st');
    return null;
  }
}

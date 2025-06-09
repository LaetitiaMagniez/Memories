import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;


Future<String> getCachedFilePath(String url, {required String extension}) async {
  final cacheDir = await getApplicationDocumentsDirectory();
  final urlHash = md5.convert(utf8.encode(url)).toString();

  // Vérifiez si un fichier existe déjà (quel que soit l'extension)
  final existingFile = Directory(cacheDir.path).listSync().whereType<File>().firstWhere(
        (file) => file.path.contains(urlHash),
    orElse: () => File(''),
  );
  if (await existingFile.exists()) return existingFile.path;

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Erreur lors du téléchargement : ${response.statusCode}');
  }

  final contentType = response.headers['content-type'];
  final extension = _extensionFromMime(contentType ?? 'image/jpeg'); // fallback

  final filePath = '${cacheDir.path}/$urlHash.$extension';
  final file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return file.path;
}

String _extensionFromMime(String mime) {
  switch (mime) {
    case 'image/png': return 'png';
    case 'image/webp': return 'webp';
    case 'image/gif': return 'gif';
    default: return 'jpg';
  }
}

Future<String?> getCachedThumbnailPath(String videoUrl) async {
  final cacheDir = await getApplicationDocumentsDirectory();
  final urlHash = md5.convert(utf8.encode(videoUrl)).toString();
  final thumbPath = '${cacheDir.path}/$urlHash-thumb.png';

  if (File(thumbPath).existsSync()) return thumbPath;

  String videoPath = videoUrl;
  if (videoUrl.startsWith('http')) {
    videoPath = await getCachedFilePath(videoUrl, extension: 'mp4');
  }

  final thumbnail = await VideoThumbnail.thumbnailFile(
    video: videoPath,
    thumbnailPath: thumbPath,
    imageFormat: ImageFormat.PNG,
    maxWidth: 120,
    quality: 75,
  );

  return thumbnail;
}


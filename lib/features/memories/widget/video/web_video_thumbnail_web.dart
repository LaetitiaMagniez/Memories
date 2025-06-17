import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

Future<Uint8List?> generateWebVideoThumbnail(Uint8List videoBytes) async {
  final blob = html.Blob([videoBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final video = html.VideoElement()
    ..src = url
    ..muted = true
    ..autoplay = false
    ..controls = false
    ..style.display = 'none';

  final completer = Completer<Uint8List?>();
  html.document.body?.append(video);

  video.onLoadedMetadata.listen((_) {
    video.currentTime = 0.1;
  });

  video.onSeeked.listen((_) {
    final canvas = html.CanvasElement(
      width: video.videoWidth,
      height: video.videoHeight,
    );
    final ctx = canvas.context2D;
    ctx.drawImage(video, 0, 0);

    final dataUrl = canvas.toDataUrl('image/jpeg');
    final base64 = dataUrl.split(',').last;
    final bytes = base64Decode(base64);

    video.remove();
    html.Url.revokeObjectUrl(url);
    completer.complete(bytes);
  });

  return completer.future;
}
